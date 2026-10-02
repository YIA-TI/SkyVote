<template>
  <div class="report-page">
    <div class="page-heading">
      <div>
        <h1 class="page-title">Laporan Hasil Survei</h1>
        <p class="page-subtitle">
          Tinjauan komprehensif mengenai metrik survei pegawai, tingkat partisipasi, dan tren
          kepuasan di seluruh departemen InJourney Airports.
        </p>
      </div>
      <div class="export-actions">
        <button type="button" class="btn-export" :disabled="noSurveySelected" @click="exportToPdf">
          <svg width="15" height="15" viewBox="0 0 20 20" fill="none">
            <path d="M10 3v9m0 0 3.5-3.5M10 12l-3.5-3.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
            <path d="M4 14v2a1.5 1.5 0 0 0 1.5 1.5h9A1.5 1.5 0 0 0 16 16v-2" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
          Ekspor ke PDF
        </button>
        <button type="button" class="btn-export btn-export-excel" :disabled="noSurveySelected" @click="exportToExcel">
          <svg width="15" height="15" viewBox="0 0 20 20" fill="none">
            <path d="M10 3v9m0 0 3.5-3.5M10 12l-3.5-3.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
            <path d="M4 14v2a1.5 1.5 0 0 0 1.5 1.5h9A1.5 1.5 0 0 0 16 16v-2" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
          Ekspor ke Excel
        </button>
      </div>
    </div>

    <div class="report-main">
        <div class="report-card">
          <div class="card-header">
            <div>
              <h2 class="card-title">Rekapitulasi Partisipasi per Tanggal</h2>
              <p class="card-subtitle">
                Ringkasan agregat pengisian survei pegawai Organik dan TAD.
              </p>
            </div>
            <div class="card-header-actions">
              <div class="survey-filter">
                <svg class="survey-filter-icon" width="14" height="14" viewBox="0 0 20 20" fill="none">
                  <rect x="5" y="4" width="10" height="13" rx="1.5" stroke="currentColor" stroke-width="1.5" />
                  <path d="M8 3.5h4a1 1 0 0 1 1 1V5H7v-.5a1 1 0 0 1 1-1Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" />
                  <path d="M7.5 8.5h5M7.5 11h5M7.5 13.5h3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
                </svg>
                <select v-model="selectedSurveyFilterId" class="survey-filter-select">
                  <option v-if="!selectedSurveyFilterId" :value="null" disabled>Pilih Survei</option>
                  <option v-for="survey in store.surveys" :key="survey.id" :value="survey.id">
                    {{ survey.nama }}
                  </option>
                </select>
                <span v-if="selectedSurveyFilterRange" class="survey-filter-range">
                  {{ selectedSurveyFilterRange }}
                </span>
              </div>
            </div>
          </div>

          <div class="table-scroll">
            <table class="report-table">
              <thead>
                <tr class="group-row">
                  <th rowspan="2">No</th>
                  <th rowspan="2">Tanggal</th>
                  <th colspan="4">Pegawai Organik</th>
                  <th colspan="4">Pegawai TAD</th>
                  <th colspan="5">Total</th>
                </tr>
                <tr class="sub-row">
                  <th>Jumlah</th>
                  <th>Target</th>
                  <th>Voting</th>
                  <th>Gap</th>
                  <th>Jumlah</th>
                  <th>Target</th>
                  <th>Voting</th>
                  <th>Gap</th>
                  <th>Jumlah</th>
                  <th>Target</th>
                  <th>Voting</th>
                  <th>Gap</th>
                  <th>Persentase</th>
                </tr>
              </thead>
              <tbody>
                <template v-for="(row, index) in dateTable.pagedRows.value" :key="row.key">
                  <tr>
                    <td>{{ dateTable.pageStart.value + index + 1 }}</td>
                    <td>
                      <div class="cell-date">{{ formatDate(row.key) }}</div>
                    </td>
                    <td>{{ row.pegawaiOrganik }}</td>
                    <td>{{ row.targetOrganik }}</td>
                    <td class="cell-accent">{{ row.pengisianOrganik }}</td>
                    <td><span class="gap-value" :class="gapValueClass(row.gapOrganik)">{{ formatGap(row.gapOrganik) }}</span></td>
                    <td>{{ row.pegawaiNonOrganik }}</td>
                    <td>{{ row.targetNonOrganik }}</td>
                    <td class="cell-accent">{{ row.pengisianNonOrganik }}</td>
                    <td><span class="gap-value" :class="gapValueClass(row.gapNonOrganik)">{{ formatGap(row.gapNonOrganik) }}</span></td>
                    <td>{{ row.pegawaiTotal }}</td>
                    <td>{{ row.targetTotal }}</td>
                    <td class="cell-accent">{{ row.pengisianTotal }}</td>
                    <td><span class="gap-value" :class="gapValueClass(row.gapTotal)">{{ formatGap(row.gapTotal) }}</span></td>
                    <td><span class="percent-bold">{{ row.persenTotal }}%</span></td>
                  </tr>
                </template>
                <tr v-if="noSurveySelected">
                  <td colspan="15" class="empty-row empty-row-warning">
                    ⚠️ Pilih survei terlebih dahulu untuk melihat data partisipasi.
                  </td>
                </tr>
                <tr v-else-if="dateTable.rows.value.length === 0">
                  <td colspan="15" class="empty-row">Belum ada data partisipasi survei.</td>
                </tr>
                <tr v-if="dateTable.rows.value.length > 0" class="total-row">
                  <td colspan="2">Total Akumulasi</td>
                  <td>{{ dateTable.totals.value.pegawaiOrganik }}</td>
                  <td>{{ dateTable.totals.value.targetOrganik }}</td>
                  <td class="cell-accent">{{ dateTable.totals.value.pengisianOrganik }}</td>
                  <td><span class="gap-value" :class="gapValueClass(dateTable.totals.value.gapOrganik)">{{ formatGap(dateTable.totals.value.gapOrganik) }}</span></td>
                  <td>{{ dateTable.totals.value.pegawaiNonOrganik }}</td>
                  <td>{{ dateTable.totals.value.targetNonOrganik }}</td>
                  <td class="cell-accent">{{ dateTable.totals.value.pengisianNonOrganik }}</td>
                  <td><span class="gap-value" :class="gapValueClass(dateTable.totals.value.gapNonOrganik)">{{ formatGap(dateTable.totals.value.gapNonOrganik) }}</span></td>
                  <td>{{ dateTable.totals.value.pegawaiTotal }}</td>
                  <td>{{ dateTable.totals.value.targetTotal }}</td>
                  <td class="cell-accent">{{ dateTable.totals.value.pengisianTotal }}</td>
                  <td><span class="gap-value" :class="gapValueClass(dateTable.totals.value.gapTotal)">{{ formatGap(dateTable.totals.value.gapTotal) }}</span></td>
                  <td><span class="percent-bold">{{ dateTable.totals.value.persenTotal }}%</span></td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="pagination">
            <span class="pagination-label">
              Menampilkan
              {{ dateTable.rows.value.length === 0 ? 0 : dateTable.pageStart.value + 1 }}-{{
                dateTable.pageEnd.value
              }}
              dari {{ dateTable.rows.value.length }} data
            </span>
            <div class="pagination-actions">
              <button
                type="button"
                class="btn-secondary"
                :disabled="dateTable.page.value === 1"
                @click="dateTable.page.value--"
              >
                Sebelumnya
              </button>
              <button
                type="button"
                class="btn-primary"
                :disabled="dateTable.page.value === dateTable.totalPages.value"
                @click="dateTable.page.value++"
              >
                Selanjutnya
              </button>
            </div>
          </div>
        </div>

        <div class="report-card">
          <div class="card-header">
            <div>
              <h2 class="card-title">Rekapitulasi Partisipasi per Divisi</h2>
              <p class="card-subtitle">
                Sebaran pengisian survei berdasarkan unit kerja / divisi.
              </p>
            </div>
          </div>

          <div class="table-scroll">
            <table class="report-table dept-table">
              <colgroup>
                <col style="width: 32px" />
                <col style="width: 220px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
                <col style="width: 75px" />
              </colgroup>
              <thead>
                <tr class="group-row">
                  <th rowspan="2">No</th>
                  <th rowspan="2">Divisi</th>
                  <th colspan="4">Pegawai Organik</th>
                  <th colspan="4">Pegawai TAD</th>
                  <th colspan="5">Total</th>
                </tr>
                <tr class="sub-row">
                  <th>Jumlah</th>
                  <th>Target</th>
                  <th>Voting</th>
                  <th>Gap</th>
                  <th>Jumlah</th>
                  <th>Target</th>
                  <th>Voting</th>
                  <th>Gap</th>
                  <th>Jumlah</th>
                  <th>Target</th>
                  <th>Voting</th>
                  <th>Gap</th>
                  <th>Persentase</th>
                </tr>
              </thead>
              <tbody>
                <template v-for="(row, index) in deptTable.pagedRows.value" :key="row.key">
                  <tr>
                    <td>{{ deptTable.pageStart.value + index + 1 }}</td>
                    <td>
                      <button type="button" class="dept-name-toggle" @click="toggleDivisi(row.key)">
                        <svg
                          class="dept-chevron"
                          :class="{ 'dept-chevron-open': expandedDept === row.key }"
                          width="12"
                          height="12"
                          viewBox="0 0 20 20"
                          fill="none"
                        >
                          <path d="M6 4l8 6-8 6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
                        </svg>
                        {{ row.key }}
                      </button>
                    </td>
                    <td>{{ row.pegawaiOrganik }}</td>
                    <td>{{ row.targetOrganik }}</td>
                    <td class="cell-accent">{{ row.pengisianOrganik }}</td>
                    <td><span class="gap-value" :class="gapValueClass(row.gapOrganik)">{{ formatGap(row.gapOrganik) }}</span></td>
                    <td>{{ row.pegawaiNonOrganik }}</td>
                    <td>{{ row.targetNonOrganik }}</td>
                    <td class="cell-accent">{{ row.pengisianNonOrganik }}</td>
                    <td><span class="gap-value" :class="gapValueClass(row.gapNonOrganik)">{{ formatGap(row.gapNonOrganik) }}</span></td>
                    <td>{{ row.pegawaiTotal }}</td>
                    <td>{{ row.targetTotal }}</td>
                    <td class="cell-accent">{{ row.pengisianTotal }}</td>
                    <td><span class="gap-value" :class="gapValueClass(row.gapTotal)">{{ formatGap(row.gapTotal) }}</span></td>
                    <td><span class="percent-bold">{{ row.persenTotal }}%</span></td>
                  </tr>
                  <tr v-if="expandedDept === row.key" class="divisi-row">
                    <td colspan="15">
                      <div class="divisi-panel">
                        <span class="divisi-panel-label">Department Head di bawah {{ row.key }}</span>
                        <table class="divisi-table">
                          <colgroup>
                            <col style="width: 190px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 70px" />
                            <col style="width: 85px" />
                          </colgroup>
                          <thead>
                            <tr class="group-row">
                              <th rowspan="2">Departemen</th>
                              <th colspan="4">Pegawai Organik</th>
                              <th colspan="4">Pegawai TAD</th>
                              <th colspan="5">Total</th>
                            </tr>
                            <tr class="sub-row">
                              <th>Jumlah</th>
                              <th>Target</th>
                              <th>Voting</th>
                              <th>Gap</th>
                              <th>Jumlah</th>
                              <th>Target</th>
                              <th>Voting</th>
                              <th>Gap</th>
                              <th>Jumlah</th>
                              <th>Target</th>
                              <th>Voting</th>
                              <th>Gap</th>
                              <th>Persentase</th>
                            </tr>
                          </thead>
                          <tbody>
                            <tr v-for="child in childrenBreakdown(row.key)" :key="child.key">
                              <td class="divisi-cell-name">
                                <RouterLink
                                  class="dept-link"
                                  :to="departmentDetailLink(child.key)"
                                >
                                  {{ shortDeptName(child.key) }}
                                </RouterLink>
                              </td>
                              <td>{{ child.pegawaiOrganik }}</td>
                              <td>{{ child.targetOrganik }}</td>
                              <td class="cell-accent">{{ child.pengisianOrganik }}</td>
                              <td><span class="gap-value" :class="gapValueClass(child.gapOrganik)">{{ formatGap(child.gapOrganik) }}</span></td>
                              <td>{{ child.pegawaiNonOrganik }}</td>
                              <td>{{ child.targetNonOrganik }}</td>
                              <td class="cell-accent">{{ child.pengisianNonOrganik }}</td>
                              <td><span class="gap-value" :class="gapValueClass(child.gapNonOrganik)">{{ formatGap(child.gapNonOrganik) }}</span></td>
                              <td>{{ child.pegawaiTotal }}</td>
                              <td>{{ child.targetTotal }}</td>
                              <td class="cell-accent">{{ child.pengisianTotal }}</td>
                              <td><span class="gap-value" :class="gapValueClass(child.gapTotal)">{{ formatGap(child.gapTotal) }}</span></td>
                              <td><span class="percent-bold">{{ child.persenTotal }}%</span></td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                    </td>
                  </tr>
                </template>
                <tr v-if="noSurveySelected">
                  <td colspan="15" class="empty-row empty-row-warning">
                    ⚠️ Pilih survei terlebih dahulu untuk melihat data partisipasi.
                  </td>
                </tr>
                <tr v-else-if="deptTable.rows.value.length === 0">
                  <td colspan="15" class="empty-row">Belum ada data partisipasi survei.</td>
                </tr>
                <tr v-if="deptTable.rows.value.length > 0" class="total-row">
                  <td colspan="2">Total Akumulasi</td>
                  <td>{{ deptTable.totals.value.pegawaiOrganik }}</td>
                  <td>{{ deptTable.totals.value.targetOrganik }}</td>
                  <td class="cell-accent">{{ deptTable.totals.value.pengisianOrganik }}</td>
                  <td><span class="gap-value" :class="gapValueClass(deptTable.totals.value.gapOrganik)">{{ formatGap(deptTable.totals.value.gapOrganik) }}</span></td>
                  <td>{{ deptTable.totals.value.pegawaiNonOrganik }}</td>
                  <td>{{ deptTable.totals.value.targetNonOrganik }}</td>
                  <td class="cell-accent">{{ deptTable.totals.value.pengisianNonOrganik }}</td>
                  <td><span class="gap-value" :class="gapValueClass(deptTable.totals.value.gapNonOrganik)">{{ formatGap(deptTable.totals.value.gapNonOrganik) }}</span></td>
                  <td>{{ deptTable.totals.value.pegawaiTotal }}</td>
                  <td>{{ deptTable.totals.value.targetTotal }}</td>
                  <td class="cell-accent">{{ deptTable.totals.value.pengisianTotal }}</td>
                  <td><span class="gap-value" :class="gapValueClass(deptTable.totals.value.gapTotal)">{{ formatGap(deptTable.totals.value.gapTotal) }}</span></td>
                  <td><span class="percent-bold">{{ deptTable.totals.value.persenTotal }}%</span></td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="pagination">
            <span class="pagination-label">
              Menampilkan
              {{ deptTable.rows.value.length === 0 ? 0 : deptTable.pageStart.value + 1 }}-{{
                deptTable.pageEnd.value
              }}
              dari {{ deptTable.rows.value.length }} divisi
            </span>
            <div class="pagination-actions">
              <button
                type="button"
                class="btn-secondary"
                :disabled="deptTable.page.value === 1"
                @click="deptTable.page.value--"
              >
                Sebelumnya
              </button>
              <button
                type="button"
                class="btn-primary"
                :disabled="deptTable.page.value === deptTable.totalPages.value"
                @click="deptTable.page.value++"
              >
                Selanjutnya
              </button>
            </div>
          </div>
        </div>
    </div>
  </div>
