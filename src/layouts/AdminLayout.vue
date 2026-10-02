<template>
  <div class="admin-layout">
    <div class="bg-blob bg-blob-1" aria-hidden="true" />
    <div class="bg-blob bg-blob-2" aria-hidden="true" />
    <div class="bg-blob bg-blob-3" aria-hidden="true" />
    <div class="bg-blob bg-blob-4" aria-hidden="true" />

    <AppHeader class="admin-header">
      <template #brand>
        <button
          class="menu-toggle"
          type="button"
          :aria-label="mobileNavOpen ? 'Tutup menu' : 'Buka menu'"
          @click="mobileNavOpen = !mobileNavOpen"
        >
          <svg v-if="!mobileNavOpen" width="20" height="20" viewBox="0 0 20 20" fill="none">
            <path d="M3 5.5h14M3 10h14M3 14.5h14" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" />
          </svg>
          <svg v-else width="20" height="20" viewBox="0 0 20 20" fill="none">
            <path d="M5 5l10 10M15 5 5 15" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" />
          </svg>
        </button>
        <div class="page-context">
          <span class="page-context-label">Admin</span>
          <span class="page-context-divider">/</span>
          <span class="page-context-title">{{ pageTitle }}</span>
        </div>
      </template>
      <template #actions>
        <div ref="notifWrapRef" class="notif-wrap">
          <button
            class="icon-button"
            type="button"
            aria-label="Notifikasi"
            @click.stop="toggleNotifPanel"
          >
            <svg width="18" height="18" viewBox="0 0 20 20" fill="none">
              <path
                d="M15 7.5a5 5 0 0 0-10 0c0 2.4-.6 3.4-1.4 4.4-.6.7-.1 1.6.8 1.6h11.2c.9 0 1.4-.9.8-1.6-.8-1-1.4-2-1.4-4.4Z"
                stroke="currentColor"
                stroke-width="1.5"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
              <path
                d="M8 16a2 2 0 0 0 4 0"
                stroke="currentColor"
                stroke-width="1.5"
                stroke-linecap="round"
              />
            </svg>
            <span v-if="store.unreadNotificationCount > 0" class="notif-dot">
              {{ store.unreadNotificationCount > 9 ? "9+" : store.unreadNotificationCount }}
            </span>
          </button>

          <div v-if="notifOpen" class="notif-panel" @click.stop>
            <div class="notif-panel-header">
              <span class="notif-panel-title">Notifikasi</span>
              <div class="notif-panel-actions">
                <button
                  v-if="store.sortedNotifications.length > 0"
                  type="button"
                  class="notif-clear-all"
                  @click="clearAllNotifications()"
                >
                  Hapus semua
                </button>
              </div>
            </div>
            <ul class="notif-list">
              <li
                v-for="notif in store.sortedNotifications"
                :key="notif.id"
                class="notif-item"
                :class="{ 'notif-item-unread': !notif.read }"
                @click="store.markNotificationRead(notif.id)"
              >
                <span class="notif-item-dot" :class="{ 'notif-item-dot-unread': !notif.read }" />
                <div class="notif-item-body">
                  <span class="notif-item-message">{{ notif.message }}</span>
                  <span class="notif-item-time">{{ formatNotifTime(notif.createdAt) }}</span>
                </div>
                <button
                  type="button"
                  class="notif-item-delete"
                  aria-label="Hapus notifikasi"
                  @click.stop="deleteNotification(notif.id)"
                >
                  <svg width="12" height="12" viewBox="0 0 20 20" fill="none">
                    <path d="M5 5l10 10M15 5 5 15" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
                  </svg>
                </button>
              </li>
              <li v-if="store.sortedNotifications.length === 0" class="notif-empty">
                Belum ada notifikasi.
              </li>
            </ul>
          </div>
        </div>

        <span class="header-divider" aria-hidden="true" />

        <div class="avatar" :title="authStore.profile?.display_name || authStore.user?.email">
          {{ avatarInitial }}
        </div>
      </template>
    </AppHeader>

    <div class="admin-body">
      <AdminSidebar :open="mobileNavOpen" @close="mobileNavOpen = false" />
      <main class="admin-content">
        <div class="admin-content-inner">
          <RouterView />
        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { useRoute } from "vue-router";
