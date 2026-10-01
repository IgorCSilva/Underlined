<template>
  <div class="avatar-picker">
    <button
      v-for="avatar in avatars"
      :key="avatar"
      type="button"
      class="avatar-option"
      :class="{ 'is-selected': modelValue === avatar }"
      :aria-pressed="modelValue === avatar"
      :aria-label="`Choose this avatar`"
      @click="$emit('update:modelValue', avatar)"
    >
      <img :src="avatar" alt="" />
    </button>
  </div>
</template>

<script setup lang="ts">
defineProps<{ modelValue: string | null }>()
defineEmits<{ 'update:modelValue': [value: string] }>()

const avatars = Array.from({ length: 10 }, (_, i) => `/avatars/avatar${i + 1}.jpg`)
</script>

<style scoped>
.avatar-picker {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.avatar-option {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  padding: 0;
  border: 2px solid transparent;
  overflow: hidden;
  cursor: pointer;
  background: var(--color-chip-fill);
  flex-shrink: 0;
}

.avatar-option img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.avatar-option.is-selected {
  border-color: var(--color-accent-secondary);
}
</style>
