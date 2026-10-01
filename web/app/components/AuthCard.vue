<template>
  <div class="auth-shell">
    <div class="auth-card card">
      <h1 class="serif auth-title">{{ title }}</h1>
      <slot />
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{ title: string }>()
</script>

<style scoped>
.auth-shell {
  min-height: calc(100vh - var(--topbar-height));
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.auth-card {
  width: 100%;
  max-width: 400px;
  padding: 32px;
  text-align: center;
}

.auth-title {
  margin: 0 0 24px;
  font-size: 1.5rem;
}
</style>
