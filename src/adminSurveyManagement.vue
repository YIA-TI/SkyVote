<template>
  <div class="dashboard-page">
    <div class="page-heading">
      <div>
        <h1 class="page-title">Kelola Survei</h1>
        <p class="page-subtitle">Buat dan kelola survei internal pegawai dengan mudah.</p>
      </div>
      <RouterLink to="/admin/buat-survey" class="btn-add">
        <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
          <path d="M10 3v14M3 10h14" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        </svg>
        Tambah Survei Baru
      </RouterLink>
    </div>

    <div class="board-card">
      <div class="toolbar">
        <div class="search-box">
          <svg class="search-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
            <circle cx="9" cy="9" r="6.5" stroke="currentColor" stroke-width="1.6" />
            <path d="M17 17l-3.5-3.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
          <input v-model="search" class="search-input" type="text" placeholder="Cari nama survei..." />
        </div>

        <div class="filter-wrap">
          <button ref="filterBtnRef" type="button" class="btn-filter" @click.stop="toggleFilter">
            <svg width="15" height="15" viewBox="0 0 20 20" fill="none">
              <path
                d="M3 5h14M6 10h8M9 15h2"
                stroke="currentColor"
                stroke-width="1.6"
                stroke-linecap="round"
              />
            </svg>
            Filter
            <span v-if="statusFilter.length" class="filter-count">({{ statusFilter.length }})</span>
          </button>

          <Teleport to="body">
            <div v-if="filterOpen" class="filter-popover" :style="filterPopoverStyle" @click.stop>
              <span class="filter-popover-label">Status Survei</span>
              <label v-for="opt in statusOptions" :key="opt" class="filter-checkbox">
                <input type="checkbox" :value="opt" v-model="statusFilter" />
                {{ opt }}
              </label>
              <button type="button" class="filter-reset" @click="statusFilter = []">
                Reset filter
              </button>
            </div>
          </Teleport>
        </div>
      </div>

      <div class="table-scroll">
        <table class="survey-table">
          <thead>
            <tr>
              <th>Nama Survei</th>
              <th>Status</th>
              <th>Periode</th>
              <th>Link</th>
              <th class="col-pengisian">Pengisian</th>
              <th class="col-action">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="survey in pagedSurveys" :key="survey.id">
              <td>
                <div class="cell-title">{{ survey.nama }}</div>
              </td>
              <td>
                <span class="status-flag">
                  <span class="status-dot" :class="statusClass(survey.status)" />
                  {{ survey.status }}
                </span>
              </td>
              <td>
                <div class="cell-periode">
                  <svg width="13" height="13" viewBox="0 0 20 20" fill="none">
                    <rect x="3" y="4" width="14" height="13" rx="1.5" stroke="currentColor" stroke-width="1.5" />
                    <path d="M3 8h14M6.5 2.5v3M13.5 2.5v3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
                  </svg>
                  {{ formatPeriode(survey) }}
                </div>
              </td>
              <td>
                <span v-if="survey.tipe === 'Internal'" class="cell-internal-badge">
                  <svg width="13" height="13" viewBox="0 0 20 20" fill="none">
                    <rect x="3" y="4" width="14" height="13" rx="1.5" stroke="currentColor" stroke-width="1.5" />
                    <path d="M6 8h8M6 11h8M6 14h5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
                  </svg>
                  {{ questionCount(survey) }} pertanyaan
                </span>
                <a
                  v-else-if="survey.link"
                  class="cell-link"
                  :href="survey.link"
                  target="_blank"
                  rel="noopener"
                >
                  <svg width="13" height="13" viewBox="0 0 20 20" fill="none">
                    <path
                      d="M8.5 11.5 11.5 8.5M9 6l.6-.6a3 3 0 0 1 4.2 4.2L13 10.4M11 14l-.6.6a3 3 0 0 1-4.2-4.2L7 9.6"
                      stroke="currentColor"
                      stroke-width="1.5"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    />
                  </svg>
                  {{ shortenLink(survey.link) }}
                </a>
                <span v-else class="cell-draft">Draft &middot; belum ada link</span>
              </td>
              <td class="col-pengisian">
                <div class="cell-pengisian">
                  <svg width="13" height="13" viewBox="0 0 20 20" fill="none">
                    <circle cx="6.5" cy="7" r="2.6" stroke="currentColor" stroke-width="1.5" />
                    <circle cx="13.5" cy="7" r="2.6" stroke="currentColor" stroke-width="1.5" />
                    <path
                      d="M1.5 17c0-2.8 2.2-4.8 5-4.8s5 2 5 4.8M11 12.5c2.5.2 4.5 2.1 4.5 4.5"
                      stroke="currentColor"
                      stroke-width="1.5"
                      stroke-linecap="round"
                    />
                  </svg>
                  <span class="pengisian-count">{{ submissionCount(survey) }} pengisian</span>
                </div>
                <span class="pengisian-limit">Maks {{ survey.maxPengisian }}x / pegawai</span>
              </td>
              <td class="col-action">
                <div class="row-actions">
                  <RouterLink
                    v-if="survey.tipe === 'Internal'"
                    :to="`/admin/survey-hasil/${survey.id}`"
                    class="icon-btn"
                    title="Lihat hasil"
                  >
                    <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
                      <path
                        d="M4 16.5V10M10 16.5V4M16 16.5v-7"
                        stroke="currentColor"
                        stroke-width="1.6"
                        stroke-linecap="round"
                      />
                    </svg>
                  </RouterLink>
                  <RouterLink
                    :to="`/admin/buat-survey/${survey.id}`"
                    class="icon-btn"
                    title="Edit survei"
                  >
                    <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
                      <path
                        d="M13.5 3.5 16 6l-8.8 8.8-3 .7.7-3L13.5 3.5Z"
                        stroke="currentColor"
                        stroke-width="1.5"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      />
                    </svg>
                  </RouterLink>
                  <button
                    type="button"
                    class="icon-btn icon-btn-danger"
                    title="Hapus survei"
                    @click="confirmDelete(survey)"
                  >
                    <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
                      <path
                        d="M4 6h12M8 6V4.5A1 1 0 0 1 9 3.5h2a1 1 0 0 1 1 1V6M6 6l.6 9.5a1 1 0 0 0 1 .9h4.8a1 1 0 0 0 1-.9L14 6"
                        stroke="currentColor"
                        stroke-width="1.5"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      />
                    </svg>
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="filteredSurveys.length === 0">
              <td colspan="6" class="empty-row">Tidak ada survei yang cocok.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pagination">
        <span class="pagination-label">
          Menampilkan {{ filteredSurveys.length === 0 ? 0 : pageStart + 1 }}-{{ pageEnd }} dari
          {{ filteredSurveys.length }} survei
        </span>
        <div class="pager" v-if="totalPages > 1">
          <button class="pager-arrow" type="button" :disabled="page === 1" @click="page--">
            &lsaquo;
          </button>
          <button
            v-for="p in totalPages"
            :key="p"
            type="button"
            class="pager-page"
            :class="{ active: p === page }"
            @click="page = p"
          >
            {{ p }}
          </button>
          <button class="pager-arrow" type="button" :disabled="page === totalPages" @click="page++">
            &rsaquo;
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { useSurveyStore } from "./stores/surveyStore";
import { useToastStore } from "./stores/toastStore";

