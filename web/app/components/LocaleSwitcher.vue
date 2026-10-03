<template>
  <select
    class="locale-switcher"
    :aria-label="t('nav.language')"
    :value="locale"
    @change="setLocale(($event.target as HTMLSelectElement).value)"
  >
    <option v-for="l in locales" :key="l.code" :value="l.code">
      {{ l.name }}
    </option>
  </select>
</template>

<script setup lang="ts">
const { t, locale, locales, setLocale } = useI18n()
</script>

<style scoped>
.locale-switcher {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  background: var(--color-surface);
  color: var(--color-text-secondary);
  font-size: 0.85rem;
  padding: 6px 10px;
  cursor: pointer;
}
</style>
