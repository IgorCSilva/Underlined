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
      <button v-if="isOwnPost && !editing" type="button" class="post-edit-toggle" @click="startEdit">
        {{ t('posts.detail.edit') }}
      </button>
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
      <p v-if="!editing" class="passage-text serif">{{ post.passage.text }}</p>
      <textarea
        v-else
        v-model="editPassage"
        class="passage-text-input serif"
        maxlength="300"
        :aria-label="t('posts.detail.passageEditAriaLabel')"
        :disabled="editPending"
      />
    </div>

    <div class="thinking-card">
      <p v-if="!editing" class="thinking-text serif">{{ post.thinking }}</p>
      <textarea
        v-else
        v-model="editThinking"
        class="thinking-text-input serif"
        :aria-label="t('posts.detail.thinkingEditAriaLabel')"
        :disabled="editPending"
      />
    </div>

    <div v-if="editing" class="post-edit-controls">
      <button
        type="button"
        class="btn-primary post-edit-save"
        :disabled="editPending || !editPassage.trim() || !editThinking.trim()"
        @click="onEditSave"
      >
        {{ editPending ? t('posts.detail.saving') : t('posts.detail.save') }}
      </button>
      <button type="button" class="post-edit-cancel" @click="cancelEdit">{{ t('posts.detail.cancel') }}</button>
      <p v-if="editError" class="form-error">{{ editError }}</p>
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
const posts = usePostsStore()

const { data: post } = await useApiFetch<Post>(`/api/posts/${route.params.id}`)
const { data: comments } = await useApiFetch<Comment[]>(`/api/posts/${route.params.id}/comments`)
const { data: relatedPosts } = await useApiFetch<Post[]>(`/api/posts/${route.params.id}/related`)

// SSR always renders anonymous (no access token is available server-side),
// so a logged-in viewer's own like never shows up in the hydrated payload.
// Once the client is ready, re-fetch with the auth header to correct it.
//
// Must wait for the session restore first: `onMounted` fires well before
// the auth plugin's `ensureInitialized()` (deferred to `onNuxtReady`), so
// checking `auth.accessToken` immediately here almost always sees it still
// null and skips the re-fetch — leaving `liked_by_user` stuck at the
// anonymous `false` for the rest of the page's life, even though the user
// really has liked the post (the next like-button click then wrongly tries
// to "like" an already-liked post instead of unliking it).
const auth = useAuthStore()
onMounted(async () => {
  await auth.ensureInitialized()
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

const isOwnPost = computed(() => !!post.value && auth.user?.id === post.value.user.id)

const editing = ref(false)
const editPassage = ref('')
const editThinking = ref('')
const editPending = ref(false)
const editError = ref('')

function startEdit() {
  if (!post.value) return
  editPassage.value = post.value.passage.text
  editThinking.value = post.value.thinking
  editError.value = ''
  editing.value = true
}

function cancelEdit() {
  editing.value = false
}

async function onEditSave() {
  if (!post.value || editPending.value) return
  const passageText = editPassage.value.trim()
  const thinking = editThinking.value.trim()
  if (!passageText || !thinking) return

  editPending.value = true
  editError.value = ''
  try {
    const updated = await posts.updatePost(post.value.id, { passage_text: passageText, thinking })
    post.value = { ...post.value, passage: updated.passage, thinking: updated.thinking }
    editing.value = false
  } catch (err) {
    editError.value = extractErrorMessage(err, t)
  } finally {
    editPending.value = false
  }
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

.post-edit-toggle {
  margin-left: auto;
  background: none;
  border: none;
  padding: 0;
  color: var(--color-accent-secondary);
  font-family: var(--font-sans);
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
}

.passage-text-input {
  flex: 1;
  margin: 0;
  width: 100%;
  min-height: 80px;
  font-size: 1.4rem;
  line-height: 1.6;
  font-family: inherit;
  color: inherit;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-card);
  padding: 12px 16px;
  resize: vertical;
}

.passage-text-input:focus {
  outline: none;
  border-color: var(--color-highlight);
}

.thinking-text-input {
  width: 100%;
  min-height: 100px;
  margin: 0;
  font-size: 1.1rem;
  line-height: 1.6;
  font-family: inherit;
  color: inherit;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-card);
  padding: 12px 16px;
  resize: vertical;
}

.thinking-text-input:focus {
  outline: none;
  border-color: var(--color-highlight);
}

.post-edit-controls {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 20px;
}

.post-edit-save {
  width: auto;
  padding: 10px 24px;
}

.post-edit-cancel {
  background: none;
  border: none;
  padding: 0;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 0.9rem;
  cursor: pointer;
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
  white-space: pre-line;
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
  white-space: pre-line;
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