</template>

<script setup>
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import * as XLSX from "xlsx";
import { computed, onMounted, ref, watch } from "vue";
import { useRoute } from "vue-router";
import { ORG_CHILDREN_BY_PARENT, ORG_PARENT_KEYS, shortDeptName } from "./orgStructure";
import { useSurveyStore } from "./stores/surveyStore";

const store = useSurveyStore();
const route = useRoute();

onMounted(() => store.ensureBaseData());

const expandedDept = ref(null);

function toggleDivisi(deptKey) {
  expandedDept.value = expandedDept.value === deptKey ? null : deptKey;
}


function departmentDetailLink(deptName) {
  return {
    name: "admin-department-detail",
    params: { department: deptName },
    query: selectedSurveyFilterId.value ? { survey: selectedSurveyFilterId.value } : {},
  };
}

// Jumlah/Target/Gap per departemen dihitung dari data pegawai ASLI
// (store.employees, hasil migrasi 005), sama seperti dateTable (lihat
// participationGroupedBy di surveyStore.js) — supaya total pegawai di
// tabel "per Tanggal" dan "per Departemen" selalu konsisten.
function buildDeptRow(key, deptNames) {
  const maxPengisian = selectedSurveyFilter.value?.maxPengisian ?? 1;
  const deptSet = new Set(deptNames);

  const employeesHere = store.employees.filter((e) => e.isActive && deptSet.has(e.unitKerja));
  const pegawaiOrganik = employeesHere.filter((e) => e.jenisPegawai === "Organik").length;
  const pegawaiNonOrganik = employeesHere.length - pegawaiOrganik;
  const pegawaiTotal = employeesHere.length;

  const targetOrganik = pegawaiOrganik * maxPengisian;
  const targetNonOrganik = pegawaiNonOrganik * maxPengisian;
  const targetTotal = targetOrganik + targetNonOrganik;

  const scoped = filteredSubmissions.value.filter((s) => deptSet.has(s.departemen));
  const pengisianOrganik = scoped.filter((s) => s.jenisPegawai === "Organik").length;
  const pengisianNonOrganik = scoped.length - pengisianOrganik;
  const pengisianTotal = scoped.length;

  return {
    key,
    pegawaiOrganik,
    pegawaiNonOrganik,
    pegawaiTotal,
    targetOrganik,
    targetNonOrganik,
    targetTotal,
    pengisianOrganik,
    pengisianNonOrganik,
    pengisianTotal,
    gapOrganik: targetOrganik - pengisianOrganik,
    gapNonOrganik: targetNonOrganik - pengisianNonOrganik,
    gapTotal: targetTotal - pengisianTotal,
    persenOrganik: targetOrganik > 0 ? Math.round((pengisianOrganik / targetOrganik) * 1000) / 10 : 0,
    persenNonOrganik:
      targetNonOrganik > 0 ? Math.round((pengisianNonOrganik / targetNonOrganik) * 1000) / 10 : 0,
    persenTotal: targetTotal > 0 ? Math.round((pengisianTotal / targetTotal) * 1000) / 10 : 0,
  };
}

