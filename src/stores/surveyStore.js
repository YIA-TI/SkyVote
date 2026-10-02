import { defineStore } from "pinia";
import { compressImage } from "../lib/imageCompress";
import { BUKTI_BUCKET, supabase } from "../lib/supabaseClient";

// Display-only relabeling: "Non-Organik" pegawai are shown as "TAD" in the
// UI, but the underlying data/enum value stays "Non-Organik" everywhere
// (db column, comparisons, stored submissions) to avoid a schema migration.
export function jenisPegawaiLabel(jenisPegawai) {
  return jenisPegawai === "Non-Organik" ? "TAD" : jenisPegawai;
}

// ── Row <-> app-shape mappers (DB columns are snake_case, the app/components
// use the camelCase field names that were already in place before this
// Supabase migration, so component templates don't need to change) ────────

function mapSurvey(row) {
  return {
    id: row.id,
    nama: row.nama,
    tipe: row.tipe ?? "Eksternal",
    link: row.link ?? "",
    tanggalMulai: row.tanggal_mulai ?? "",
    tanggalSelesai: row.tanggal_selesai ?? "",
    status: row.status,
    maxPengisian: row.max_pengisian,
  };
}

function toSurveyRow({ nama, tipe, link, tanggalMulai, tanggalSelesai, status, maxPengisian }) {
  const isInternal = tipe === "Internal";
  let processedLink = isInternal || !link ? "" : link.trim();
  // Auto-add https:// if link doesn't start with http:// or https://
  if (processedLink && !processedLink.match(/^https?:\/\//i)) {
    processedLink = "https://" + processedLink;
  }
  return {
    nama: nama.trim(),
    tipe: isInternal ? "Internal" : "Eksternal",
    link: processedLink,
    tanggal_mulai: tanggalMulai || null,
    tanggal_selesai: tanggalSelesai || null,
    status: status || "Draft",
    max_pengisian: Number(maxPengisian) || 20,
  };
}

function mapQuestion(row) {
  return {
    id: row.id,
    surveyId: row.survey_id,
    urutan: row.urutan,
    tipe: row.tipe ?? "Pilihan",
    pertanyaan: row.pertanyaan,
    options: (row.survey_question_options ?? [])
      .slice()
      .sort((a, b) => a.urutan - b.urutan)
      .map((o) => ({ id: o.id, urutan: o.urutan, opsi: o.opsi })),
  };
}

function mapSubmission(row) {
  return {
    id: row.id,
    nama: row.nama,
    tanggal: row.tanggal,
    surveyId: row.survey_id,
    jenisPegawai: row.jenis_pegawai,
    departemen: row.departemen,
    fileBukti: row.file_bukti,
    createdAt: row.created_at,
  };
}

function mapEmployee(row) {
  return {
    id: row.id,
    nip: row.nip ?? "",
    nama: row.nama,
    unitKerja: row.unit_kerja,
    jenisPegawai: row.jenis_pegawai,
    isActive: row.is_active ?? true,
  };
}

function toEmployeeRow({ nip, nama, unitKerja, jenisPegawai }) {
  return {
    nip: nip ? nip.trim() : null,
    nama: nama.trim(),
    unit_kerja: unitKerja,
    jenis_pegawai: jenisPegawai,
  };
}

function mapNotification(row) {
  return {
    id: row.id,
    message: row.message,
    createdAt: row.created_at,
    read: row.read,
  };
}

export const useSurveyStore = defineStore("survey", {
  state: () => ({
    surveys: [],
    submissions: [],
    employees: [],
    departments: [],
    notifications: [],
    workforceTotals: { Organik: 0, "Non-Organik": 0 },
    lastSubmission: null,
    baseDataLoaded: false,
    realtimeChannels: [],
    questionCounts: {},
  }),

  getters: {
    findSurvey: (state) => (surveyId) =>
      state.surveys.find((s) => s.id === surveyId) || null,

    submissionCountForSurvey: (state) => (surveyId) =>
      state.submissions.filter((s) => s.surveyId === surveyId).length,

    submissionCountForEmployeeSurvey: (state) => (surveyId, nama) =>
      state.submissions.filter((s) => s.surveyId === surveyId && s.nama === nama).length,

    isSurveyFullForEmployee() {
      return (surveyId, nama) => {
        const survey = this.findSurvey(surveyId);
        if (!survey || !survey.maxPengisian || !nama) return false;
        return this.submissionCountForEmployeeSurvey(surveyId, nama) >= survey.maxPengisian;
      };
    },

    // Mirrors the DB-side check (RLS + enforce_submission_quota trigger):
    // status must be "Aktif" AND today must fall within the survey's date
    // period. Client-side filter for immediate display; the server side is
    // the actual enforcement, this just keeps the UI consistent with it in
    // the seconds between the period lapsing and the next sync_survey_statuses
    // tick.
    activeAvailableSurveys() {
      const today = new Date().toISOString().slice(0, 10);
      return this.surveys.filter((s) => {
        if (s.status !== "Aktif") return false;
        if (s.tanggalMulai && s.tanggalMulai > today) return false;
        if (s.tanggalSelesai && s.tanggalSelesai < today) return false;
        return true;
      });
    },

    submissionsBySurvey: (state) => (surveyId) =>
      state.submissions.filter((s) => s.surveyId === surveyId),

    sortedNotifications: (state) => [...state.notifications].sort((a, b) => b.id - a.id),

    unreadNotificationCount: (state) => state.notifications.filter((n) => !n.read).length,

    participationGroupedBy(state) {
      return (getKey, submissionsList, allKeys, maxPengisian = 1) => {
        const list = submissionsList ?? state.submissions;
        const activeEmployees = state.employees.filter((e) => e.isActive);
        const totalOrganik = activeEmployees.filter((e) => e.jenisPegawai === "Organik").length;
        const totalNonOrganik = activeEmployees.length - totalOrganik;
        const totalPegawai = totalOrganik + totalNonOrganik;
        const targetOrganik = totalOrganik * maxPengisian;
        const targetNonOrganik = totalNonOrganik * maxPengisian;
        const targetTotal = targetOrganik + targetNonOrganik;

        const grouped = new Map();
        if (allKeys) {
          for (const key of allKeys) {
            grouped.set(key, { organik: 0, nonOrganik: 0 });
          }
        }
        for (const submission of list) {
          const key = getKey(submission);
          if (!grouped.has(key)) {
            grouped.set(key, { organik: 0, nonOrganik: 0 });
          }
          const bucket = grouped.get(key);
          if (submission.jenisPegawai === "Organik") bucket.organik++;
          else bucket.nonOrganik++;
        }

        return Array.from(grouped.entries()).map(([key, { organik, nonOrganik }]) => {
          const pengisianTotal = organik + nonOrganik;
          return {
            key,
            pegawaiOrganik: totalOrganik,
            pegawaiNonOrganik: totalNonOrganik,
            pegawaiTotal: totalPegawai,
            targetOrganik,
            targetNonOrganik,
            targetTotal,
            pengisianOrganik: organik,
            pengisianNonOrganik: nonOrganik,
            pengisianTotal,
            gapOrganik: targetOrganik - organik,
            gapNonOrganik: targetNonOrganik - nonOrganik,
            gapTotal: targetTotal - pengisianTotal,
            persenOrganik: targetOrganik > 0 ? Math.round((organik / targetOrganik) * 1000) / 10 : 0,
            persenNonOrganik:
              targetNonOrganik > 0 ? Math.round((nonOrganik / targetNonOrganik) * 1000) / 10 : 0,
            persenTotal: targetTotal > 0 ? Math.round((pengisianTotal / targetTotal) * 1000) / 10 : 0,
          };
        });
      };
    },
  },

  actions: {
    // ── Fetches (populate the reactive cache from Supabase) ──────────────
    async fetchSurveys() {
      // Opportunistic sync so status reflects the date period immediately
      // on page load, without waiting for the next pg_cron tick. Swallow
      // errors — this is a freshness nicety, not something that should
      // block the survey list from loading.
      try {
        await supabase.rpc("sync_survey_statuses");
      } catch (err) {
        console.warn("sync_survey_statuses failed:", err);
      }

      const { data, error } = await supabase.from("surveys").select("*").order("id");
      if (error) throw error;
      this.surveys = data.map(mapSurvey);
    },

    async fetchSubmissions() {
      const { data, error } = await supabase.from("submissions").select("*").order("id");
      if (error) throw error;
      this.submissions = data.map(mapSubmission);
    },

    async fetchEmployees() {
      const { data, error } = await supabase.from("employees").select("*").order("nama");
      if (error) throw error;
      this.employees = data.map(mapEmployee);
    },

    async fetchDepartments() {
      const { data, error } = await supabase.from("departments").select("*").order("nama");
      if (error) throw error;
      this.departments = data.map((row) => row.nama);
    },

    async fetchWorkforceTotals() {
      const { data, error } = await supabase.from("workforce_totals").select("*");
      if (error) throw error;
      const totals = { Organik: 0, "Non-Organik": 0 };
      for (const row of data) totals[row.jenis_pegawai] = row.total;
      this.workforceTotals = totals;
    },

    async fetchNotifications() {
      const { data, error } = await supabase
        .from("notifications")
        .select("*")
        .order("id", { ascending: false })
        .limit(50);
      if (error) throw error;
      this.notifications = data.map(mapNotification);
    },

    // Fetches the shared data every page needs (surveys, employees,
    // submissions, workforce totals). Safe to call from every page's
    // onMounted — only hits the network once thanks to baseDataLoaded.
    async ensureBaseData() {
      if (this.baseDataLoaded) return;
      await Promise.all([
        this.fetchSurveys(),
        this.fetchEmployees(),
        this.fetchDepartments(),
        this.fetchSubmissions(),
        this.fetchWorkforceTotals(),
      ]);
      this.baseDataLoaded = true;
    },

    // ── Mutations ─────────────────────────────────────────────────────────
    async addSurvey(payload) {
      const { data, error } = await supabase
        .from("surveys")
        .insert(toSurveyRow(payload))
        .select()
        .single();
      if (error) throw error;
      const survey = mapSurvey(data);
      this.surveys.push(survey);
      return survey;
    },

    async updateSurvey(surveyId, payload) {
      const { data, error } = await supabase
        .from("surveys")
        .update(toSurveyRow(payload))
        .eq("id", surveyId)
        .select()
        .single();
      if (error) throw error;
      const survey = mapSurvey(data);
      const index = this.surveys.findIndex((s) => s.id === surveyId);
      if (index !== -1) this.surveys[index] = survey;
      return survey;
    },

    async updateSurveyStatus(surveyId, status) {
      const { error } = await supabase.from("surveys").update({ status }).eq("id", surveyId);
      if (error) throw error;
      const survey = this.findSurvey(surveyId);
      if (survey) survey.status = status;
    },

    async removeSurvey(surveyId) {
      const { error } = await supabase.from("surveys").delete().eq("id", surveyId);
      if (error) throw error;
      this.surveys = this.surveys.filter((s) => s.id !== surveyId);
      this.submissions = this.submissions.filter((s) => s.surveyId !== surveyId);
    },

    async addEmployee(payload) {
      const { data, error } = await supabase
        .from("employees")
        .insert(toEmployeeRow(payload))
        .select()
        .single();
      if (error) throw error;
      const employee = mapEmployee(data);
      this.employees.push(employee);
      this.employees.sort((a, b) => a.nama.localeCompare(b.nama));
      return employee;
    },

    async updateEmployee(employeeId, payload) {
      const { data, error } = await supabase
        .from("employees")
        .update(toEmployeeRow(payload))
        .eq("id", employeeId)
        .select()
        .single();
      if (error) throw error;
      const employee = mapEmployee(data);
      const index = this.employees.findIndex((e) => e.id === employeeId);
      if (index !== -1) this.employees[index] = employee;
      return employee;
    },

    // "Deleting" an employee is a soft delete: their row and all past
    // submissions stay intact for reporting, they're just flipped to
    // inactive so the public survey form's name search and the "belum
    // mengisi survei" list stop offering them.
    async setEmployeeActive(employeeId, isActive) {
      const { data, error } = await supabase
        .from("employees")
        .update({ is_active: isActive })
        .eq("id", employeeId)
        .select()
        .single();
      if (error) throw error;
      const employee = mapEmployee(data);
      const index = this.employees.findIndex((e) => e.id === employeeId);
      if (index !== -1) this.employees[index] = employee;
      return employee;
    },

    // Lightweight per-survey question tally for the Kelola Survei table (the
    // full question+options fetch is only worth doing per-survey in the
    // builder/results pages, not for every row of a list).
    async fetchQuestionCounts() {
      const { data, error } = await supabase.from("survey_questions").select("survey_id");
      if (error) throw error;
      const counts = {};
      for (const row of data) counts[row.survey_id] = (counts[row.survey_id] ?? 0) + 1;
      this.questionCounts = counts;
    },

    async fetchSurveyQuestions(surveyId) {
      const { data, error } = await supabase
        .from("survey_questions")
        .select("*, survey_question_options(*)")
        .eq("survey_id", surveyId)
        .order("urutan");
      if (error) throw error;
      return data.map(mapQuestion);
    },

    // Replaces every question/option row for this survey. Simplest correct
    // approach for a builder UI (delete-then-insert instead of diffing) — see
    // 014_internal_surveys.sql for the trade-off this implies for historical
    // answers.
    async saveSurveyQuestions(surveyId, questions) {
      const { error: delError } = await supabase
        .from("survey_questions")
        .delete()
        .eq("survey_id", surveyId);
      if (delError) throw delError;

      for (let i = 0; i < questions.length; i++) {
        const q = questions[i];
        const { data: qRow, error: qError } = await supabase
          .from("survey_questions")
          .insert({ survey_id: surveyId, urutan: i, tipe: q.tipe, pertanyaan: q.pertanyaan.trim() })
          .select()
          .single();
        if (qError) throw qError;

        if (q.tipe === "Lisan") continue;
        const optionsPayload = q.options
          .map((o, oi) => ({ question_id: qRow.id, urutan: oi, opsi: o.opsi.trim() }))
          .filter((o) => o.opsi);
        if (optionsPayload.length) {
          const { error: oError } = await supabase.from("survey_question_options").insert(optionsPayload);
          if (oError) throw oError;
        }
      }
    },

    // Aggregates answers per question for the admin results page: option
    // tallies for "Pilihan"/"PilihanMulti" questions, the raw text list for
    // "Lisan" ones. Matched primarily by question_id so two questions that
    // happen to share the same wording don't leak answers into each other;
    // falls back to pertanyaan-text matching only for orphaned answers whose
    // question_id no longer points at a live row (after saveSurveyQuestions
    // has delete-then-reinserted the question list — see 014's migration note).
    async fetchSurveyResults(surveyId) {
      const [{ data: questions, error: qError }, { data: answers, error: aError }] = await Promise.all([
        supabase
          .from("survey_questions")
          .select("*, survey_question_options(*)")
          .eq("survey_id", surveyId)
          .order("urutan"),
        supabase.from("survey_answers").select("*").eq("survey_id", surveyId).order("id"),
      ]);
      if (qError) throw qError;
      if (aError) throw aError;

      const liveQuestionIds = new Set(questions.map((q) => q.id));

      return questions.map((q) => {
        const questionAnswers = answers.filter(
          (a) => a.question_id === q.id || (!liveQuestionIds.has(a.question_id) && a.pertanyaan === q.pertanyaan)
        );
        // Distinct respondents, not raw answer rows: a "PilihanMulti" question
        // can produce several answer rows per submission (one per checked
        // option), so counting rows would inflate totalJawaban and skew %.
        const totalJawaban = new Set(questionAnswers.map((a) => a.submission_id)).size;

        if (q.tipe === "Lisan") {
          return {
            id: q.id,
            tipe: "Lisan",
            pertanyaan: q.pertanyaan,
            totalJawaban,
            answers: questionAnswers.map((a) => a.jawaban),
          };
        }
        const options = (q.survey_question_options ?? []).slice().sort((a, b) => a.urutan - b.urutan);
        return {
          id: q.id,
          tipe: q.tipe,
          pertanyaan: q.pertanyaan,
          totalJawaban,
          options: options.map((o) => ({
            id: o.id,
            opsi: o.opsi,
            count: questionAnswers.filter((a) => a.jawaban === o.opsi).length,
          })),
        };
      });
    },

    async addSubmission({ nama, tanggal, surveyId, jenisPegawai, departemen, file, answers }) {
      if (answers) {
        // Internal survey: answers are already the record, no file upload.
        // One RPC round-trip so we get the new submission's id back without
        // needing an anon SELECT policy on submissions (see addSubmission's
        // file-upload branch below for why that's normally avoided).
        const { data, error } = await supabase.rpc("submit_internal_survey", {
          p_survey_id: surveyId,
          p_nama: nama,
          p_tanggal: tanggal,
          p_jenis_pegawai: jenisPegawai,
          p_departemen: departemen,
          p_answers: answers,
        });
        if (error) throw new Error(error.message);
        const submission = mapSubmission(data);
        this.submissions.push(submission);
        this.lastSubmission = submission;
        return submission;
      }

      const compressedFile = await compressImage(file);
      const path = `${surveyId}/${Date.now()}-${compressedFile.name}`;
      const { error: uploadError } = await supabase.storage
        .from(BUKTI_BUCKET)
        .upload(path, compressedFile);
      if (uploadError) {
        throw new Error(`Gagal mengunggah bukti: ${uploadError.message}`);
      }

      // No .select() here — the public submissions_insert_public RLS policy
      // only grants anon INSERT, not SELECT (that's admin-only), so asking
      // Postgrest to read the row back after insert would fail RLS even
      // though the insert itself succeeded. Build the local copy from what
      // we already know instead of round-tripping a read.
      const { error } = await supabase.from("submissions").insert({
        nama,
        tanggal,
        survey_id: surveyId,
        jenis_pegawai: jenisPegawai,
        departemen,
        file_bukti: path,
      });

      if (error) {
        // The DB trigger raises the quota/inactive-survey exceptions in
        // Indonesian already (see enforce_submission_quota in
        // 001_schema.sql) — surface that message as-is to the toast.
        throw new Error(error.message);
      }

      const submission = mapSubmission({
        id: `local-${Date.now()}`,
        nama,
        tanggal,
        survey_id: surveyId,
        jenis_pegawai: jenisPegawai,
        departemen,
        file_bukti: path,
        created_at: new Date().toISOString(),
      });
      this.submissions.push(submission);
      this.lastSubmission = submission;
      return submission;
    },

    // Deletes one submission row entirely (plus its evidence photo, if
    // any) — used by the per-row "Hapus Data" button. Drops that employee's
    // participation record for this survey, so their quota resets.
    async deleteSubmission(submissionId) {
      const submission = this.submissions.find((s) => s.id === submissionId);
      if (!submission) return;

      if (submission.fileBukti) {
        const { error: removeError } = await supabase.storage
          .from(BUKTI_BUCKET)
          .remove([submission.fileBukti]);
        if (removeError) {
          throw new Error(`Gagal menghapus file: ${removeError.message}`);
        }
      }

      const { error: deleteError } = await supabase.from("submissions").delete().eq("id", submissionId);
      if (deleteError) throw new Error(deleteError.message);

      this.submissions = this.submissions.filter((s) => s.id !== submissionId);
    },

    // Deletes the submission rows themselves (not just the photos) for one
    // survey — used by the "Hapus Data" button when the admin wants to wipe
    // out every employee's entry for that survey, not merely free up
    // storage. Also drops quota/participation history, so employees could
    // submit again from scratch.
    async deleteAllSubmissionsForSurvey(surveyId) {
      const targets = this.submissions.filter((s) => s.surveyId === surveyId);
      if (targets.length === 0) return 0;

      const paths = targets.filter((s) => s.fileBukti).map((s) => s.fileBukti);
      if (paths.length > 0) {
        const { error: removeError } = await supabase.storage.from(BUKTI_BUCKET).remove(paths);
        if (removeError) {
          throw new Error(`Gagal menghapus file: ${removeError.message}`);
        }
      }

      const { error: deleteError } = await supabase
        .from("submissions")
        .delete()
        .eq("survey_id", surveyId);
      if (deleteError) throw new Error(deleteError.message);

      this.submissions = this.submissions.filter((s) => s.surveyId !== surveyId);

      return targets.length;
    },

    async markNotificationRead(notificationId) {
      const { error } = await supabase
        .from("notifications")
        .update({ read: true })
        .eq("id", notificationId);
      if (error) throw error;
      const notification = this.notifications.find((n) => n.id === notificationId);
      if (notification) notification.read = true;
    },

    async markAllNotificationsRead() {
      const unreadIds = this.notifications.filter((n) => !n.read).map((n) => n.id);
      if (unreadIds.length === 0) return;
      const { error } = await supabase
        .from("notifications")
        .update({ read: true })
        .in("id", unreadIds);
      if (error) throw error;
      this.notifications.forEach((n) => {
        n.read = true;
      });
    },

    async deleteNotification(notificationId) {
      const { data, error } = await supabase
        .from("notifications")
        .delete()
        .eq("id", notificationId)
        .select("id");
      if (error) throw error;
      if (!data || data.length === 0) {
        throw new Error(
          "Notifikasi tidak terhapus di database (kemungkinan migrasi 012_notifications_admin_delete.sql belum dijalankan)."
        );
      }
      this.notifications = this.notifications.filter((n) => n.id !== notificationId);
    },

    async clearAllNotifications() {
      const ids = this.notifications.map((n) => n.id);
      if (ids.length === 0) return;
      const { data, error } = await supabase.from("notifications").delete().in("id", ids).select("id");
      if (error) throw error;
      if (!data || data.length < ids.length) {
        throw new Error(
          "Sebagian notifikasi tidak terhapus di database (kemungkinan migrasi 012_notifications_admin_delete.sql belum dijalankan)."
        );
      }
      this.notifications = [];
    },

    // ── Realtime subscriptions ────────────────────────────────────────────
    setupRealtimeSubscriptions() {
      const surveysChannel = supabase
        .channel("surveys-changes")
        .on(
          "postgres_changes",
          { event: "INSERT", schema: "public", table: "surveys" },
          (payload) => {
            const survey = mapSurvey(payload.new);
            this.surveys.push(survey);
          }
        )
        .on(
          "postgres_changes",
          { event: "UPDATE", schema: "public", table: "surveys" },
          (payload) => {
            const index = this.surveys.findIndex((s) => s.id === payload.new.id);
            if (index !== -1) {
              this.surveys[index] = mapSurvey(payload.new);
            }
          }
        )
        .on(
          "postgres_changes",
          { event: "DELETE", schema: "public", table: "surveys" },
          (payload) => {
            this.surveys = this.surveys.filter((s) => s.id !== payload.old.id);
          }
        )
        .subscribe();

      const submissionsChannel = supabase
        .channel("submissions-changes")
        .on(
          "postgres_changes",
          { event: "INSERT", schema: "public", table: "submissions" },
          (payload) => {
            const submission = mapSubmission(payload.new);
            this.submissions.push(submission);
            this.lastSubmission = submission;
          }
        )
        .on(
          "postgres_changes",
          { event: "UPDATE", schema: "public", table: "submissions" },
          (payload) => {
            const index = this.submissions.findIndex((s) => s.id === payload.new.id);
            if (index !== -1) {
              this.submissions[index] = mapSubmission(payload.new);
            }
          }
        )
        .on(
          "postgres_changes",
          { event: "DELETE", schema: "public", table: "submissions" },
          (payload) => {
            this.submissions = this.submissions.filter((s) => s.id !== payload.old.id);
          }
        )
        .subscribe();

      const notificationsChannel = supabase
        .channel("notifications-changes")
        .on(
          "postgres_changes",
          { event: "INSERT", schema: "public", table: "notifications" },
          (payload) => {
            const notification = mapNotification(payload.new);
            this.notifications.unshift(notification);
          }
        )
        .on(
          "postgres_changes",
          { event: "UPDATE", schema: "public", table: "notifications" },
          (payload) => {
            const index = this.notifications.findIndex((n) => n.id === payload.new.id);
            if (index !== -1) {
              this.notifications[index] = mapNotification(payload.new);
            }
          }
        )
        .subscribe();

      this.realtimeChannels.push(surveysChannel, submissionsChannel, notificationsChannel);
    },

    cleanupRealtimeSubscriptions() {
      for (const channel of this.realtimeChannels) {
        supabase.removeChannel(channel);
      }
      this.realtimeChannels = [];
    },
  },
});
