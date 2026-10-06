<template>
  <div v-if="readers.length" class="similar-readers">
    <NuxtLink v-for="reader in readers" :key="reader.id" :to="`/profile/${reader.id}`" class="similar-reader">
      <AvatarCircle :name="reader.name" :avatar-url="reader.avatar_url" :size="48" />
      <span class="shared-score-pill">{{ t('profile.sharedIdeas', { count: reader.shared_score }) }}</span>
    </NuxtLink>
  </div>
</template>

<script setup lang="ts">
import AvatarCircle from './AvatarCircle.vue'

export interface SimilarReader {
  id: string
  name: string
  avatar_url: string | null
  shared_score: number
}

defineProps<{ readers: SimilarReader[] }>()
const { t } = useI18n()
</script>

<style scoped>
.similar-readers {
  display: flex;
  gap: 20px;
  overflow-x: auto;
  padding-bottom: 4px;
}

.similar-reader {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
  text-decoration: none;
}

.shared-score-pill {
  background: var(--color-accent-primary);
  color: #fff;
  font-size: 0.7rem;
  font-weight: 600;
  padding: 3px 10px;
  border-radius: var(--radius-pill);
  white-space: nowrap;
}
</style>
