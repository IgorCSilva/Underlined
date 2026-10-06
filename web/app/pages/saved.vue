<template>
  <div class="saved-page">
    <h1 class="serif saved-title">{{ t('saved.title') }}</h1>

    <p v-if="state.loaded && !state.posts.length" class="status-text">{{ t('saved.empty') }}</p>
    <div v-else class="feed-list">
      <PostFeedItem v-for="post in state.posts" :key="post.id" :post="post" show-saved-badge />
    </div>

    <button
      v-if="state.hasMore"
      type="button"
      class="load-more"
      :disabled="state.loadingMore"
      @click="loadMore"
    >
      {{ state.loadingMore ? t('feed.loading') : t('feed.loadMore') }}
    </button>
  </div>
</template>

<script setup lang="ts">
import type { Post } from '~/stores/posts'

definePageMeta({ middleware: 'auth' })

const PAGE_SIZE = 20

interface SavedState {
  posts: Post[]
  hasMore: boolean
  loadingMore: boolean
  loaded: boolean
}

const { t } = useI18n()
const { request } = useApi()

const state = reactive<SavedState>({ posts: [], hasMore: false, loadingMore: false, loaded: false })

// This page is auth-gated and always renders for a logged-in user, so unlike
// `feed.vue`'s public tab there's no SSR-anonymous payload to correct —
// fetch once client-side, after the `auth` middleware has already resolved
// the access token.
onMounted(async () => {
  const res = await request<{ data: Post[] }>('/api/me/bookmarks')
  state.posts = res.data
  state.hasMore = res.data.length === PAGE_SIZE
  state.loaded = true
})

async function loadMore() {
  const last = state.posts[state.posts.length - 1]
  if (!last) return

  state.loadingMore = true
  try {
    const next = await request<{ data: Post[] }>('/api/me/bookmarks', {
      query: { before: last.inserted_at },
    })
    state.posts.push(...next.data)
    state.hasMore = next.data.length === PAGE_SIZE
  } finally {
    state.loadingMore = false
  }
}
</script>

<style scoped>
.saved-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.saved-title {
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
