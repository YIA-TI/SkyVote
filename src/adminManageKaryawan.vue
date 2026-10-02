<template>
  <div class="dashboard-page">
    <div class="page-heading">
      <div>
        <h1 class="page-title">Kelola Pegawai</h1>
        <p class="page-subtitle">
          Tambah, ubah, dan nonaktifkan data pegawai. Pegawai nonaktif tidak muncul di form survei publik, tapi
          riwayat pengisiannya tetap tersimpan.
        </p>
      </div>
      <button type="button" class="btn-add" @click="openAddForm">
        <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
          <path d="M10 3v14M3 10h14" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        </svg>
        Tambah Pegawai
      </button>
    </div>

    <div class="board-card">
      <div class="toolbar">
        <div class="search-box">
          <svg class="search-icon" width="15" height="15" viewBox="0 0 20 20" fill="none">
            <circle cx="9" cy="9" r="6.5" stroke="currentColor" stroke-width="1.6" />
            <path d="M17 17l-3.5-3.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
          <input v-model="search" class="search-input" type="text" placeholder="Cari nama atau NIP..." />
        </div>

        <select v-model="unitFilter" class="unit-filter">
          <option value="">Semua Unit Kerja</option>
          <option v-for="unit in unitOptions" :key="unit" :value="unit">{{ shortDeptName(unit) }}</option>
        </select>

        <select v-model="statusFilter" class="unit-filter">
          <option value="active">Aktif</option>
          <option value="inactive">Nonaktif</option>
          <option value="all">Semua Status</option>
        </select>
      </div>

      <div class="table-scroll">
        <table class="survey-table">
          <thead>
            <tr>
              <th>NIP</th>
              <th>Nama</th>
              <th>Unit Kerja</th>
              <th>Jenis Pegawai</th>
              <th>Status</th>
              <th class="col-action">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="employee in pagedEmployees" :key="employee.id" :class="{ 'row-inactive': !employee.isActive }">
              <td>
                <span class="cell-muted">{{ employee.nip || "-" }}</span>
              </td>
              <td>
                <div class="cell-title">{{ employee.nama }}</div>
              </td>
              <td>
                <span class="cell-muted">{{ shortDeptName(employee.unitKerja) }}</span>
              </td>
              <td>
                <span class="status-flag">
                  <span
                    class="status-dot"
                    :class="employee.jenisPegawai === 'Organik' ? 'status-aktif' : 'status-terjadwal'"
                  />
                  {{ jenisPegawaiLabel(employee.jenisPegawai) }}
                </span>
              </td>
              <td>
                <span class="status-badge" :class="employee.isActive ? 'badge-active' : 'badge-inactive'">
                  {{ employee.isActive ? "Aktif" : "Nonaktif" }}
                </span>
              </td>
              <td class="col-action">
                <div class="row-actions">
                  <button type="button" class="icon-btn" title="Edit pegawai" @click="openEditForm(employee)">
                    <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
                      <path
                        d="M13.5 3.5 16 6l-8.8 8.8-3 .7.7-3L13.5 3.5Z"
                        stroke="currentColor"
                        stroke-width="1.5"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      />
                    </svg>
                  </button>
                  <button
                    v-if="employee.isActive"
                    type="button"
                    class="icon-btn icon-btn-danger"
                    title="Nonaktifkan pegawai"
                    @click="askDeactivate(employee)"
                  >
                    <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
                      <path
                        d="M4 6h12M8 6V4.5A1 1 0 0 1 9 3.5h2a1 1 0 0 1 1 1V6M6 6l.6 9.5a1 1 0 0 0 1 .9h4.8a1 1 0 0 0 1-.9L14 6"
                        stroke="currentColor"
                        stroke-width="1.5"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      />
                    </svg>
                  </button>
                  <button
                    v-else
                    type="button"
                    class="icon-btn icon-btn-success"
                    title="Aktifkan kembali pegawai"
                    @click="reactivate(employee)"
                  >
                    <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
                      <path
                        d="M4 10.5 8 14.5 16 5.5"
                        stroke="currentColor"
                        stroke-width="1.6"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      />
                    </svg>
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="filteredEmployees.length === 0">
              <td colspan="6" class="empty-row">Tidak ada pegawai yang cocok.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pagination">
        <span class="pagination-label">
          Menampilkan {{ filteredEmployees.length === 0 ? 0 : pageStart + 1 }}-{{ pageEnd }} dari
          {{ filteredEmployees.length }} pegawai
        </span>
        <div class="pager" v-if="totalPages > 1">
          <button class="pager-arrow" type="button" :disabled="page === 1" @click="page--">&lsaquo;</button>
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
          <button class="pager-arrow" type="button" :disabled="page === totalPages" @click="page++">&rsaquo;</button>
        </div>
      </div>
    </div>

    <teleport to="body">
      <transition name="confirm-fade">
        <div v-if="formOpen" class="form-overlay" @click.self="closeForm">
          <div class="form-modal" role="dialog" aria-modal="true">
            <h2 class="form-title">{{ editingId ? "Edit Pegawai" : "Tambah Pegawai" }}</h2>

            <form class="form-body" @submit.prevent="submitForm">
              <div class="field">
                <label class="field-label" for="karyawan-nip">NIP <span class="required">*</span></label>
                <input
                  id="karyawan-nip"
                  v-model="form.nip"
                  class="input"
                  type="text"
                  placeholder="Nomor induk pegawai"
                  required
                />
              </div>

              <div class="field">
                <label class="field-label" for="karyawan-nama">Nama <span class="required">*</span></label>
                <input
                  id="karyawan-nama"
                  v-model="form.nama"
                  class="input"
                  type="text"
                  placeholder="Nama lengkap pegawai"
                  required
                />
              </div>

              <div class="field">
                <label class="field-label" for="karyawan-unit">Unit Kerja <span class="required">*</span></label>
                <select id="karyawan-unit" v-model="form.unitKerja" class="input input-select" required>
                  <option value="" disabled>Pilih unit kerja</option>
                  <option v-for="unit in unitOptions" :key="unit" :value="unit">{{ shortDeptName(unit) }}</option>
                </select>
              </div>

              <div class="field">
                <label class="field-label" for="karyawan-jenis">Jenis Pegawai <span class="required">*</span></label>
                <select id="karyawan-jenis" v-model="form.jenisPegawai" class="input input-select" required>
                  <option value="Organik">Organik</option>
                  <option value="Non-Organik">TAD (Non-Organik)</option>
                </select>
              </div>

              <div class="form-footer">
                <button type="button" class="confirm-btn confirm-btn-secondary" @click="closeForm">Batal</button>
                <button type="submit" class="confirm-btn confirm-btn-primary" :disabled="saving">
                  {{ saving ? "Menyimpan..." : editingId ? "Simpan Perubahan" : "Tambah Pegawai" }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </transition>
    </teleport>

    <ConfirmDialog
      :visible="deactivateTarget !== null"
      title="Nonaktifkan pegawai?"
      :message="deactivateTarget ? `“${deactivateTarget.nama}” tidak akan muncul lagi di pencarian nama pada form survei publik.` : ''"
      note="Data dan riwayat pengisian survei pegawai ini tidak dihapus, dan bisa diaktifkan kembali kapan saja."
      confirm-text="Ya, Nonaktifkan"
      cancel-text="Batal"
      danger
      @confirm="confirmDeactivate"
      @cancel="deactivateTarget = null"
    />
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from "vue";
import ConfirmDialog from "./components/ConfirmDialog.vue";
import { ORG_STRUCTURE, shortDeptName } from "./orgStructure.js";
import { jenisPegawaiLabel, useSurveyStore } from "./stores/surveyStore";
import { useToastStore } from "./stores/toastStore";

const store = useSurveyStore();
const toast = useToastStore();

const unitOptions = ORG_STRUCTURE.flatMap((group) => group.children);

const search = ref("");
const unitFilter = ref("");
const statusFilter = ref("active");
const page = ref(1);
const pageSize = 8;

onMounted(() => {
  store.ensureBaseData();
});

const filteredEmployees = computed(() => {
  const term = search.value.trim().toLowerCase();
  return store.employees.filter((e) => {
    const matchesTerm =
      !term || e.nama.toLowerCase().includes(term) || (e.nip || "").toLowerCase().includes(term);
    const matchesUnit = !unitFilter.value || e.unitKerja === unitFilter.value;
    const matchesStatus =
      statusFilter.value === "all" ||
      (statusFilter.value === "active" ? e.isActive : !e.isActive);
    return matchesTerm && matchesUnit && matchesStatus;
  });
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredEmployees.value.length / pageSize)));

