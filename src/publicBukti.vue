<template>
  <div class="bukti-page">
    <div class="bg-blob bg-blob-1" aria-hidden="true" />
    <div class="bg-blob bg-blob-3" aria-hidden="true" />

    <AppHeader>
      <template #actions>
        <RouterLink to="/" class="back-link">
          <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
            <path d="M12 4 6 10l6 6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          Pengisian Data Survei
        </RouterLink>
      </template>
    </AppHeader>

    <main class="main-content">
      <div class="card">
        <div class="card-heading">
          <h1 class="card-title">Hasil Input Bukti Survei</h1>
          <p class="card-subtitle">Daftar pegawai yang sudah mengunggah bukti pengisian survei.</p>
        </div>

        <div class="toolbar">
          <div class="field survey-field">
            <label class="field-label" for="survey">Pilih survei</label>
            <select id="survey" v-model="selectedSurveyId" class="control" :disabled="surveysLoading">
              <option v-if="surveys.length === 0" :value="null" disabled>
                {{ surveysLoading ? "Memuat survei..." : "Belum ada survei" }}
              </option>
              <option v-for="survey in surveys" :key="survey.id" :value="survey.id">
                {{ survey.nama }}
              </option>
            </select>
          </div>

          <div class="field search-field">
            <label class="field-label" for="search">Cari nama pegawai</label>
            <input
              id="search"
              v-model="search"
              type="text"
              class="control"
              placeholder="Ketik nama..."
              autocomplete="off"
            />
          </div>

          <div class="field date-field">
            <label class="field-label" for="tanggal-dari">Dari tanggal</label>
            <input
              id="tanggal-dari"
              v-model="tanggalDari"
              type="date"
              class="control"
              :min="selectedSurvey?.tanggalMulai || undefined"
              :max="tanggalSampai || selectedSurvey?.tanggalSelesai || undefined"
              :disabled="!selectedSurveyId"
            />
          </div>

          <div class="field date-field">
            <label class="field-label" for="tanggal-sampai">Sampai tanggal</label>
            <input
              id="tanggal-sampai"
              v-model="tanggalSampai"
              type="date"
              class="control"
              :min="tanggalDari || selectedSurvey?.tanggalMulai || undefined"
              :max="selectedSurvey?.tanggalSelesai || undefined"
              :disabled="!selectedSurveyId"
            />
          </div>

          <button
            v-if="tanggalDari || tanggalSampai"
            type="button"
            class="btn-reset"
            @click="resetDates"
          >
            Reset tanggal
          </button>
        </div>

        <p v-if="errorMessage" class="state-message state-error">{{ errorMessage }}</p>

        <div class="table-scroll">
          <table class="bukti-table">
            <thead>
              <tr>
                <th class="col-no">No</th>
                <th>Tanggal &amp; Waktu Pengisian</th>
                <th>Nama Pegawai</th>
                <th>Unit</th>
                <th>Organik/TAD</th>
                <th>Bukti Upload</th>
                <th>Bukti Upload Opsional</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(row, index) in rows" :key="row.id">
                <td class="col-no">{{ offset + index + 1 }}</td>
                <td>
                  <div class="cell-date">{{ formatTanggal(row.tanggal) }}</div>
                  <div class="cell-time">{{ formatWaktu(row.createdAt) }}</div>
                </td>
                <td class="cell-name">{{ row.nama }}</td>
                <td class="cell-muted">{{ shortDeptName(row.departemen) }}</td>
                <td>
                  <span class="type-flag">
                    <span
                      class="type-dot"
                      :class="row.jenisPegawai === 'Organik' ? 'type-organik' : 'type-non-organik'"
                    />
                    {{ jenisPegawaiLabel(row.jenisPegawai) }}
                  </span>
                </td>
                <td>
                  <button
                    v-if="imageUrls[row.fileBukti]"
                    type="button"
                    class="thumb"
                    :aria-label="`Lihat bukti ${row.nama}`"
                    @click="openLightbox(imageUrls[row.fileBukti], `Bukti ${row.nama}`)"
                  >
                    <img :src="imageUrls[row.fileBukti]" :alt="`Bukti ${row.nama}`" loading="lazy" />
                  </button>
                  <span v-else-if="row.fileBukti && imagesLoading" class="cell-muted">Memuat...</span>
                  <span v-else class="cell-muted">-</span>
                </td>
                <td>
                  <button
                    v-if="imageUrls[row.fileBukti2]"
                    type="button"
                    class="thumb"
                    :aria-label="`Lihat bukti tambahan ${row.nama}`"
                    @click="openLightbox(imageUrls[row.fileBukti2], `Bukti tambahan ${row.nama}`)"
                  >
                    <img :src="imageUrls[row.fileBukti2]" :alt="`Bukti tambahan ${row.nama}`" loading="lazy" />
                  </button>
                  <span v-else-if="row.fileBukti2 && imagesLoading" class="cell-muted">Memuat...</span>
                  <span v-else class="cell-muted">-</span>
                </td>
              </tr>
              <tr v-if="rowsLoading && rows.length === 0">
                <td colspan="7" class="empty-row">Memuat data...</td>
              </tr>
              <tr v-else-if="!rowsLoading && rows.length === 0 && selectedSurveyId">
                <td colspan="7" class="empty-row">
                  {{ search ? "Tidak ada pegawai yang cocok." : "Belum ada bukti yang diunggah." }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pagination">
          <span class="pagination-label">
            Menampilkan {{ total === 0 ? 0 : offset + 1 }}-{{ Math.min(offset + pageSize, total) }} dari
            {{ total }} data
          </span>
          <div class="pagination-actions">
            <button type="button" class="btn-secondary" :disabled="page === 1" @click="page--">
              Sebelumnya
            </button>
            <button type="button" class="btn-primary" :disabled="page >= totalPages" @click="page++">
              Selanjutnya
            </button>
          </div>
        </div>
      </div>

      <footer class="page-footer">
        Hak Cipta &copy; {{ currentYear }} Yogyakarta International Airport. Seluruh hak dilindungi.
      </footer>
    </main>

    <Teleport to="body">
      <div v-if="lightbox" class="lightbox" @click="closeLightbox">
        <button type="button" class="lightbox-close" aria-label="Tutup" @click="closeLightbox">&times;</button>
        <img class="lightbox-image" :src="lightbox.url" :alt="lightbox.alt" @click.stop />
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import AppHeader from "./components/AppHeader.vue";
import { shortDeptName } from "./orgStructure";
import { jenisPegawaiLabel, useSurveyStore } from "./stores/surveyStore";

const store = useSurveyStore();
const currentYear = new Date().getFullYear();
const pageSize = 10;

const surveys = ref([]);
const surveysLoading = ref(true);
const selectedSurveyId = ref(null);

const search = ref("");
// Inclusive range on the date the employee picked when filling the survey.
const tanggalDari = ref("");
const tanggalSampai = ref("");
const page = ref(1);

const selectedSurvey = computed(() =>
  surveys.value.find((s) => s.id === selectedSurveyId.value) ?? null
);

function resetDates() {
  tanggalDari.value = "";
  tanggalSampai.value = "";
}

// A range picked for one survey doesn't carry over to another.
watch(selectedSurveyId, resetDates);
const rows = ref([]);
const total = ref(0);
const rowsLoading = ref(false);
const errorMessage = ref("");

const imageUrls = ref({});
const imagesLoading = ref(false);

const lightbox = ref(null);

const offset = computed(() => (page.value - 1) * pageSize);
const totalPages = computed(() => Math.max(1, Math.ceil(total.value / pageSize)));

function formatTanggal(isoDate) {
  if (!isoDate) return "-";
  return new Date(`${isoDate}T00:00:00`).toLocaleDateString("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

// Always shown in WIB regardless of the visitor's device timezone.
const waktuFormatter = new Intl.DateTimeFormat("en-GB", {
  timeZone: "Asia/Jakarta",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hour12: false,
});

function formatWaktu(createdAt) {
  if (!createdAt) return "-";
  return `${waktuFormatter.format(new Date(createdAt))} WIB`;
}

onMounted(async () => {
  window.addEventListener("keydown", closeLightboxOnEscape);
  try {
    surveys.value = await store.fetchPublicBuktiSurveys();
    selectedSurveyId.value = surveys.value[0]?.id ?? null;
  } catch (err) {
    errorMessage.value = `Gagal memuat daftar survei: ${err.message}`;
  } finally {
    surveysLoading.value = false;
  }
});

onBeforeUnmount(() => {
  window.removeEventListener("keydown", closeLightboxOnEscape);
  clearTimeout(searchTimer);
});

// Switching survey or typing a new search restarts from page 1. Search is
// debounced so each keystroke doesn't fire a request.
let searchTimer = null;
const debouncedSearch = ref("");

watch(search, (value) => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    debouncedSearch.value = value.trim();
  }, 300);
});

