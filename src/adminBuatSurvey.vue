<template>
  <div class="buat-survey-page">
    <div class="page-heading">
      <div>
        <RouterLink to="/admin/management" class="back-link">
          <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
            <path d="M12 4 6 10l6 6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          Kembali
        </RouterLink>
        <h1 class="page-title">{{ isEditing ? "Edit Survei" : "Buat Survei Baru" }}</h1>
        <p class="page-subtitle">
          {{
            isEditing
              ? "Perbarui detail survei ini."
              : "Isi detail survei untuk ditambahkan ke daftar survei."
          }}
        </p>
      </div>
    </div>

    <form class="form-card" @submit.prevent="handleSubmit">
      <div class="section">
        <span class="section-label">Informasi Dasar</span>

        <div class="field">
          <label class="field-label" for="nama">Nama Survei</label>
          <div class="input-wrap">
            <svg class="input-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
              <rect x="3" y="4" width="14" height="12" rx="1.5" stroke="currentColor" stroke-width="1.5" />
              <path d="M6 8h8M6 11h5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
            </svg>
            <input
              id="nama"
              v-model.trim="form.nama"
              class="input"
              placeholder="Contoh: Kepuasan Layanan Terminal 3"
              required
            />
          </div>
        </div>

        <div class="field">
          <label class="field-label">Pilih Survei</label>
          <div class="tipe-toggle">
            <button
              type="button"
              class="tipe-btn"
              :class="{ active: form.tipe === 'Eksternal' }"
              @click="form.tipe = 'Eksternal'"
            >
              Eksternal
            </button>
            <button
              type="button"
              class="tipe-btn"
              :class="{ active: form.tipe === 'Internal' }"
              @click="form.tipe = 'Internal'"
            >
              Internal
            </button>
          </div>

          <div v-if="form.tipe === 'Internal'" class="tipe-field">
            <label class="field-label" for="deskripsi">Deskripsi</label>
            <textarea
              id="deskripsi"
              v-model.trim="form.deskripsi"
              class="input input-textarea"
              rows="4"
              placeholder="Jelaskan detail kegiatan survei yang akan dilakukan..."
            />
          </div>

          <template v-if="form.tipe === 'Eksternal'">
            <div class="input-wrap tipe-field">
              <svg class="input-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
                <path
                  d="M8.5 11.5 11.5 8.5M9 6l.6-.6a3 3 0 0 1 4.2 4.2L13 10.4M11 14l-.6.6a3 3 0 0 1-4.2-4.2L7 9.6"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
              </svg>
              <input
                id="link"
                v-model.trim="form.link"
                class="input"
                type="text"
                placeholder="https://forms.familia.id/..."
              />
            </div>
            <p class="field-helper">Opsional — bisa dikosongkan dan diisi nanti sebelum survei diaktifkan.</p>
          </template>

          <div v-else class="question-builder tipe-field">
            <div v-for="(q, qi) in form.questions" :key="qi" class="qb-question">
              <div class="qb-question-header">
                <span class="qb-question-index">Pertanyaan {{ qi + 1 }}</span>
                <button type="button" class="qb-remove" @click="removeQuestion(qi)">Hapus</button>
              </div>
              <input
                v-model.trim="q.pertanyaan"
                class="input qb-question-input"
                placeholder="Tulis pertanyaan..."
              />

              <div class="qb-tipe-toggle">
                <button
                  type="button"
                  class="qb-tipe-btn"
                  :class="{ active: q.tipe === 'Pilihan' }"
                  @click="setQuestionTipe(qi, 'Pilihan')"
                >
                  Single Choice
                </button>
                <button
                  type="button"
                  class="qb-tipe-btn"
                  :class="{ active: q.tipe === 'PilihanMulti' }"
                  @click="setQuestionTipe(qi, 'PilihanMulti')"
                >
                  Multi Choice
                </button>
                <button
                  type="button"
                  class="qb-tipe-btn"
                  :class="{ active: q.tipe === 'Lisan' }"
                  @click="setQuestionTipe(qi, 'Lisan')"
                >
                  Teks
                </button>
              </div>

              <template v-if="q.tipe !== 'Lisan'">
                <div class="qb-options">
                  <div v-for="(opt, oi) in q.options" :key="oi" class="qb-option-row">
                    <input v-model.trim="opt.opsi" class="input qb-option-input" placeholder="Opsi jawaban" />
                    <button
                      type="button"
                      class="qb-remove-option"
                      title="Hapus opsi"
                      @click="removeOption(qi, oi)"
                    >
                      &times;
                    </button>
                  </div>
                </div>
                <button type="button" class="qb-add-option" @click="addOption(qi)">+ Tambah Opsi</button>
              </template>
              <p v-else class="qb-lisan-hint">Pegawai akan mengisi jawaban bebas (teks), tanpa opsi.</p>
            </div>
            <button type="button" class="btn-outline qb-add-question" @click="addQuestion">
              + Tambah Pertanyaan
            </button>
            <p class="field-helper">
              Pegawai akan menjawab pertanyaan ini langsung di halaman input, tanpa perlu upload bukti foto.
            </p>
          </div>
        </div>
      </div>

      <div class="section-divider" />

      <div class="section">
        <span class="section-label">Rentang Tanggal</span>

        <div class="field-row">
          <div class="field">
            <label class="field-label" for="tanggal-mulai">Tanggal Mulai</label>
            <div class="input-wrap" @click="openDatePicker(tanggalMulaiInput)">
              <svg class="input-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
                <rect x="3" y="4" width="14" height="13" rx="1.5" stroke="currentColor" stroke-width="1.5" />
                <path d="M3 8h14M6.5 2.5v3M13.5 2.5v3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
              </svg>
              <input
                id="tanggal-mulai"
                ref="tanggalMulaiInput"
                v-model="form.tanggalMulai"
                class="input"
                type="date"
                required
              />
            </div>
          </div>
          <div class="field">
            <label class="field-label" for="tanggal-selesai">Tanggal Selesai</label>
            <div class="input-wrap" @click="openDatePicker(tanggalSelesaiInput)">
              <svg class="input-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
                <rect x="3" y="4" width="14" height="13" rx="1.5" stroke="currentColor" stroke-width="1.5" />
                <path d="M3 8h14M6.5 2.5v3M13.5 2.5v3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
              </svg>
              <input
                id="tanggal-selesai"
                ref="tanggalSelesaiInput"
                v-model="form.tanggalSelesai"
                class="input"
                type="date"
                :min="form.tanggalMulai"
                required
              />
            </div>
          </div>
        </div>
        <p class="field-helper">
          Tidak wajib diisi jika Anda menyimpan survei ini sebagai draft.
        </p>
      </div>

      <div class="section-divider" />

      <div class="section">
        <span class="section-label">Kuota &amp; Status</span>

        <div class="field-row">
          <div class="field">
            <label class="field-label" for="max-pengisian">Max Pengisian</label>
            <div class="input-wrap">
              <svg class="input-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
                <path
                  d="M10 3v14M3 10h14"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                />
              </svg>
              <input
                id="max-pengisian"
                v-model.number="form.maxPengisian"
                class="input"
                type="number"
                min="1"
                required
              />
            </div>
            <p class="field-helper">
              Batas maksimal satu pegawai mengisi survei ini (standar: 20 kali). Pegawai lain tetap
              punya kuota sendiri-sendiri.
            </p>
          </div>
          <div class="field">
            <label class="field-label" for="status">Status Survei</label>
            <div class="input-wrap">
              <svg class="input-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
                <path d="M5 3v14M5 3h8l-2 3 2 3H5" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" />
              </svg>
              <select id="status" v-model="form.status" class="input input-select">
                <option value="Draft">Draft</option>
                <option value="Terjadwal">Terjadwal</option>
                <option value="Aktif">Aktif</option>
                <option value="Selesai">Selesai</option>
              </select>
            </div>
            <p class="field-helper">
              Survei "Aktif" langsung tampil di halaman input bukti pegawai. Jika periode tanggal
              diisi, status akan otomatis berubah ke "Aktif" saat tanggal mulai tiba dan ke "Selesai"
              setelah tanggal selesai terlewati.
            </p>
          </div>
        </div>
      </div>

      <div class="form-footer">
        <RouterLink to="/admin/management" class="btn-secondary">Batal</RouterLink>
        <button type="button" class="btn-outline" @click="handleSaveDraft">
          Simpan sebagai Draft
        </button>
        <button type="submit" class="btn-primary">
          {{ isEditing ? "Simpan Perubahan" : "Simpan Survei" }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { computed, reactive, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useSurveyStore } from "./stores/surveyStore";
import { useToastStore } from "./stores/toastStore";

const store = useSurveyStore();
const toast = useToastStore();
const router = useRouter();
const route = useRoute();

const editingId = computed(() => (route.params.id ? Number(route.params.id) : null));
const isEditing = computed(() => editingId.value !== null);

const tanggalMulaiInput = ref(null);
const tanggalSelesaiInput = ref(null);

function openDatePicker(inputRef) {
  try {
    inputRef.value?.showPicker();
  } catch {
    inputRef.value?.focus();
  }
}

function emptyQuestion() {
  return { tipe: "Pilihan", pertanyaan: "", options: [{ opsi: "" }, { opsi: "" }] };
}

function setQuestionTipe(questionIndex, tipe) {
  const q = form.questions[questionIndex];
  q.tipe = tipe;
  if (tipe !== "Lisan" && q.options.length === 0) {
    q.options = [{ opsi: "" }, { opsi: "" }];
  }
}

const form = reactive({
  nama: "",
  tipe: "Eksternal",
  link: "",
  deskripsi: "",
  questions: [emptyQuestion()],
  tanggalMulai: "",
  tanggalSelesai: "",
  status: "Draft",
  maxPengisian: 20,
});

function addQuestion() {
  form.questions.push(emptyQuestion());
}

function removeQuestion(index) {
  form.questions.splice(index, 1);
}

function addOption(questionIndex) {
  form.questions[questionIndex].options.push({ opsi: "" });
}

function removeOption(questionIndex, optionIndex) {
  form.questions[questionIndex].options.splice(optionIndex, 1);
}

watch(
  editingId,
  async (id) => {
    await store.ensureBaseData();

    if (id === null) {
      form.nama = "";
      form.tipe = "Eksternal";
      form.link = "";
      form.deskripsi = "";
      form.questions = [emptyQuestion()];
      form.tanggalMulai = "";
      form.tanggalSelesai = "";
      form.status = "Draft";
      form.maxPengisian = 20;
      return;
    }

    const survey = store.findSurvey(id);
    if (!survey) {
      toast.show("Survei tidak ditemukan.", "error");
      router.replace("/admin/management");
      return;
    }

    form.nama = survey.nama;
    form.tipe = survey.tipe;
    form.link = survey.link;
    form.deskripsi = survey.deskripsi;
    form.tanggalMulai = survey.tanggalMulai;
    form.tanggalSelesai = survey.tanggalSelesai;
    form.status = survey.status;
    form.maxPengisian = survey.maxPengisian;

    if (survey.tipe === "Internal") {
      try {
        const questions = await store.fetchSurveyQuestions(id);
        form.questions = questions.length
          ? questions.map((q) => ({
              tipe: q.tipe,
              pertanyaan: q.pertanyaan,
              options:
                q.tipe === "Lisan"
                  ? []
                  : q.options.length
                  ? q.options.map((o) => ({ opsi: o.opsi }))
                  : [{ opsi: "" }, { opsi: "" }],
            }))
          : [emptyQuestion()];
      } catch (err) {
        toast.show("Gagal memuat pertanyaan survei.", "error");
      }
    } else {
      form.questions = [emptyQuestion()];
    }
  },
  { immediate: true }
);

function buildPayload(overrides = {}) {
  return {
    nama: form.nama,
    tipe: form.tipe,
    link: form.link,
    deskripsi: form.deskripsi,
    tanggalMulai: form.tanggalMulai,
    tanggalSelesai: form.tanggalSelesai,
    status: form.status,
    maxPengisian: form.maxPengisian,
    ...overrides,
  };
}

function validQuestions() {
  return form.questions
    .map((q) => ({
      tipe: q.tipe,
      pertanyaan: q.pertanyaan.trim(),
      options: q.tipe === "Lisan" ? [] : q.options.filter((o) => o.opsi.trim()),
    }))
    .filter((q) => q.pertanyaan && (q.tipe === "Lisan" || q.options.length >= 2));
}

async function saveSurvey(payload, { requireQuestions } = {}) {
  if (payload.tipe === "Internal") {
    const questions = validQuestions();
    if (requireQuestions && questions.length === 0) {
      throw new Error("Survei Internal butuh minimal 1 pertanyaan dengan 2 opsi jawaban.");
    }
    const survey = isEditing.value
      ? await store.updateSurvey(editingId.value, payload)
      : await store.addSurvey(payload);
    await store.saveSurveyQuestions(survey.id, questions);
    return survey;
  }

  if (isEditing.value) {
    return store.updateSurvey(editingId.value, payload);
  }
  return store.addSurvey(payload);
}

async function handleSubmit() {
  try {
    await saveSurvey(buildPayload(), { requireQuestions: true });
    toast.show(isEditing.value ? "Survei berhasil diperbarui" : "Survei berhasil ditambahkan", "success");
    router.push("/admin/management");
  } catch (err) {
    toast.show(err.message, "error");
  }
}

async function handleSaveDraft() {
  if (!form.nama.trim()) {
    toast.show("Nama survei wajib diisi.", "error");
    return;
  }
  try {
    await saveSurvey(buildPayload({ status: "Draft" }));
    toast.show("Survei disimpan sebagai draft", "success");
    router.push("/admin/management");
  } catch (err) {
    toast.show(err.message, "error");
  }
}
</script>

<style scoped>
.buat-survey-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 100%;
  max-width: 640px;
  margin: 0 auto;
}

