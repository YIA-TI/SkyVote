<template>
  <div class="report-page">
    <div class="page-heading">
      <div>
        <h1 class="page-title">Laporan Hasil Survei</h1>
        <p class="page-subtitle">
          Rekap tingkat partisipasi pengisian survei seluruh pegawai Bandara Internasional
          Yogyakarta, per tanggal dan per divisi.
        </p>
      </div>
      <div class="export-actions">
        <div class="refresh-group">
          <button
            type="button"
            class="btn-refresh"
            :class="{ 'btn-refresh-loading': refreshing }"
            :disabled="refreshing"
            @click="refreshData"
          >
            <svg class="refresh-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
              <path
                d="M16.5 10a6.5 6.5 0 1 1-1.9-4.6M16.5 3.5v3.2h-3.2"
                stroke="currentColor"
                stroke-width="1.6"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
            {{ refreshing ? "Memuat..." : "Muat Ulang" }}
          </button>
          <span v-if="lastUpdated" class="refresh-time">Diperbarui {{ lastUpdated }}</span>
        </div>
        <button type="button" class="btn-export" :disabled="noFilterSelected" @click="exportToPdf">
          <svg width="15" height="15" viewBox="0 0 20 20" fill="none">
            <path d="M10 3v9m0 0 3.5-3.5M10 12l-3.5-3.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
            <path d="M4 14v2a1.5 1.5 0 0 0 1.5 1.5h9A1.5 1.5 0 0 0 16 16v-2" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
          Ekspor ke PDF
        </button>
        <button type="button" class="btn-export btn-export-excel" :disabled="noFilterSelected" @click="exportToExcel">
          <svg width="15" height="15" viewBox="0 0 20 20" fill="none">
            <path d="M10 3v9m0 0 3.5-3.5M10 12l-3.5-3.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
            <path d="M4 14v2a1.5 1.5 0 0 0 1.5 1.5h9A1.5 1.5 0 0 0 16 16v-2" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
          Ekspor ke Excel
        </button>
      </div>
    </div>

    <div class="report-main">
        <!-- The day-by-day view only makes sense for external surveys (a
             per-day limit); an internal survey is filled once per period. -->
        <div v-if="!isInternal" class="report-card">
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
                  <option v-for="survey in surveyOptions" :key="survey.id" :value="survey.id">
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
              <p v-if="isInternal" class="card-subtitle">
                Survei internal hanya bisa diisi 1 kali per pegawai selama periode survei, jadi angka di
                bawah adalah total seluruh periode (target = jumlah pegawai &times; 1).
              </p>
              <p v-else class="card-subtitle">
                Sebaran pengisian survei berdasarkan unit kerja / divisi pada satu tanggal. Target
                dihitung per hari (jumlah pegawai &times; max pengisian per hari).
              </p>
            </div>
            <div v-if="!isInternal" class="card-header-actions">
              <div class="survey-filter">
                <svg class="survey-filter-icon" width="14" height="14" viewBox="0 0 20 20" fill="none">
                  <rect x="3" y="4" width="14" height="13" rx="1.5" stroke="currentColor" stroke-width="1.5" />
                  <path d="M3 8h14M6.5 2.5v3M13.5 2.5v3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
                </svg>
                <input
                  v-model="selectedTanggal"
                  type="date"
                  class="survey-filter-select survey-filter-date"
                  :min="selectedSurveyFilter?.tanggalMulai || undefined"
                  :max="selectedSurveyFilter?.tanggalSelesai || undefined"
                  :disabled="noSurveySelected"
                  aria-label="Pilih tanggal"
                />
              </div>
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
                                  v-if="!publicMode"
                                  class="dept-link"
                                  :to="departmentDetailLink(child.key)"
                                >
                                  {{ shortDeptName(child.key) }}
                                </RouterLink>
                                <!-- Public view: no drill-down to which employees haven't filled. -->
                                <span v-else>{{ shortDeptName(child.key) }}</span>
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
                <tr v-if="noFilterSelected">
                  <td colspan="15" class="empty-row empty-row-warning">
                    ⚠️ Pilih survei dan tanggal terlebih dahulu untuk melihat data partisipasi.
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

        <!-- Admin only: lists employee names, which the public /report page
             never shows (it only gets aggregate numbers). -->
        <div v-if="!publicMode" class="report-card">
          <div class="card-header">
            <div>
              <h2 class="card-title">{{ RANK_SIZE }} Pegawai dengan Vote Tersedikit</h2>
              <p v-if="isInternal" class="card-subtitle">
                Survei internal hanya bisa diisi 1 kali per pegawai, jadi pegawai yang belum mengisi (0 vote)
                tampil lebih dulu, diurutkan menurut nama.
              </p>
              <p v-else class="card-subtitle">
                Total vote setiap pegawai aktif selama periode survei sampai hari ini, dari yang paling
                sedikit. Pegawai yang belum pernah mengisi (0 vote) ikut dihitung.
              </p>
            </div>
          </div>

          <p v-if="noSurveySelected" class="rank-empty rank-empty-warning">
            ⚠️ Pilih survei terlebih dahulu untuk melihat peringkat.
          </p>
          <p v-else-if="lowestVoters.rows.length === 0" class="rank-empty">
            Belum ada data pegawai aktif.
          </p>
          <template v-else>
            <div class="table-scroll">
              <table class="rank-table">
                <thead>
                  <tr>
                    <th class="rank-col-no">No</th>
                    <th>Nama Pegawai</th>
                    <th>Unit</th>
                    <th>Organik/TAD</th>
                    <th class="rank-col-num">Vote</th>
                    <th class="rank-col-num">Target</th>
                    <th class="rank-col-num">Persentase</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(row, index) in lowestVoters.rows" :key="row.id">
                    <td class="rank-col-no">{{ index + 1 }}</td>
                    <td class="rank-name">{{ row.nama }}</td>
                    <td>{{ shortDeptName(row.unit) }}</td>
                    <td>{{ jenisPegawaiLabel(row.jenis) }}</td>
                    <td class="rank-col-num">
                      <span class="gap-value" :class="row.vote === 0 ? 'gap-pending' : ''">{{ row.vote }}</span>
                    </td>
                    <td class="rank-col-num">{{ row.target ?? "-" }}</td>
                    <td class="rank-col-num">
                      <span class="percent-bold">{{ row.persen === null ? "-" : `${row.persen}%` }}</span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <p v-if="lowestVoters.tied > 0" class="rank-note">
              Masih ada <strong>{{ lowestVoters.tied }}</strong> pegawai lain dengan jumlah vote yang sama
              ({{ lowestVoters.cutoff }}) yang tidak masuk daftar. Urutan di antara pegawai dengan vote yang
              sama mengikuti abjad nama.
            </p>
          </template>
        </div>

        <div v-if="!publicMode" class="report-card">
          <div class="card-header">
            <div>
              <h2 class="card-title">{{ DIVISION_RANK_SIZE }} Divisi dengan Vote Tersedikit</h2>
              <p class="card-subtitle">
                Total vote selama
                {{ isInternal ? "periode survei" : "periode survei sampai hari ini" }}, dari yang paling
                sedikit. Hanya unit kepala divisi (Division Head) yang dihitung; departemen di bawahnya tidak
                ikut. Karena jumlah pegawai tiap kepala divisi berbeda, lihat kolom Persentase untuk
                membandingkan secara adil.
              </p>
            </div>
          </div>

          <p v-if="noSurveySelected" class="rank-empty rank-empty-warning">
            ⚠️ Pilih survei terlebih dahulu untuk melihat peringkat.
          </p>
          <template v-else>
            <div class="table-scroll">
              <table class="rank-table">
                <thead>
                  <tr>
                    <th class="rank-col-no">No</th>
                    <th>Divisi</th>
                    <th class="rank-col-num">Pegawai</th>
                    <th class="rank-col-num">Vote</th>
                    <th class="rank-col-num">Target</th>
                    <th class="rank-col-num">Persentase</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(row, index) in lowestDivisions.rows" :key="row.key">
                    <td class="rank-col-no">{{ index + 1 }}</td>
                    <td class="rank-name">{{ row.key }}</td>
                    <td class="rank-col-num">{{ row.pegawai }}</td>
                    <td class="rank-col-num">
                      <span class="gap-value" :class="row.vote === 0 ? 'gap-pending' : ''">{{ row.vote }}</span>
                    </td>
                    <td class="rank-col-num">{{ row.target ?? "-" }}</td>
                    <td class="rank-col-num">
                      <span class="percent-bold">{{ row.persen === null ? "-" : `${row.persen}%` }}</span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <p v-if="lowestDivisions.tied > 0" class="rank-note">
              Masih ada <strong>{{ lowestDivisions.tied }}</strong> divisi lain dengan jumlah vote yang sama
              ({{ lowestDivisions.cutoff }}) yang tidak masuk daftar. Urutan di antara divisi dengan vote yang
              sama mengikuti abjad nama.
            </p>
          </template>
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
import {
  ORG_CHILDREN_BY_PARENT,
  ORG_HEAD_BY_PARENT,
  ORG_PARENT_KEYS,
  shortDeptName,
} from "./orgStructure";
import { formatWibDateTime, wibToday } from "./lib/wib";
import { jenisPegawaiLabel, surveyQuota, useSurveyStore } from "./stores/surveyStore";
import { useToastStore } from "./stores/toastStore";

