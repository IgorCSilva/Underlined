<template>
  <span class="ch-gate" :class="{ 'is-unavailable': !available }" :title="!available ? t('communityHealth.unavailable') : undefined">
    <span class="ch-gate-content">
      <slot />
    </span>
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
  cursor: not-allowed;
}

/* pointer-events: none goes on the inner wrapper, not the outer span: the
   outer span carries `title` for the hover tooltip, and an element with
   pointer-events: none never registers :hover — put it there and the
   tooltip can never show. */
.ch-gate.is-unavailable .ch-gate-content {
  pointer-events: none;
}
</style>