function childrenBreakdown(parentKey) {
  const children = ORG_CHILDREN_BY_PARENT.get(parentKey) ?? [];
  return children.map((leaf) => buildDeptRow(leaf, [leaf]));
}

function useRowsTable(rowsRef, { pageSize = 10 } = {}) {
  const page = ref(1);
  const rows = computed(() => rowsRef.value);
  const totalPages = computed(() => Math.max(1, Math.ceil(rows.value.length / pageSize)));

  watch(rows, () => {
    if (page.value > totalPages.value) page.value = totalPages.value;
  });

  const pageStart = computed(() => (page.value - 1) * pageSize);
  const pageEnd = computed(() => Math.min(pageStart.value + pageSize, rows.value.length));
  const pagedRows = computed(() => rows.value.slice(pageStart.value, pageEnd.value));

  const totals = computed(() => {
    const list = rows.value;
    const sum = (field) => list.reduce((acc, r) => acc + r[field], 0);
    const pegawaiOrganik = sum("pegawaiOrganik");
    const pegawaiNonOrganik = sum("pegawaiNonOrganik");
    const pegawaiTotal = pegawaiOrganik + pegawaiNonOrganik;
    const targetOrganik = sum("targetOrganik");
    const targetNonOrganik = sum("targetNonOrganik");
    const targetTotal = targetOrganik + targetNonOrganik;
    const pengisianOrganik = sum("pengisianOrganik");
    const pengisianNonOrganik = sum("pengisianNonOrganik");
    const pengisianTotal = pengisianOrganik + pengisianNonOrganik;

    return {
      pegawaiOrganik,
      pegawaiNonOrganik,
      pegawaiTotal,
      targetOrganik,
      targetNonOrganik,
      targetTotal,
      pengisianOrganik,
      pengisianNonOrganik,
      pengisianTotal,
      gapOrganik: targetOrganik - pengisianOrganik,
      gapNonOrganik: targetNonOrganik - pengisianNonOrganik,
      gapTotal: targetTotal - pengisianTotal,
      persenOrganik: targetOrganik > 0 ? Math.round((pengisianOrganik / targetOrganik) * 1000) / 10 : 0,
      persenNonOrganik:
        targetNonOrganik > 0 ? Math.round((pengisianNonOrganik / targetNonOrganik) * 1000) / 10 : 0,
      persenTotal: targetTotal > 0 ? Math.round((pengisianTotal / targetTotal) * 1000) / 10 : 0,
    };
  });

  return { page, rows, totalPages, pageStart, pageEnd, pagedRows, totals };
}