const store = useSurveyStore();
const toast = useToastStore();

const search = ref("");
const filterOpen = ref(false);
const filterBtnRef = ref(null);
const filterPopoverStyle = ref({});

const POPOVER_WIDTH = 200;
const POPOVER_MARGIN = 16;

function positionFilterPopover() {
  const btn = filterBtnRef.value;
  if (!btn) return;
  const rect = btn.getBoundingClientRect();
  const width = Math.min(POPOVER_WIDTH, window.innerWidth - POPOVER_MARGIN * 2);
  let left = rect.right - width;
  left = Math.max(POPOVER_MARGIN, Math.min(left, window.innerWidth - width - POPOVER_MARGIN));
  filterPopoverStyle.value = {
    top: `${rect.bottom + 8}px`,
    left: `${left}px`,
    width: `${width}px`,
  };
}

async function toggleFilter() {
  filterOpen.value = !filterOpen.value;
  if (filterOpen.value) {
    await nextTick();
    positionFilterPopover();
  }
}

function closeFilterOnOutsideClick() {
  filterOpen.value = false;
}

onMounted(() => {
  document.addEventListener("click", closeFilterOnOutsideClick);
  window.addEventListener("resize", positionFilterPopover);
  store.ensureBaseData();
  store.fetchQuestionCounts();
});
onBeforeUnmount(() => {
  document.removeEventListener("click", closeFilterOnOutsideClick);
  window.removeEventListener("resize", positionFilterPopover);
});
const statusOptions = ["Draft", "Terjadwal", "Aktif", "Selesai"];
const statusFilter = ref([]);
const page = ref(1);
const pageSize = 8;

