<template>
  <div class="loading" role="status" aria-live="polite">
    <span class="loading-ring" aria-hidden="true" />
    <span class="loading-label">{{ label }}</span>
  </div>
</template>

<script setup>
defineProps({
  label: { type: String, default: "Memuat data..." },
});
</script>

<style scoped>
.loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 32px 16px;
  color: var(--color-text-muted);
  font-size: 13px;
  font-weight: 600;
}

.loading-ring {
  flex-shrink: 0;
  width: 20px;
  height: 20px;
  border: 2.5px solid var(--color-border-strong);
  border-top-color: var(--color-primary);
  border-radius: 50%;
  animation: loading-spin 0.7s linear infinite;
}

@keyframes loading-spin {
  to {
    transform: rotate(360deg);
  }
}

/* No spinning for people who ask for less motion; the text still says it. */
@media (prefers-reduced-motion: reduce) {
  .loading-ring {
    animation: none;
    border-top-color: var(--color-border-strong);
  }
}
</style>