watch([selectedSurveyId, debouncedSearch, tanggalDari, tanggalSampai], () => {
  // Already on page 1: load directly. Otherwise resetting the page triggers
  // the page watcher below, so don't load twice.
  if (page.value === 1) loadRows();
  else page.value = 1;
});

watch(page, loadRows);

// Out-of-order responses (fast paging / typing) must not overwrite newer ones.
let latestRequest = 0;

async function loadRows() {
  if (!selectedSurveyId.value) {
    rows.value = [];
    total.value = 0;
    return;
  }

  const request = ++latestRequest;
  rowsLoading.value = true;
  errorMessage.value = "";
  try {
    const result = await store.fetchPublicBukti(selectedSurveyId.value, {
      search: debouncedSearch.value,
      limit: pageSize,
      offset: offset.value,
      tanggalDari: tanggalDari.value,
      tanggalSampai: tanggalSampai.value,
    });
    if (request !== latestRequest) return;
    rows.value = result.rows;
    total.value = result.total;
    loadImages(result.rows, request);
  } catch (err) {
    if (request !== latestRequest) return;
    rows.value = [];
    total.value = 0;
    errorMessage.value = `Gagal memuat data: ${err.message}`;
  } finally {
    if (request === latestRequest) rowsLoading.value = false;
  }
}