watch([search, unitFilter, statusFilter, filteredEmployees], () => {
  if (page.value > totalPages.value) page.value = totalPages.value;
});

const pageStart = computed(() => (page.value - 1) * pageSize);
const pageEnd = computed(() => Math.min(pageStart.value + pageSize, filteredEmployees.value.length));
const pagedEmployees = computed(() => filteredEmployees.value.slice(pageStart.value, pageEnd.value));

const formOpen = ref(false);
const editingId = ref(null);
const saving = ref(false);
const form = reactive({ nip: "", nama: "", unitKerja: "", jenisPegawai: "Organik" });

function resetForm() {
  form.nip = "";
  form.nama = "";
  form.unitKerja = "";
  form.jenisPegawai = "Organik";
}

function openAddForm() {
  editingId.value = null;
  resetForm();
  formOpen.value = true;
}

function openEditForm(employee) {
  editingId.value = employee.id;
  form.nip = employee.nip || "";
  form.nama = employee.nama;
  form.unitKerja = employee.unitKerja;
  form.jenisPegawai = employee.jenisPegawai;
  formOpen.value = true;
}

function closeForm() {
  formOpen.value = false;
}

async function submitForm() {
  saving.value = true;
  try {
    if (editingId.value) {
      await store.updateEmployee(editingId.value, { ...form });
      toast.show(`Data "${form.nama}" berhasil diperbarui`, "success");
    } else {
      await store.addEmployee({ ...form });
      toast.show(`Pegawai "${form.nama}" berhasil ditambahkan`, "success");
    }
    formOpen.value = false;
  } catch (err) {
    toast.show(err.message, "error");
  } finally {
    saving.value = false;
  }
}

