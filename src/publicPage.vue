<template>
  <div class="public-page">
    <div class="bg-blob bg-blob-1" aria-hidden="true" />
    <div class="bg-blob bg-blob-2" aria-hidden="true" />
    <div class="bg-blob bg-blob-3" aria-hidden="true" />
    <div class="bg-blob bg-blob-4" aria-hidden="true" />

    <svg class="bg-flower bg-flower-1" viewBox="0 0 24 24" aria-hidden="true">
      <g>
        <ellipse cx="12" cy="6" rx="3" ry="5" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(60 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(120 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(180 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(240 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(300 12 12)" />
        <circle cx="12" cy="12" r="2.4" />
      </g>
    </svg>
    <svg class="bg-flower bg-flower-2" viewBox="0 0 24 24" aria-hidden="true">
      <g>
        <ellipse cx="12" cy="6" rx="3" ry="5" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(60 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(120 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(180 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(240 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(300 12 12)" />
        <circle cx="12" cy="12" r="2.4" />
      </g>
    </svg>

    <AppHeader />

    <main class="main-content">
      <div class="page-body">
      <div class="card">
        <div class="card-accent" aria-hidden="true" />
        <div class="decorative-blur-blob" />

        <div class="card-heading">
          <h1 class="card-title">Pengisian Data Survei</h1>
          <p class="card-subtitle">Silakan lengkapi data survei di bawah ini.</p>
        </div>

        <form class="form" @submit.prevent="handleSubmit">
          <div class="field">
            <label class="field-label" for="survey">Pilih survei</label>
            <div class="input-wrap">
              <svg class="input-icon" width="19" height="19" viewBox="0 0 20 20" fill="none">
                <rect x="5" y="4" width="10" height="13" rx="1.5" stroke="currentColor" stroke-width="1.5" />
                <path d="M8 3.5h4a1 1 0 0 1 1 1V5H7v-.5a1 1 0 0 1 1-1Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" />
                <path d="M7.5 8.5h5M7.5 11h5M7.5 13.5h3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
              </svg>
              <select id="survey" v-model="selectedSurveyId" class="select">
                <option v-for="survey in surveys" :key="survey.id" :value="survey.id">
                  {{ survey.nama }}
                </option>
              </select>
            </div>

            <div v-if="selectedSurvey && selectedSurvey.tipe !== 'Internal'" class="survey-meta">
              <a
                v-if="selectedSurvey.link"
                class="survey-link-button"
                :href="selectedSurvey.link"
                target="_blank"
                rel="noopener"
              >
                <svg width="15" height="15" viewBox="0 0 20 20" fill="none">
                  <path
                    d="M8.5 11.5 11.5 8.5M9 6l.6-.6a3 3 0 0 1 4.2 4.2L13 10.4M11 14l-.6.6a3 3 0 0 1-4.2-4.2L7 9.6"
                    stroke="currentColor"
                    stroke-width="1.6"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  />
                </svg>
                Buka Link Survei
              </a>
              <span v-else class="survey-link-empty">Link belum tersedia</span>
            </div>

            <p v-if="selectedSurvey?.tipe === 'Internal' && selectedSurvey.deskripsi" class="survey-deskripsi">
              {{ selectedSurvey.deskripsi }}
            </p>
          </div>

          <div class="field">
            <label class="field-label" for="tanggal">Pilih tanggal</label>
            <div class="input-wrap" @click="openDatePicker">
              <svg class="input-icon" width="16" height="16" viewBox="0 0 20 20" fill="none">
                <rect x="3" y="4" width="14" height="13" rx="1.5" stroke="currentColor" stroke-width="1.5" />
                <path d="M3 8h14M6.5 2.5v3M13.5 2.5v3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
              </svg>
              <input
                id="tanggal"
                ref="tanggalInput"
                v-model="form.tanggal"
                type="date"
                class="input"
                :min="minDate"
                :max="maxDate"
                required
              />
            </div>
          </div>

          <div class="field" :class="{ 'field-elevated': showSuggestions }">
            <label class="field-label" for="nama">Pilih nama</label>
            <div ref="autocompleteRef" class="autocomplete">
              <div class="input-wrap">
                <svg class="input-icon" width="16" height="16" viewBox="0 0 20 20" fill="none">
                  <circle cx="10" cy="7" r="3.2" stroke="currentColor" stroke-width="1.5" />
                  <path d="M4 17c0-3.3 2.7-5.5 6-5.5s6 2.2 6 5.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
                </svg>
                <input
                  id="nama"
                  v-model="nameQuery"
                  type="text"
                  class="input"
                  placeholder="Cari nama pegawai..."
                  autocomplete="off"
                  required
                  @focus="showSuggestions = true"
                  @input="handleNameInput"
                />
              </div>
              <ul v-if="showSuggestions && suggestions.length" class="suggestion-list">
                <li
                  v-for="employee in suggestions"
                  :key="employee.id"
                  class="suggestion-item"
                  @click="selectEmployee(employee)"
                >
                  <span class="suggestion-name">{{ employee.nama }}</span>
                  <span class="suggestion-unit">{{ shortDeptName(employee.unitKerja) }}</span>
                </li>
              </ul>
              <p
                v-else-if="showSuggestions && nameQuery && !selectedEmployee"
                class="suggestion-empty"
              >
                Nama tidak ditemukan di data pegawai.
              </p>
            </div>
            <p v-if="selectedEmployee && selectedSurvey" class="name-quota-info" :class="quotaBadgeClass">
              Anda sudah mengisi survei sebanyak {{ employeeSubmissionCount }} / {{ selectedSurvey.maxPengisian }}
            </p>
          </div>

          <div v-if="selectedSurvey?.tipe === 'Internal'" class="field questions-field">
            <label class="field-label">Pertanyaan</label>
            <div v-if="questionsLoading" class="questions-loading">Memuat pertanyaan...</div>
            <div v-else v-for="q in questions" :key="q.id" class="question-block">
              <p class="question-text">{{ q.pertanyaan }}</p>
              <template v-if="q.tipe === 'Pilihan'">
                <label v-for="opt in q.options" :key="opt.id" class="option-choice">
                  <input type="radio" :name="`question-${q.id}`" :value="opt.id" v-model="answers[q.id]" />
                  {{ opt.opsi }}
                </label>
              </template>
              <template v-else-if="q.tipe === 'PilihanMulti'">
                <label v-for="opt in q.options" :key="opt.id" class="option-choice">
                  <input type="checkbox" :value="opt.id" v-model="answers[q.id]" />
                  {{ opt.opsi }}
                </label>
              </template>
              <textarea
                v-else
                v-model="answers[q.id]"
                class="input lisan-input"
                rows="3"
                placeholder="Tulis jawaban Anda..."
              />
            </div>
          </div>

          <div v-else class="field">
            <label class="field-label">Upload Bukti</label>
            <div
              class="dropzone"
              :class="{ 'dropzone-active': isDragging, 'dropzone-disabled': quotaFull }"
              @click="!quotaFull && triggerFilePicker()"
              @dragover.prevent="!quotaFull && (isDragging = true)"
              @dragleave.prevent="isDragging = false"
              @drop.prevent="handleDrop"
            >
              <input
                ref="fileInput"
                type="file"
                accept="image/*"
                class="file-input"
                :disabled="quotaFull"
                @change="handleFileChange"
              />
              <template v-if="form.file">
                <p class="dropzone-filename">{{ form.file.name }}</p>
                <p class="dropzone-hint">Klik untuk mengganti file</p>
              </template>
              <template v-else>
                <p class="dropzone-text">
                  <span class="dropzone-link">Klik untuk upload</span> atau drag and drop
                </p>
                <p class="dropzone-hint">PNG, JPG, atau GIF (Maks. 5MB)</p>
              </template>
            </div>
            <p v-if="quotaFull" class="field-error">
              <svg class="field-error-icon" width="16" height="16" viewBox="0 0 20 20" fill="none">
                <path
                  d="M10 2 2 17h16L10 2Z"
                  stroke="currentColor"
                  stroke-width="1.6"
                  stroke-linejoin="round"
                />
                <path d="M10 8v4M10 14.5v.01" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
              </svg>
              Anda sudah mencapai batas maksimal pengisian survei ini ({{ selectedSurvey?.maxPengisian }} kali).
            </p>
          </div>

          <button type="submit" class="submit-button" :disabled="!canSubmit || submitting">
            <span v-if="submitting" class="spinner" aria-hidden="true" />
            {{ submitting ? "Mengirim..." : selectedSurvey?.tipe === "Internal" ? "Kirim Jawaban" : "Upload Bukti" }}
            <svg v-if="!submitting" class="submit-arrow" width="15" height="15" viewBox="0 0 20 20" fill="none">
              <path d="M4 10h12M11 5l5 5-5 5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
          </button>
        </form>
      </div>

      <footer class="page-footer">
        Hak Cipta &copy; {{ currentYear }} Yogyakarta International Airport.
      </footer>
      </div>
    </main>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from "vue";
import { useRouter } from "vue-router";
import AppHeader from "./components/AppHeader.vue";
import { shortDeptName } from "./orgStructure";
import { useSurveyStore } from "./stores/surveyStore";
import { useToastStore } from "./stores/toastStore";

const store = useSurveyStore();
const toast = useToastStore();
const router = useRouter();
const surveys = computed(() => store.activeAvailableSurveys);
const currentYear = new Date().getFullYear();

const selectedSurveyId = ref(null);
const fileInput = ref(null);
const tanggalInput = ref(null);
const isDragging = ref(false);
const submitting = ref(false);

const today = new Date().toISOString().slice(0, 10);

const form = reactive({
  tanggal: today,
  file: null,
});

let pollInterval = null;

onMounted(async () => {
  await store.ensureBaseData();
  selectedSurveyId.value = surveys.value[0]?.id ?? null;

  // Poll surveys every 3 seconds for real-time updates
  pollInterval = setInterval(async () => {
    try {
      await store.fetchSurveys();
    } catch (err) {
      console.error("Poll error:", err);
    }
  }, 3000);

  // Also refetch when user refocuses tab
  window.addEventListener("focus", () => {
    store.fetchSurveys().catch(console.error);
  });
});

const nameQuery = ref("");
const selectedEmployee = ref(null);
const showSuggestions = ref(false);
const autocompleteRef = ref(null);

const suggestions = computed(() => {
  const term = nameQuery.value.trim().toLowerCase();
  if (!term) return [];
  return store.employees
    .filter((e) => e.isActive && e.nama.toLowerCase().includes(term))
    .slice(0, 6);
});

function handleNameInput() {
  showSuggestions.value = true;
  if (selectedEmployee.value && selectedEmployee.value.nama !== nameQuery.value) {
    selectedEmployee.value = null;
  }
}

function selectEmployee(employee) {
  selectedEmployee.value = employee;
  nameQuery.value = employee.nama;
  showSuggestions.value = false;
}

function closeSuggestionsOnOutsideClick(event) {
  if (autocompleteRef.value && !autocompleteRef.value.contains(event.target)) {
    showSuggestions.value = false;
  }
}

onMounted(() => document.addEventListener("click", closeSuggestionsOnOutsideClick));
onBeforeUnmount(() => {
  document.removeEventListener("click", closeSuggestionsOnOutsideClick);
  if (pollInterval) clearInterval(pollInterval);
  window.removeEventListener("focus", () => store.fetchSurveys());
});

const selectedSurvey = computed(() => store.findSurvey(selectedSurveyId.value));

const questions = ref([]);
const questionsLoading = ref(false);
const answers = reactive({});

// Watches selectedSurveyId (a primitive) rather than selectedSurvey (an
// object computed from store.surveys) on purpose: the public page polls
// fetchSurveys() every 3s, which replaces store.surveys wholesale, so
// selectedSurvey would get a brand-new object reference every poll even
// when the selected survey hasn't changed. Watching the object directly
// fired this handler every 3s and wiped out whatever the employee had just
// answered — watching the id avoids that while still re-fetching questions
// when the employee actually switches surveys.
watch(selectedSurveyId, async (id) => {
  questions.value = [];
  for (const key of Object.keys(answers)) delete answers[key];
  const survey = store.findSurvey(id);
  if (survey?.tipe !== "Internal") return;

  questionsLoading.value = true;
  try {
    questions.value = await store.fetchSurveyQuestions(survey.id);
    for (const q of questions.value) {
      if (q.tipe === "PilihanMulti") answers[q.id] = [];
    }
  } catch (err) {
    toast.show("Gagal memuat pertanyaan survei.", "error");
  } finally {
    questionsLoading.value = false;
  }
}, { immediate: true });

// Date picker is clamped to the selected survey's own open period — any date
// from tanggalMulai to tanggalSelesai is fillable, including future dates
// within that window.
const minDate = computed(() => selectedSurvey.value?.tanggalMulai || undefined);
const maxDate = computed(() => selectedSurvey.value?.tanggalSelesai || undefined);

const employeeSubmissionCount = computed(() =>
  selectedSurveyId.value && selectedEmployee.value
    ? store.submissionCountForEmployeeSurvey(selectedSurveyId.value, selectedEmployee.value.nama)
    : 0
);

const quotaFull = computed(() =>
  selectedSurveyId.value && selectedEmployee.value
    ? store.isSurveyFullForEmployee(selectedSurveyId.value, selectedEmployee.value.nama)
    : false
);

const quotaBadgeClass = computed(() => {
  if (!selectedSurvey.value || !selectedEmployee.value) return "";
  const ratio = employeeSubmissionCount.value / selectedSurvey.value.maxPengisian;
  if (ratio >= 1) return "quota-full";
  if (ratio >= 0.8) return "quota-warning";
  return "quota-ok";
});

const canSubmit = computed(() => {
  if (quotaFull.value || !selectedEmployee.value || !form.tanggal) return false;
  if (selectedSurvey.value?.tipe === "Internal") {
    return (
      questions.value.length > 0 &&
      questions.value.every((q) => {
        if (q.tipe === "Lisan") return String(answers[q.id] ?? "").trim();
        if (q.tipe === "PilihanMulti") return Array.isArray(answers[q.id]) && answers[q.id].length > 0;
        return !!answers[q.id];
      })
    );
  }
  return !!form.file;
});

watch(selectedSurveyId, () => {
  form.file = null;
  if (fileInput.value) fileInput.value.value = "";
  if (minDate.value && form.tanggal < minDate.value) form.tanggal = minDate.value;
  if (maxDate.value && form.tanggal > maxDate.value) form.tanggal = maxDate.value;
});

function openDatePicker() {
  try {
    tanggalInput.value?.showPicker();
  } catch {
    tanggalInput.value?.focus();
  }
}

function triggerFilePicker() {
  fileInput.value?.click();
}

const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

function setFileIfValid(file) {
  if (!file) return;
  if (file.size > MAX_FILE_SIZE) {
    toast.show(
      `Ukuran file terlalu besar (${(file.size / 1024 / 1024).toFixed(1)}MB). Maksimal 5MB.`,
      "error"
    );
    return;
  }
  form.file = file;
}

function handleFileChange(event) {
  const file = event.target.files?.[0];
  setFileIfValid(file);
  if (event.target.value) event.target.value = "";
}

function handleDrop(event) {
  isDragging.value = false;
  if (quotaFull.value) return;
  const file = event.dataTransfer?.files?.[0];
  setFileIfValid(file);
}

async function handleSubmit() {
  if (!canSubmit.value || !selectedSurveyId.value || submitting.value) return;
  submitting.value = true;
  const isInternal = selectedSurvey.value?.tipe === "Internal";
  try {
    await store.addSubmission({
      surveyId: selectedSurveyId.value,
      nama: selectedEmployee.value.nama,
      tanggal: form.tanggal,
      jenisPegawai: selectedEmployee.value.jenisPegawai,
      departemen: selectedEmployee.value.unitKerja,
      file: isInternal ? undefined : form.file,
      answers: isInternal
        ? questions.value.flatMap((q) => {
            if (q.tipe === "Lisan") {
              return [{ question_id: q.id, pertanyaan: q.pertanyaan, jawaban: String(answers[q.id] ?? "").trim() }];
            }
            if (q.tipe === "PilihanMulti") {
              return (answers[q.id] ?? []).map((optId) => ({
                question_id: q.id,
                pertanyaan: q.pertanyaan,
                jawaban: q.options.find((o) => o.id === optId)?.opsi ?? "",
              }));
            }
            return [
              {
                question_id: q.id,
                pertanyaan: q.pertanyaan,
                jawaban: q.options.find((o) => o.id === answers[q.id])?.opsi ?? "",
              },
            ];
          })
        : undefined,
    });
    toast.show(isInternal ? "Jawaban berhasil dikirim" : "Bukti berhasil di-upload", "success");
    router.push("/success");
  } catch (err) {
    toast.show(err.message, "error");
  } finally {
    submitting.value = false;
  }
}
</script>

<style scoped>
.public-page {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: var(--color-bg);
}

.main-content {
  flex: 1;
  min-height: 0;
  display: flex;
  align-items: safe center;
  justify-content: center;
  padding: 16px 24px;
  overflow-y: auto;
}

.page-body {
  width: 100%;
  max-width: 460px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.page-footer {
  text-align: center;
  font-size: 12px;
  line-height: 1.4;
  color: var(--color-text-secondary);
}

/* ── Drifting spinning-flower silhouettes ────────────────────────────────
   Purely decorative, sits behind the glass card at the same z-index/style
   as the bg-blobs (translucent, brand accent colors, no new palette). */
.bg-flower {
  position: absolute;
  z-index: -1;
  pointer-events: none;
  will-change: transform, opacity;
}

.bg-flower-1 {
  top: 20%;
  left: -8%;
  width: 88px;
  height: 88px;
  fill: var(--color-primary-light);
  animation: flower-drift-1 24s linear infinite;
}

.bg-flower-2 {
  top: 64%;
  left: -8%;
  width: 60px;
  height: 60px;
  fill: var(--color-accent-cyan-strong);
  animation: flower-drift-2 32s linear infinite;
}

@keyframes flower-drift-1 {
  0% { transform: translate(0, 0) rotate(0deg); opacity: 0; }
  8% { opacity: 0.4; }
  92% { opacity: 0.4; }
  100% { transform: translate(125vw, -18vh) rotate(1080deg); opacity: 0; }
}

@keyframes flower-drift-2 {
  0% { transform: translate(0, 0) rotate(0deg); opacity: 0; }
  8% { opacity: 0.45; }
  92% { opacity: 0.45; }
  100% { transform: translate(120vw, 16vh) rotate(-1080deg); opacity: 0; }
}

@media (prefers-reduced-motion: reduce) {
  .bg-flower {
    animation: none !important;
    display: none;
  }
}

.card {
  position: relative;
  width: 100%;
  max-width: 460px;
  padding: 22px 24px 20px;
  border-radius: 20px;
  background-color: var(--glass-bg-strong);
  backdrop-filter: blur(var(--glass-blur));
  -webkit-backdrop-filter: blur(var(--glass-blur));
  border: 1px solid var(--glass-border);
  box-shadow: 0 24px 60px -12px rgba(15, 23, 42, 0.22), var(--glass-shadow);
  display: flex;
  flex-direction: column;
  gap: 12px;
  animation: card-enter 0.5s cubic-bezier(0.16, 1, 0.3, 1) both;
  transition: box-shadow 0.3s ease, transform 0.3s ease;
}

.card:hover {
  box-shadow: 0 28px 64px -10px rgba(15, 23, 42, 0.26), 0 0 0 1px rgba(0, 93, 172, 0.08);
  transform: translateY(-2px);
}

.card-accent {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(
    90deg,
    var(--color-primary) 0%,
    var(--color-primary-light) 45%,
    var(--color-accent-cyan-strong) 100%
  );
}

.card-heading,
.form .field {
  animation: field-enter 0.45s cubic-bezier(0.16, 1, 0.3, 1) both;
}

.card-heading {
  animation-delay: 0.06s;
}

.form .field:nth-of-type(1) { animation-delay: 0.13s; }
.form .field:nth-of-type(2) { animation-delay: 0.19s; }
.form .field:nth-of-type(3) { animation-delay: 0.25s; }
.form .field:nth-of-type(4) { animation-delay: 0.31s; }

.submit-button {
  animation: field-enter 0.45s cubic-bezier(0.16, 1, 0.3, 1) both;
  animation-delay: 0.37s;
}

@keyframes card-enter {
  from {
    opacity: 0;
    transform: translateY(28px) scale(0.97);
  }
  to {
    opacity: 1;
  }
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
  .card,
  .card-heading,
  .form .field,
  .submit-button {
    animation: none !important;
  }

  .card:hover {
    transform: none;
  }
}

.decorative-blur-blob {
  position: absolute;
  top: -40px;
  right: -40px;
  width: 128px;
  height: 128px;
  border-radius: var(--radius-full);
  background-color: var(--color-accent-blue-soft);
  filter: blur(32px);
  opacity: 0.5;
}

.card-heading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  text-align: center;
  position: relative;
}

.card-title {
  color: var(--color-text);
  font-size: 18px;
  font-weight: 700;
  letter-spacing: -0.02em;
}

.card-subtitle {
  color: var(--color-text-secondary);
  font-size: 13px;
  line-height: 1.4;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 10px;
  position: relative;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.field-elevated {
  position: relative;
  z-index: 30;
}

.field-label {
  color: var(--color-text-secondary);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.01em;
}

.input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.input-icon {
  position: absolute;
  left: 13px;
  color: var(--color-text-muted);
  pointer-events: none;
  transition: color 0.2s ease;
  z-index: 1;
}

.input-wrap:has(.select:focus, .input:focus) .input-icon {
  color: var(--color-primary);
}

.select,
.input {
  width: 100%;
  height: 38px;
  padding: 0 12px 0 36px;
  border: 1px solid var(--color-border);
  border-radius: 12px;
  font-family: var(--font-sans);
  font-size: 14px;
  color: var(--color-text);
  background-color: var(--color-bg);
  transition: border-color 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease;
}

.select {
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8' fill='none'%3E%3Cpath d='M1 1.5 6 6.5 11 1.5' stroke='%23334155' stroke-width='1.6' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 14px center;
  padding-right: 34px;
  cursor: pointer;
}

.select:focus,
.input:focus {
  outline: none;
  border-color: var(--color-primary);
  background-color: var(--color-surface);
  box-shadow: 0 0 0 3px rgba(0, 93, 172, 0.14);
}

.autocomplete {
  position: relative;
}

.suggestion-list {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  max-height: 220px;
  overflow-y: auto;
  margin: 0;
  padding: 4px;
  list-style: none;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  z-index: 20;
}

.suggestion-item {
  display: flex;
  flex-direction: column;
  padding: 8px 10px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: background-color 0.15s ease, transform 0.1s ease;
}

.suggestion-item:active {
  transform: scale(0.97);
}

.suggestion-item:hover {
  background-color: var(--color-bg);
}

.suggestion-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--color-text);
}

.suggestion-unit {
  font-size: 12px;
  color: var(--color-text-muted);
}

.suggestion-empty {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  margin: 0;
  padding: 10px 12px;
  font-size: 13px;
  color: var(--color-text-muted);
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  z-index: 20;
}

.survey-meta {
  display: flex;
  align-items: center;
  margin-top: 6px;
}

.survey-deskripsi {
  margin-top: 6px;
  max-height: 120px;
  overflow-y: auto;
  padding: 8px 10px;
  border-radius: 8px;
  background-color: rgba(0, 93, 172, 0.06);
  font-size: 13px;
  line-height: 1.5;
  color: var(--color-text-secondary);
  white-space: pre-line;
}

.name-quota-info {
  margin-top: 4px;
  padding: 6px 10px;
  border-radius: var(--radius-md);
  font-size: 12px;
  line-height: 1.4;
}

.name-quota-info.quota-ok {
  background-color: var(--color-success-bg);
  color: var(--color-success);
}

.name-quota-info.quota-warning {
  background-color: var(--color-warning-bg);
  color: var(--color-warning);
}

.name-quota-info.quota-full {
  background-color: var(--color-danger-bg);
  color: var(--color-danger);
}

.survey-link-button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 7px 14px;
  border-radius: var(--radius-md);
  background-color: var(--color-primary);
  color: #ffffff;
  font-size: 13px;
  font-weight: 600;
  text-decoration: none;
  box-shadow: 0 2px 6px rgba(0, 93, 172, 0.3);
  transition: background-color 0.15s ease, box-shadow 0.15s ease, transform 0.1s ease;
}

.survey-link-button:hover {
  background-color: var(--color-primary-dark);
  box-shadow: 0 3px 10px rgba(0, 93, 172, 0.4);
}

.survey-link-button:active {
  transform: translateY(1px);
}

.survey-link-empty {
  font-size: 13px;
  color: var(--color-text-muted);
  font-style: italic;
}

.questions-field {
  gap: 10px;
}

.questions-loading {
  font-size: 13px;
  color: var(--color-text-muted);
}

.question-block {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 10px 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
}

.question-text {
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text);
  margin: 0 0 2px;
}

.option-choice {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.lisan-input {
  height: auto;
  padding: 8px 10px;
  resize: vertical;
  font-family: var(--font-sans);
  line-height: 1.4;
}

.dropzone {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 3px;
  padding: 14px 16px;
  border: 1.5px dashed var(--color-border-strong);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  text-align: center;
  cursor: pointer;
  transition: border-color 0.15s ease, background-color 0.15s ease, transform 0.1s ease;
}

.dropzone:hover {
  border-color: var(--color-primary-light);
}

.dropzone:active {
  transform: scale(0.985);
}

.dropzone-active {
  border-color: var(--color-primary);
  background-color: rgba(0, 93, 172, 0.04);
}

.dropzone-disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.file-input {
  display: none;
}

.dropzone-text,
.dropzone-filename {
  color: var(--color-text-secondary);
  font-size: 14px;
  margin: 0;
}

.dropzone-link {
  color: var(--color-primary);
  font-weight: 600;
}

.dropzone-hint {
  color: var(--color-text-muted);
  font-size: 12px;
  margin: 0;
}

.field-error {
  display: flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  padding: 10px 12px;
  border-radius: var(--radius-md);
  background-color: var(--color-danger-bg);
  border: 1px solid var(--color-danger);
  color: var(--color-danger);
  font-size: 12.5px;
  font-weight: 600;
}

.field-error-icon {
  flex-shrink: 0;
}

.submit-button {
  width: 100%;
  height: 40px;
  padding: 0;
  border: none;
  border-radius: 12px;
  background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-primary-light) 100%);
  color: #ffffff;
  font-family: var(--font-sans);
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 0.01em;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  box-shadow: 0 4px 14px rgba(0, 93, 172, 0.28);
  cursor: pointer;
  transition: box-shadow 0.2s ease, transform 0.15s ease, filter 0.15s ease;
}

.submit-arrow {
  transition: transform 0.2s ease;
}

.submit-button:hover:not(:disabled) {
  filter: brightness(1.06);
  box-shadow: 0 8px 20px rgba(0, 93, 172, 0.38);
  transform: translateY(-1px);
}

.submit-button:hover:not(:disabled) .submit-arrow {
  transform: translateX(3px);
}

.submit-button:active:not(:disabled) {
  transform: scale(0.97);
}

.submit-button:disabled {
  background: var(--color-border-strong);
  box-shadow: none;
  cursor: not-allowed;
}

.spinner {
  width: 15px;
  height: 15px;
  border: 2px solid rgba(255, 255, 255, 0.4);
  border-top-color: #ffffff;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
