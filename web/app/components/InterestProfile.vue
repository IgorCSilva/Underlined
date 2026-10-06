<template>
  <div v-if="profile.length" class="interest-profile">
    <div v-for="entry in profile" :key="entry.keyword" class="interest-row">
      <span class="interest-keyword">{{ entry.keyword }}</span>
      <span class="interest-track">
        <span class="interest-bar" :style="{ width: `${barWidth(entry.post_count)}%` }" />
      </span>
      <span class="interest-count">{{ entry.post_count }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
export interface InterestEntry {
  keyword: string
  post_count: number
}

const props = defineProps<{ profile: InterestEntry[] }>()

const maxCount = computed(() => Math.max(1, ...props.profile.map((entry) => entry.post_count)))

function barWidth(count: number): number {
  return Math.max(6, Math.round((count / maxCount.value) * 100))
}
</script>

<style scoped>
.interest-profile {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.interest-row {
  display: grid;
  grid-template-columns: 120px 1fr 32px;
  align-items: center;
  gap: 12px;
}

.interest-keyword {
  font-size: 0.85rem;
  color: var(--color-ink);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.interest-track {
  display: block;
  height: 8px;
  border-radius: var(--radius-pill);
  background: var(--color-chip-fill);
  overflow: hidden;
}

.interest-bar {
  display: block;
  height: 100%;
  border-radius: var(--radius-pill);
  background: linear-gradient(to right, var(--color-accent-secondary), var(--color-accent-primary));
}

.interest-count {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
  text-align: right;
}
</style>
