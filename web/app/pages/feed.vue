<template>
  <div class="feed-page">
    <h1 class="serif feed-title">The Feed</h1>

    <div v-if="auth.user" class="feed-tabs" role="tablist">
      <button
        type="button"
        class="feed-tab"
        :class="{ 'is-active': activeTab === 'for-you' }"
        role="tab"
        :aria-selected="activeTab === 'for-you'"
        @click="activeTab = 'for-you'"
      >
        For You
      </button>
      <button
        type="button"
        class="feed-tab"
        :class="{ 'is-active': activeTab === 'following' }"
        role="tab"
        :aria-selected="activeTab === 'following'"
        @click="activeTab = 'following'"
      >
        Following
      </button>
    </div>

    <p v-if="!activeState.posts.length" class="status-text">{{ emptyMessage }}</p>
    <div v-else class="feed-list">
      <PostFeedItem v-for="post in activeState.posts" :key="post.id" :post="post" />
    </div>

    <button
      v-if="activeState.hasMore"
      type="button"
      class="load-more"
      :disabled="activeState.loadingMore"
      @click="loadMore"
    >
      {{ activeState.loadingMore ? 'Loading…' : 'Load more' }}
    </button>
  </div>
</template>

<script setup lang="ts">
import type { Post } from '~/stores/posts'

const PAGE_SIZE = 20

interface FeedState {
  posts: Post[]
  hasMore: boolean
  loadingMore: boolean
  loaded: boolean
}

const auth = useAuthStore()

const { data: initialPosts } = await useApiFetch<Post[]>('/api/posts')

const forYou = reactive<FeedState>({
  posts: initialPosts.value ?? [],
  hasMore: (initialPosts.value?.length ?? 0) === PAGE_SIZE,
  loadingMore: false,
  loaded: true,
})

const following = reactive<FeedState>({ posts: [], hasMore: false, loadingMore: false, loaded: false })

const activeTab = ref<'for-you' | 'following'>('for-you')
const activeState = computed(() => (activeTab.value === 'for-you' ? forYou : following))
const activeUrl = computed(() => (activeTab.value === 'for-you' ? '/api/posts' : '/api/posts/following'))

const emptyMessage = computed(() =>
  activeTab.value === 'for-you' ? "Nothing's been published yet." : "No posts yet from people you follow.",
)

// SSR always renders anonymous (no access token is available server-side),
// so a logged-in viewer's own likes never show up in the hydrated payload.
// Once the client is ready, re-fetch the first page with the auth header and
// merge in the corrected like state (without disturbing any pages already
// appended via "Load more", which already fetch authenticated).
onMounted(async () => {
  if (!auth.accessToken || !forYou.posts.length) return
  const { request } = useApi()
  const fresh = await request<{ data: Post[] }>('/api/posts')
  const byId = new Map(fresh.data.map((post) => [post.id, post]))
  forYou.posts = forYou.posts.map((post) => byId.get(post.id) ?? post)
})

watch(activeTab, async (tab) => {
  const state = tab === 'for-you' ? forYou : following
  if (state.loaded) return
  state.loaded = true

  const { request } = useApi()
  const res = await request<{ data: Post[] }>(activeUrl.value)
  state.posts = res.data
  state.hasMore = res.data.length === PAGE_SIZE
})

async function loadMore() {
  const state = activeState.value
  const last = state.posts[state.posts.length - 1]
  if (!last) return

  state.loadingMore = true
  try {
    const { request } = useApi()
    const next = await request<{ data: Post[] }>(activeUrl.value, { query: { before: last.inserted_at } })
    state.posts.push(...next.data)
    state.hasMore = next.data.length === PAGE_SIZE
  } finally {
    state.loadingMore = false
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

.feed-tabs {
  display: flex;
  gap: 24px;
  margin-bottom: 24px;
}

.feed-tab {
  background: none;
  border: none;
  padding: 4px 0;
  font-family: var(--font-sans);
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.feed-tab.is-active {
  color: var(--color-ink);
  text-decoration: underline solid var(--color-highlight) 3px;
  text-underline-offset: 6px;
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
