<template>
  <teleport to="body">
    <transition name="confirm-fade">
      <div v-if="visible" class="confirm-overlay" @click.self="$emit('cancel')">
        <div class="confirm-card" role="alertdialog" aria-modal="true">
          <div class="confirm-heading">
            <span v-if="danger" class="confirm-icon" aria-hidden="true">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
                <path
                  d="M10 2.2 18.5 17H1.5L10 2.2Z"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linejoin="round"
                />
                <path d="M10 7.8v3.6" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
                <circle cx="10" cy="14.2" r="0.9" fill="currentColor" />
              </svg>
            </span>
            <h2 class="confirm-title">{{ title }}</h2>
          </div>
          <p class="confirm-message">{{ message }}</p>
          <p v-if="note" class="confirm-note">{{ note }}</p>
          <div class="confirm-actions">
            <button type="button" class="confirm-btn confirm-btn-secondary" @click="$emit('cancel')">
              {{ cancelText }}
            </button>
            <button
              type="button"
              class="confirm-btn"
              :class="danger ? 'confirm-btn-danger' : 'confirm-btn-primary'"
              @click="$emit('confirm')"
            >
              {{ confirmText }}
            </button>
          </div>
        </div>
      </div>
    </transition>
  </teleport>
</template>

<script setup>
defineProps({
  visible: { type: Boolean, default: false },
  title: { type: String, default: "Konfirmasi" },
  message: { type: String, default: "Apakah Anda yakin?" },
  note: { type: String, default: "" },
  confirmText: { type: String, default: "Ya" },
  cancelText: { type: String, default: "Batal" },
  danger: { type: Boolean, default: false },
});
defineEmits(["confirm", "cancel"]);
</script>

<style scoped>
.confirm-overlay {
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

.confirm-card {
  width: 100%;
  max-width: 380px;
  background-color: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  padding: 24px;
  font-family: var(--font-sans);
}

.confirm-heading {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.confirm-icon {
  display: inline-flex;
  flex-shrink: 0;
  color: var(--color-danger);
}

.confirm-title {
  margin: 0;
  font-size: 17px;
  font-weight: 800;
  letter-spacing: -0.01em;
  color: var(--color-text);
}

.confirm-message {
  margin: 0;
  font-size: 14px;
  line-height: 1.5;
  color: var(--color-text-muted);
  white-space: pre-line;
}

.confirm-note {
  margin: 14px 0 0;
  padding: 10px 12px;
  border-radius: var(--radius-md);
  background-color: var(--color-danger-bg);
  border: 1px solid rgba(217, 45, 32, 0.2);
  color: var(--color-danger);
  font-size: 13px;
  font-weight: 600;
  line-height: 1.5;
}

.confirm-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 20px;
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

.confirm-btn-danger {
  background-color: var(--color-danger);
  color: #ffffff;
}

.confirm-btn-danger:hover {
  filter: brightness(0.92);
}

.confirm-fade-enter-active,
.confirm-fade-leave-active {
  transition: opacity 0.15s ease;
}

.confirm-fade-enter-from,
.confirm-fade-leave-to {
  opacity: 0;
}

.confirm-fade-enter-active .confirm-card,
.confirm-fade-leave-active .confirm-card {
  transition: transform 0.15s ease;
}

.confirm-fade-enter-from .confirm-card,
.confirm-fade-leave-to .confirm-card {
  transform: scale(0.96);
}
</style>
