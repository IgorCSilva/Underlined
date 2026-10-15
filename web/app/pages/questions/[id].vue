<template>
  <div v-if="question" class="question-detail-page">
    <div class="question-meta">
      <NuxtLink :to="`/profile/${question.user.id}`" class="question-avatar-link">
        <AvatarCircle :name="question.user.name" :avatar-url="question.user.avatar_url" :size="36" />
      </NuxtLink>
      <div class="question-meta-text">
        <NuxtLink :to="`/profile/${question.user.id}`" class="question-username">{{ question.user.name }}</NuxtLink>
        <span class="question-date">{{ formattedDate }}</span>
      </div>
    </div>

    <div class="passage-hero">
      <span class="question-badge" aria-hidden="true">?</span>
      <NuxtLink :to="`/books/${question.book.id}`" class="passage-book">
        <span class="passage-book-cover">
          <img v-if="question.book.cover_url" :src="question.book.cover_url" alt="" />
          <span v-else class="passage-book-placeholder">📖</span>
        </span>
        <span class="passage-book-info">
          <span class="passage-book-title serif">{{ question.book.title }}</span>
          <span class="passage-book-author">{{ question.book.author }}</span>
        </span>
      </NuxtLink>
      <p class="passage-text serif">{{ question.passage.text }}</p>
    </div>

    <div class="question-card">
      <p class="question-text">{{ question.body }}</p>
    </div>

    <h2 class="serif answers-heading">{{ t('questions.answersHeading', { count: answers?.length ?? 0 }) }}</h2>

    <AnswerThread
      :question-id="question.id"
      :answers="answers ?? []"
      :can-mark-best="isOwnQuestion"
      @answer-added="onAnswerAdded"
    />
  </div>
  <p v-else class="status-text">{{ t('questions.notFound') }}</p>
</template>

<script setup lang="ts">
import type { Question } from '~/stores/questions'
import type { Answer } from '~/stores/questions'
import AnswerThread from '~/components/questions/AnswerThread.vue'

const route = useRoute()
const { t } = useI18n()

const { data: question } = await useApiFetch<Question>(`/api/questions/${route.params.id}`)
const { data: answers } = await useApiFetch<Answer[]>(`/api/questions/${route.params.id}/answers`)

const auth = useAuthStore()
onMounted(async () => {
  await auth.ensureInitialized()
})

const isOwnQuestion = computed(() => !!question.value && auth.user?.id === question.value.user.id)

function onAnswerAdded() {
  if (!question.value) return
  question.value = { ...question.value, answer_count: question.value.answer_count + 1 }
}

const { formatDate } = useLocaleFormat()

const formattedDate = computed(() => {
  if (!question.value) return ''
  return formatDate(question.value.inserted_at, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
})
</script>

<style scoped>
.question-detail-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
  padding: 48px 24px;
}

.question-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
}

.question-avatar-link {
  display: inline-flex;
}

.question-meta-text {
  display: flex;
  flex-direction: column;
  line-height: 1.3;
}

.question-username {
  font-weight: 600;
  color: var(--color-ink);
  text-decoration: none;
}

.question-username:hover {
  text-decoration: underline;
}

.question-date {
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.passage-hero {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 20px;
  background: var(--color-highlight-fill);
  border-radius: var(--radius-card);
  padding: 32px;
  margin-bottom: 20px;
}

.question-badge {
  position: absolute;
  top: 16px;
  left: 16px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: var(--color-accent-secondary);
  color: #fff;
  font-size: 0.85rem;
  font-weight: 700;
}

.passage-book {
  display: flex;
  text-align: left;
  gap: 12px;
  color: inherit;
  text-decoration: none;
  padding-left: 32px;
}

.passage-book-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  width: 100%;
}

.passage-book:hover .passage-book-title {
  text-decoration: underline solid var(--color-highlight) 2px;
  text-underline-offset: 3px;
}

.passage-book-cover {
  flex: 0 0 auto;
  width: 66px;
  height: 99px;
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
  font-size: 1.4rem;
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

.question-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-left: 4px solid var(--color-accent-secondary);
  border-radius: var(--radius-card);
  padding: 24px;
  margin-bottom: 20px;
}

.question-text {
  margin: 0;
  font-weight: 600;
  font-size: 1.1rem;
  line-height: 1.6;
  white-space: pre-line;
}

.answers-heading {
  margin: 0 0 4px;
  font-size: 1.1rem;
}
</style>
