<template>
  <div class="discussion-feed">
    <form v-if="canPost" class="post-composer" @submit.prevent="onSubmit">
      <textarea
        v-model="body"
        class="post-composer-input"
        rows="2"
        :placeholder="t('clubs.discussion.addPlaceholder')"
        :aria-label="t('clubs.discussion.addPlaceholder')"
        :disabled="pending"
      />
      <div class="post-composer-row">
        <select v-if="chapters.length" v-model="chapterId" class="post-composer-chapter" :disabled="pending">
          <option value="">{{ t('clubs.discussion.generalHeading') }}</option>
          <option v-for="chapter in chapters" :key="chapter.id" :value="chapter.id">{{ chapter.label }}</option>
        </select>
        <button type="submit" class="post-composer-submit" :disabled="pending || !body.trim()">
          {{ t('clubs.discussion.post') }}
        </button>
      </div>
      <p v-if="error" class="post-composer-error">{{ error }}</p>
    </form>

    <p v-if="!posts.length" class="discussion-empty">{{ t('clubs.discussion.empty') }}</p>

    <div v-for="group in groups" :key="group.key" class="discussion-group">
      <h3 class="serif discussion-group-title">{{ group.label }}</h3>

      <div v-for="post in group.posts" :key="post.id" class="discussion-post">
        <div class="discussion-post-meta">
          <AvatarCircle :name="post.user.name" :avatar-url="post.user.avatar_url" :size="28" />
          <NuxtLink :to="`/profile/${post.user.id}`" class="discussion-post-author">{{ post.user.name }}</NuxtLink>
          <span class="discussion-post-date">{{ formatDate(post.inserted_at, { year: 'numeric', month: 'short', day: 'numeric' }) }}</span>
        </div>
        <div v-if="isBlocked(post)" class="discussion-post-spoiler">
          <span class="discussion-post-spoiler-icon" aria-hidden="true">🔒</span>
          <p class="discussion-post-spoiler-text">
            {{ t('clubs.spoiler.blocked', { label: post.chapter?.label }) }}
          </p>
          <button
            type="button"
            class="discussion-post-spoiler-reveal"
            :disabled="revealing.has(post.id)"
            @click="revealPost(post)"
          >
            {{ t('clubs.spoiler.revealAnyway') }}
          </button>
        </div>

        <template v-else>
          <p class="discussion-post-body">{{ displayBody(post) }}</p>

          <button type="button" class="discussion-post-comments-toggle" @click="toggleComments(post)">
            {{ t('clubs.discussion.commentCount', { count: post.comment_count }) }}
          </button>

          <div v-if="expanded.has(post.id)" class="discussion-post-comments">
            <CommentThread
              :base-path="`/api/club_posts/${post.id}`"
              :comments="loadedComments[post.id] ?? []"
              @comment-added="post.comment_count++"
            />
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Comment } from '~/stores/comments'
import type { ClubChapter, ClubPost } from '~/stores/clubs'

const props = defineProps<{ clubId: string; posts: ClubPost[]; chapters: ClubChapter[]; canPost: boolean }>()
const emit = defineEmits<{ 'post-added': [post: ClubPost] }>()

const { t } = useI18n()
const { formatDate } = useLocaleFormat()
const clubs = useClubsStore()

const body = ref('')
const chapterId = ref('')
const pending = ref(false)
const error = ref('')

const expanded = ref(new Set<string>())
const loadedComments = reactive<Record<string, Comment[]>>({})

const revealing = ref(new Set<string>())
const revealedBodies = reactive<Record<string, string>>({})

function isBlocked(post: ClubPost) {
  return post.spoiler_blocked && !(post.id in revealedBodies)
}

function displayBody(post: ClubPost) {
  return revealedBodies[post.id] ?? post.body ?? ''
}

async function revealPost(post: ClubPost) {
  if (revealing.value.has(post.id)) return
  revealing.value = new Set(revealing.value).add(post.id)
  try {
    const full = await clubs.revealPost(post.id)
    revealedBodies[post.id] = full.body ?? ''
  } finally {
    revealing.value = new Set(revealing.value)
    revealing.value.delete(post.id)
  }
}

interface Group {
  key: string
  label: string
  posts: ClubPost[]
}