const selectedSurveyFilterId = ref(route.query.survey ? Number(route.query.survey) : null);

const selectedSurveyFilter = computed(() =>
  selectedSurveyFilterId.value ? store.findSurvey(selectedSurveyFilterId.value) : null
);

const selectedSurveyFilterRange = computed(() => {
  const survey = selectedSurveyFilter.value;
  if (!survey || !survey.tanggalMulai || !survey.tanggalSelesai) return "";
  return `${formatDate(survey.tanggalMulai)} - ${formatDate(survey.tanggalSelesai)}`;
});

const noSurveySelected = computed(() => !selectedSurveyFilterId.value);

const filteredSubmissions = computed(() => {
  const survey = selectedSurveyFilter.value;
  if (!survey) return [];
  return store.submissions.filter((s) => s.surveyId === survey.id);
});

function useParticipationTable(getKey, { pageSize = 3, sort, allKeys } = {}) {
  const page = ref(1);

  const rows = computed(() => {
    const maxPengisian = selectedSurveyFilter.value?.maxPengisian ?? 1;
    const list = store.participationGroupedBy(
      getKey,
      filteredSubmissions.value,
      allKeys?.value ?? allKeys,
      maxPengisian
    );
    return sort ? [...list].sort(sort) : list;
  });

  const totalPages = computed(() => Math.max(1, Math.ceil(rows.value.length / pageSize)));

  watch(rows, () => {
    if (page.value > totalPages.value) page.value = totalPages.value;
  });

  const pageStart = computed(() => (page.value - 1) * pageSize);
  const pageEnd = computed(() => Math.min(pageStart.value + pageSize, rows.value.length));
  const pagedRows = computed(() => rows.value.slice(pageStart.value, pageEnd.value));

  const totals = computed(() => {
    const list = rows.value;
    const first = list[0];
    const pengisianOrganik = list.reduce((sum, r) => sum + r.pengisianOrganik, 0);
    const pengisianNonOrganik = list.reduce((sum, r) => sum + r.pengisianNonOrganik, 0);
    const pengisianTotal = pengisianOrganik + pengisianNonOrganik;
    const pegawaiOrganik = first?.pegawaiOrganik ?? 0;
    const pegawaiNonOrganik = first?.pegawaiNonOrganik ?? 0;
    const pegawaiTotal = first?.pegawaiTotal ?? 0;
    const targetOrganik = first?.targetOrganik ?? 0;
    const targetNonOrganik = first?.targetNonOrganik ?? 0;
    const targetTotal = first?.targetTotal ?? 0;

    return {
      pegawaiOrganik,
      pegawaiNonOrganik,
      pegawaiTotal,
      targetOrganik,
      targetNonOrganik,
      targetTotal,
      pengisianOrganik,
      pengisianNonOrganik,
      pengisianTotal,
      gapOrganik: targetOrganik - pengisianOrganik,
      gapNonOrganik: targetNonOrganik - pengisianNonOrganik,
      gapTotal: targetTotal - pengisianTotal,
      persenOrganik: targetOrganik > 0 ? Math.round((pengisianOrganik / targetOrganik) * 1000) / 10 : 0,
      persenNonOrganik:
        targetNonOrganik > 0 ? Math.round((pengisianNonOrganik / targetNonOrganik) * 1000) / 10 : 0,
      persenTotal: targetTotal > 0 ? Math.round((pengisianTotal / targetTotal) * 1000) / 10 : 0,
    };
  });

  return { page, rows, totalPages, pageStart, pageEnd, pagedRows, totals };
}