const filteredSurveys = computed(() => {
  const term = search.value.trim().toLowerCase();
  return store.surveys.filter((s) => {
    const matchesTerm = !term || s.nama.toLowerCase().includes(term);
    const matchesStatus = statusFilter.value.length === 0 || statusFilter.value.includes(s.status);
    return matchesTerm && matchesStatus;
  });
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredSurveys.value.length / pageSize)));

watch([search, statusFilter, filteredSurveys], () => {
  if (page.value > totalPages.value) page.value = totalPages.value;
});

const pageStart = computed(() => (page.value - 1) * pageSize);
const pageEnd = computed(() => Math.min(pageStart.value + pageSize, filteredSurveys.value.length));
const pagedSurveys = computed(() => filteredSurveys.value.slice(pageStart.value, pageEnd.value));

function formatPeriode(survey) {
  if (!survey.tanggalMulai || !survey.tanggalSelesai) return "Belum dijadwalkan";
  const start = new Date(survey.tanggalMulai);
  const end = new Date(survey.tanggalSelesai);
  const format = (d) => d.toLocaleDateString("id-ID", { day: "2-digit", month: "short", year: "numeric" });
  return `${format(start)} - ${format(end)}`;
}

function submissionCount(survey) {
  return store.submissionsBySurvey(survey.id).length;
}

function questionCount(survey) {
  return store.questionCounts[survey.id] ?? 0;
}

function shortenLink(url) {
  try {
    const parsed = new URL(url);
    return `${parsed.hostname}/...`;
  } catch {
    return url;
  }
}

function statusClass(status) {
  if (status === "Aktif") return "status-aktif";
  if (status === "Selesai") return "status-selesai";
  if (status === "Draft") return "status-draft";
  return "status-terjadwal";
}

async function confirmDelete(survey) {
  try {
    await store.removeSurvey(survey.id);
    toast.show(`Survei "${survey.nama}" berhasil dihapus`, "success");
  } catch (err) {
    toast.show(err.message, "error");
  }
}
</script>

<style scoped>
.dashboard-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.page-heading {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
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
  margin-top: 4px;
}

.btn-add {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
  height: 40px;
  padding: 0 18px;
  border: none;
  border-radius: var(--radius-md);
  background-color: var(--color-primary);
  color: #ffffff;
  font-family: var(--font-sans);
  font-size: 14px;
  font-weight: 600;
  text-decoration: none;
  white-space: nowrap;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-add:hover {
  background-color: var(--color-primary-dark);
}

.board-card {
  display: flex;
  flex-direction: column;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
}

.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 16px 24px;
  border-bottom: 1px solid var(--color-border);
  flex-wrap: wrap;
}

.search-box {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
  max-width: 320px;
}

.search-icon {
  position: absolute;
  left: 12px;
  color: var(--color-text-muted);
}

.search-input {
  width: 100%;
  height: 40px;
  padding: 0 12px 0 36px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  font-family: var(--font-sans);
  font-size: 14px;
}