.page-heading {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.back-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  color: var(--color-text-muted);
  font-size: 13px;
  font-weight: 600;
  text-decoration: none;
}

.back-link:hover {
  color: var(--color-primary);
}

.page-title {
  font-size: 22px;
  font-weight: 800;
  color: var(--color-text);
  letter-spacing: -0.025em;
}

.page-subtitle {
  font-size: 14px;
  color: var(--color-text-muted);
  line-height: 1.5;
}

.form-card {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 28px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.section {
  display: flex;
  flex-direction: column;
  gap: 16px;
  animation: field-enter 0.4s cubic-bezier(0.16, 1, 0.3, 1) both;
}

.section:nth-of-type(1) {
  animation-delay: 0.16s;
}

.section:nth-of-type(2) {
  animation-delay: 0.24s;
}

.section:nth-of-type(3) {
  animation-delay: 0.32s;
}

.form-footer {
  animation: field-enter 0.4s cubic-bezier(0.16, 1, 0.3, 1) both;
  animation-delay: 0.4s;
}

@keyframes field-enter {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
  }
}

@media (prefers-reduced-motion: reduce) {
  .section,
  .form-footer {
    animation: none !important;
  }
}

.section-label {
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--color-text-muted);
}

.section-divider {
  height: 1px;
  background-color: var(--color-border);
}

