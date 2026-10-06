<template>
  <div v-if="page" class="keyword-page">
    <h1 class="serif keyword-headline">{{ page.name }}</h1>

    <div class="keyword-stats">
      <span class="keyword-stat-badge">{{ t('keywords.stats.posts', { count: page.stats.post_count }) }}</span>
      <span class="keyword-stat-badge">{{ t('keywords.stats.books', { count: page.stats.book_count }) }}</span>
      <span class="keyword-stat-badge">{{ t('keywords.stats.readers', { count: page.stats.reader_count }) }}</span>
    </div>

    <div v-if="page.related_keywords.length" class="keyword-related">
      <span class="keyword-related-label">{{ t('keywords.related') }}</span>
      <div class="keyword-related-chips">
        <NuxtLink
          v-for="related in page.related_keywords"
          :key="related"
          :to="`/keywords/${encodeURIComponent(related)}`"
          class="keyword-related-chip"
        >
          {{ related }}
        </NuxtLink>
      </div>
    </div>

    <p v-if="!state.posts.length" class="status-text">{{ t('keywords.empty') }}</p>
    <div v-else class="feed-list">
      <PostFeedItem v-for="post in state.posts" :key="post.id" :post="post" />
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
  <p v-else class="status-text">{{ t('keywords.notFound') }}</p>
</template>

<script setup lang="ts">
import type { Post } from '~/stores/posts'

interface KeywordStats {
  post_count: number
  book_count: number
  reader_count: number
}

interface KeywordPage {
  name: string
  stats: KeywordStats
  related_keywords: string[]
  posts: Post[]
}

const PAGE_SIZE = 20
const route = useRoute()
const { t } = useI18n()
const auth = useAuthStore()
const apiPath = computed(() => `/api/keywords/${encodeURIComponent(String(route.params.name))}`)

const { data: page } = await useApiFetch<KeywordPage>(apiPath.value)

const state = reactive({
  posts: page.value?.posts ?? [],
  hasMore: (page.value?.posts.length ?? 0) === PAGE_SIZE,
  loadingMore: false,
})

// SSR always renders anonymous (no access token is available server-side),
// so a logged-in viewer's own likes/bookmarks never show up in the hydrated
// payload. Once the client is ready, re-fetch the first page with the auth
// header and correct it (without disturbing any pages already appended via
// "Load more", which already fetch authenticated).
onMounted(async () => {
  if (!auth.accessToken || !page.value) return
  const { request } = useApi()
  const fresh = await request<{ data: KeywordPage }>(apiPath.value)
  state.posts = fresh.data.posts
  state.hasMore = fresh.data.posts.length === PAGE_SIZE
})

async function loadMore() {
  const last = state.posts[state.posts.length - 1]
  if (!last) return

  state.loadingMore = true
  try {
    const { request } = useApi()
    const next = await request<{ data: KeywordPage }>(apiPath.value, {
      query: { before: last.inserted_at },
    })
    state.posts.push(...next.data.posts)
    state.hasMore = next.data.posts.length === PAGE_SIZE
  } finally {
    state.loadingMore = false
  }
}
</script>

<style scoped>
.keyword-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.keyword-headline {
  display: inline-block;
  margin: 0 0 24px;
  font-size: 2.2rem;
  text-transform: capitalize;
  text-decoration: underline solid var(--color-highlight) 4px;
  text-underline-offset: 10px;
}

.keyword-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 24px;
}

.keyword-stat-badge {
  border: 1px solid var(--color-border);
  background: var(--color-surface);
  border-radius: var(--radius-pill);
  padding: 6px 14px;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  color: var(--color-ink);
}

.keyword-related {
  margin-bottom: 32px;
}

.keyword-related-label {
  display: block;
  margin-bottom: 8px;
  font-size: 0.8rem;
  color: var(--color-text-secondary);
}

.keyword-related-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.keyword-related-chip {
  border: 1px solid var(--color-accent-secondary);
  color: var(--color-accent-secondary);
  background: transparent;
  padding: 4px 12px;
  border-radius: var(--radius-pill);
  font-size: 0.8rem;
  text-decoration: none;
}

.keyword-related-chip:hover {
  background: var(--color-accent-secondary);
  color: var(--color-surface);
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
  padding: 48px 24px;
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
