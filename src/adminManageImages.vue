<template>
  <div class="manage-page">
    <div class="page-heading">
      <div>
        <h1 class="page-title">Hapus Data</h1>
        <p class="page-subtitle">
          Kelola dan hapus foto bukti survei yang tersimpan untuk menghemat penyimpanan, atau hapus
          seluruh data submission (termasuk data pegawai yang sudah mengisi) untuk satu survei.
        </p>
      </div>
    </div>

    <div class="board-card">
      <div class="toolbar">
        <div class="search-box">
          <svg class="search-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
            <circle cx="9" cy="9" r="6.5" stroke="currentColor" stroke-width="1.6" />
            <path d="M17 17l-3.5-3.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
          <input v-model="search" class="search-input" type="text" placeholder="Cari nama pegawai..." />
        </div>

        <div class="survey-filter">
          <svg class="survey-filter-icon" width="14" height="14" viewBox="0 0 20 20" fill="none">
            <rect x="5" y="4" width="10" height="13" rx="1.5" stroke="currentColor" stroke-width="1.5" />
            <path d="M8 3.5h4a1 1 0 0 1 1 1V5H7v-.5a1 1 0 0 1 1-1Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" />
            <path d="M7.5 8.5h5M7.5 11h5M7.5 13.5h3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
          </svg>
          <select v-model="selectedSurveyId" class="survey-filter-select">
            <option :value="null">Semua Survei</option>
            <option v-for="survey in store.surveys" :key="survey.id" :value="survey.id">
              {{ survey.nama }}
            </option>
          </select>
        </div>

        <button
          type="button"
          class="delete-all-button"
          :disabled="!selectedSurveyId || deletingAll"
          :title="!selectedSurveyId ? 'Pilih satu survei terlebih dahulu' : ''"
          @click="openDeleteAllConfirm"
        >
          {{ deletingAll ? "Menghapus..." : "Hapus Data" }}
        </button>
      </div>

      <div class="table-scroll">
        <table class="manage-table">
          <thead>
            <tr>
              <th class="col-no">No</th>
              <th>Nama Pegawai</th>
              <th>Survei</th>
              <th>Departemen</th>
              <th>Tanggal</th>
              <th>Waktu</th>
              <th class="col-action">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <template v-for="(sub, index) in pagedSubmissions" :key="sub.id">
              <tr>
                <td class="col-no">{{ pageStart + index + 1 }}</td>
                <td class="cell-name">{{ sub.nama }}</td>
                <td class="cell-muted">{{ surveyNameFor(sub) }}</td>
                <td class="cell-muted">{{ shortDeptName(sub.departemen) }}</td>
                <td>{{ formatTanggal(sub.tanggal) }}</td>
                <td class="cell-muted">{{ submissionTime(sub) || "-" }}</td>
                <td class="col-action">
                  <div class="action-cell">
                    <button v-if="sub.fileBukti" type="button" class="view-toggle" @click="toggleImage(sub)">
                      {{ expandedId === sub.id ? "Tutup" : "Lihat Bukti" }}
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="expandedId === sub.id" class="image-row">
                <td colspan="7">
                  <p v-if="imageLoadingId === sub.id" class="loading-text">Memuat bukti...</p>
                  <template v-else-if="imageUrls[sub.id]">
                    <img
                      class="preview-image"
                      :src="imageUrls[sub.id]"
                      :alt="`Bukti ${sub.nama} ${sub.tanggal}`"
                    />
                    <p v-if="imageSizes[sub.id]" class="image-size-text">{{ imageSizes[sub.id] }}</p>
                  </template>
                  <p v-else class="loading-text">Gagal memuat bukti.</p>
                </td>
              </tr>
            </template>
            <tr v-if="filteredSubmissions.length === 0">
              <td colspan="7" class="empty-row">Tidak ada submission yang cocok.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pagination">
        <span class="pagination-label">
          Menampilkan {{ filteredSubmissions.length === 0 ? 0 : pageStart + 1 }}-{{ pageEnd }} dari
          {{ filteredSubmissions.length }} submission
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

    <ConfirmDialog
      :visible="showDeleteAllConfirm"
      title="Hapus semua data submission?"
      :message="deleteAllConfirmMessage"
      :note="DELETE_ALL_CONFIRM_NOTE"
      confirm-text="Ya, Hapus"
      cancel-text="Batal"
      danger
      @confirm="performDeleteAll"
      @cancel="showDeleteAllConfirm = false"
    />
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from "vue";
import ConfirmDialog from "./components/ConfirmDialog.vue";
import { BUKTI_BUCKET, supabase } from "./lib/supabaseClient";
import { shortDeptName } from "./orgStructure";
import { useSurveyStore } from "./stores/surveyStore";
import { useToastStore } from "./stores/toastStore";

