<template>
  <Teleport to="body">
    <div class="preview-overlay" role="dialog" aria-modal="true" aria-label="Pratinjau survei" @click.self="$emit('close')">
      <div class="preview-shell">
        <div class="preview-bar">
          <span class="preview-badge">Pratinjau</span>
          <span class="preview-hint">Seperti inilah tampilan yang dilihat pegawai. Anda boleh mencoba memilih jawaban; tidak ada yang tersimpan.</span>
          <button type="button" class="preview-close" aria-label="Tutup pratinjau" @click="$emit('close')">&times;</button>
        </div>

        <div class="preview-scroll">
          <div v-if="skipped.length" class="preview-warning" role="status">
            <strong>{{ skipped.length }} pertanyaan tidak akan ikut tersimpan:</strong>
            <ul>
              <li v-for="item in skipped" :key="item.number">
                Pertanyaan {{ item.number }} — {{ item.reason }}
              </li>
            </ul>
          </div>

          <div class="card">
            <div class="card-accent" aria-hidden="true" />
            <div class="card-heading">
              <h1 class="card-title">Pengisian Data Survei</h1>
              <p class="card-subtitle">Silakan lengkapi data survei di bawah ini.</p>
            </div>

            <div class="form">
              <div class="field">
                <span class="field-label">Pilih survei</span>
                <div class="fake-input fake-select">{{ nama || "(Nama survei belum diisi)" }}</div>
                <p v-if="deskripsi" class="survey-deskripsi">{{ deskripsi }}</p>
              </div>

              <div class="field">
                <span class="field-label">Tanggal</span>
                <div class="fake-input">{{ todayLabel }}</div>
              </div>

              <div class="field">
                <span class="field-label">Pilih nama</span>
                <div class="fake-input fake-placeholder">Cari nama pegawai...</div>
              </div>

              <div class="field questions-field">
                <span class="field-label">Pertanyaan</span>

                <p v-if="shown.length === 0" class="empty-questions">
                  Belum ada pertanyaan yang lengkap. Tambahkan pertanyaan dan opsi jawaban di form.
                </p>

                <div v-for="q in shown" :key="q.number" class="question-block">
                  <p class="question-text">{{ q.number }}. {{ q.pertanyaan }}</p>

                  <template v-if="q.tipe === 'Pilihan'">
                    <label v-for="(opt, oi) in q.options" :key="oi" class="option-choice">
                      <input v-model="answers[q.number]" type="radio" :name="`preview-${q.number}`" :value="oi" />
                      <span class="option-body">
                        <span class="option-letter">{{ optionLabel(oi) }}.</span>
                        <span>{{ opt }}</span>
                      </span>
                    </label>
                  </template>

                  <template v-else-if="q.tipe === 'PilihanMulti'">
                    <label v-for="(opt, oi) in q.options" :key="oi" class="option-choice">
                      <input v-model="answers[q.number]" type="checkbox" :value="oi" />
                      <span class="option-body">
                        <span class="option-letter">{{ optionLabel(oi) }}.</span>
                        <span>{{ opt }}</span>
                      </span>
                    </label>
                  </template>

                  <textarea
                    v-else
                    v-model="answers[q.number]"
                    class="lisan-input"
                    rows="3"
                    placeholder="Tulis jawaban Anda..."
                  />
                </div>
              </div>

              <button type="button" class="submit-button" disabled>Kirim Jawaban</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive } from "vue";
import { optionLabel } from "../lib/optionLabel";

const props = defineProps({
  nama: { type: String, default: "" },
  deskripsi: { type: String, default: "" },
  // The builder's raw questions: { tipe, pertanyaan, options: [{ opsi }] }
  questions: { type: Array, default: () => [] },
});

const emit = defineEmits(["close"]);

// Same rule the save step applies (see validQuestions in adminBuatSurvey.vue):
// a question needs its text, and a choice question needs at least 2 filled
// options. Anything else is dropped on save, so the preview says so instead
// of silently hiding it.
const evaluated = computed(() =>
  props.questions.map((q, index) => {
    const pertanyaan = (q.pertanyaan ?? "").trim();
    const options =
      q.tipe === "Lisan" ? [] : (q.options ?? []).map((o) => (o.opsi ?? "").trim()).filter(Boolean);
    let reason = "";
    if (!pertanyaan) reason = "teks pertanyaan masih kosong";
    else if (q.tipe !== "Lisan" && options.length < 2) reason = "butuh minimal 2 opsi jawaban";
    return { number: index + 1, tipe: q.tipe, pertanyaan, options, reason };
  })
);