const dateTable = useParticipationTable((s) => s.tanggal, {
  pageSize: 6,
  sort: (a, b) => (a.key < b.key ? 1 : -1),
});
const deptRows = computed(() =>
  noSurveySelected.value
    ? []
    : ORG_PARENT_KEYS.map((key) => buildDeptRow(key, ORG_CHILDREN_BY_PARENT.get(key) ?? []))
);
const deptTable = useRowsTable(deptRows, { pageSize: 10 });

function gapValueClass(value) {
  if (value > 0) return "gap-done";
  return "gap-pending";
}

function formatGap(value) {
  return value > 0 ? `+${value}` : `${value}`;
}

function formatDate(isoDate) {
  const date = new Date(isoDate);
  return date.toLocaleDateString("id-ID", { day: "2-digit", month: "short", year: "numeric" });
}

const reportGroupHead = [
  [
    { content: "No", rowSpan: 2 },
    { content: "", rowSpan: 2 },
    { content: "Pegawai Organik", colSpan: 4, styles: { halign: "center" } },
    { content: "Pegawai TAD", colSpan: 4, styles: { halign: "center" } },
    { content: "Total", colSpan: 5, styles: { halign: "center" } },
  ],
  [
    "Jumlah", "Target", "Voting", "Gap",
    "Jumlah", "Target", "Voting", "Gap",
    "Jumlah", "Target", "Voting", "Gap", "Persentase",
  ],
];