const store = useSurveyStore();
const toast = useToastStore();

onMounted(() => store.ensureBaseData());

function formatTanggal(isoDate) {
  const [year, month, day] = isoDate.split("-");
  return `${day}-${month}-${year}`;
}

const search = ref("");
const selectedSurveyId = ref(null);
const page = ref(1);
const pageSize = 10;

function surveyNameFor(sub) {
  return store.findSurvey(sub.surveyId)?.nama ?? "-";
}

function submissionTime(sub) {
  if (!sub.createdAt) return "";
  const date = new Date(sub.createdAt);
  const pad = (n) => String(n).padStart(2, "0");
  return `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
}

const filteredSubmissions = computed(() => {
  let list = [...store.submissions].sort((a, b) => b.id - a.id);

  if (selectedSurveyId.value) {
    list = list.filter((s) => s.surveyId === selectedSurveyId.value);
  }

  const term = search.value.trim().toLowerCase();
  if (term) {
    list = list.filter((s) => s.nama.toLowerCase().includes(term));
  }

  return list;
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredSubmissions.value.length / pageSize)));

watch([search, selectedSurveyId, filteredSubmissions], () => {
  if (page.value > totalPages.value) page.value = totalPages.value;
});

const pageStart = computed(() => (page.value - 1) * pageSize);
const pageEnd = computed(() => Math.min(pageStart.value + pageSize, filteredSubmissions.value.length));
const pagedSubmissions = computed(() => filteredSubmissions.value.slice(pageStart.value, pageEnd.value));

const expandedId = ref(null);
const imageUrls = ref({});
const imageSizes = ref({});
const imageLoadingId = ref(null);

function formatFileSize(bytes) {
  if (!bytes && bytes !== 0) return "";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

async function toggleImage(submission) {
  if (expandedId.value === submission.id) {
    expandedId.value = null;
    return;
  }

  expandedId.value = submission.id;

  if (imageUrls.value[submission.id] || !submission.fileBukti) return;

  imageLoadingId.value = submission.id;
  const { data, error } = await supabase.storage
    .from(BUKTI_BUCKET)
    .createSignedUrl(submission.fileBukti, 300);
  if (!error) {
    imageUrls.value = { ...imageUrls.value, [submission.id]: data.signedUrl };
    try {
      const res = await fetch(data.signedUrl, { method: "HEAD" });
      const size = Number(res.headers.get("content-length"));
      if (size) {
        imageSizes.value = { ...imageSizes.value, [submission.id]: formatFileSize(size) };
      }
    } catch {
      // ignore, size is just a nice-to-have
    }
  }
  imageLoadingId.value = null;
}

const deletingAll = ref(false);
const showDeleteAllConfirm = ref(false);

const deleteAllConfirmMessage = computed(() => {
  if (!selectedSurveyId.value) return "";
  const surveyName = store.findSurvey(selectedSurveyId.value)?.nama ?? "survei ini";
  const count = store.submissions.filter((s) => s.surveyId === selectedSurveyId.value).length;
  return [
    `Anda akan menghapus ${count} data submission untuk survei "${surveyName}".`,
    "Foto bukti dan baris data pegawai akan terhapus sekaligus, dan kuota pengisian survei ini ikut ter-reset.",
  ].join("\n\n");
});

const DELETE_ALL_CONFIRM_NOTE =
  "Tindakan ini tidak bisa dibatalkan. Pastikan Anda sudah ekspor ke PDF atau Excel sebelum melanjutkan.";

function openDeleteAllConfirm() {
  if (!selectedSurveyId.value) return;

  const count = store.submissions.filter((s) => s.surveyId === selectedSurveyId.value).length;
  if (count === 0) {
    toast.show("Tidak ada data untuk dihapus pada survei ini.", "info");
    return;
  }

  showDeleteAllConfirm.value = true;
}

async function performDeleteAll() {
  showDeleteAllConfirm.value = false;
  deletingAll.value = true;
  try {
    const deletedCount = await store.deleteAllSubmissionsForSurvey(selectedSurveyId.value);
    expandedId.value = null;
    imageUrls.value = {};
    imageSizes.value = {};
    toast.show(`${deletedCount} data submission berhasil dihapus.`, "success");
  } catch (err) {
    toast.show(err.message || "Gagal menghapus data.", "error");
  } finally {
    deletingAll.value = false;
  }
}
</script>

<style scoped>
.manage-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 100%;
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
  max-width: 760px;
}

.board-card {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 24px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
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

.survey-filter {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 40px;
  padding: 0 14px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.survey-filter:hover {
  border-color: var(--color-primary-light);
}

.survey-filter:focus-within {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px rgba(0, 93, 172, 0.15);
}

.survey-filter-icon {
  color: var(--color-primary);
  flex-shrink: 0;
}

.survey-filter-select {
  border: none;
  outline: none;
  min-width: 180px;
  max-width: 280px;
  height: 100%;
  font-family: var(--font-sans);
  font-size: 13px;
  color: var(--color-text-secondary);
  background: transparent;
  cursor: pointer;
}

.delete-all-button {
  height: 40px;
  padding: 0 16px;
  border: 1px solid var(--color-danger);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  color: var(--color-danger);
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: background-color 0.15s ease;
}

.delete-all-button:hover:not(:disabled) {
  background-color: var(--color-danger-bg);
}

.delete-all-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.table-scroll {
  overflow-x: auto;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.manage-table {
  width: 100%;
  min-width: 820px;
  border-collapse: collapse;
  font-size: 13px;
}

.manage-table thead th {
  text-align: left;
  padding: 10px 14px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  background-color: var(--color-bg);
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}

.manage-table tbody td {
  padding: 10px 14px;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text);
}

.manage-table tbody tr:last-child td {
  border-bottom: none;
}

.col-no {
  width: 44px;
  color: var(--color-text-muted);
}

.col-action {
  width: 220px;
}

.cell-name {
  font-weight: 600;
}

.cell-muted {
  color: var(--color-text-secondary);
}

.action-cell {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.view-toggle {
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

.view-toggle:hover {
  background-color: var(--color-bg);
}

.delete-button {
  padding: 5px 12px;
  border: 1px solid var(--color-danger);
  border-radius: var(--radius-sm);
  background-color: var(--color-surface);
  color: var(--color-danger);
  font-family: var(--font-sans);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.delete-button:hover:not(:disabled) {
  background-color: var(--color-danger-bg);
}

.delete-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.image-row td {
  background-color: var(--color-bg);
  padding: 16px;
}

.preview-image {
  display: block;
  width: 100%;
  max-height: 420px;
  object-fit: contain;
  margin: 0 auto;
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border);
  background-color: var(--color-surface);
}

.image-size-text {
  text-align: center;
  color: var(--color-text-muted);
  font-size: 12px;
  margin-top: 8px;
}

.loading-text {
  text-align: center;
  color: var(--color-text-muted);
  font-size: 13px;
  padding: 12px;
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
  .board-card {
    padding: 16px;
  }

  .search-box {
    max-width: none;
    min-width: 0;
    flex-basis: 100%;
  }

  .delete-all-button {
    width: 100%;
  }
}
</style>