// publicMode: the same report rendered on the public /report page. It
// reads aggregate counts through RPCs (anonymous visitors can't read
// submissions), only lists surveys the admin ticked "tampil publik" for, and
// drops the links to the per-employee detail pages.
const props = defineProps({
  publicMode: { type: Boolean, default: false },
});

const store = useSurveyStore();
const toast = useToastStore();
const route = useRoute();

const publicSurveys = ref([]);
const publicSubmissions = ref([]);

const surveyOptions = computed(() => (props.publicMode ? publicSurveys.value : store.surveys));

// "Muat Ulang" button + the "Diperbarui HH.MM WIB" label next to it.
const refreshing = ref(false);
const lastUpdated = ref("");
const updatedFormatter = new Intl.DateTimeFormat("id-ID", {
  timeZone: "Asia/Jakarta",
  hour: "2-digit",
  minute: "2-digit",
});

function markUpdated() {
  lastUpdated.value = `${updatedFormatter.format(new Date())} WIB`;
}

onMounted(async () => {
  // Employees (public read) are needed for the Jumlah / Target columns. The
  // public view skips the admin-only tables (submissions etc.) entirely.
  await (props.publicMode ? store.ensurePublicData() : store.ensureBaseData());
  if (props.publicMode) {
    try {
      publicSurveys.value = await store.fetchPublicReportSurveys();
      if (!selectedSurveyFilterId.value) {
        selectedSurveyFilterId.value = publicSurveys.value[0]?.id ?? null;
      }
    } catch (err) {
      console.error("Gagal memuat daftar survei:", err);
    }
  }
  markUpdated();
});