function buildReportBody(rows, totals, keyFormatter) {
  const body = rows.map((row, index) => [
    index + 1,
    keyFormatter(row.key),
    row.pegawaiOrganik,
    row.targetOrganik,
    row.pengisianOrganik,
    formatGap(row.gapOrganik),
    row.pegawaiNonOrganik,
    row.targetNonOrganik,
    row.pengisianNonOrganik,
    formatGap(row.gapNonOrganik),
    row.pegawaiTotal,
    row.targetTotal,
    row.pengisianTotal,
    formatGap(row.gapTotal),
    { content: `${row.persenTotal}%`, styles: { fontStyle: "bold" } },
  ]);

  body.push([
    { content: "Total Akumulasi", colSpan: 2, styles: { fontStyle: "bold" } },
    totals.pegawaiOrganik,
    totals.targetOrganik,
    totals.pengisianOrganik,
    formatGap(totals.gapOrganik),
    totals.pegawaiNonOrganik,
    totals.targetNonOrganik,
    totals.pengisianNonOrganik,
    formatGap(totals.gapNonOrganik),
    totals.pegawaiTotal,
    totals.targetTotal,
    totals.pengisianTotal,
    formatGap(totals.gapTotal),
    { content: `${totals.persenTotal}%`, styles: { fontStyle: "bold" } },
  ]);

  return body;
}

const SECTION_BOUNDARY_COLUMNS = [1, 5, 9];

function drawSectionDividers(data) {
  if (!SECTION_BOUNDARY_COLUMNS.includes(data.column.index)) return;
  const x = data.cell.x + data.cell.width;
  if (data.section === "head") {
    data.doc.setDrawColor(255, 255, 255);
  } else {
    data.doc.setDrawColor(100, 116, 139);
  }
  data.doc.setLineWidth(0.3);
  data.doc.line(x, data.cell.y, x, data.cell.y + data.cell.height);
}

function exportToPdf() {
  if (noSurveySelected.value) return;
  const doc = new jsPDF({ orientation: "landscape" });
  const surveyLabel = selectedSurveyFilter.value.nama;

  doc.setFontSize(14);
  doc.text("Laporan Hasil Survei - SkyVote", 14, 15);
  doc.setFontSize(10);
  doc.text(`Survei: ${surveyLabel}`, 14, 21);
  doc.text(`Diekspor pada: ${new Date().toLocaleString("id-ID")}`, 14, 26);

  const dateHead = JSON.parse(JSON.stringify(reportGroupHead));
  dateHead[0][1].content = "Tanggal";

  doc.setFontSize(12);
  doc.text("Rekapitulasi Partisipasi per Tanggal", 14, 34);
  autoTable(doc, {
    head: dateHead,
    body: buildReportBody(dateTable.rows.value, dateTable.totals.value, formatDate),
    startY: 37,
    theme: "grid",
    tableLineColor: [15, 23, 42],
    tableLineWidth: 0.3,
    styles: { fontSize: 8, halign: "center", lineColor: [180, 190, 205], lineWidth: 0.15 },
    headStyles: {
      fillColor: [0, 93, 172],
      halign: "center",
      lineColor: [255, 255, 255],
      lineWidth: 0.15,
    },
    columnStyles: { 1: { halign: "left" } },
    didDrawCell: drawSectionDividers,
  });

  const deptHead = JSON.parse(JSON.stringify(reportGroupHead));
  deptHead[0][1].content = "Divisi";

  doc.addPage();
  doc.setFontSize(12);
  doc.text("Rekapitulasi Partisipasi per Divisi", 14, 15);
  autoTable(doc, {
    head: deptHead,
    body: buildReportBody(deptTable.rows.value, deptTable.totals.value, (key) => key),
    startY: 18,
    theme: "grid",
    tableLineColor: [15, 23, 42],
    tableLineWidth: 0.3,
    styles: { fontSize: 8, halign: "center", lineColor: [180, 190, 205], lineWidth: 0.15 },
    headStyles: {
      fillColor: [0, 93, 172],
      halign: "center",
      lineColor: [255, 255, 255],
      lineWidth: 0.15,
    },
    columnStyles: { 1: { halign: "left" } },
    didDrawCell: drawSectionDividers,
  });

  const slug = surveyLabel.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  const dateStamp = new Date().toISOString().slice(0, 10);
  doc.save(`laporan-survei-${slug}-${dateStamp}.pdf`);
}