const deactivateTarget = ref(null);

function askDeactivate(employee) {
  deactivateTarget.value = employee;
}

async function confirmDeactivate() {
  if (!deactivateTarget.value) return;
  const employee = deactivateTarget.value;
  deactivateTarget.value = null;
  try {
    await store.setEmployeeActive(employee.id, false);
    toast.show(`Pegawai "${employee.nama}" dinonaktifkan`, "success");
  } catch (err) {
    toast.show(err.message, "error");
  }
}

async function reactivate(employee) {
  try {
    await store.setEmployeeActive(employee.id, true);
    toast.show(`Pegawai "${employee.nama}" diaktifkan kembali`, "success");
  } catch (err) {
    toast.show(err.message, "error");
  }
}
</script>

<style scoped>
.dashboard-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
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
  margin-top: 4px;
}

.btn-add {
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
  font-size: 14px;
  font-weight: 600;
  white-space: nowrap;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-add:hover {
  background-color: var(--color-primary-dark);
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

.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 16px 24px;
  border-bottom: 1px solid var(--color-border);
  flex-wrap: wrap;
}

.search-box {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
  max-width: 320px;
}

.search-icon {
  position: absolute;
  left: 12px;
  color: var(--color-text-muted);
}

.search-input {
  width: 100%;
  height: 40px;
  padding: 0 12px 0 36px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  font-family: var(--font-sans);
  font-size: 14px;
}

.search-input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px rgba(0, 93, 172, 0.2);
}

.unit-filter {
  height: 40px;
  padding: 0 12px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 14px;
  max-width: 260px;
}

.table-scroll {
  overflow-x: auto;
}

