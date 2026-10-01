<template>
  <NuxtLink :to="`/posts/${post.id}`" class="feed-item">
    <div class="feed-meta">
      <AvatarCircle :name="post.user.name" :avatar-url="post.user.avatar_url" :size="28" />
      <span class="feed-meta-text">
        <span class="feed-username">{{ post.user.name }}</span>
        on <span class="feed-book-title">{{ post.book.title }}</span>
      </span>
    </div>

    <p class="feed-passage serif">{{ post.passage.text }}</p>
    <p class="feed-thinking serif">{{ post.thinking }}</p>

    <div v-if="post.keywords.length" class="feed-keywords">
      <span v-for="keyword in post.keywords" :key="keyword" class="feed-keyword-chip">{{ keyword }}</span>
    </div>

    <div class="feed-icon-row">
      <span class="feed-icon">♡ 0</span>
      <span class="feed-icon">💬 0</span>
    </div>
  </NuxtLink>
</template>

<script setup lang="ts">
import type { Post } from '~/stores/posts'

defineProps<{ post: Post }>()
</script>

<style scoped>
.feed-item {
  display: block;
  padding: 24px 0;
  border-bottom: 1px solid var(--color-border);
  color: inherit;
  text-decoration: none;
}

.feed-item:last-child {
  border-bottom: none;
}

.feed-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.feed-username {
  font-weight: 600;
  color: var(--color-ink);
}

.feed-book-title {
  font-weight: 600;
}

.feed-passage {
  margin: 0 0 8px;
  font-size: 1.05rem;
  line-height: 1.6;
  text-decoration: underline wavy var(--color-highlight) 2px;
  text-underline-offset: 6px;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.feed-thinking {
  margin: 0 0 12px;
  font-style: italic;
  font-size: 0.95rem;
  color: var(--color-ink);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.feed-keywords {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 12px;
}

.feed-keyword-chip {
  background: var(--color-chip-fill);
  color: var(--color-chip-text);
  padding: 4px 10px;
  border-radius: var(--radius-pill);
  font-size: 0.75rem;
}

.feed-icon-row {
  display: flex;
  gap: 16px;
  color: var(--color-accent-secondary);
  font-size: 0.85rem;
}
</style>
