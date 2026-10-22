<template>
  <div class="employee-status">
    <div v-if="ready" class="toolbar">
      <div class="search-box">
        <svg class="search-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
          <circle cx="9" cy="9" r="6.5" stroke="currentColor" stroke-width="1.6" />
          <path d="M17 17l-3.5-3.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
        </svg>
        <input v-model="search" class="search-input" type="text" placeholder="Cari Nama Pegawai..." />
      </div>

      <div class="status-toggle">
        <button
          type="button"
          class="toggle-option"
          :class="{ active: statusFilter === 'sudah' }"
          @click="statusFilter = 'sudah'; page = 1"
        >
          Sudah Selesai
        </button>
        <button
          type="button"
          class="toggle-option"
          :class="{ active: statusFilter === 'belum' }"
          @click="statusFilter = 'belum'; page = 1"
        >
          Belum Mengisi
        </button>
      </div>
    </div>

    <template v-if="ready">
      <div class="table-scroll">
        <table class="employee-table">
          <thead>
            <tr>
              <th class="col-no">No</th>
              <th>Nama Pegawai</th>
              <th>Departemen</th>
              <th>Status</th>
              <th>Pengisian</th>
              <th class="col-sisa-kuota">Sisa Kuota</th>
              <th class="col-action">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(employee, index) in pagedEmployees" :key="employee.id">
              <td class="col-no">{{ pageStart + index + 1 }}</td>
              <td class="cell-name">{{ employee.nama }}</td>
              <td class="cell-unit">{{ shortDeptName(employee.unitKerja) }}</td>
              <td>
                <span class="type-flag">
                  <span
                    class="type-dot"
                    :class="employee.jenisPegawai === 'Organik' ? 'type-organik' : 'type-non-organik'"
                  />
                  {{ jenisPegawaiLabel(employee.jenisPegawai) }}
                </span>
              </td>
              <td>
                <span class="fill-badge" :class="fillBadgeClass(employee)">
                  {{ fillCountFor(employee) }}/{{ quota.limit }}
                </span>
              </td>
              <td class="col-sisa-kuota">
                <span v-if="remainingQuotaFor(employee) > 0" class="remaining-badge">
                  {{ remainingQuotaFor(employee) }}
                </span>
                <span v-else class="remaining-badge remaining-done">Selesai</span>
              </td>
              <td class="col-action">
                <button type="button" class="detail-button" @click="openDetail(employee)">
                  Detail
                </button>
              </td>
            </tr>
            <tr v-if="filteredEmployees.length === 0">
              <td colspan="7" class="empty-row">Tidak ada pegawai yang cocok.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pagination">
        <span class="pagination-label">
          Menampilkan {{ filteredEmployees.length === 0 ? 0 : pageStart + 1 }}-{{ pageEnd }} dari
          {{ filteredEmployees.length }} pegawai
        </span>
        <div class="pager" v-if="totalPages > 1">
          <button class="pager-arrow" type="button" :disabled="page === 1" @click="page--">
            &lsaquo;
          </button>
          <template v-for="item in pageItems(page, totalPages)" :key="item">
            <span v-if="typeof item === 'string'" class="pager-gap" aria-hidden="true">&hellip;</span>
            <button
              v-else
              type="button"
              class="pager-page"
              :class="{ active: item === page }"
              :aria-current="item === page ? 'page' : undefined"
              @click="page = item"
            >
              {{ item }}
            </button>
          </template>
          <button
            class="pager-arrow"
            type="button"
            :disabled="page === totalPages"
            @click="page++"
          >
            &rsaquo;
          </button>
        </div>
      </div>
    </template>

    <p v-else-if="survey" class="empty-state">Pilih tanggal untuk melihat status pengisian pegawai pada hari tersebut.</p>
    <p v-else class="empty-state">Pilih survei tertentu (bukan "Semua Survei") untuk melihat detail pengisian pegawai.</p>

    <Teleport to="body">
      <div v-if="detailEmployee" class="detail-modal-overlay" @click.self="closeDetail">
        <div class="detail-modal">
          <div class="detail-modal-header">
            <div>
              <h3 class="detail-modal-title">Bukti Survei — {{ detailEmployee.nama }}</h3>
              <p class="detail-modal-subtitle">{{ survey?.nama }}</p>
              <p v-if="detailSummary" class="detail-modal-summary">{{ detailSummary }}</p>
            </div>
            <button type="button" class="detail-modal-close" @click="closeDetail">
              <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
                <path d="M5 5l10 10M15 5 5 15" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
              </svg>
            </button>
          </div>

          <div v-if="detailRows.length === 0" class="detail-modal-loading">
            {{ quota.perDay ? "Periode survei belum dimulai." : "Pegawai ini belum mengisi survei." }}
          </div>
          <table v-else class="detail-table">
            <thead>
              <tr>
                <th class="col-no">No</th>
                <th>Tanggal</th>
                <th>Status</th>
                <th>Waktu</th>
                <th>Aksi</th>
              </tr>
            </thead>
            <tbody>
              <template v-for="(row, index) in detailRows" :key="row.key">
                <tr v-if="!row.submission" class="detail-missed-row">
                  <td class="col-no">{{ index + 1 }}</td>
                  <td>{{ row.tanggal }}</td>
                  <td><span class="fill-badge fill-empty">Tidak mengisi</span></td>
                  <td>-</td>
                  <td>-</td>
                </tr>
                <template v-else>
                  <tr>
                    <td class="col-no">{{ index + 1 }}</td>
                    <td>{{ row.tanggal }}</td>
                    <td>
                      <span class="fill-badge" :class="row.dayCount >= quota.limit ? 'fill-full' : 'fill-partial'">
                        Mengisi{{ quota.perDay ? ` ${row.dayCount}/${quota.limit}` : "" }}
                      </span>
                    </td>
                    <td>{{ submissionTime(row.submission) || "-" }}</td>
                    <td>
                      <template v-if="row.evidence.length > 0">
                        <button
                          v-for="evidence in row.evidence"
                          :key="evidence.key"
                          type="button"
                          class="detail-view-toggle"
                          @click="toggleImage(evidence)"
                        >
                          {{ expandedKey === evidence.key ? "Tutup" : `Lihat ${evidence.label}` }}
                        </button>
                      </template>
                      <span v-else class="detail-deleted-label">Gambar dihapus</span>
                    </td>
                  </tr>
                  <tr
                    v-for="evidence in row.evidence.filter((e) => e.key === expandedKey)"
                    :key="`${evidence.key}-image`"
                    class="detail-image-row"
                  >
                    <td colspan="5">
                      <p v-if="imageLoadingKey === evidence.key" class="detail-modal-loading">Memuat bukti...</p>
                      <img
                        v-else-if="imageUrls[evidence.key]"
                        class="detail-list-image-el"
                        :src="imageUrls[evidence.key]"
                        :alt="`${evidence.label} ${detailEmployee.nama} ${row.tanggal}`"
                      />
                      <p v-else class="detail-image-error">
                        Gagal memuat bukti.<br />
                        <span v-if="imageErrors[evidence.key]">{{ imageErrors[evidence.key] }}</span>
                      </p>
                    </td>
                  </tr>
                </template>
              </template>
            </tbody>
          </table>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, ref, watch } from "vue";
