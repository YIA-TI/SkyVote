<template>
  <transition name="toast-fade">
    <div v-if="toast.visible" class="toast" :class="toast.type">
      <span class="toast-icon">
        <svg
          v-if="toast.type === 'success'"
          width="16"
          height="16"
          viewBox="0 0 20 20"
          fill="none"
        >
          <path
            d="M16.6 5.6L8.3 13.9L4.4 10"
            stroke="white"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>
        <svg v-else width="16" height="16" viewBox="0 0 20 20" fill="none">
          <path
            d="M10 6v5m0 3h.01M18 10A8 8 0 1 1 2 10a8 8 0 0 1 16 0Z"
            stroke="white"
            stroke-width="1.6"
            stroke-linecap="round"
          />
        </svg>
      </span>
      <span class="toast-message">{{ toast.message }}</span>
    </div>
  </transition>
</template>

<script setup>
import { useToastStore } from "../stores/toastStore";

const toast = useToastStore();
</script>

<style scoped>
.toast {
  position: fixed;
  top: 80px;
  right: 24px;
  z-index: 1000;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  color: #ffffff;
  font-family: var(--font-sans);
  font-size: 14px;
  font-weight: 600;
}

.toast.success {
  background-color: var(--color-success);
}

.toast.error {
  background-color: var(--color-danger);
}

.toast.info {
  background-color: var(--color-primary);
}

.toast-icon {
  display: flex;
  align-items: center;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: all 0.25s ease;
}

.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