// Re-fetches everything the report is built from. Public mode goes through
// the aggregate RPCs; admin mode reloads the store's tables directly (admins
// also get realtime updates, so this is mostly a manual fallback there).
async function refreshData() {
  if (refreshing.value) return;
  refreshing.value = true;
  try {
    if (props.publicMode) {
      const [surveys] = await Promise.all([
        store.fetchPublicReportSurveys(),
        store.fetchEmployees(),
      ]);
      publicSurveys.value = surveys;
      if (selectedSurveyFilterId.value && !surveys.some((s) => s.id === selectedSurveyFilterId.value)) {
        // The survey was hidden or removed in the meantime; the survey watcher
        // below clears the tables.
        selectedSurveyFilterId.value = null;
      } else {
        await loadPublicSubmissions(selectedSurveyFilterId.value, { clear: false });
      }
    } else {
      await Promise.all([store.fetchSurveys(), store.fetchEmployees(), store.fetchSubmissions()]);
    }
    markUpdated();
  } catch (err) {
    toast.show(err.message || "Gagal memuat ulang data.", "error");
  } finally {
    refreshing.value = false;
  }
}


const expandedDept = ref(null);

function toggleDivisi(deptKey) {
  expandedDept.value = expandedDept.value === deptKey ? null : deptKey;
}