import AdminSidebar from "../components/AdminSidebar.vue";
import AppHeader from "../components/AppHeader.vue";
import { useAuthStore } from "../stores/authStore";
import { useSurveyStore } from "../stores/surveyStore";
import { useToastStore } from "../stores/toastStore";

const route = useRoute();
const store = useSurveyStore();
const toast = useToastStore();

async function deleteNotification(id) {
  try {
    await store.deleteNotification(id);
  } catch (err) {
    toast.show(err.message || "Gagal menghapus notifikasi.", "error");
  }
}

async function clearAllNotifications() {
  try {
    await store.clearAllNotifications();
  } catch (err) {
    toast.show(err.message || "Gagal menghapus notifikasi.", "error");
  }
}
const authStore = useAuthStore();

const mobileNavOpen = ref(false);
watch(() => route.fullPath, () => {
  mobileNavOpen.value = false;
});

const pageTitle = computed(() => {
  if (route.name === "admin-buat-survey") {
    return route.params.id ? "Edit Survei" : "Buat Survei";
  }
  return route.meta.title || "Dashboard";
});

const avatarInitial = computed(() => {
  const source = authStore.profile?.display_name || authStore.user?.email || "A";
  return source.charAt(0).toUpperCase();
});

const notifOpen = ref(false);
const notifWrapRef = ref(null);

function closeNotifOnOutsideClick(event) {
  if (notifWrapRef.value && !notifWrapRef.value.contains(event.target)) {
    notifOpen.value = false;
  }
}

async function toggleNotifPanel() {
  notifOpen.value = !notifOpen.value;
  if (notifOpen.value) {
    await store.fetchNotifications();
    store.markAllNotificationsRead();
  }
}

onMounted(() => {
  document.addEventListener("click", closeNotifOnOutsideClick);
  store.fetchNotifications();
  store.setupRealtimeSubscriptions();
});
onBeforeUnmount(() => {
  document.removeEventListener("click", closeNotifOnOutsideClick);
  store.cleanupRealtimeSubscriptions();
});

function formatNotifTime(isoString) {
  const date = new Date(isoString);
  const diffMs = Date.now() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 1) return "Baru saja";
  if (diffMin < 60) return `${diffMin} menit lalu`;
  const diffHour = Math.floor(diffMin / 60);
  if (diffHour < 24) return `${diffHour} jam lalu`;
  const diffDay = Math.floor(diffHour / 24);
  return `${diffDay} hari lalu`;
}
</script>

<style scoped>
.admin-layout {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  min-height: 100vh;
  background-color: var(--color-bg);
}

.admin-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 30;
}

.admin-header :deep(.app-header) {
  background-color: var(--glass-bg-strong);
  backdrop-filter: blur(var(--glass-blur));
  -webkit-backdrop-filter: blur(var(--glass-blur));
}

.admin-header::after {
  content: "";
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 2px;
  background: linear-gradient(
    90deg,
    var(--color-primary) 0%,
    var(--color-primary-light) 45%,
    var(--color-accent-cyan-strong) 100%
  );
  opacity: 0.7;
}

.menu-toggle {
  display: none;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  flex-shrink: 0;
  border: none;
  border-radius: var(--radius-full);
  background-color: transparent;
  color: var(--color-text-secondary);
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.menu-toggle:hover {
  background-color: var(--color-bg);
}

.page-context {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.page-context-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--color-text-muted);
}

.page-context-divider {
  font-size: 13px;
  color: var(--color-border-strong);
}

.page-context-title {
  font-size: 15px;
  font-weight: 700;
  color: var(--color-text);
  letter-spacing: -0.01em;
}

.admin-body {
  position: relative;
  padding-top: 64px;
}

.admin-content {
  margin-left: 256px;
  padding: 32px 24px;
}

.admin-content-inner {
  max-width: 1280px;
  margin: 0 auto;
}

