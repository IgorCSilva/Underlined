<template>
  <div class="chip-row">
    <span v-for="(keyword, index) in modelValue" :key="keyword" class="chip">
      {{ keyword }}
      <button
        type="button"
        class="chip-remove"
        :aria-label="t('posts.composer.removeKeyword', { keyword })"
        @click="remove(index)"
      >
        ✕
      </button>
    </span>
    <input
      v-if="modelValue.length < max"
      v-model="draft"
      type="text"
      class="chip-input"
      :placeholder="modelValue.length === 0 ? t('posts.composer.keywordPlaceholder') : ''"
      :aria-label="t('posts.composer.keywordAriaLabel')"
      @keydown.enter.prevent="commit"
      @keydown.,.prevent="commit"
      @blur="commit"
    />
  </div>
</template>

<script setup lang="ts">
const { t } = useI18n()

const props = defineProps<{
  modelValue: string[]
  max?: number
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string[]]
}>()

const max = props.max ?? 8
const draft = ref('')

function commit() {
  const value = draft.value.trim()
  draft.value = ''
  if (!value || props.modelValue.length >= max) return
  if (props.modelValue.some((existing) => existing.toLowerCase() === value.toLowerCase())) return

  emit('update:modelValue', [...props.modelValue, value])
}

function remove(index: number) {
  emit(
    'update:modelValue',
    props.modelValue.filter((_, i) => i !== index),
  )
}
</script>

<style scoped>
.chip-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: var(--radius-pill);
  background: var(--color-chip-fill);
  color: var(--color-chip-text);
  font-size: 0.85rem;
  font-weight: 500;
}

.chip-remove {
  border: none;
  background: none;
  color: inherit;
  opacity: 0.6;
  font-size: 0.7rem;
  cursor: pointer;
  padding: 0;
  line-height: 1;
}

.chip-remove:hover {
  opacity: 1;
}

.chip-input {
  flex: 1;
  min-width: 120px;
  border: none;
  outline: none;
  font-family: var(--font-sans);
  font-size: 0.9rem;
  background: transparent;
  color: var(--color-ink);
  padding: 6px 4px;
}
</style>
