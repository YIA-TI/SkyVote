<template>
  <div class="detail-page">
    <div class="page-heading">
      <div>
        <RouterLink :to="backToReportLink" class="back-link">
          <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
            <path d="M12 4 6 10l6 6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          Kembali ke Laporan
        </RouterLink>
        <h1 class="page-title">Detail Survei</h1>
        <p class="page-subtitle">{{ departmentName }}</p>
      </div>
    </div>

    <div class="detail-card">
      <div class="card-header">
        <div>
          <h2 class="card-title">Status Pengisian Pegawai</h2>
          <p class="card-subtitle" v-if="selectedSurvey">
            {{ selectedSurvey.nama }}
            <span class="card-subtitle-range">&middot; Maks {{ selectedSurvey.maxPengisian }}x per pegawai</span>
          </p>
          <p class="card-subtitle" v-else>Belum ada survei dipilih.</p>
        </div>
      </div>

      <EmployeeSurveyStatusTable :employees="employeesInDept" :survey-id="selectedSurveyId" />
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from "vue";
import { useRoute } from "vue-router";
import EmployeeSurveyStatusTable from "./components/EmployeeSurveyStatusTable.vue";
import { useSurveyStore } from "./stores/surveyStore";

const store = useSurveyStore();
const route = useRoute();

onMounted(() => store.ensureBaseData());

const departmentName = computed(() => decodeURIComponent(route.params.department ?? ""));

const selectedSurveyId = ref(route.query.survey ? Number(route.query.survey) : null);

watch(
  () => route.query.survey,
  (value) => {
    if (value) selectedSurveyId.value = Number(value);
  }
);

const selectedSurvey = computed(() =>
  selectedSurveyId.value ? store.findSurvey(selectedSurveyId.value) : null
);

const backToReportLink = computed(() => ({
  path: "/admin/report",
  query: selectedSurveyId.value ? { survey: selectedSurveyId.value } : {},
}));

const employeesInDept = computed(() =>
  store.employees.filter((e) => e.isActive && e.unitKerja === departmentName.value)
);
</script>

<style scoped>
.detail-page {
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
  max-width: 720px;
  margin-top: 2px;
}

.detail-card {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 24px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.card-title {
  font-size: 15px;
  font-weight: 800;
  color: var(--color-text);
  letter-spacing: -0.01em;
}

.card-subtitle {
  font-size: 13px;
  color: var(--color-text-muted);
  line-height: 1.5;
  margin-top: 2px;
}

.card-subtitle-range {
  color: var(--color-text-muted);
}

</style>