function departmentDetailLink(deptName) {
  return {
    name: "admin-department-detail",
    params: { department: deptName },
    query: {
      ...(selectedSurveyFilterId.value ? { survey: selectedSurveyFilterId.value } : {}),
      ...(selectedTanggal.value ? { tanggal: selectedTanggal.value } : {}),
    },
  };
}

// Jumlah/Target/Gap per departemen dihitung dari data pegawai ASLI
// (store.employees, hasil migrasi 005), sama seperti dateTable (lihat
// participationGroupedBy di surveyStore.js) — supaya total pegawai di
// tabel "per Tanggal" dan "per Departemen" selalu konsisten.
function buildDeptRow(key, deptNames) {
  const maxPengisian = surveyQuota(selectedSurveyFilter.value).limit;
  const deptSet = new Set(deptNames);

  const employeesHere = store.employees.filter((e) => e.isActive && deptSet.has(e.unitKerja));
  const pegawaiOrganik = employeesHere.filter((e) => e.jenisPegawai === "Organik").length;
  const pegawaiNonOrganik = employeesHere.length - pegawaiOrganik;
  const pegawaiTotal = employeesHere.length;

  const targetOrganik = pegawaiOrganik * maxPengisian;
  const targetNonOrganik = pegawaiNonOrganik * maxPengisian;
  const targetTotal = targetOrganik + targetNonOrganik;

  const scoped = deptSubmissions.value.filter((s) => deptSet.has(s.departemen));
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
    gapOrganik: pengisianOrganik - targetOrganik,
    gapNonOrganik: pengisianNonOrganik - targetNonOrganik,
    gapTotal: pengisianTotal - targetTotal,
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
      gapOrganik: pengisianOrganik - targetOrganik,
      gapNonOrganik: pengisianNonOrganik - targetNonOrganik,
      gapTotal: pengisianTotal - targetTotal,
      persenOrganik: targetOrganik > 0 ? Math.round((pengisianOrganik / targetOrganik) * 1000) / 10 : 0,
      persenNonOrganik:
        targetNonOrganik > 0 ? Math.round((pengisianNonOrganik / targetNonOrganik) * 1000) / 10 : 0,
      persenTotal: targetTotal > 0 ? Math.round((pengisianTotal / targetTotal) * 1000) / 10 : 0,
    };
  });

  return { page, rows, totalPages, pageStart, pageEnd, pagedRows, totals };
}

const selectedSurveyFilterId = ref(route.query.survey ? Number(route.query.survey) : null);

// Public mode: fetch the aggregate counts whenever the survey changes. The
// latest-request guard stops a slow response for a previous survey from
// overwriting the one currently selected.
let publicRequest = 0;

// `clear: false` keeps the old numbers on screen while a manual refresh is in
// flight, instead of flashing empty tables. Errors propagate to the caller.
async function loadPublicSubmissions(surveyId, { clear = true } = {}) {
  const request = ++publicRequest;
  if (clear) publicSubmissions.value = [];
  if (!surveyId) return;
  const rows = await store.fetchPublicReportSubmissions(surveyId);
  if (request === publicRequest) publicSubmissions.value = rows;
}

watch(
  () => (props.publicMode ? selectedSurveyFilterId.value : null),
  async (surveyId) => {
    try {
      await loadPublicSubmissions(surveyId);
    } catch (err) {
      console.error("Gagal memuat data survei:", err);
    }
  },
  { immediate: true }
);

const selectedSurveyFilter = computed(() =>
  selectedSurveyFilterId.value
    ? surveyOptions.value.find((s) => s.id === selectedSurveyFilterId.value) ?? null
    : null
);

const selectedSurveyFilterRange = computed(() => {
  const survey = selectedSurveyFilter.value;
  if (!survey || !survey.tanggalMulai || !survey.tanggalSelesai) return "";
  return `${formatDate(survey.tanggalMulai)} - ${formatDate(survey.tanggalSelesai)}`;
});

const noSurveySelected = computed(() => !selectedSurveyFilterId.value);