const groups = computed<Group[]>(() => {
  const result: Group[] = []
  for (const post of props.posts) {
    const key = post.chapter?.id ?? 'general'
    const label = post.chapter?.label ?? t('clubs.discussion.generalHeading')
    const last = result[result.length - 1]
    if (last && last.key === key) {
      last.posts.push(post)
    } else {
      result.push({ key, label, posts: [post] })
    }
  }
  return result
})

async function toggleComments(post: ClubPost) {
  if (expanded.value.has(post.id)) {
    expanded.value.delete(post.id)
    expanded.value = new Set(expanded.value)
    return
  }

  if (!loadedComments[post.id]) {
    const { request } = useApi()
    const res = await request<{ data: Comment[] }>(`/api/club_posts/${post.id}/comments`)
    loadedComments[post.id] = res.data
  }

  expanded.value = new Set(expanded.value).add(post.id)
}

async function onSubmit() {
  if (pending.value || !body.value.trim()) return
  pending.value = true
  error.value = ''
  try {
    const post = await clubs.createPost(props.clubId, {
      body: body.value.trim(),
      chapter_id: chapterId.value || undefined,
    })
    body.value = ''
    chapterId.value = ''
    emit('post-added', post)
  } catch (err) {
    error.value = extractErrorMessage(err, t)
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.post-composer {
  margin-bottom: 28px;
  padding: 16px;
  border: 1px solid var(--color-border);
  border-radius: 12px;
  background: var(--color-surface);
}

.post-composer-input {
  width: 100%;
  resize: vertical;
  border: none;
  font-family: var(--font-sans);
  font-size: 0.9rem;
  color: var(--color-ink);
  background: none;
}

.post-composer-input:focus {
  outline: none;
}

.post-composer-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-top: 8px;
}

.post-composer-chapter {
  flex: 1;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 6px 12px;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  background: var(--color-surface);
  color: var(--color-ink);
}

.post-composer-submit {
  flex-shrink: 0;
  background: var(--color-accent-primary);
  color: #fff;
  border: none;
  border-radius: var(--radius-pill);
  font-family: var(--font-sans);
  font-weight: 700;
  font-size: 0.85rem;
  padding: 8px 18px;
  cursor: pointer;
}

.post-composer-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.post-composer-error {
  margin: 8px 0 0;
  color: var(--color-accent-primary);
  font-size: 0.8rem;
}

.discussion-empty {
  color: var(--color-text-secondary);
  text-align: center;
  padding: 24px 0;
}

.discussion-group {
  margin-bottom: 32px;
}

.discussion-group-title {
  font-size: 1.1rem;
  margin: 0 0 16px;
  display: inline-block;
  text-decoration: underline solid var(--color-highlight) 3px;
  text-underline-offset: 6px;
}

.discussion-post {
  padding: 16px 0;
  border-bottom: 1px solid var(--color-border);
}

.discussion-post:last-child {
  border-bottom: none;
}

.discussion-post-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.discussion-post-author {
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--color-ink);
  text-decoration: none;
}

.discussion-post-author:hover {
  text-decoration: underline;
}

.discussion-post-date {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.discussion-post-body {
  margin: 0 0 8px;
  font-size: 0.9rem;
  line-height: 1.5;
  color: var(--color-ink);
  white-space: pre-wrap;
}

.discussion-post-comments-toggle {
  background: none;
  border: none;
  padding: 0;
  color: var(--color-accent-secondary);
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
}

.discussion-post-comments {
  margin-top: 10px;
}

.discussion-post-spoiler {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  min-height: 72px;
  justify-content: center;
  padding: 20px 16px;
  border-radius: 12px;
  background: rgba(250, 247, 241, 0.85);
  backdrop-filter: blur(6px);
  border: 1px solid var(--color-border);
  text-align: center;
}

.discussion-post-spoiler-icon {
  font-size: 1.4rem;
}

.discussion-post-spoiler-text {
  margin: 0;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.discussion-post-spoiler-reveal {
  background: none;
  border: 1.5px solid var(--color-accent-primary);
  border-radius: var(--radius-pill);
  color: var(--color-accent-primary);
  font-family: var(--font-sans);
  font-weight: 600;
  font-size: 0.8rem;
  padding: 6px 16px;
  cursor: pointer;
}

.discussion-post-spoiler-reveal:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