async function loadImages(list, request) {
  const paths = list.flatMap((r) => [r.fileBukti, r.fileBukti2]).filter(Boolean);
  if (paths.length === 0) return;
  imagesLoading.value = true;
  try {
    const urls = await store.fetchBuktiSignedUrls(paths);
    if (request === latestRequest) imageUrls.value = { ...imageUrls.value, ...urls };
  } catch (err) {
    console.error("Gagal memuat bukti:", err);
  } finally {
    if (request === latestRequest) imagesLoading.value = false;
  }
}

function openLightbox(url, alt) {
  lightbox.value = { url, alt };
}

function closeLightbox() {
  lightbox.value = null;
}

function closeLightboxOnEscape(event) {
  if (event.key === "Escape") closeLightbox();
}
</script>

<style scoped>
.bukti-page {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  min-height: 100dvh;
  background-color: var(--color-bg);
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
  padding: 24px;
}

.back-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--color-text-muted);
  font-size: 13px;
  font-weight: 600;
  text-decoration: none;
}

.back-link:hover {
  color: var(--color-primary);
}

.card {
  width: 100%;
  max-width: 1100px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 24px;
  border-radius: 20px;
  background-color: var(--glass-bg-strong);
  backdrop-filter: blur(var(--glass-blur));
  -webkit-backdrop-filter: blur(var(--glass-blur));
  border: 1px solid var(--glass-border);
  box-shadow: 0 24px 60px -12px rgba(15, 23, 42, 0.22), var(--glass-shadow);
}