// External surveys have a per-day limit, so the per-Divisi view (target vs
// voting) is only meaningful for one chosen day. Internal surveys are filled
// once per employee for the whole period: no day to pick, and the numbers are
// the totals for the entire period.
const isInternal = computed(() => selectedSurveyFilter.value?.tipe === "Internal");
const selectedTanggal = ref(typeof route.query.tanggal === "string" ? route.query.tanggal : "");
const noFilterSelected = computed(
  () => noSurveySelected.value || (!isInternal.value && !selectedTanggal.value)
);

// A date from the previous survey may fall outside the new survey's period.
watch(selectedSurveyFilterId, () => {
  const survey = selectedSurveyFilter.value;
  const tanggal = selectedTanggal.value;
  if (!survey || !tanggal) return;
  if (
    (survey.tanggalMulai && tanggal < survey.tanggalMulai) ||
    (survey.tanggalSelesai && tanggal > survey.tanggalSelesai)
  ) {
    selectedTanggal.value = "";
  }
});

const filteredSubmissions = computed(() => {
  const survey = selectedSurveyFilter.value;
  if (!survey) return [];
  const source = props.publicMode ? publicSubmissions.value : store.submissions;
  return source.filter((s) => s.surveyId === survey.id);
});

const deptSubmissions = computed(() => {
  if (isInternal.value) return filteredSubmissions.value;
  return selectedTanggal.value
    ? filteredSubmissions.value.filter((s) => s.tanggal === selectedTanggal.value)
    : [];
});

// Every day of the survey's period up to today (or its end), so the per-Tanggal
// table also lists days with zero submissions — each day carries its own
// per-day target. Empty when the survey has no fixed period; the table then
// only lists days that have submissions.
const periodDates = computed(() => {
  const survey = selectedSurveyFilter.value;
  if (!survey?.tanggalMulai || !survey?.tanggalSelesai) return [];
  const today = wibToday();
  const last = survey.tanggalSelesai < today ? survey.tanggalSelesai : today;
  const dates = [];
  let cursor = Date.parse(`${survey.tanggalMulai}T00:00:00Z`);
  const end = Date.parse(`${last}T00:00:00Z`);
  while (cursor <= end && dates.length < 1000) {
    dates.push(new Date(cursor).toISOString().slice(0, 10));
    cursor += 24 * 60 * 60 * 1000;
  }
  return dates;
});

// ── Pegawai dengan vote tersedikit ─────────────────────────────────────────
// Every ACTIVE employee, including those with 0 votes, ranked from the fewest
// votes up; equal votes are ordered by name so the list is stable. Vote = all of
// the employee's submissions to the survey (matched by name, like the rest of
// the report). Target = days in the period so far x the per-day limit for
// external surveys (the same basis as the Bukti Survei dialog), or 1 for an
// internal survey; there is no target for an external survey without a period.
const RANK_SIZE = 20;
const DIVISION_RANK_SIZE = 5;

// One employee's target over the period (shared by both rankings): external =
// days so far x per-day limit, null when the survey has no fixed period;
// internal = 1.
const perEmployeeTarget = computed(() => {
  const survey = selectedSurveyFilter.value;
  if (!survey) return null;
  const { limit, perDay } = surveyQuota(survey);
  if (!perDay) return limit;
  return periodDates.value.length > 0 ? periodDates.value.length * limit : null;
});

const lowestVoters = computed(() => {
  const empty = { rows: [], tied: 0, cutoff: 0 };
  const survey = selectedSurveyFilter.value;
  if (props.publicMode || !survey) return empty;

  const target = perEmployeeTarget.value;

  const votes = new Map();
  for (const s of filteredSubmissions.value) votes.set(s.nama, (votes.get(s.nama) ?? 0) + 1);

  const ranked = store.employees
    .filter((e) => e.isActive)
    .map((e) => {
      const vote = votes.get(e.nama) ?? 0;
      return {
        id: e.id,
        nama: e.nama,
        unit: e.unitKerja,
        jenis: e.jenisPegawai,
        vote,
        target,
        persen: target ? Math.round((vote / target) * 1000) / 10 : null,
      };
    })
    .sort((a, b) => a.vote - b.vote || a.nama.localeCompare(b.nama, "id"));

  const rows = ranked.slice(0, RANK_SIZE);
  // Employees just past the cut with the same vote count as the last one shown.
  const cutoff = rows.at(-1)?.vote ?? 0;
  const tied =
    rows.length === RANK_SIZE ? ranked.slice(RANK_SIZE).filter((r) => r.vote === cutoff).length : 0;
  return { rows, tied, cutoff };
});

