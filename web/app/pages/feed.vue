<template>
  <div class="feed-page">
    <h1 class="serif feed-title">The Feed</h1>

    <p v-if="!posts.length" class="status-text">Nothing's been published yet.</p>
    <div v-else class="feed-list">
      <PostFeedItem v-for="post in posts" :key="post.id" :post="post" />
    </div>

    <button v-if="hasMore" type="button" class="load-more" :disabled="loadingMore" @click="loadMore">
      {{ loadingMore ? 'Loading…' : 'Load more' }}
    </button>
  </div>
</template>

<script setup lang="ts">
import type { Post } from '~/stores/posts'

const PAGE_SIZE = 20

const { data: initialPosts } = await useApiFetch<Post[]>('/api/posts')

const posts = ref<Post[]>(initialPosts.value ?? [])
const hasMore = ref(posts.value.length === PAGE_SIZE)
const loadingMore = ref(false)

async function loadMore() {
  const last = posts.value[posts.value.length - 1]
  if (!last) return

  loadingMore.value = true
  try {
    const next = await $fetch<{ data: Post[] }>('/api/posts', {
      baseURL: apiBaseUrl(),
      query: { before: last.inserted_at },
    })
    posts.value.push(...next.data)
    hasMore.value = next.data.length === PAGE_SIZE
  } finally {
    loadingMore.value = false
  }
}
</script>

<style scoped>
.feed-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.feed-title {
  margin: 0 0 24px;
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
}

.load-more {
  display: block;
  margin: 24px auto 0;
  background: none;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 10px 24px;
  font-family: var(--font-sans);
  font-size: 0.9rem;
  color: var(--color-accent-secondary);
  cursor: pointer;
}

.load-more:hover:not(:disabled) {
  border-color: var(--color-accent-secondary);
}

.load-more:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