.field-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.01em;
  color: var(--color-text-secondary);
}

.field-helper {
  font-size: 12px;
  color: var(--color-text-muted);
  margin-top: 2px;
}

.input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.input-icon {
  position: absolute;
  left: 12px;
  color: var(--color-text-muted);
  pointer-events: none;
  transition: color 0.15s ease;
}

.input {
  width: 100%;
  height: 40px;
  padding: 0 12px 0 36px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  font-family: var(--font-sans);
  font-size: 14px;
  color: var(--color-text);
  background-color: var(--color-surface);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.input-textarea {
  height: auto;
  min-height: 96px;
  padding: 10px 12px;
  line-height: 1.5;
  resize: vertical;
}

.input-select {
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8' fill='none'%3E%3Cpath d='M1 1.5 6 6.5 11 1.5' stroke='%23334155' stroke-width='1.6' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 14px center;
  padding-right: 34px;
  cursor: pointer;
}

.input:hover {
  border-color: var(--color-text-muted);
}

.input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px rgba(0, 93, 172, 0.2);
}

.input-wrap:has(.input:focus) .input-icon {
  color: var(--color-primary);
}

.tipe-toggle {
  display: inline-flex;
  padding: 3px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  background-color: var(--color-bg);
  width: fit-content;
}

.tipe-btn {
  padding: 7px 18px;
  border: none;
  border-radius: calc(var(--radius-md) - 3px);
  background-color: transparent;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.tipe-btn.active {
  background-color: var(--color-primary);
  color: #ffffff;
}

.tipe-field {
  margin-top: 10px;
}

.question-builder {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.qb-question {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 14px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background-color: var(--color-bg);
}

.qb-question-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.qb-question-index {
  font-size: 12px;
  font-weight: 700;
  color: var(--color-text-secondary);
}

.qb-remove {
  border: none;
  background: transparent;
  color: var(--color-danger);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  padding: 0;
}

.qb-question-input {
  padding-left: 12px;
}

.qb-tipe-toggle {
  display: inline-flex;
  padding: 2px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-sm);
  background-color: var(--color-surface);
  width: fit-content;
}

.qb-tipe-btn {
  padding: 5px 12px;
  border: none;
  border-radius: calc(var(--radius-sm) - 2px);
  background-color: transparent;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.qb-tipe-btn.active {
  background-color: var(--color-primary);
  color: #ffffff;
}

.qb-lisan-hint {
  margin: 0;
  font-size: 12px;
  color: var(--color-text-muted);
  font-style: italic;
}

.qb-options {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.qb-option-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.qb-option-input {
  height: 34px;
  padding-left: 12px;
  font-size: 13px;
}

.qb-remove-option {
  flex-shrink: 0;
  width: 26px;
  height: 26px;
  border: none;
  border-radius: var(--radius-sm);
  background-color: transparent;
  color: var(--color-text-muted);
  font-size: 16px;
  line-height: 1;
  cursor: pointer;
}

.qb-remove-option:hover {
  background-color: var(--color-danger-bg);
  color: var(--color-danger);
}

.qb-add-option {
  align-self: flex-start;
  border: none;
  background: transparent;
  color: var(--color-primary);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  padding: 0;
}

.qb-add-question {
  align-self: flex-start;
}

.form-footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 12px;
  margin-top: 4px;
  flex-wrap: wrap;
}

.btn-primary {
  min-height: 40px;
  padding: 10px 24px;
  border: none;
  border-radius: var(--radius-md);
  background-color: var(--color-primary);
  color: #ffffff;
  font-family: var(--font-sans);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary:hover {
  background-color: var(--color-primary-dark);
}

.btn-outline {
  min-height: 40px;
  padding: 10px 20px;
  border: 1px solid var(--color-primary);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  color: var(--color-primary);
  font-family: var(--font-sans);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-outline:hover {
  background-color: var(--color-bg);
}

.btn-secondary {
  min-height: 40px;
  padding: 10px 20px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 14px;
  font-weight: 600;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.15s ease;
}

.btn-secondary:hover {
  background-color: var(--color-bg);
}

@media (max-width: 640px) {
  .form-card {
    padding: 18px;
  }

  .field-row {
    grid-template-columns: 1fr;
  }

  .form-footer {
    flex-direction: column-reverse;
    align-items: stretch;
  }

  .form-footer > * {
    width: 100%;
    justify-content: center;
    text-align: center;
  }
}
</style>
