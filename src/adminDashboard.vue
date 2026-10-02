<template>
  <div class="dashboard-page">
    <div class="page-heading">
      <div>
        <h1 class="page-title">Dashboard</h1>
        <p class="page-subtitle">Ringkasan partisipasi survei per divisi.</p>
      </div>
    </div>

    <div class="chart-card">
      <div class="chart-card-header">
        <h2 class="chart-title">Total Partisipasi per Divisi</h2>
        <div class="survey-filter">
          <svg class="survey-filter-icon" width="14" height="14" viewBox="0 0 20 20" fill="none">
            <rect x="5" y="4" width="10" height="13" rx="1.5" stroke="currentColor" stroke-width="1.5" />
            <path d="M8 3.5h4a1 1 0 0 1 1 1V5H7v-.5a1 1 0 0 1 1-1Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" />
            <path d="M7.5 8.5h5M7.5 11h5M7.5 13.5h3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
          </svg>
          <select v-model="selectedSurveyId" class="survey-filter-select">
            <option v-if="!selectedSurveyId" :value="null" disabled>Pilih Survei</option>
            <option v-for="survey in store.surveys" :key="survey.id" :value="survey.id">
              {{ survey.nama }}
            </option>
          </select>
        </div>
      </div>

      <p v-if="noSurveySelected" class="survey-required-warning">
        ⚠️ Pilih survei terlebih dahulu untuk melihat data partisipasi.
      </p>

      <template v-else>
        <div class="stat-box">
          <div class="stat-item">
            <span class="stat-label">Total Target</span>
            <span class="stat-value">{{ grandTotals.target.toLocaleString("id-ID") }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">Total Voting</span>
            <span class="stat-value">{{ grandTotals.voting.toLocaleString("id-ID") }}</span>
          </div>
        </div>

        <div class="legend">
          <span class="legend-item">
            <span class="legend-swatch legend-swatch-target" />
            Target
          </span>
          <span class="legend-item">
            <span class="legend-swatch legend-swatch-voting" />
            Voting
          </span>
        </div>

        <div class="chart-area">
          <div class="chart-scroll">
            <div class="chart-gridlines">
              <div v-for="line in gridlines" :key="line" class="gridline" :style="{ bottom: line + '%' }" />
            </div>
            <div class="chart-bars">
              <div v-for="row in divisionRows" :key="row.key" class="bar-group">
                <div class="bar-pair">
                  <div
                    class="bar bar-target"
                    :style="{ height: barHeight(row.target) + '%' }"
                    :title="`Target ${row.shortLabel}: ${row.target.toLocaleString('id-ID')}`"
                  >
                    <span class="bar-value">{{ row.target.toLocaleString("id-ID") }}</span>
                  </div>
                  <div
                    class="bar bar-voting"
                    :style="{ height: barHeight(row.voting) + '%' }"
                    :title="`Voting ${row.shortLabel}: ${row.voting.toLocaleString('id-ID')}`"
                  >
                    <span class="bar-value">{{ row.voting.toLocaleString("id-ID") }}</span>
                  </div>
                </div>
                <span class="bar-label">{{ row.shortLabel }}</span>
              </div>
            </div>
          </div>
        </div>
      </template>
    </div>

    <div class="chart-card">
      <div class="chart-card-header">
        <h2 class="chart-title">Total Partisipasi per Departemen</h2>
      </div>

      <p v-if="noSurveySelected" class="survey-required-warning">
        ⚠️ Pilih survei terlebih dahulu untuk melihat data partisipasi.
      </p>

      <template v-else>
        <div class="legend">
          <span class="legend-item">
            <span class="legend-swatch legend-swatch-target" />
            Target
          </span>
          <span class="legend-item">
            <span class="legend-swatch legend-swatch-voting" />
            Voting
          </span>
        </div>

        <div class="dept-list">
          <div v-for="row in departmentRows" :key="row.key" class="dept-row">
            <span class="dept-row-label" :title="row.shortLabel">{{ row.shortLabel }}</span>
            <div class="dept-row-bars">
              <div class="dept-bar-row">
                <div class="dept-bar-track">
                  <div
                    class="dept-bar dept-bar-target"
                    :style="{ width: deptBarWidth(row.target) + '%' }"
                    :title="`Target: ${row.target.toLocaleString('id-ID')}`"
                  />
                </div>
                <span class="dept-bar-value">{{ row.target.toLocaleString("id-ID") }}</span>
              </div>
              <div class="dept-bar-row">
                <div class="dept-bar-track">
                  <div
                    class="dept-bar dept-bar-voting"
                    :style="{ width: deptBarWidth(row.voting) + '%' }"
                    :title="`Voting: ${row.voting.toLocaleString('id-ID')}`"
                  />
                </div>
                <span class="dept-bar-value">{{ row.voting.toLocaleString("id-ID") }}</span>
              </div>
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { ORG_CHILDREN_BY_PARENT, ORG_PARENT_KEYS, shortDeptName } from "./orgStructure";
import { useSurveyStore } from "./stores/surveyStore";

const store = useSurveyStore();

const chartMounted = ref(false);

onMounted(async () => {
  await store.ensureBaseData();
  // Start bars at 0% and grow them into place on the very first paint,
  // so navigating into the dashboard always plays the "bars rising" entrance.
  requestAnimationFrame(() => {
    chartMounted.value = true;
  });
});

const selectedSurveyId = ref(null);

const noSurveySelected = computed(() => !selectedSurveyId.value);

const selectedSurvey = computed(() =>
  selectedSurveyId.value ? store.findSurvey(selectedSurveyId.value) : null
);

const maxPengisian = computed(() => selectedSurvey.value?.maxPengisian ?? 1);

const filteredSubmissions = computed(() => {
  const survey = selectedSurvey.value;
  if (!survey) return [];
  return store.submissions.filter((s) => s.surveyId === survey.id);
});

const shortLabels = {
  "General Manager": "GM",
  "Airport Quality & Safety Management System": "Quality & Safety",
  "Airport Operation, Services & Security": "Ops & Security",
  "Airport Technical": "Technical",
  "Airport Commercial": "Commercial",
};

const divisionRows = computed(() =>
  ORG_PARENT_KEYS.map((key) => {
    const deptSet = new Set(ORG_CHILDREN_BY_PARENT.get(key) ?? []);
    const employeeCount = store.employees.filter((e) => e.isActive && deptSet.has(e.unitKerja)).length;
    const target = employeeCount * maxPengisian.value;
    const voting = filteredSubmissions.value.filter((s) => deptSet.has(s.departemen)).length;
    return { key, shortLabel: shortLabels[key] ?? key, target, voting };
  })
);

const grandTotals = computed(() =>
  divisionRows.value.reduce(
    (acc, row) => ({ target: acc.target + row.target, voting: acc.voting + row.voting }),
    { target: 0, voting: 0 }
  )
);

const chartMax = computed(() => {
  const max = Math.max(1, ...divisionRows.value.flatMap((row) => [row.target, row.voting]));
  return max;
});

function barHeight(value) {
  if (!chartMounted.value || chartMax.value === 0) return 0;
  return Math.max(2, Math.round((value / chartMax.value) * 100));
}

const gridlines = [0, 25, 50, 75, 100];

const departmentRows = computed(() =>
  ORG_PARENT_KEYS.flatMap((parentKey) => ORG_CHILDREN_BY_PARENT.get(parentKey) ?? []).map((dept) => {
    const employeeCount = store.employees.filter((e) => e.isActive && e.unitKerja === dept).length;
    const target = employeeCount * maxPengisian.value;
    const voting = filteredSubmissions.value.filter((s) => s.departemen === dept).length;
    return { key: dept, shortLabel: shortDeptName(dept), target, voting };
  })
);

const deptChartMax = computed(() => {
  return Math.max(1, ...departmentRows.value.flatMap((row) => [row.target, row.voting]));
});

function deptBarWidth(value) {
  if (!chartMounted.value || deptChartMax.value === 0) return 0;
  return Math.max(1.5, Math.round((value / deptChartMax.value) * 1000) / 10);
}
</script>

<style scoped>
.dashboard-page {
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
  max-width: 720px;
}

.chart-card {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 24px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  animation: page-fade-up 0.4s cubic-bezier(0.16, 1, 0.3, 1) both;
  animation-delay: 0.08s;
}

@media (prefers-reduced-motion: reduce) {
  .chart-card {
    animation: none;
  }
}

.chart-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.chart-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--color-text);
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

