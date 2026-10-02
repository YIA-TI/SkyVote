<template>
  <div class="public-success">
    <AppHeader />

    <main class="main-content">
      <div class="card">
        <div class="card-accent" aria-hidden="true" />
        <div class="icon-badge-wrap">
          <span class="icon-ring" />
          <div class="icon-badge">
            <svg width="30" height="30" viewBox="0 0 24 24" fill="none">
              <path
                class="check-path"
                d="M20 6L9 17l-5-5"
                stroke="#005dac"
                stroke-width="2.5"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </div>
        </div>

        <div class="card-heading anim-in anim-delay-1">
          <h1 class="card-title">Berhasil Mengunggah Survei Internal</h1>
          <p class="card-subtitle">
            Terima kasih, survei Anda telah berhasil disimpan dalam sistem.
          </p>
        </div>

        <div v-if="submission" class="summary anim-in anim-delay-2">
          <div class="summary-row">
            <span class="summary-label">Survei</span>
            <span class="summary-value">{{ surveyName }}</span>
          </div>
          <div class="summary-row">
            <span class="summary-label">Tanggal</span>
            <span class="summary-value">{{ submission.tanggal }}</span>
          </div>
          <div v-if="submissionTime" class="summary-row">
            <span class="summary-label">Jam</span>
            <span class="summary-value">{{ submissionTime }}</span>
          </div>
          <div class="summary-row">
            <span class="summary-label">Nama</span>
            <span class="summary-value">{{ submission.nama }}</span>
          </div>
        </div>

        <RouterLink to="/" class="button anim-in anim-delay-3">
          <svg class="button-arrow" width="15" height="15" viewBox="0 0 20 20" fill="none">
            <path d="M16 10H4M9 5l-5 5 5 5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          Kembali
        </RouterLink>
      </div>
    </main>
  </div>
</template>

<script setup>
import { computed } from "vue";
import { useRouter } from "vue-router";
import AppHeader from "./components/AppHeader.vue";
import { useSurveyStore } from "./stores/surveyStore";

const store = useSurveyStore();
const router = useRouter();
const submission = computed(() => store.lastSubmission);

// Opened directly without ever submitting a survey -> nothing to confirm.
if (!store.lastSubmission) {
  router.replace("/");
}
const surveyName = computed(() =>
  submission.value
    ? submission.value.surveyNama || store.findSurvey(submission.value.surveyId)?.nama || "-"
    : "-"
);
const submissionTime = computed(() => {
  if (!submission.value?.createdAt) return "";
  const date = new Date(submission.value.createdAt);
  const pad = (n) => String(n).padStart(2, "0");
  return `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
});
</script>

<style scoped>
.public-success {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: linear-gradient(
    328deg,
    rgba(0, 93, 172, 1) 0%,
    rgba(92, 233, 254, 1) 33%,
    rgba(25, 118, 210, 1) 67%,
    rgba(69, 216, 237, 1) 100%
  );
}

.main-content {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 32px 24px;
}

.card {
  position: relative;
  width: 100%;
  max-width: 480px;
  overflow: hidden;
  padding: 32px 28px 28px;
  border-radius: 22px;
  background-color: var(--glass-bg-strong);
  backdrop-filter: blur(var(--glass-blur));
  -webkit-backdrop-filter: blur(var(--glass-blur));
  border: 1px solid var(--glass-border);
  box-shadow: 0 24px 60px -12px rgba(15, 23, 42, 0.22), var(--glass-shadow);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 24px;
  animation: card-pop 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) both;
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

.icon-badge-wrap {
  position: relative;
  width: 64px;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-ring {
  position: absolute;
  inset: 0;
  border-radius: var(--radius-full);
  background-color: var(--color-accent-cyan-strong);
  opacity: 0.6;
  animation: ring-ping 0.9s cubic-bezier(0.16, 1, 0.3, 1) 0.15s both;
}

.icon-badge {
  position: relative;
  width: 64px;
  height: 64px;
  border-radius: var(--radius-full);
  background-color: var(--color-accent-cyan-strong);
  display: flex;
  align-items: center;
  justify-content: center;
  animation: badge-pop 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) 0.05s both;
}

.check-path {
  stroke-dasharray: 24;
  stroke-dashoffset: 24;
  animation: draw-check 0.35s ease-out 0.35s forwards;
}

@keyframes card-pop {
  from {
    opacity: 0;
    transform: scale(0.94) translateY(10px);
  }
  to {
    opacity: 1;
  }
}

@keyframes badge-pop {
  from {
    opacity: 0;
    transform: scale(0.3);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes ring-ping {
  from {
    opacity: 0.5;
    transform: scale(0.6);
  }
  to {
    opacity: 0;
    transform: scale(1.6);
  }
}

@keyframes draw-check {
  to {
    stroke-dashoffset: 0;
  }
}

.anim-in {
  opacity: 0;
  animation: field-fade-up 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

.anim-delay-1 {
  animation-delay: 0.5s;
}

.anim-delay-2 {
  animation-delay: 0.58s;
}

.anim-delay-3 {
  animation-delay: 0.66s;
}

@keyframes field-fade-up {
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
  .icon-ring,
  .icon-badge,
  .check-path,
  .anim-in {
    animation: none !important;
    opacity: 1;
    stroke-dashoffset: 0;
  }
}

.card-heading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  text-align: center;
}

.card-title {
  color: var(--color-text);
  font-size: 20px;
  font-weight: 700;
  letter-spacing: -0.02em;
}

.card-subtitle {
  color: var(--color-text-secondary);
  font-size: 14px;
  line-height: 1.5;
}

.summary {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 24px;
  border-radius: var(--radius-md);
  background-color: rgba(242, 244, 246, 0.6);
  border: 1px solid #ffffff66;
  backdrop-filter: blur(2px);
}

.summary-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.summary-label {
  color: var(--color-text-secondary);
  font-size: 12px;
  font-weight: 500;
}

.summary-value {
  color: var(--color-text);
  font-size: 14px;
  font-weight: 600;
}

.button {
  width: 100%;
  height: 46px;
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
  text-align: center;
  text-decoration: none;
  box-shadow: 0 4px 14px rgba(0, 93, 172, 0.28);
  transition: box-shadow 0.2s ease, transform 0.15s ease, filter 0.15s ease;
}

.button-arrow {
  transition: transform 0.2s ease;
}

.button:hover {
  filter: brightness(1.06);
  box-shadow: 0 8px 20px rgba(0, 93, 172, 0.38);
  transform: translateY(-1px);
}

.button:hover .button-arrow {
  transform: translateX(-3px);
}

.button:active {
  transform: scale(0.97);
}
</style>
