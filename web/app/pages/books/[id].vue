<template>
  <div v-if="page" class="book-page">
    <div class="book-header">
      <div class="book-cover">
        <img v-if="page.cover_url" :src="page.cover_url" alt="" />
        <span v-else class="book-cover-placeholder">📖</span>
      </div>
      <div class="book-header-info">
        <h1 class="serif book-title">{{ page.title }}</h1>
        <p class="book-author">{{ page.author }}</p>
        <NuxtLink
          v-if="page.series_name && page.series_position"
          :to="`/books?series=${encodeURIComponent(page.series_name)}`"
          class="book-series"
        >
          {{ t('books.page.seriesPosition', { position: page.series_position, series: page.series_name }) }}
        </NuxtLink>
        <div v-if="page.genres.length" class="genre-chips">
          <span v-for="genre in page.genres" :key="genre" class="genre-chip">{{ genre }}</span>
        </div>
        <div class="book-stats">
          <span class="book-stat-badge">{{ t('books.page.stats.posts', { count: page.stats.post_count }) }}</span>
          <span class="book-stat-badge">{{ t('books.page.stats.readers', { count: page.stats.reader_count }) }}</span>
        </div>
        <div v-if="auth.user" class="book-actions-row">
          <BookShelfControl :book-id="page.id" />
          <WishlistButton :book-id="page.id" />
        </div>
      </div>
    </div>

    <div class="club-section">
      <div class="club-section-header">
        <h2 class="serif club-section-title">{{ t('clubs.sectionTitle') }}</h2>
        <CreateClubButton :book-id="page.id" @created="onClubCreated" />
      </div>
      <p v-if="!clubs.length" class="club-section-empty">{{ t('clubs.empty') }}</p>
      <div v-else class="club-list">
        <ClubCard v-for="club in clubs" :key="club.id" :club="club" />
      </div>
    </div>

    <p v-if="!feedItems.length" class="status-text">{{ t('books.page.empty') }}</p>
    <div v-else class="feed-list">
      <template v-for="entry in feedItems" :key="entry.item.id">
        <PostFeedItem v-if="entry.type === 'post'" :post="entry.item" />
        <QuestionFeedItem v-else :question="entry.item" />
      </template>
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
  <p v-else class="status-text">{{ t('books.page.notFound') }}</p>
</template>

<script setup lang="ts">
import type { Club } from '~/stores/clubs'
import type { Post } from '~/stores/posts'
import type { Question } from '~/stores/questions'

interface BookStats {
  post_count: number
  reader_count: number
}

interface BookPage {
  id: string
  title: string
  author: string
  cover_url: string | null
  genres: string[]
  series_name: string | null
  series_position: number | null
  stats: BookStats
  posts: Post[]
  questions: Question[]
}

type FeedEntry = { type: 'post'; item: Post } | { type: 'question'; item: Question }

const PAGE_SIZE = 20
const route = useRoute()
const { t } = useI18n()
const auth = useAuthStore()
const apiPath = computed(() => `/api/books/${route.params.id}/page`)

const { data: page } = await useApiFetch<BookPage>(apiPath.value)

const state = reactive({
  posts: page.value?.posts ?? [],
  questions: page.value?.questions ?? [],
  hasMore: (page.value?.posts.length ?? 0) === PAGE_SIZE,
  loadingMore: false,
})

// Posts and questions are separate resources/tables (each with its own
// pagination needs), but the design calls for one interleaved,
// chronological feed — so they're merged client-side purely for display.
// Only `state.posts` grows via "load more"; `state.questions` is small
// enough to fetch in full on every page load (see BookController.page/2).
const feedItems = computed<FeedEntry[]>(() => {
  const postEntries: FeedEntry[] = state.posts.map((item) => ({ type: 'post', item }))
  const questionEntries: FeedEntry[] = state.questions.map((item) => ({ type: 'question', item }))
  return [...postEntries, ...questionEntries].sort(
    (a, b) => new Date(b.item.inserted_at).getTime() - new Date(a.item.inserted_at).getTime(),
  )
})

const { data: clubsData } = await useApiFetch<Club[]>(`/api/books/${route.params.id}/clubs`)
const clubs = ref<Club[]>(clubsData.value ?? [])

function onClubCreated(club: Club) {
  clubs.value = [club, ...clubs.value]
}

// SSR always renders anonymous (no access token is available server-side),
// so a logged-in viewer's own likes/bookmarks never show up in the hydrated
// payload. Once the client is ready, re-fetch the first page with the auth
// header and correct it (without disturbing any pages already appended via
// "Load more", which already fetch authenticated).
onMounted(async () => {
  await auth.ensureInitialized()
  if (!auth.accessToken || !page.value) return
  const { request } = useApi()
  const fresh = await request<{ data: BookPage }>(apiPath.value)
  state.posts = fresh.data.posts
  state.questions = fresh.data.questions
  state.hasMore = fresh.data.posts.length === PAGE_SIZE
})

async function loadMore() {
  const last = state.posts[state.posts.length - 1]
  if (!last) return

  state.loadingMore = true
  try {
    const { request } = useApi()
    const next = await request<{ data: BookPage }>(apiPath.value, {
      query: { before: last.inserted_at },
    })
    // `next.data.questions` is intentionally ignored — the full question
    // list for the book was already loaded on the first page and doesn't
    // paginate.
    state.posts.push(...next.data.posts)
    state.hasMore = next.data.posts.length === PAGE_SIZE
  } finally {
    state.loadingMore = false
  }
}
</script>

<style scoped>
.book-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.book-header {
  display: flex;
  gap: 24px;
  align-items: flex-start;
  margin-bottom: 40px;
}

.book-cover {
  flex: 0 0 160px;
  aspect-ratio: 2 / 3;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  background: var(--color-chip-fill);
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
}

.book-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.book-cover-placeholder {
  font-size: 2.5rem;
}

.book-header-info {
  flex: 1;
  padding-top: 8px;
}

.book-title {
  margin: 0 0 6px;
  font-size: 2rem;
}

.book-author {
  margin: 0 0 4px;
  color: var(--color-text-secondary);
}

.book-series {
  display: block;
  margin: 0 0 8px;
  font-size: 0.85rem;
  color: var(--color-text-secondary);
  text-decoration: none;
}

.book-series:hover {
  text-decoration: underline solid var(--color-highlight) 2px;
  text-underline-offset: 3px;
}

.genre-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 16px;
}

.genre-chip {
  display: inline-block;
  border: 1px solid var(--color-chip-text);
  border-radius: var(--radius-pill);
  padding: 3px 10px;
  color: var(--color-chip-text);
  background: transparent;
  font-size: 0.75rem;
}

.book-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.book-stat-badge {
  border: 1px solid var(--color-border);
  background: var(--color-surface);
  border-radius: var(--radius-pill);
  padding: 6px 14px;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  color: var(--color-ink);
}

.book-actions-row {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-top: 16px;
}

.club-section {
  margin-bottom: 40px;
}

.club-section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
}

.club-section-title {
  margin: 0;
  font-size: 1.3rem;
}

.club-section-empty {
  color: var(--color-text-secondary);
}

.club-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
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