.icon-button {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border: none;
  border-radius: var(--radius-full);
  background-color: transparent;
  color: var(--color-text-secondary);
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.icon-button:hover {
  background-color: var(--color-bg);
}

.notif-wrap {
  position: relative;
}

.notif-dot {
  position: absolute;
  top: 0;
  right: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 16px;
  height: 16px;
  padding: 0 3px;
  border-radius: var(--radius-full);
  background-color: var(--color-danger);
  color: #ffffff;
  font-size: 9.5px;
  font-weight: 700;
  line-height: 1;
  border: 2px solid var(--color-surface);
  box-shadow: 0 0 0 0 rgba(217, 45, 32, 0.5);
  animation: notif-pulse 2.2s ease-out infinite;
}

@keyframes notif-pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(217, 45, 32, 0.45);
  }
  70% {
    box-shadow: 0 0 0 5px rgba(217, 45, 32, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(217, 45, 32, 0);
  }
}

@media (prefers-reduced-motion: reduce) {
  .notif-dot {
    animation: none;
  }
}

.header-divider {
  width: 1px;
  height: 24px;
  background-color: var(--color-border);
}

.notif-panel {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  width: 340px;
  max-width: calc(100vw - 32px);
  max-height: 400px;
  display: flex;
  flex-direction: column;
  background-color: var(--glass-bg-strong);
  backdrop-filter: blur(var(--glass-blur));
  -webkit-backdrop-filter: blur(var(--glass-blur));
  border: 1px solid var(--glass-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--glass-shadow);
  z-index: 50;
  overflow: hidden;
}

.notif-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 14px 16px;
  border-bottom: 1px solid var(--color-border);
}

.notif-panel-title {
  font-size: 14px;
  font-weight: 700;
  color: var(--color-text);
}

.notif-panel-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.notif-clear-all {
  border: none;
  background: transparent;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  padding: 0;
}

.notif-clear-all {
  color: var(--color-danger);
}

.notif-list {
  list-style: none;
  margin: 0;
  padding: 4px;
  overflow-y: auto;
}

.notif-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 10px 12px;
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: background-color 0.15s ease, transform 0.1s ease;
}

.notif-item:active {
  transform: scale(0.97);
}

.notif-item:hover {
  background-color: var(--color-bg);
}

.notif-item-unread {
  background-color: rgba(0, 93, 172, 0.05);
}

.notif-item-dot {
  margin-top: 5px;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
  background-color: transparent;
}

.notif-item-dot-unread {
  background-color: var(--color-primary);
}

.notif-item-body {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.notif-item-message {
  font-size: 13px;
  color: var(--color-text);
  line-height: 1.4;
}

.notif-item-time {
  font-size: 11px;
  color: var(--color-text-muted);
}

.notif-item-delete {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  margin-left: auto;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--color-text-muted);
  cursor: pointer;
  opacity: 0;
  transition: opacity 0.15s ease, background-color 0.15s ease, color 0.15s ease;
}

.notif-item:hover .notif-item-delete {
  opacity: 1;
}

.notif-item-delete:hover {
  background-color: var(--color-danger-bg);
  color: var(--color-danger);
}

.notif-empty {
  padding: 24px 16px;
  text-align: center;
  font-size: 13px;
  color: var(--color-text-muted);
}

.avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border-radius: var(--radius-full);
  background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-accent-cyan-strong) 100%);
  color: #ffffff;
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 700;
  box-shadow: 0 2px 8px rgba(0, 93, 172, 0.35);
  cursor: default;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.avatar:hover {
  transform: scale(1.06);
  box-shadow: 0 4px 12px rgba(0, 93, 172, 0.45);
}

@media (max-width: 768px) {
  .admin-content {
    margin-left: 0;
    padding: 20px 16px;
  }

  .menu-toggle {
    display: flex;
  }

  .page-context-label {
    display: none;
  }

  .page-context-divider {
    display: none;
  }

  .notif-panel {
    position: fixed;
    top: 68px;
    left: 12px;
    right: 12px;
    width: auto;
    max-width: none;
  }
}

@media (max-width: 420px) {
  .header-divider {
    display: none;
  }
}
</style>
