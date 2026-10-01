<template>
  <div v-if="post" class="post-detail-page">
    <div class="post-meta">
      <AvatarCircle :name="post.user.name" :avatar-url="post.user.avatar_url" :size="36" />
      <div class="post-meta-text">
        <span class="post-username">{{ post.user.name }}</span>
        <span class="post-date">{{ formattedDate }}</span>
      </div>
    </div>

    <div class="passage-hero">
      <div class="passage-book">
        <span class="passage-book-cover">
          <img v-if="post.book.cover_url" :src="post.book.cover_url" alt="" />
          <span v-else class="passage-book-placeholder">📖</span>
        </span>
        <span class="passage-book-title serif">{{ post.book.title }}</span>
        <span class="passage-book-author">{{ post.book.author }}</span>
      </div>
      <p class="passage-text serif">{{ post.passage.text }}</p>
    </div>

    <div class="thinking-card">
      <p class="thinking-text serif">{{ post.thinking }}</p>
    </div>

    <div v-if="post.keywords.length" class="post-keywords">
      <span v-for="keyword in post.keywords" :key="keyword" class="post-keyword-chip">{{ keyword }}</span>
    </div>

    <div class="post-icon-row">
      <span class="post-icon">♡ 0</span>
      <span class="post-icon">💬 0</span>
    </div>
  </div>
  <p v-else class="status-text">Post not found.</p>
</template>

<script setup lang="ts">
import type { Post } from '~/stores/posts'

const route = useRoute()

const { data: post } = await useApiFetch<Post>(`/api/posts/${route.params.id}`)

const formattedDate = computed(() => {
  if (!post.value) return ''
  return new Date(post.value.inserted_at).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
})
</script>

<style scoped>
.post-detail-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
  padding: 48px 24px;
}

.post-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
}

.post-meta-text {
  display: flex;
  flex-direction: column;
  line-height: 1.3;
}

.post-username {
  font-weight: 600;
  color: var(--color-ink);
}

.post-date {
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.passage-hero {
  display: flex;
  gap: 24px;
  align-items: flex-start;
  background: var(--color-highlight-fill);
  border-radius: var(--radius-card);
  padding: 32px;
  margin-bottom: 20px;
}

.passage-book {
  flex: 0 0 96px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 6px;
}

.passage-book-cover {
  width: 64px;
  height: 96px;
  border-radius: 4px;
  overflow: hidden;
  border: 1px solid var(--color-border);
  background: var(--color-chip-fill);
  display: flex;
  align-items: center;
  justify-content: center;
}

.passage-book-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.passage-book-placeholder {
  font-size: 1.5rem;
}

.passage-book-title {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-ink);
}

.passage-book-author {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.passage-text {
  flex: 1;
  margin: 0;
  font-size: 1.4rem;
  line-height: 1.6;
  text-decoration: underline wavy var(--color-highlight) 2px;
  text-underline-offset: 8px;
}

.thinking-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-left: 4px solid var(--color-accent-secondary);
  border-radius: var(--radius-card);
  padding: 24px;
  margin-bottom: 20px;
}

.thinking-text {
  margin: 0;
  font-size: 1.1rem;
  line-height: 1.6;
}

.post-keywords {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 20px;
}

.post-keyword-chip {
  background: var(--color-chip-fill);
  color: var(--color-chip-text);
  padding: 5px 12px;
  border-radius: var(--radius-pill);
  font-size: 0.8rem;
}

.post-icon-row {
  display: flex;
  gap: 20px;
  color: var(--color-accent-secondary);
  font-size: 0.9rem;
}
</style>
