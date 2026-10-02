<template>
  <header class="app-header">
    <div class="brand">
      <slot name="brand">
        <div class="brand-mark">
          <img src="/logo_skyvote.jpeg" alt="SkyVote" class="brand-mark-img" />
        </div>
        <div class="brand-text">
          <span class="brand-title">SkyVote</span>
        </div>
      </slot>
    </div>
    <div class="header-actions">
      <slot name="actions" />
    </div>
  </header>
</template>

<script setup></script>

<style scoped>
.app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  align-self: stretch;
  width: 100%;
  height: 64px;
  padding: 0 24px;
  background-color: var(--color-surface);
  box-shadow: var(--shadow-sm);
  position: relative;
  z-index: 10;
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
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
  box-shadow: 0 0 0 1px rgba(0, 93, 172, 0.12), 0 6px 16px rgba(0, 93, 172, 0.22);
  transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1), box-shadow 0.2s ease;
}

.brand:hover .brand-mark {
  transform: scale(1.05) rotate(-2deg);
  box-shadow: 0 0 0 1px rgba(0, 93, 172, 0.2), 0 8px 20px rgba(0, 93, 172, 0.3);
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
  background: linear-gradient(90deg, var(--color-primary) 0%, var(--color-primary-light) 60%, var(--color-accent-cyan-strong) 100%);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  font-family: var(--font-sans);
  font-size: 19px;
  font-weight: 800;
  letter-spacing: -0.02em;
  white-space: nowrap;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}
</style>
