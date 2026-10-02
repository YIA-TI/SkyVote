<template>
  <div v-if="open" class="sidebar-backdrop" @click="$emit('close')" />

  <aside class="sidebar" :class="{ 'sidebar-open': open }">
    <svg class="sidebar-flower sidebar-flower-1" viewBox="0 0 24 24" aria-hidden="true">
      <g>
        <ellipse cx="12" cy="6" rx="3" ry="5" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(60 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(120 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(180 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(240 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(300 12 12)" />
        <circle cx="12" cy="12" r="2.4" />
      </g>
    </svg>
    <svg class="sidebar-flower sidebar-flower-2" viewBox="0 0 24 24" aria-hidden="true">
      <g>
        <ellipse cx="12" cy="6" rx="3" ry="5" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(60 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(120 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(180 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(240 12 12)" />
        <ellipse cx="12" cy="6" rx="3" ry="5" transform="rotate(300 12 12)" />
        <circle cx="12" cy="12" r="2.4" />
      </g>
    </svg>

    <div class="sidebar-brand">
      <div class="brand-mark">
        <img src="/logo_skyvote.jpeg" alt="SkyVote" class="brand-mark-img" />
      </div>
      <div class="brand-text">
        <span class="brand-title">SkyVote</span>
      </div>
    </div>

    <nav class="sidebar-nav">
      <RouterLink to="/admin/dashboard" class="nav-item" active-class="active" @click="$emit('close')">
        <span class="nav-icon-box">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
            <rect x="2.5" y="10.5" width="3.5" height="7" rx="1" stroke="currentColor" stroke-width="1.6" />
            <rect x="8.25" y="6" width="3.5" height="11.5" rx="1" stroke="currentColor" stroke-width="1.6" />
            <rect x="14" y="2.5" width="3.5" height="15" rx="1" stroke="currentColor" stroke-width="1.6" />
          </svg>
        </span>
        Dashboard
      </RouterLink>

      <RouterLink to="/admin/management" class="nav-item" active-class="active" @click="$emit('close')">
        <span class="nav-icon-box">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
            <path
              d="M3 15V5m6.5 10V8m6.5 7V3"
              stroke="currentColor"
              stroke-width="1.6"
              stroke-linecap="round"
            />
          </svg>
        </span>
        Kelola Survei
      </RouterLink>

      <RouterLink
        to="/admin/survey-result"
        class="nav-item"
        :class="{ active: isSurveyResultActive }"
        @click="$emit('close')"
      >
        <span class="nav-icon-box">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
            <path
              d="M6.5 9.5 9 12l4.5-5M4 3h12a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1Z"
              stroke="currentColor"
              stroke-width="1.6"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
        </span>
        Hasil Survei
      </RouterLink>

      <RouterLink to="/admin/report" class="nav-item" active-class="active" @click="$emit('close')">
        <span class="nav-icon-box">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
            <rect x="2" y="3" width="16" height="14" rx="2" stroke="currentColor" stroke-width="1.6" />
            <path d="M6 12v2M10 9v5M14 7v7" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
        </span>
        Laporan
      </RouterLink>

      <RouterLink to="/admin/karyawan" class="nav-item" active-class="active" @click="$emit('close')">
        <span class="nav-icon-box">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
            <circle cx="7.5" cy="6" r="2.6" stroke="currentColor" stroke-width="1.6" />
            <path
              d="M2.5 16.2c0-2.9 2.2-5 5-5s5 2.1 5 5"
              stroke="currentColor"
              stroke-width="1.6"
              stroke-linecap="round"
            />
            <path
              d="M13 6.2a2.6 2.6 0 1 1 1.8 4.5M14.5 11.3c1.8.4 3 1.9 3 4.1"
              stroke="currentColor"
              stroke-width="1.6"
              stroke-linecap="round"
            />
          </svg>
        </span>
        Kelola Pegawai
      </RouterLink>

      <RouterLink to="/admin/hapus-gambar" class="nav-item" active-class="active" @click="$emit('close')">
        <span class="nav-icon-box">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
            <path
              d="M3 5.5h14M8 5.5V4a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v1.5M5 5.5l.7 10.2a1.5 1.5 0 0 0 1.5 1.4h5.6a1.5 1.5 0 0 0 1.5-1.4l.7-10.2"
              stroke="currentColor"
              stroke-width="1.6"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
        </span>
        Hapus Data
      </RouterLink>
    </nav>

    <div class="sidebar-footer">
      <button class="nav-item nav-item-plain" type="button" @click="showLogoutConfirm = true">
        <span class="nav-icon-box">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
            <path
              d="M7.5 17H4a1.5 1.5 0 0 1-1.5-1.5V4.5A1.5 1.5 0 0 1 4 3h3.5M13 13.5 17.5 9 13 4.5M17.5 9H7.5"
              stroke="currentColor"
              stroke-width="1.6"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
        </span>
        Logout
      </button>
    </div>

    <ConfirmDialog
      :visible="showLogoutConfirm"
      title="Logout dari SkyVote?"
      message="Anda perlu login lagi untuk mengakses halaman admin."
      confirm-text="Ya, Logout"
      cancel-text="Batal"
      danger
      @confirm="handleLogout"
      @cancel="showLogoutConfirm = false"
    />
  </aside>
</template>

<script setup>
import { computed, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useAuthStore } from "../stores/authStore";
import ConfirmDialog from "./ConfirmDialog.vue";

defineProps({
  open: { type: Boolean, default: false },
});
defineEmits(["close"]);

const authStore = useAuthStore();
const router = useRouter();
const route = useRoute();
const showLogoutConfirm = ref(false);

// RouterLink's built-in active-class only lights up for the exact route (or
// its own descendants in the route tree). admin-survey-hasil (the detail
// page opened via "Lihat Hasil") is a sibling of admin-survey-result (the
// list), not a child of it, so it needs this explicit check to keep the
// sidebar highlighted while viewing a survey's results.
const isSurveyResultActive = computed(() =>
  ["admin-survey-result", "admin-survey-hasil"].includes(route.name)
);

async function handleLogout() {
  showLogoutConfirm.value = false;
  await authStore.signOut();
  router.push("/admin/login");
}
</script>

<style scoped>
.sidebar {
  position: fixed;
  top: 64px;
  left: 0;
  bottom: 0;
  width: 256px;
  overflow: hidden;
  background-color: var(--glass-sidebar-bg);
  backdrop-filter: blur(var(--glass-blur));
  -webkit-backdrop-filter: blur(var(--glass-blur));
  border-right: 1px solid rgba(255, 255, 255, 0.08);
  display: flex;
  flex-direction: column;
  z-index: 20;
}

/* ── Drifting spinning-flower silhouettes ────────────────────────────────
   Same decorative motif as the public page, tuned for this narrow, tall
   panel (px-based travel instead of vw/vh, muted so nav text stays legible). */
.sidebar-flower {
  position: absolute;
  z-index: -1;
  pointer-events: none;
  will-change: transform, opacity;
}

.sidebar-flower-1 {
  top: 42%;
  left: -14%;
  width: 64px;
  height: 64px;
  fill: rgba(255, 255, 255, 0.4);
  animation: sidebar-flower-drift-1 20s linear infinite;
}

.sidebar-flower-2 {
  top: 58%;
  left: 60%;
  width: 46px;
  height: 46px;
  fill: var(--color-accent-cyan-strong);
  animation: sidebar-flower-drift-2 26s linear infinite;
}

@keyframes sidebar-flower-drift-1 {
  0% { transform: translate(0, 0) rotate(0deg); opacity: 0; }
  10% { opacity: 0.35; }
  90% { opacity: 0.35; }
  100% { transform: translate(220px, -380px) rotate(720deg); opacity: 0; }
}

@keyframes sidebar-flower-drift-2 {
  0% { transform: translate(0, 0) rotate(0deg); opacity: 0; }
  10% { opacity: 0.3; }
  90% { opacity: 0.3; }
  100% { transform: translate(-160px, 320px) rotate(-720deg); opacity: 0; }
}

@media (prefers-reduced-motion: reduce) {
  .sidebar-flower {
    animation: none !important;
    display: none;
  }
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 22px 20px;
  border-bottom: 1px solid var(--color-sidebar-border);
}

.brand-mark {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 46px;
  height: 46px;
  flex-shrink: 0;
  border-radius: 12px;
  background: linear-gradient(135deg, var(--color-primary-light) 0%, var(--color-accent-cyan-strong) 100%);
  padding: 2px;
  box-shadow: 0 0 0 1px rgba(92, 233, 254, 0.25), 0 6px 16px rgba(0, 93, 172, 0.35);
  transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1), box-shadow 0.2s ease;
}

.sidebar-brand:hover .brand-mark {
  transform: scale(1.05) rotate(-2deg);
  box-shadow: 0 0 0 1px rgba(92, 233, 254, 0.4), 0 8px 20px rgba(0, 93, 172, 0.45);
}

.brand-mark-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 10px;
}

.brand-text {
  display: flex;
  align-items: center;
  min-width: 0;
}

.brand-title {
  background: linear-gradient(90deg, #ffffff 0%, var(--color-accent-cyan-strong) 100%);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  font-family: var(--font-sans);
  font-size: 19px;
  font-weight: 800;
  letter-spacing: -0.02em;
  white-space: nowrap;
}

.sidebar-nav {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 16px 12px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: var(--radius-md);
  color: var(--color-sidebar-text-muted);
  font-family: var(--font-sans);
  font-size: 14px;
  font-weight: 500;
  text-decoration: none;
  border: none;
  background: transparent;
  width: 100%;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.nav-item:hover {
  background-color: var(--color-sidebar-bg-alt);
  color: #ffffff;
}

.nav-item.active {
  background-color: var(--color-sidebar-active);
  color: #ffffff;
  font-weight: 600;
}

.nav-icon-box {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  flex-shrink: 0;
}

.sidebar-footer {
  margin-top: auto;
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 12px;
  border-top: 1px solid var(--color-sidebar-border);
}

.sidebar-backdrop {
  display: none;
}

@media (max-width: 768px) {
  .sidebar-backdrop {
    display: block;
    position: fixed;
    inset: 64px 0 0 0;
    background-color: rgba(15, 23, 42, 0.5);
    z-index: 19;
    animation: backdrop-fade 0.2s ease both;
  }

  @keyframes backdrop-fade {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }

  .sidebar {
    transform: translateX(-100%);
    box-shadow: none;
    transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
    background-color: var(--color-sidebar-bg);
    backdrop-filter: none;
    -webkit-backdrop-filter: none;
  }

  .sidebar.sidebar-open {
    transform: translateX(0);
    box-shadow: 8px 0 24px rgba(15, 23, 42, 0.25);
  }

  @media (prefers-reduced-motion: reduce) {
    .sidebar {
      transition: none;
    }

    .sidebar-backdrop {
      animation: none;
    }
  }
}
</style>
