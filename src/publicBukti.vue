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
      <!-- Same report as admin/report, read-only (aggregate numbers only). -->
      <AdminReport public-mode class="report" />

      <footer class="page-footer">
        Hak Cipta &copy; {{ currentYear }} Yogyakarta International Airport. Seluruh hak dilindungi.
      </footer>
    </main>
  </div>
</template>

<script setup>
import AdminReport from "./adminReport.vue";
import AppHeader from "./components/AppHeader.vue";

const currentYear = new Date().getFullYear();
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
  gap: 20px;
  padding: 24px;
}

.report {
  max-width: 1280px;
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

.page-footer {
  text-align: center;
  font-size: 12px;
  color: var(--color-text-secondary);
}

@media (max-width: 520px) {
  .main-content {
    padding: 12px;
  }
}
</style>