function buildExcelSheet(labelHeader, rows, totals, keyFormatter) {
  const header1 = ["No", labelHeader, "Pegawai Organik", "", "", "", "Pegawai TAD", "", "", "", "Total", "", "", "", ""];
  const header2 = [
    "", "",
    "Jumlah", "Target", "Voting", "Gap",
    "Jumlah", "Target", "Voting", "Gap",
    "Jumlah", "Target", "Voting", "Gap", "Persentase",
  ];

  const body = rows.map((row, index) => [
    index + 1,
    keyFormatter(row.key),
    row.pegawaiOrganik,
    row.targetOrganik,
    row.pengisianOrganik,
    row.gapOrganik,
    row.pegawaiNonOrganik,
    row.targetNonOrganik,
    row.pengisianNonOrganik,
    row.gapNonOrganik,
    row.pegawaiTotal,
    row.targetTotal,
    row.pengisianTotal,
    row.gapTotal,
    row.persenTotal / 100,
  ]);

  body.push([
    "Total Akumulasi", "",
    totals.pegawaiOrganik,
    totals.targetOrganik,
    totals.pengisianOrganik,
    totals.gapOrganik,
    totals.pegawaiNonOrganik,
    totals.targetNonOrganik,
    totals.pengisianNonOrganik,
    totals.gapNonOrganik,
    totals.pegawaiTotal,
    totals.targetTotal,
    totals.pengisianTotal,
    totals.gapTotal,
    totals.persenTotal / 100,
  ]);

  const ws = XLSX.utils.aoa_to_sheet([header1, header2, ...body]);
  const totalRowIndex = body.length + 1;

  ws["!merges"] = [
    { s: { r: 0, c: 0 }, e: { r: 1, c: 0 } },
    { s: { r: 0, c: 1 }, e: { r: 1, c: 1 } },
    { s: { r: 0, c: 2 }, e: { r: 0, c: 5 } },
    { s: { r: 0, c: 6 }, e: { r: 0, c: 9 } },
    { s: { r: 0, c: 10 }, e: { r: 0, c: 14 } },
    { s: { r: totalRowIndex, c: 0 }, e: { r: totalRowIndex, c: 1 } },
  ];

  ws["!cols"] = [{ wch: 5 }, { wch: 24 }, ...Array(12).fill({ wch: 11 }), { wch: 12 }];

  const GAP_COLS = [5, 9, 13];
  for (let r = 2; r < 2 + body.length; r++) {
    for (const c of GAP_COLS) {
      const cell = ws[XLSX.utils.encode_cell({ r, c })];
      if (cell) cell.z = "+0;-0;0";
    }
    const percentCell = ws[XLSX.utils.encode_cell({ r, c: 14 })];
    if (percentCell) percentCell.z = "0.0%";
  }

  return ws;
}

function exportToExcel() {
  if (noSurveySelected.value) return;
  const surveyLabel = selectedSurveyFilter.value.nama;

  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(
    wb,
    buildExcelSheet("Tanggal", dateTable.rows.value, dateTable.totals.value, formatDate),
    "Per Tanggal"
  );
  XLSX.utils.book_append_sheet(
    wb,
    buildExcelSheet("Divisi", deptTable.rows.value, deptTable.totals.value, (key) => key),
    "Per Divisi"
  );

  const slug = surveyLabel.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  const dateStamp = new Date().toISOString().slice(0, 10);
  XLSX.writeFile(wb, `laporan-survei-${slug}-${dateStamp}.xlsx`);
}
</script>