// ── Divisi dengan vote tersedikit ──────────────────────────────────────────
// Ranks the divisions by their TOTAL votes over the whole period (not one
// day), fewest first; equal votes are ordered by name. Only the division's OWN
// head unit counts (ORG_HEAD_BY_PARENT) — not the departments beneath it, which
// the per-Divisi table above already covers. Vote = submissions recorded under
// that unit; target = its active employees x one employee's target. Divisions
// have different numbers of people in their head unit, so the target and
// percentage are shown beside the count.
const lowestDivisions = computed(() => {
  const empty = { rows: [], tied: 0, cutoff: 0 };
  if (props.publicMode || !selectedSurveyFilter.value) return empty;

  const perEmployee = perEmployeeTarget.value;

  const ranked = ORG_PARENT_KEYS.map((key) => {
    const head = ORG_HEAD_BY_PARENT.get(key);
    const pegawai = store.employees.filter((e) => e.isActive && e.unitKerja === head).length;
    const vote = filteredSubmissions.value.filter((s) => s.departemen === head).length;
    const target = perEmployee === null ? null : pegawai * perEmployee;
    return {
      key,
      pegawai,
      vote,
      target,
      persen: target ? Math.round((vote / target) * 1000) / 10 : null,
    };
  }).sort((a, b) => a.vote - b.vote || a.key.localeCompare(b.key, "id"));

  const rows = ranked.slice(0, DIVISION_RANK_SIZE);
  const cutoff = rows.at(-1)?.vote ?? 0;
  const tied =
    rows.length === DIVISION_RANK_SIZE
      ? ranked.slice(DIVISION_RANK_SIZE).filter((r) => r.vote === cutoff).length
      : 0;
  return { rows, tied, cutoff };
});

