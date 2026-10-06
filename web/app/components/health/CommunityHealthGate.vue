<template>
  <span class="ch-gate" :class="{ 'is-unavailable': !available }" :title="!available ? t('communityHealth.unavailable') : undefined">
    <slot />
  </span>
</template>

<script setup lang="ts">
defineProps<{ available: boolean }>()
const { t } = useI18n()
</script>

<style scoped>
.ch-gate {
  display: inline-flex;
}

.ch-gate.is-unavailable {
  opacity: 0.4;
  filter: grayscale(1);
  pointer-events: none;
  cursor: not-allowed;
}
</style>