.search-input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px rgba(0, 93, 172, 0.2);
}

.filter-wrap {
  position: relative;
}

.btn-filter {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 40px;
  padding: 0 16px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
  transition: background-color 0.15s ease, border-color 0.15s ease;
}

.btn-filter:hover {
  background-color: var(--color-bg);
  border-color: var(--color-text-muted);
}

.filter-count {
  color: var(--color-primary);
  font-weight: 700;
}

.filter-popover {
  position: fixed;
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 16px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  z-index: 30;
}

.filter-popover-label {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  margin-bottom: 2px;
}

.filter-checkbox {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.filter-reset {
  align-self: flex-start;
  margin-top: 4px;
  border: none;
  background: transparent;
  color: var(--color-primary);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  padding: 0;
}

.table-scroll {
  overflow-x: auto;
}

.survey-table {
  width: 100%;
  min-width: 980px;
  border-collapse: collapse;
  font-size: 14px;
}

.survey-table thead th {
  text-align: left;
  padding: 10px 24px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  background-color: var(--color-bg);
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}

.col-action {
  text-align: center;
}

.survey-table tbody td {
  padding: 16px 24px;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text);
  vertical-align: middle;
}

.survey-table tbody tr {
  transition: background-color 0.12s ease;
}

.survey-table tbody tr:hover td {
  background-color: rgba(248, 250, 252, 0.8);
}

.survey-table tbody tr:last-child td {
  border-bottom: none;
}

.cell-title {
  font-weight: 600;
  color: var(--color-text);
}


.cell-link {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  color: var(--color-primary);
  text-decoration: none;
  font-weight: 500;
  font-size: 13px;
}

.cell-link:hover {
  text-decoration: underline;
}

.cell-draft {
  color: var(--color-text-muted);
  font-size: 13px;
}

.cell-internal-badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  color: var(--color-text-secondary);
  font-weight: 500;
  font-size: 13px;
}

.cell-periode {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--color-text-secondary);
  font-size: 13px;
  white-space: nowrap;
}

.status-flag {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text-secondary);
}

.cell-pengisian {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--color-text-secondary);
  font-size: 13px;
  white-space: nowrap;
}

.col-pengisian {
  white-space: nowrap;
}

.pengisian-count {
  color: var(--color-text-secondary);
  font-weight: 600;
}

.pengisian-limit {
  display: block;
  margin-top: 2px;
  font-size: 11px;
  color: var(--color-text-muted);
}

.status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
}

.status-aktif {
  background-color: var(--color-success);
}

.status-selesai {
  background-color: var(--color-text-muted);
}

.status-terjadwal {
  background-color: var(--color-warning);
}

.status-draft {
  background-color: var(--color-border-strong);
}

.col-action {
  width: 90px;
}

.row-actions {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  opacity: 0;
  transition: opacity 0.15s ease;
}

.survey-table tbody tr:hover .row-actions {
  opacity: 1;
}

@media (hover: none) {
  .row-actions {
    opacity: 1;
  }
}

.icon-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border: none;
  border-radius: var(--radius-sm);
  background-color: transparent;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.icon-btn:hover {
  background-color: var(--color-bg);
  color: var(--color-primary);
}

.icon-btn-danger:hover {
  background-color: var(--color-danger-bg);
  color: var(--color-danger);
}

.empty-row {
  text-align: center;
  padding: 32px;
  color: var(--color-text-muted);
}

.pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  padding: 14px 24px;
  border-top: 1px solid var(--color-border);
}

.pagination-label {
  font-size: 13px;
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
  min-width: 28px;
  height: 28px;
  padding: 0 6px;
  border: none;
  border-radius: var(--radius-sm);
  background-color: transparent;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 13px;
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

@media (max-width: 640px) {
  .page-heading {
    flex-wrap: wrap;
  }

  .btn-add {
    width: 100%;
    justify-content: center;
  }

  .toolbar {
    padding: 16px;
  }

  .search-box {
    max-width: none;
  }
}
</style>