.survey-required-warning {
  padding: 32px;
  text-align: center;
  font-weight: 600;
  color: var(--color-warning);
  background: var(--color-warning-bg);
  border-radius: var(--radius-md);
}

.stat-box {
  display: flex;
  gap: 32px;
  padding: 18px 20px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  width: fit-content;
}

.stat-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.stat-label {
  font-size: 13px;
  color: var(--color-text-muted);
}

.stat-value {
  font-size: 26px;
  font-weight: 700;
  color: var(--color-text);
  letter-spacing: -0.01em;
}

.legend {
  display: flex;
  gap: 20px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--color-text-secondary);
  font-weight: 500;
}

.legend-swatch {
  width: 12px;
  height: 12px;
  border-radius: 3px;
  flex-shrink: 0;
}

.legend-swatch-target {
  background-color: var(--color-border-strong);
}

.legend-swatch-voting {
  background-color: var(--color-primary);
}

.chart-area {
  position: relative;
  height: 280px;
  padding-top: 8px;
}

.chart-scroll {
  height: 100%;
}

.chart-gridlines {
  position: absolute;
  inset: 8px 0 32px 0;
}

.gridline {
  position: absolute;
  left: 0;
  right: 0;
  border-top: 1px dashed var(--color-border);
}

.chart-bars {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: flex-end;
  justify-content: space-around;
  gap: 12px;
  height: 100%;
  padding-bottom: 32px;
}