import { BUKTI_BUCKET, supabase } from "../lib/supabaseClient";
import { pageItems } from "../lib/pagination";
import { formatWibTime, wibToday } from "../lib/wib";
import { shortDeptName } from "../orgStructure";
import { jenisPegawaiLabel, surveyQuota, useSurveyStore } from "../stores/surveyStore";

const props = defineProps({
  employees: {
    type: Array,
    required: true,
  },
  surveyId: {
    type: [Number, String, null],
    default: null,
  },
  // Quota is per day: fill counts are for this one date (YYYY-MM-DD).
  tanggal: {
    type: String,
    default: "",
  },
});

const store = useSurveyStore();

const search = ref("");
const statusFilter = ref("belum");
const page = ref(1);
const pageSize = 10;

const survey = computed(() => (props.surveyId ? store.findSurvey(props.surveyId) : null));

// External: maxPengisian per day, so a date is needed. Internal: once per
// employee for the whole period, so no date is needed and every date counts.
const quota = computed(() => surveyQuota(survey.value));
const ready = computed(() => !!survey.value && (!quota.value.perDay || !!props.tanggal));

function fillCountFor(employee) {
  return store.submissionCountForEmployeeSurvey(props.surveyId, employee.nama, props.tanggal);
}

function fillBadgeClass(employee) {
  const count = fillCountFor(employee);
  if (count === 0) return "fill-empty";
  if (survey.value && count >= quota.value.limit) return "fill-full";
  return "fill-partial";
}