.survey-table {
  width: 100%;
  min-width: 780px;
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

.col-action {
  text-align: center;
  width: 90px;
}

.survey-table tbody td {
  padding: 16px 24px;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text);
  vertical-align: middle;
}

.survey-table tbody tr {
  transition: background-color 0.12s ease;
}

.survey-table tbody tr:hover td {
  background-color: rgba(248, 250, 252, 0.8);
}

.survey-table tbody tr:last-child td {
  border-bottom: none;
}

.cell-title {
  font-weight: 600;
  color: var(--color-text);
}

.cell-muted {
  color: var(--color-text-secondary);
  font-size: 13px;
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

.status-terjadwal {
  background-color: var(--color-warning);
}

.row-actions {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  opacity: 0;
  transition: opacity 0.15s ease;
}

.survey-table tbody tr:hover .row-actions {
  opacity: 1;
}

@media (hover: none) {
  .row-actions {
    opacity: 1;
  }
}

.icon-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border: none;
  border-radius: var(--radius-sm);
  background-color: transparent;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.icon-btn:hover {
  background-color: var(--color-bg);
  color: var(--color-primary);
}

.icon-btn-danger:hover {
  background-color: var(--color-danger-bg);
  color: var(--color-danger);
}

.icon-btn-success:hover {
  background-color: rgba(22, 163, 74, 0.12);
  color: var(--color-success);
}

.row-inactive td {
  opacity: 0.6;
}

.status-badge {
  display: inline-flex;
  align-items: center;
  padding: 3px 10px;
  border-radius: var(--radius-full, 999px);
  font-size: 12px;
  font-weight: 600;
}

.badge-active {
  background-color: rgba(22, 163, 74, 0.12);
  color: var(--color-success);
}

.badge-inactive {
  background-color: var(--color-bg);
  color: var(--color-text-muted);
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
  padding: 14px 24px;
  border-top: 1px solid var(--color-border);
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

/* ── Add/edit modal ────────────────────────────────────────────────────── */
.form-overlay {
  position: fixed;
  inset: 0;
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(4px);
  padding: 16px;
}

.form-modal {
  width: 100%;
  max-width: 440px;
  background-color: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  padding: 24px;
  font-family: var(--font-sans);
}

.form-title {
  margin: 0 0 16px;
  font-size: 17px;
  font-weight: 800;
  letter-spacing: -0.01em;
  color: var(--color-text);
}

.form-body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text-secondary);
}

.required {
  color: var(--color-danger);
}

.input {
  height: 40px;
  padding: 0 12px;
  border: 1px solid var(--color-border-strong);
  border-radius: var(--radius-md);
  background-color: var(--color-surface);
  font-family: var(--font-sans);
  font-size: 14px;
  color: var(--color-text);
}

.input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px rgba(0, 93, 172, 0.2);
}

.input-select {
  appearance: auto;
}

.form-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 8px;
}

.confirm-btn {
  padding: 9px 16px;
  border-radius: var(--radius-md);
  font-family: var(--font-sans);
  font-size: 14px;
  font-weight: 600;
  border: 1px solid transparent;
  cursor: pointer;
}

.confirm-btn-secondary {
  background-color: var(--color-surface);
  border-color: var(--color-border);
  color: var(--color-text-secondary);
}

.confirm-btn-secondary:hover {
  background-color: var(--color-bg);
}

.confirm-btn-primary {
  background-color: var(--color-primary);
  color: #ffffff;
}

.confirm-btn-primary:hover {
  background-color: var(--color-primary-dark);
}

.confirm-btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.confirm-fade-enter-active,
.confirm-fade-leave-active {
  transition: opacity 0.15s ease;
}

.confirm-fade-enter-from,
.confirm-fade-leave-to {
  opacity: 0;
}

@media (max-width: 640px) {
  .page-heading {
    flex-wrap: wrap;
  }

  .btn-add {
    width: 100%;
    justify-content: center;
  }

  .toolbar {
    padding: 16px;
  }

  .search-box {
    max-width: none;
  }
}
</style>
