<template>
  <span class="avatar-circle" :style="{ width: `${size}px`, height: `${size}px` }">
    <img v-if="avatarUrl" :src="avatarUrl" alt="" class="avatar-img" />
    <span v-else class="avatar-placeholder" :style="{ fontSize: `${size * 0.45}px` }">{{ initial }}</span>
  </span>
</template>

<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    name: string
    avatarUrl?: string | null
    size?: number
  }>(),
  { avatarUrl: null, size: 36 },
)

const initial = computed(() => props.name?.[0]?.toUpperCase() ?? '?')
</script>

<style scoped>
.avatar-circle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  flex-shrink: 0;
  overflow: hidden;
  background: var(--color-chip-fill);
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-placeholder {
  font-family: var(--font-serif);
  color: var(--color-chip-text);
}
</style>
