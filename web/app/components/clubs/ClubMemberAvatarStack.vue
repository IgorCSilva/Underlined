<template>
  <div class="avatar-stack">
    <AvatarCircle
      v-for="member in visibleMembers"
      :key="member.id"
      :name="member.name"
      :avatar-url="member.avatar_url"
      :size="size"
      class="avatar-stack-item"
    />
    <span v-if="remaining > 0" class="avatar-stack-more" :style="{ width: `${size}px`, height: `${size}px` }">
      +{{ remaining }}
    </span>
  </div>
</template>

<script setup lang="ts">
import type { ClubMember } from '~/stores/clubs'

const props = withDefaults(
  defineProps<{
    members: ClubMember[]
    totalCount: number
    size?: number
    visibleLimit?: number
  }>(),
  { size: 32, visibleLimit: 4 },
)

const visibleMembers = computed(() => props.members.slice(0, props.visibleLimit))
const remaining = computed(() => Math.max(props.totalCount - visibleMembers.value.length, 0))
</script>

<style scoped>
.avatar-stack {
  display: flex;
  align-items: center;
}

.avatar-stack-item {
  border: 2px solid var(--color-surface);
  margin-left: -10px;
}

.avatar-stack-item:first-child {
  margin-left: 0;
}

.avatar-stack-more {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-left: -10px;
  border: 2px solid var(--color-surface);
  border-radius: 50%;
  background: var(--color-chip-fill);
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 0.7rem;
  font-weight: 600;
  flex-shrink: 0;
}
</style>
