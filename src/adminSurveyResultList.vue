<template>
  <div class="dashboard-page">
    <div class="page-heading">
      <div>
        <h1 class="page-title">Hasil Survei</h1>
        <p class="page-subtitle">Lihat rekap jawaban dari pengisi survei internal.</p>
      </div>
    </div>

    <div class="board-card">
      <div class="table-scroll">
        <table class="survey-table">
          <thead>
            <tr>
              <th>Nama Survei</th>
              <th>Status</th>
              <th>Pertanyaan</th>
              <th>Responden</th>
              <th class="col-action">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="survey in internalSurveys" :key="survey.id">
              <td>
                <div class="cell-title">{{ survey.nama }}</div>
              </td>
              <td>
                <span class="status-flag">
                  <span class="status-dot" :class="statusClass(survey.status)" />
                  {{ survey.status }}
                </span>
              </td>
              <td>{{ questionCount(survey) }} pertanyaan</td>
              <td>{{ submissionCount(survey) }} responden</td>
              <td class="col-action">
                <RouterLink :to="`/admin/survey-hasil/${survey.id}`" class="btn-view">
                  Lihat Hasil
                </RouterLink>
              </td>
            </tr>
            <tr v-if="internalSurveys.length === 0">
              <td colspan="5" class="empty-row">
                Belum ada survei Internal. Buat survei baru dengan tipe "Internal" di Kelola Survei.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from "vue";
import { useSurveyStore } from "./stores/surveyStore";

const store = useSurveyStore();

onMounted(() => {
  store.ensureBaseData();
  store.fetchQuestionCounts();
});

const internalSurveys = computed(() => store.surveys.filter((s) => s.tipe === "Internal"));

function questionCount(survey) {
  return store.questionCounts[survey.id] ?? 0;
}

function submissionCount(survey) {
  return store.submissionsBySurvey(survey.id).length;
}

function statusClass(status) {
  if (status === "Aktif") return "status-aktif";
  if (status === "Selesai") return "status-selesai";
  if (status === "Draft") return "status-draft";
  return "status-terjadwal";
}
</script>

<style scoped>
.dashboard-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
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

.board-card {
  display: flex;
  flex-direction: column;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
}

.table-scroll {
  overflow-x: auto;
}

.survey-table {
  width: 100%;
  min-width: 720px;
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

.survey-table tbody td {
  padding: 16px 24px;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text);
  vertical-align: middle;
}

.survey-table tbody tr:last-child td {
  border-bottom: none;
}

.cell-title {
  font-weight: 600;
  color: var(--color-text);
}

.status-flag {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text-secondary);
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
  width: 140px;
}

.btn-view {
  display: inline-flex;
  align-items: center;
  height: 32px;
  padding: 0 14px;
  border-radius: var(--radius-md);
  background-color: var(--color-primary);
  color: #ffffff;
  font-size: 13px;
  font-weight: 600;
  text-decoration: none;
  white-space: nowrap;
  transition: background-color 0.15s ease;
}

.btn-view:hover {
  background-color: var(--color-primary-dark);
}

.empty-row {
  text-align: center;
  padding: 32px;
  color: var(--color-text-muted);
}
</style>
