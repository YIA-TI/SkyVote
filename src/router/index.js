import { createRouter, createWebHistory } from "vue-router";
import AdminLayout from "../layouts/AdminLayout.vue";
import { useAuthStore } from "../stores/authStore";

const routes = [
  {
    path: "/",
    name: "public-page",
    component: () => import("../publicPage.vue"),
  },
  {
    path: "/success",
    name: "public-success",
    component: () => import("../publicSuccess.vue"),
  },
  {
    path: "/report",
    name: "public-bukti",
    component: () => import("../publicBukti.vue"),
  },
  {
    path: "/admin/login",
    name: "admin-login",
    component: () => import("../adminLogin.vue"),
  },
  {
    path: "/admin",
    component: AdminLayout,
    meta: { requiresAdmin: true },
    children: [
      {
        path: "",
        redirect: { name: "admin-survey-management" },
      },
      {
        path: "dashboard",
        name: "admin-dashboard",
        component: () => import("../adminDashboard.vue"),
        meta: { title: "Dashboard", readonlyOk: true },
      },
      {
        path: "management",
        name: "admin-survey-management",
        component: () => import("../adminSurveyManagement.vue"),
        meta: { title: "Kelola Survei" },
      },
      {
        path: "buat-survey/:id?",
        name: "admin-buat-survey",
        component: () => import("../adminBuatSurvey.vue"),
        meta: { title: "Buat Survei" },
      },
      {
        path: "survey-result",
        name: "admin-survey-result",
        component: () => import("../adminSurveyResultList.vue"),
        meta: { title: "Hasil Survei Internal", readonlyOk: true },
      },
      {
        path: "survey-hasil/:id",
        name: "admin-survey-hasil",
        component: () => import("../adminSurveyHasil.vue"),
        meta: { title: "Hasil Survei Internal", readonlyOk: true },
      },
      {
        path: "report",
        name: "admin-report",
        component: () => import("../adminReport.vue"),
        meta: { title: "Laporan", readonlyOk: true },
      },
      {
        path: "detail-survey/:department",
        name: "admin-department-detail",
        component: () => import("../adminDepartmentDetail.vue"),
        meta: { title: "Detail Survei", readonlyOk: true },
      },
      {
        path: "karyawan",
        name: "admin-manage-karyawan",
        component: () => import("../adminManageKaryawan.vue"),
        meta: { title: "Kelola Pegawai" },
      },
      {
        path: "hapus-gambar",
        name: "admin-manage-images",
        component: () => import("../adminManageImages.vue"),
        meta: { title: "Hapus Data", requiresSuperAdmin: true },
      },
    ],
  },
  {
    path: "/:pathMatch(.*)*",
    redirect: "/",
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach(async (to) => {
  if (!to.matched.some((record) => record.meta.requiresAdmin)) return true;

  const authStore = useAuthStore();
  if (!authStore.ready) {
    await authStore.restoreSession();
  }

  if (!authStore.isStaff) {
    return { name: "admin-login" };
  }

  // Readonly accounts only get the pages marked readonlyOk (Dashboard, Hasil
  // Survei Internal, Laporan and the department detail opened from Laporan).
  if (authStore.isReadonly && !to.matched.some((record) => record.meta.readonlyOk)) {
    return { name: "admin-dashboard" };
  }

  // Regular admins are sent back to the survey list instead of these pages.
  if (to.matched.some((record) => record.meta.requiresSuperAdmin) && !authStore.isSuperAdmin) {
    return { name: "admin-survey-management" };
  }

  return true;
});

export default router;