function remainingQuotaFor(employee) {
  if (!survey.value) return 0;
  return Math.max(0, quota.value.limit - fillCountFor(employee));
}

function isCompleted(employee) {
  return survey.value ? fillCountFor(employee) >= quota.value.limit : false;
}

function submissionTime(submission) {
  return formatWibTime(submission.createdAt);
}

const detailEmployee = ref(null);
const detailSubmissions = ref([]);
// Each submission can have a main proof photo plus an optional extra one;
// every photo is addressed by its own key ("<id>" / "<id>:2").
const expandedKey = ref(null);
const imageUrls = ref({});
const imageLoadingKey = ref(null);
const imageErrors = ref({});

function evidenceFiles(submission) {
  return [
    { key: String(submission.id), label: "Bukti", path: submission.fileBukti },
    { key: `${submission.id}:2`, label: "Bukti Tambahan", path: submission.fileBukti2 },
  ].filter((e) => e.path);
}

// Every YYYY-MM-DD from `start` to `end`, inclusive. Done in UTC so the
// device timezone can't skip or repeat a day.
function datesBetween(start, end) {
  const dates = [];
  const cursor = new Date(`${start}T00:00:00Z`);
  const last = new Date(`${end}T00:00:00Z`);
  while (cursor <= last) {
    dates.push(cursor.toISOString().slice(0, 10));
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }
  return dates;
}

// The days the employee was expected to fill: from the start of the survey
// period up to today (or the end of the period, if it is already over).
const detailDates = computed(() => {
  const start = survey.value?.tanggalMulai || detailSubmissions.value[0]?.tanggal;
  if (!start) return [];
  const today = wibToday();
  const end = survey.value?.tanggalSelesai && survey.value.tanggalSelesai < today ? survey.value.tanggalSelesai : today;
  return datesBetween(start, end);
});

// External surveys are per day, so the detail lists every day of the period
// and marks the days without a submission as "Tidak mengisi". Internal
// surveys are once per period, so only the submission itself is listed.
const detailRows = computed(() => {
  const byDate = new Map();
  for (const sub of detailSubmissions.value) {
    if (!byDate.has(sub.tanggal)) byDate.set(sub.tanggal, []);
    byDate.get(sub.tanggal).push(sub);
  }

  const toRows = (tanggal, subs) =>
    subs.map((sub) => ({
      key: sub.id,
      tanggal,
      submission: sub,
      dayCount: subs.length,
      evidence: evidenceFiles(sub),
    }));

  if (!quota.value.perDay) {
    return [...byDate].flatMap(([tanggal, subs]) => toRows(tanggal, subs));
  }

  // Submissions outside the computed range (e.g. dated after today) still show.
  const dates = new Set([...detailDates.value, ...byDate.keys()]);
  return [...dates]
    .sort()
    .flatMap((tanggal) =>
      byDate.has(tanggal) ? toRows(tanggal, byDate.get(tanggal)) : [{ key: `missed-${tanggal}`, tanggal, submission: null }]
    );
});

// "Jumlah vote X dari target Y (periode)". Vote = all the employee's
// submissions to this survey; target = days in the listed range x the per-day
// limit (e.g. 11 days x 2 = 22), the same range the day-by-day table shows.
const detailSummary = computed(() => {
  if (!quota.value.perDay || detailDates.value.length === 0) return "";
  const vote = detailSubmissions.value.length;
  const target = detailDates.value.length * quota.value.limit;
  return `Jumlah vote ${vote} dari target ${target} (${detailDates.value[0]} s.d. ${detailDates.value.at(-1)})`;
});

function openDetail(employee) {
  if (!props.surveyId) return;
  detailEmployee.value = employee;
  detailSubmissions.value = store.submissions
    .filter((s) => s.surveyId === props.surveyId && s.nama === employee.nama)
    .sort((a, b) => a.tanggal.localeCompare(b.tanggal) || String(a.createdAt).localeCompare(String(b.createdAt)));
  expandedKey.value = null;
  imageUrls.value = {};
}

function closeDetail() {
  detailEmployee.value = null;
  detailSubmissions.value = [];
  expandedKey.value = null;
  imageUrls.value = {};
}

