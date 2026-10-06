<template>
  <div v-if="post" class="post-detail-page">
    <div class="post-meta">
      <NuxtLink :to="`/profile/${post.user.id}`" class="post-avatar-link">
        <AvatarCircle :name="post.user.name" :avatar-url="post.user.avatar_url" :size="36" />
      </NuxtLink>
      <div class="post-meta-text">
        <NuxtLink :to="`/profile/${post.user.id}`" class="post-username">{{ post.user.name }}</NuxtLink>
        <span class="post-date">{{ formattedDate }}</span>
      </div>
    </div>

    <div class="passage-hero">
      <NuxtLink :to="`/books/${post.book.id}`" class="passage-book">
        <span class="passage-book-cover">
          <img v-if="post.book.cover_url" :src="post.book.cover_url" alt="" />
          <span v-else class="passage-book-placeholder">📖</span>
        </span>
        <span class="passage-book-title serif">{{ post.book.title }}</span>
        <span class="passage-book-author">{{ post.book.author }}</span>
      </NuxtLink>
      <p class="passage-text serif">{{ post.passage.text }}</p>
    </div>

    <div class="thinking-card">
      <p class="thinking-text serif">{{ post.thinking }}</p>
    </div>

    <div v-if="post.keywords.length" class="post-keywords">
      <NuxtLink
        v-for="keyword in post.keywords"
        :key="keyword"
        :to="`/keywords/${encodeURIComponent(keyword)}`"
        class="post-keyword-chip"
      >
        {{ keyword }}
      </NuxtLink>
    </div>

    <div class="post-icon-row">
      <LikeButton :post-id="post.id" :liked-by-user="post.liked_by_user" :like-count="post.like_count" />
      <span class="post-icon">💬 {{ post.comment_count }}</span>
      <ReportButton resource-type="post" :resource-id="post.id" />
    </div>

    <CommentThread :post-id="post.id" :comments="comments ?? []" @comment-added="onCommentAdded" />

    <RelatedPosts :posts="relatedPosts ?? []" />
  </div>
  <p v-else class="status-text">{{ t('posts.detail.notFound') }}</p>
</template>

<script setup lang="ts">
import type { Post } from '~/stores/posts'
import type { Comment } from '~/stores/comments'

const route = useRoute()
const { t } = useI18n()

const { data: post } = await useApiFetch<Post>(`/api/posts/${route.params.id}`)
const { data: comments } = await useApiFetch<Comment[]>(`/api/posts/${route.params.id}/comments`)
const { data: relatedPosts } = await useApiFetch<Post[]>(`/api/posts/${route.params.id}/related`)

// SSR always renders anonymous (no access token is available server-side),
// so a logged-in viewer's own like never shows up in the hydrated payload.
// Once the client is ready, re-fetch with the auth header to correct it.
const auth = useAuthStore()
onMounted(async () => {
  if (!auth.accessToken || !post.value) return
  const { request } = useApi()
  const fresh = await request<{ data: Post }>(`/api/posts/${route.params.id}`)
  post.value = fresh.data
})

// `post` is a shallowRef (Nuxt's useFetch), so an in-place mutation like
// `post.value.comment_count++` would not trigger reactivity — reassign
// `.value` instead.
function onCommentAdded() {
  if (!post.value) return
  post.value = { ...post.value, comment_count: post.value.comment_count + 1 }
}

const { formatDate } = useLocaleFormat()

const formattedDate = computed(() => {
  if (!post.value) return ''
  return formatDate(post.value.inserted_at, {
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

.post-avatar-link {
  display: inline-flex;
}

.post-meta-text {
  display: flex;
  flex-direction: column;
  line-height: 1.3;
}

.post-username {
  font-weight: 600;
  color: var(--color-ink);
  text-decoration: none;
}

.post-username:hover {
  text-decoration: underline;
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
  color: inherit;
  text-decoration: none;
}

.passage-book:hover .passage-book-title {
  text-decoration: underline solid var(--color-highlight) 2px;
  text-underline-offset: 3px;
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
  text-decoration: underline solid var(--color-highlight) 2px;
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
  text-decoration: none;
}

.post-keyword-chip:hover {
  text-decoration: underline solid var(--color-highlight) 2px;
  text-underline-offset: 3px;
}

.post-icon-row {
  display: flex;
  gap: 20px;
  color: var(--color-accent-secondary);
  font-size: 0.9rem;
}
</style>