.card-title {
  font-size: 20px;
  color: var(--color-text);
}

.card-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--color-text-secondary);
}

.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.survey-field {
  flex: 1 1 280px;
}

.search-field {
  flex: 1 1 220px;
}

.date-field {
  flex: 0 1 160px;
}

.btn-reset {
  align-self: flex-end;
  height: 40px;
  padding: 0 14px;
  border: none;
  background: none;
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 600;
  color: var(--color-primary);
  text-decoration: underline;
  cursor: pointer;
}

.control:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.field-label {
  font-size: 12px;
  font-weight: 700;
  color: var(--color-text-secondary);
}

.control {
  width: 100%;
  height: 40px;
  padding: 0 12px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  font-family: var(--font-sans);
  font-size: 14px;
  color: var(--color-text);
}

.control:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px rgba(0, 93, 172, 0.2);
}

.state-message {
  padding: 10px 14px;
  border-radius: var(--radius-md);
  font-size: 13px;
  font-weight: 600;
}

.state-error {
  color: var(--color-danger);
  background-color: var(--color-danger-bg);
}

.table-scroll {
  overflow-x: auto;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
}

.bukti-table {
  width: 100%;
  min-width: 860px;
  border-collapse: collapse;
  font-size: 13px;
}

.bukti-table th {
  padding: 12px 14px;
  text-align: left;
  font-size: 12px;
  font-weight: 700;
  color: var(--color-text-secondary);
  background-color: var(--color-bg);
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}

.bukti-table td {
  padding: 10px 14px;
  vertical-align: middle;
  color: var(--color-text);
  border-bottom: 1px solid var(--color-border);
}

.bukti-table tbody tr:last-child td {
  border-bottom: none;
}

.col-no {
  width: 48px;
  color: var(--color-text-muted);
}

.cell-name {
  font-weight: 700;
}

.cell-date {
  font-weight: 600;
}

.cell-time {
  font-size: 12px;
  color: var(--color-text-muted);
}

.cell-muted {
  color: var(--color-text-muted);
}

.type-flag {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
}

.type-dot {
  width: 8px;
  height: 8px;
  border-radius: var(--radius-full);
}

.type-organik {
  background-color: var(--color-primary);
}

.type-non-organik {
  background-color: var(--color-warning);
}

.thumb {
  display: block;
  width: 56px;
  height: 56px;
  padding: 0;
  overflow: hidden;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  background: var(--color-bg);
  cursor: zoom-in;
}

.thumb img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.empty-row {
  padding: 32px 14px;
  text-align: center;
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

.pagination-actions {
  display: flex;
  gap: 8px;
}

.btn-secondary,
.btn-primary {
  height: 36px;
  padding: 0 16px;
  border-radius: var(--radius-md);
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

.btn-secondary {
  color: var(--color-text-secondary);
  background-color: var(--color-surface);
  border: 1px solid var(--color-border-strong);
}

.btn-primary {
  color: #ffffff;
  background-color: var(--color-primary);
  border: 1px solid var(--color-primary);
}

.btn-secondary:disabled,
.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.page-footer {
  text-align: center;
  font-size: 12px;
  color: var(--color-text-secondary);
}

.lightbox {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background-color: rgba(15, 23, 42, 0.8);
  cursor: zoom-out;
}

.lightbox-image {
  max-width: 100%;
  max-height: 100%;
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  cursor: default;
}

.lightbox-close {
  position: absolute;
  top: 12px;
  right: 16px;
  border: none;
  background: none;
  font-size: 36px;
  line-height: 1;
  color: #ffffff;
  cursor: pointer;
}

@media (max-width: 520px) {
  .main-content {
    padding: 12px;
  }

  .card {
    padding: 16px;
  }
}
</style>