async function toggleImage(evidence) {
  if (expandedKey.value === evidence.key) {
    expandedKey.value = null;
    return;
  }

  expandedKey.value = evidence.key;

  if (imageUrls.value[evidence.key] || !evidence.path) return;

  imageLoadingKey.value = evidence.key;
  const { data, error } = await supabase.storage
    .from(BUKTI_BUCKET)
    .createSignedUrl(evidence.path, 300);
  if (!error) {
    imageUrls.value = { ...imageUrls.value, [evidence.key]: data.signedUrl };
  } else {
    imageErrors.value = { ...imageErrors.value, [evidence.key]: error.message };
    console.error("createSignedUrl error:", error, "path:", evidence.path);
  }
  imageLoadingKey.value = null;
}

const filteredEmployees = computed(() => {
  if (!survey.value) return [];
  let list = props.employees;

  list = list.filter((e) => (statusFilter.value === "sudah" ? isCompleted(e) : !isCompleted(e)));

  const term = search.value.trim().toLowerCase();
  if (term) {
    list = list.filter((e) => e.nama.toLowerCase().includes(term));
  }

  return list;
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredEmployees.value.length / pageSize)));

watch([search, statusFilter, () => props.surveyId, filteredEmployees], () => {
  if (page.value > totalPages.value) page.value = totalPages.value;
});

const pageStart = computed(() => (page.value - 1) * pageSize);
const pageEnd = computed(() => Math.min(pageStart.value + pageSize, filteredEmployees.value.length));
const pagedEmployees = computed(() => filteredEmployees.value.slice(pageStart.value, pageEnd.value));
</script>

<style scoped>
.employee-status {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.search-box {
  position: relative;
  display: flex;
  align-items: center;
  max-width: 320px;
  flex: 1;
  min-width: 220px;
}

.search-icon {
  position: absolute;
  left: 12px;
  color: var(--color-text-muted);
}

.search-input {
  width: 100%;
  padding: 10px 12px 10px 36px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  font-family: var(--font-sans);
  font-size: 14px;
}

.search-input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px rgba(0, 93, 172, 0.2);
}

.status-toggle {
  display: flex;
  gap: 4px;
  padding: 4px;
  background-color: var(--color-bg);
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border);
}

.toggle-option {
  padding: 7px 14px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease, color 0.15s ease;
  white-space: nowrap;
}

.toggle-option:hover:not(.active) {
  background-color: var(--color-surface);
}

.toggle-option.active {
  background-color: var(--color-primary);
  color: #ffffff;
}

.table-scroll {
  overflow-x: auto;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.employee-table {
  width: 100%;
  min-width: 700px;
  border-collapse: collapse;
  font-size: 13px;
  background-color: var(--color-surface);
}

.employee-table thead th {
  text-align: left;
  padding: 9px 14px;
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  background-color: var(--color-bg);
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}

.employee-table tbody td {
  padding: 10px 14px;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text);
}

.employee-table tbody tr {
  transition: background-color 0.12s ease;
}

.employee-table tbody tr:hover td {
  background-color: rgba(248, 250, 252, 0.8);
}

.employee-table tbody tr:last-child td {
  border-bottom: none;
}

.col-no {
  width: 44px;
  color: var(--color-text-muted);
}

.cell-name {
  font-weight: 600;
}

.cell-unit {
  color: var(--color-text-secondary);
}

.type-flag {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  font-weight: 600;
  color: var(--color-text-secondary);
}

.type-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
}

.type-organik {
  background-color: var(--color-primary);
}

.type-non-organik {
  background-color: var(--color-text-muted);
}

.fill-badge {
  display: inline-flex;
  align-items: center;
  padding: 2px 9px;
  border-radius: var(--radius-full);
  font-size: 11.5px;
  font-weight: 700;
}

.fill-empty {
  background-color: var(--color-danger-bg);
  color: var(--color-danger);
}

.fill-partial {
  background-color: #eff6ff;
  color: var(--color-primary);
}

.fill-full {
  background-color: #f0fdf4;
  color: var(--color-success);
}

.employee-table th.col-sisa-kuota,
.employee-table td.col-sisa-kuota {
  text-align: center;
}

.remaining-badge {
  display: inline-block;
  font-size: 12.5px;
  font-weight: 600;
  color: var(--color-text-secondary);
}

.remaining-done {
  color: var(--color-success);
}