// Numbered by their position in the builder, like the public form numbers the
// saved ones (a skipped question just isn't shown).
const shown = computed(() => evaluated.value.filter((q) => !q.reason));
const skipped = computed(() => evaluated.value.filter((q) => q.reason));

const answers = reactive({});

const todayLabel = new Date().toLocaleDateString("id-ID", {
  timeZone: "Asia/Jakarta",
  weekday: "long",
  day: "numeric",
  month: "long",
  year: "numeric",
});

function onKeydown(event) {
  if (event.key === "Escape") emit("close");
}

onMounted(() => {
  window.addEventListener("keydown", onKeydown);
  document.body.style.overflow = "hidden";
});

onBeforeUnmount(() => {
  window.removeEventListener("keydown", onKeydown);
  document.body.style.overflow = "";
});
</script>

<style scoped>
.preview-overlay {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  background-color: rgba(15, 23, 42, 0.6);
}

.preview-shell {
  display: flex;
  flex-direction: column;
  width: 100%;
  max-width: 500px;
  /* An explicit viewport-based cap; with only max-height: 100% some mobile
     browsers let the shell grow past the screen and the bottom is cut off. */
  max-height: calc(100vh - 32px);
  max-height: calc(100dvh - 32px);
  overflow: hidden;
  border-radius: 16px;
  background-color: var(--color-bg);
  box-shadow: 0 24px 60px -12px rgba(15, 23, 42, 0.45);
}

.preview-bar {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  background-color: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
}

.preview-badge {
  flex-shrink: 0;
  padding: 2px 10px;
  border-radius: var(--radius-full);
  background-color: var(--color-primary);
  color: #ffffff;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.preview-hint {
  flex: 1;
  font-size: 12px;
  line-height: 1.4;
  color: var(--color-text-muted);
}

.preview-close {
  flex-shrink: 0;
  width: 30px;
  height: 30px;
  border: none;
  border-radius: 8px;
  background: none;
  color: var(--color-text-muted);
  font-size: 24px;
  line-height: 1;
  cursor: pointer;
}

.preview-close:hover {
  background-color: var(--color-bg);
  color: var(--color-text);
}

/* The scroll area is a plain block, not a flex column. As a flex column its
   child card (which has overflow: hidden, so no automatic minimum height)
   was shrunk to fit the window instead of overflowing, which clipped the
   questions inside it and left nothing to scroll: invisible with a couple of
   questions, obvious on an existing survey with many. min-height: 0 lets this
   area itself shrink so overflow-y can take over. */
.preview-scroll {
  flex: 1 1 auto;
  min-height: 0;
  padding: 16px;
  overflow-y: auto;
  overscroll-behavior: contain;
}

.preview-warning {
  margin-bottom: 12px;
  padding: 10px 12px;
  border-left: 3px solid var(--color-warning);
  border-radius: var(--radius-sm);
  background-color: var(--color-warning-bg);
  color: #92400e;
  font-size: 12px;
  line-height: 1.5;
}

.preview-warning ul {
  margin: 4px 0 0;
  padding-left: 18px;
}

/* The block below imitates the public form card (publicPage.vue). */
.card {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 22px 20px 20px;
  overflow: hidden;
  border-radius: 20px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  box-shadow: var(--shadow-md);
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

.card-heading {
  text-align: center;
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

.form {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  color: var(--color-text-secondary);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.01em;
}

.fake-input {
  display: flex;
  align-items: center;
  min-height: 38px;
  padding: 6px 12px;
  border: 1px solid var(--color-border);
  border-radius: 12px;
  background-color: var(--color-bg);
  font-size: 14px;
  color: var(--color-text);
}

.fake-select {
  font-weight: 600;
}

.fake-placeholder {
  color: var(--color-text-muted);
}

.survey-deskripsi {
  margin: 0;
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

.questions-field {
  gap: 10px;
}

.empty-questions {
  margin: 0;
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
  margin: 0 0 2px;
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text);
}

.option-choice {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.option-body {
  display: flex;
  align-items: baseline;
  gap: 3px;
}

.option-letter {
  min-width: 1.05em;
  font-weight: 700;
  color: var(--color-primary);
}

.lisan-input {
  padding: 8px 10px;
  border: 1px solid var(--color-border);
  border-radius: 12px;
  background-color: var(--color-bg);
  font-family: var(--font-sans);
  font-size: 14px;
  line-height: 1.4;
  resize: vertical;
}

.lisan-input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(0, 93, 172, 0.14);
}

.submit-button {
  width: 100%;
  height: 40px;
  border: none;
  border-radius: 12px;
  background: var(--color-border-strong);
  color: #ffffff;
  font-family: var(--font-sans);
  font-size: 14px;
  font-weight: 700;
  cursor: not-allowed;
}
</style>
