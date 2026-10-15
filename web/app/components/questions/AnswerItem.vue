<template>
  <div class="answer-item" :class="{ 'is-best': answer.best }">
    <span v-if="answer.best" class="answer-best-badge" :title="t('questions.bestAnswer')">★</span>
    <NuxtLink :to="`/profile/${answer.user.id}`" class="answer-avatar-link">
      <AvatarCircle :name="answer.user.name" :avatar-url="answer.user.avatar_url" :size="24" />
    </NuxtLink>
    <div class="answer-body-col">
      <div class="answer-meta">
        <NuxtLink :to="`/profile/${answer.user.id}`" class="answer-username">{{ answer.user.name }}</NuxtLink>
        <span class="answer-date">{{ formattedDate }}</span>
      </div>
      <p class="answer-text">{{ answer.body }}</p>
      <button
        v-if="canMarkBest && !answer.best"
        type="button"
        class="answer-mark-best"
        :disabled="marking"
        @click="onMarkBest"
      >
        {{ marking ? t('questions.markingBest') : t('questions.markBest') }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Answer } from '~/stores/questions'

const props = defineProps<{ answer: Answer; canMarkBest: boolean }>()
const emit = defineEmits<{ marked: [answer: Answer] }>()

const questions = useQuestionsStore()
const { t } = useI18n()
const marking = ref(false)

const { formatDate } = useLocaleFormat()

const formattedDate = computed(() =>
  formatDate(props.answer.inserted_at, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }),
)

async function onMarkBest() {
  if (marking.value) return
  marking.value = true
  try {
    const updated = await questions.markBestAnswer(props.answer.id)
    emit('marked', updated)
  } finally {
    marking.value = false
  }
}
</script>

<style scoped>
.answer-item {
  position: relative;
  display: flex;
  gap: 10px;
  padding: 12px 14px;
  margin-bottom: 8px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-card);
  background: var(--color-surface);
}

.answer-item.is-best {
  background: #fdf6e8;
  border-color: #e8c468;
}

.answer-best-badge {
  position: absolute;
  top: -8px;
  left: -8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #d9a521;
  color: #fff;
  font-size: 0.7rem;
}

.answer-avatar-link {
  display: inline-flex;
  flex-shrink: 0;
}

.answer-body-col {
  flex: 1;
  min-width: 0;
}

.answer-meta {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 4px;
}

.answer-username {
  font-weight: 600;
  font-size: 0.85rem;
  color: var(--color-ink);
  text-decoration: none;
}

.answer-username:hover {
  text-decoration: underline;
}

.answer-date {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.answer-text {
  margin: 0 0 6px;
  font-size: 0.88rem;
  line-height: 1.5;
  color: var(--color-ink);
}

.answer-mark-best {
  background: none;
  border: none;
  padding: 0;
  color: var(--color-accent-secondary);
  font-family: var(--font-sans);
  font-size: 0.78rem;
  font-weight: 600;
  cursor: pointer;
}

.answer-mark-best:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