.empty-row {
  text-align: center;
  padding: 28px;
  color: var(--color-text-muted);
}

.empty-state {
  text-align: center;
  padding: 20px;
  color: var(--color-text-muted);
  font-size: 13px;
}

.pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}

.pagination-label {
  font-size: 12.5px;
  color: var(--color-text-muted);
}

.pager {
  display: flex;
  align-items: center;
  gap: 4px;
}

.pager-arrow,
.pager-page {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 26px;
  height: 26px;
  padding: 0 6px;
  border: none;
  border-radius: var(--radius-sm);
  background-color: transparent;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
}

.pager-arrow:hover:not(:disabled),
.pager-page:hover:not(.active) {
  background-color: var(--color-bg);
}

.pager-arrow:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.pager-page.active {
  background-color: var(--color-primary);
  color: #ffffff;
}

.col-action {
  width: 76px;
  text-align: center !important;
}

.detail-button {
  padding: 5px 12px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-sm);
  background-color: var(--color-surface);
  color: var(--color-primary);
  font-family: var(--font-sans);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease, border-color 0.15s ease;
}

.detail-button:hover:not(:disabled) {
  background-color: var(--color-bg);
  border-color: var(--color-primary-light);
}

.detail-button:disabled {
  color: var(--color-text-muted);
  cursor: not-allowed;
  opacity: 0.6;
}

.detail-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 200;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background-color: rgba(0, 93, 172, 0.28);
  backdrop-filter: blur(2px);
  -webkit-backdrop-filter: blur(2px);
  animation: overlay-fade-in 0.15s ease;
}

@keyframes overlay-fade-in {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.detail-modal {
  width: 100%;
  max-width: 640px;
  max-height: 80vh;
  overflow-y: auto;
  padding: 20px;
  border-radius: var(--radius-lg);
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  box-shadow: var(--shadow-lg);
  display: flex;
  flex-direction: column;
  gap: 16px;
  animation: modal-pop-in 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes modal-pop-in {
  from {
    opacity: 0;
    transform: scale(0.96) translateY(8px);
  }
  to {
    opacity: 1;
  }
}

.detail-modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.detail-modal-title {
  font-size: 15px;
  font-weight: 700;
  color: var(--color-text);
}

.detail-modal-subtitle {
  font-size: 12.5px;
  color: var(--color-text-muted);
  margin-top: 2px;
}

.detail-modal-summary {
  font-size: 12.5px;
  font-weight: 600;
  color: var(--color-text-secondary);
  margin-top: 6px;
}

.detail-missed-row td {
  color: var(--color-text-muted);
}

.detail-modal-close {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  border-radius: var(--radius-full);
  background-color: var(--color-bg);
  color: var(--color-text-secondary);
  cursor: pointer;
}

.detail-modal-close:hover {
  background-color: var(--color-border);
}

.detail-modal-loading {
  padding: 32px;
  text-align: center;
  color: var(--color-text-muted);
  font-size: 13px;
}

.detail-table {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  overflow: hidden;
  font-size: 13px;
}

.detail-table thead th {
  text-align: center;
  padding: 10px 14px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  background-color: var(--color-bg);
  border-bottom: 1px solid var(--color-border);
}

.col-no {
  width: 40px;
  color: var(--color-text-muted);
}

.detail-table tbody td {
  text-align: center;
  padding: 10px 14px;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text);
  font-weight: 600;
}

.detail-table tbody tr:last-child td {
  border-bottom: none;
}

.detail-view-toggle {
  padding: 5px 12px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-sm);
  background-color: var(--color-surface);
  color: var(--color-primary);
  font-family: var(--font-sans);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.detail-view-toggle + .detail-view-toggle {
  margin-left: 6px;
}

.detail-view-toggle:hover {
  background-color: var(--color-bg);
}

.detail-deleted-label {
  font-size: 12px;
  font-style: italic;
  color: var(--color-text-muted);
}

.detail-image-row td {
  background-color: var(--color-bg);
  padding: 14px;
}

.detail-list-image-el {
  display: block;
  width: 100%;
  max-height: 420px;
  object-fit: contain;
  margin: 0 auto;
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border);
  background-color: var(--color-surface);
}

.detail-image-error {
  color: var(--color-text-muted);
  font-size: 12.5px;
  text-align: center;
  padding: 12px;
}
</style>