.bar-group {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  flex: 1;
  height: 100%;
}

.bar-pair {
  display: flex;
  align-items: flex-end;
  gap: 8px;
  flex: 1;
  width: 100%;
  justify-content: center;
}

.bar {
  width: 32px;
  min-height: 2px;
  border-radius: 6px 6px 2px 2px;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  transition: height 0.5s cubic-bezier(0.34, 1.2, 0.64, 1), opacity 0.15s ease;
  cursor: default;
}

@media (prefers-reduced-motion: reduce) {
  .bar {
    transition: opacity 0.15s ease;
  }
}

.bar:hover {
  opacity: 0.85;
}

.bar-target {
  background-color: var(--color-border-strong);
}

.bar-voting {
  background-color: var(--color-primary);
}

.bar-value {
  font-size: 11px;
  font-weight: 700;
  color: var(--color-text-secondary);
  transform: translateY(-18px);
  white-space: nowrap;
}

.bar-voting .bar-value {
  color: var(--color-primary-dark);
}

.bar-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--color-text-secondary);
  text-align: center;
  white-space: nowrap;
}

.dept-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.dept-row {
  display: flex;
  align-items: center;
  gap: 14px;
}

.dept-row-label {
  width: 190px;
  flex-shrink: 0;
  font-size: 12.5px;
  font-weight: 600;
  color: var(--color-text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.dept-row-bars {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.dept-bar-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.dept-bar-track {
  flex: 1;
  display: flex;
  align-items: center;
  height: 16px;
  background-color: var(--color-bg);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.dept-bar {
  height: 100%;
  border-radius: var(--radius-sm);
  transition: width 0.5s cubic-bezier(0.34, 1.2, 0.64, 1);
}

.dept-bar-target {
  background-color: var(--color-border-strong);
}

.dept-bar-voting {
  background-color: var(--color-primary);
}

.dept-bar-value {
  width: 44px;
  flex-shrink: 0;
  text-align: right;
  font-size: 11px;
  font-weight: 700;
  color: var(--color-text-secondary);
  white-space: nowrap;
}

@media (prefers-reduced-motion: reduce) {
  .dept-bar {
    transition: none;
  }
}

@media (max-width: 720px) {
  .dept-row-label {
    width: 110px;
    font-size: 11px;
  }

  .bar {
    width: 20px;
  }

  .chart-card {
    padding: 16px;
  }

  .chart-area {
    height: 220px;
  }

  .chart-scroll {
    overflow-x: auto;
    overflow-y: hidden;
  }

  .chart-bars {
    min-width: 480px;
  }

  .stat-box {
    width: 100%;
    gap: 20px;
  }
}
</style>