<style scoped>
.report-page {
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

.export-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

.btn-export {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
  padding: 10px 18px;
  border: none;
  border-radius: var(--radius-md);
  background-color: var(--color-primary);
  color: #ffffff;
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(0, 93, 172, 0.3);
  transition: background-color 0.15s ease, box-shadow 0.15s ease;
}

.btn-export:hover {
  background-color: var(--color-primary-dark);
  box-shadow: 0 3px 10px rgba(0, 93, 172, 0.4);
}

.btn-export-excel {
  background-color: var(--color-success);
  box-shadow: 0 2px 6px rgba(18, 183, 106, 0.3);
}

.btn-export-excel:hover {
  background-color: #0e9c5a;
  box-shadow: 0 3px 10px rgba(18, 183, 106, 0.4);
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

.report-main {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Report card */
.report-card {
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

.card-header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
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
  min-width: 200px;
  max-width: 280px;
  height: 100%;
  font-family: var(--font-sans);
  font-size: 13px;
  color: var(--color-text-secondary);
  background: transparent;
  cursor: pointer;
}

.survey-filter-range {
  font-size: 12px;
  color: var(--color-text-muted);
  white-space: nowrap;
  padding-left: 8px;
  border-left: 1px solid var(--color-border);
}

.table-scroll {
  overflow-x: auto;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.report-table {
  width: 100%;
  min-width: 1100px;
  table-layout: fixed;
  border-collapse: collapse;
  font-size: 12px;
}

.dept-table {
  width: auto;
  min-width: 1227px;
  table-layout: fixed;
}

.report-table.dept-table tbody td:nth-child(2) {
  white-space: normal;
}

.report-table.dept-table tr.group-row th {
  white-space: normal;
}

.report-table thead th {
  text-align: center;
  padding: 12px 6px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.02em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  background-color: var(--color-bg);
  border-bottom: 1px solid var(--color-border);
  border-right: 1px solid var(--color-border);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.report-table thead .group-row th:first-child,
.report-table thead .group-row th:nth-child(2) {
  text-align: left;
}

.report-table.dept-table thead .group-row th:nth-child(2) {
  text-align: center;
}

.report-table tbody td {
  text-align: center;
  padding: 12px 5px;
  border-bottom: 1px solid var(--color-border);
  border-right: 1px solid var(--color-border);
  color: var(--color-text);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.report-table tbody tr:not(.total-row) td:first-child,
.report-table tbody tr:not(.total-row) td:nth-child(2) {
  text-align: left;
}

.report-table tbody tr.total-row td:first-child {
  text-align: left;
}

.report-table tr:not(.sub-row) th:first-child,
.report-table td:first-child {
  width: 32px;
}

.report-table tr:not(.sub-row) th:nth-child(2),
.report-table td:nth-child(2) {
  width: 100px;
}

.report-table tbody tr:last-child td {
  border-bottom: none;
}

.report-table th:first-child,
.report-table td:first-child {
  border-left: 1px solid var(--color-border);
}

.report-table tbody tr:not(.total-row):not(.expand-row):hover td {
  background-color: rgba(248, 250, 252, 0.8);
}

.report-table tbody tr {
  transition: background-color 0.15s ease;
}

.cell-accent {
  color: var(--color-primary);
  font-weight: 600;
}

.cell-date {
  color: var(--color-text);
}

.total-row td {
  font-weight: 700;
  color: var(--color-primary);
  background-color: #eff6ff;
}

.dept-name-toggle {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border: none;
  background: transparent;
  padding: 0;
  color: var(--color-text);
  font-family: var(--font-sans);
  font-size: inherit;
  font-weight: inherit;
  cursor: pointer;
  text-align: left;
}

.dept-name-toggle:hover {
  color: var(--color-primary);
}

.dept-chevron {
  flex-shrink: 0;
  color: var(--color-text-muted);
  transition: transform 0.15s ease;
}

.dept-chevron-open {
  transform: rotate(90deg);
  color: var(--color-primary);
}

.divisi-row td {
  background-color: var(--color-bg);
  padding: 0;
  white-space: normal;
  overflow: visible;
  text-overflow: initial;
}

.divisi-panel {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 16px 20px;
  text-align: left;
  white-space: normal;
}

.divisi-panel-label {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--color-text-muted);
}

.divisi-table {
  width: auto;
  table-layout: fixed;
  border-collapse: collapse;
  font-size: 12px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.divisi-table thead tr:first-child th {
  border-top: 2px solid var(--color-border-strong);
}

.divisi-table tbody tr:last-child td {
  border-bottom: 2px solid var(--color-border-strong);
}

.divisi-table thead th {
  text-align: center !important;
  padding: 7px 8px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.03em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  background-color: var(--color-bg);
  border-bottom: 1px solid var(--color-border);
  border-right: 1px solid var(--color-border);
  white-space: normal !important;
  overflow: visible !important;
  text-overflow: initial !important;
  line-height: 1.3;
}

.divisi-table tbody td {
  text-align: center !important;
  padding: 7px 8px;
  border-bottom: 1px solid var(--color-border);
  border-right: 1px solid var(--color-border);
  color: var(--color-text);
  white-space: normal !important;
  overflow: visible !important;
  text-overflow: initial !important;
  line-height: 1.3;
}

.divisi-table th:first-child,
.divisi-table td:first-child {
  border-left: 1px solid var(--color-border);
}

.divisi-cell-name {
  text-align: center !important;
  color: var(--color-text-secondary);
  font-weight: 500;
}

.dept-link {
  color: var(--color-primary);
  font-size: 12px;
  font-weight: 600;
  text-decoration: none;
}

.dept-link:hover {
  text-decoration: underline;
}

.gap-value {
  font-weight: 700;
}

.gap-done {
  color: var(--color-success);
}

.gap-pending {
  color: var(--color-danger);
}

.percent-bold {
  font-weight: 700;
  color: var(--color-primary);
}

.empty-row {
  text-align: center !important;
  padding: 32px;
  color: var(--color-text-muted);
}

.empty-row-warning {
  color: var(--color-warning);
  background: var(--color-warning-bg);
  font-weight: 600;
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
  padding: 8px 16px;
  border-radius: var(--radius-md);
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-secondary {
  border: 1px solid var(--color-border);
  background-color: var(--color-surface);
  color: var(--color-text-secondary);
}

.btn-secondary:hover:not(:disabled) {
  background-color: var(--color-bg);
}

.btn-primary {
  border: none;
  background-color: var(--color-primary);
  color: #ffffff;
}

.btn-primary:hover:not(:disabled) {
  background-color: var(--color-primary-dark);
}

.btn-secondary:disabled,
.btn-primary:disabled,
.btn-export:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

@media (max-width: 640px) {
  .page-heading {
    flex-wrap: wrap;
  }

  .export-actions {
    width: 100%;
    flex-direction: column;
  }

  .btn-export {
    width: 100%;
    justify-content: center;
  }

  .report-card {
    padding: 16px;
  }

  .survey-filter-select {
    min-width: 0;
  }
}
</style>