function useParticipationTable(getKey, { pageSize = 3, sort, allKeys } = {}) {
  const page = ref(1);

  const rows = computed(() => {
    const maxPengisian = surveyQuota(selectedSurveyFilter.value).limit;
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
    // Each row is one day with its own per-day target, so the accumulated
    // target is the sum across days.
    const targetOrganik = list.reduce((sum, r) => sum + r.targetOrganik, 0);
    const targetNonOrganik = list.reduce((sum, r) => sum + r.targetNonOrganik, 0);
    const targetTotal = targetOrganik + targetNonOrganik;

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
      gapOrganik: pengisianOrganik - targetOrganik,
      gapNonOrganik: pengisianNonOrganik - targetNonOrganik,
      gapTotal: pengisianTotal - targetTotal,
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
  allKeys: periodDates,
});
const deptRows = computed(() =>
  noFilterSelected.value
    ? []
    : ORG_PARENT_KEYS.map((key) => buildDeptRow(key, ORG_CHILDREN_BY_PARENT.get(key) ?? []))
);
const deptTable = useRowsTable(deptRows, { pageSize: 10 });

// Gap = voting - target. Below target -> negative and red; target met or
// exceeded -> green.
function gapValueClass(value) {
  if (value < 0) return "gap-pending";
  return "gap-done";
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
  if (noFilterSelected.value) return;
  const doc = new jsPDF({ orientation: "landscape" });
  const surveyLabel = selectedSurveyFilter.value.nama;

  doc.setFontSize(14);
  doc.text("Laporan Hasil Survei - SkyVote", 14, 15);
  doc.setFontSize(10);
  doc.text(`Survei: ${surveyLabel}`, 14, 21);
  doc.text(`Diekspor pada: ${formatWibDateTime()}`, 14, 26);

  // The per-Tanggal table is for external surveys only; an internal survey
  // (once per employee per period) goes straight to the per-Divisi table.
  if (!isInternal.value) {
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
    doc.addPage();
  }

  const deptHead = JSON.parse(JSON.stringify(reportGroupHead));
  deptHead[0][1].content = "Divisi";

  // On the first page (internal) the header text above takes the top space.
  const deptTitleY = isInternal.value ? 34 : 15;
  doc.setFontSize(12);
  doc.text(
    isInternal.value
      ? "Rekapitulasi Partisipasi per Divisi - seluruh periode survei"
      : `Rekapitulasi Partisipasi per Divisi - ${formatDate(selectedTanggal.value)}`,
    14,
    deptTitleY
  );
  autoTable(doc, {
    head: deptHead,
    body: buildReportBody(deptTable.rows.value, deptTable.totals.value, (key) => key),
    startY: deptTitleY + 3,
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
  const dateStamp = wibToday();
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
  if (noFilterSelected.value) return;
  const surveyLabel = selectedSurveyFilter.value.nama;

  const wb = XLSX.utils.book_new();
  // The per-Tanggal sheet is for external surveys only (see exportToPdf).
  if (!isInternal.value) {
    XLSX.utils.book_append_sheet(
      wb,
      buildExcelSheet("Tanggal", dateTable.rows.value, dateTable.totals.value, formatDate),
      "Per Tanggal"
    );
  }
  XLSX.utils.book_append_sheet(
    wb,
    buildExcelSheet("Divisi", deptTable.rows.value, deptTable.totals.value, (key) => key),
    isInternal.value ? "Per Divisi" : `Per Divisi ${selectedTanggal.value}`
  );

  const slug = surveyLabel.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  const dateStamp = wibToday();
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

/* The "Diperbarui ..." label hangs below the button (absolute) so it doesn't
   make this group taller than the export buttons next to it. */
.refresh-group {
  position: relative;
  display: flex;
}

.btn-refresh {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  height: 40px;
  padding: 0 16px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

.btn-refresh:hover:not(:disabled) {
  border-color: var(--color-primary-light);
  color: var(--color-primary);
}

.btn-refresh:disabled {
  opacity: 0.7;
  cursor: progress;
}

.btn-refresh-loading .refresh-icon {
  animation: refresh-spin 0.8s linear infinite;
}

@keyframes refresh-spin {
  to {
    transform: rotate(360deg);
  }
}

@media (prefers-reduced-motion: reduce) {
  .btn-refresh-loading .refresh-icon {
    animation: none;
  }
}

.refresh-time {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  font-size: 11px;
  text-align: center;
  color: var(--color-text-muted);
  white-space: nowrap;
}

.btn-export {
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

.survey-filter-date {
  min-width: 140px;
}

.survey-filter-select:disabled {
  cursor: not-allowed;
  opacity: 0.6;
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

/* "Pegawai dengan vote tersedikit" table */
.rank-table {
  width: 100%;
  min-width: 640px;
  border-collapse: collapse;
  font-size: 13px;
  background-color: var(--color-surface);
}

.rank-table th {
  padding: 10px 12px;
  text-align: left;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.02em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  background-color: var(--color-bg);
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}

.rank-table td {
  padding: 10px 12px;
  color: var(--color-text);
  border-bottom: 1px solid var(--color-border);
}

.rank-table tbody tr:last-child td {
  border-bottom: none;
}

.rank-table tbody tr:hover td {
  background-color: rgba(248, 250, 252, 0.8);
}

.rank-col-no {
  width: 44px;
  color: var(--color-text-muted);
}

.rank-col-num {
  text-align: right !important;
  white-space: nowrap;
}

.rank-name {
  font-weight: 600;
}

.rank-empty {
  padding: 28px;
  text-align: center;
  color: var(--color-text-muted);
}

.rank-empty-warning {
  color: var(--color-warning);
  background: var(--color-warning-bg);
  border-radius: var(--radius-md);
  font-weight: 600;
}

.rank-note {
  font-size: 12px;
  line-height: 1.5;
  color: var(--color-text-muted);
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

  /* Stacked layout: the button fills the width and the label sits below it
     in the normal flow instead of hanging out of the group. */
  .refresh-group {
    flex-direction: column;
    width: 100%;
  }

  .btn-refresh {
    width: 100%;
  }

  .refresh-time {
    position: static;
    margin-top: 4px;
  }

  .report-card {
    padding: 16px;
  }

  .survey-filter-select {
    min-width: 0;
  }
}
</style>
