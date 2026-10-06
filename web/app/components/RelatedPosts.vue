<template>
  <div v-if="posts.length" class="related-posts">
    <h2 class="related-posts-label">{{ t('posts.related.title') }}</h2>
    <NuxtLink
      v-for="related in posts"
      :key="related.id"
      :to="`/posts/${related.id}`"
      class="related-post-row"
    >
      <p class="related-post-passage serif">{{ related.passage.text }}</p>
      <span class="related-post-book">{{ related.book.title }}</span>
    </NuxtLink>
  </div>
</template>

<script setup lang="ts">
import type { Post } from '~/stores/posts'

defineProps<{ posts: Post[] }>()
const { t } = useI18n()
</script>

<style scoped>
.related-posts {
  background: var(--color-highlight-fill);
  border-radius: var(--radius-card);
  padding: 24px;
  margin-top: 32px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.related-posts-label {
  margin: 0;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-ink);
}

.related-post-row {
  display: block;
  color: inherit;
  text-decoration: none;
}

.related-post-passage {
  margin: 0 0 4px;
  font-size: 0.95rem;
  line-height: 1.5;
  text-decoration: underline solid var(--color-highlight) 2px;
  text-underline-offset: 4px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.related-post-book {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}
</style>
