<template>
  <form class="answer-composer" @submit.prevent="onSubmit">
    <input
      v-model="body"
      type="text"
      class="answer-input"
      :placeholder="t('questions.answerPlaceholder')"
      :aria-label="t('questions.answerPlaceholder')"
      :disabled="pending"
    />
    <button type="submit" class="answer-submit" :disabled="pending || !body.trim()">
      {{ t('questions.answerSubmit') }}
    </button>
    <p v-if="error" class="answer-composer-error">{{ error }}</p>
  </form>
</template>

<script setup lang="ts">
import type { Answer } from '~/stores/questions'

const props = defineProps<{ questionId: string }>()
const emit = defineEmits<{ posted: [answer: Answer] }>()

const questions = useQuestionsStore()
const body = ref('')
const pending = ref(false)
const error = ref('')
const { t } = useI18n()

async function onSubmit() {
  if (pending.value || !body.value.trim()) return
  pending.value = true
  error.value = ''
  try {
    const answer = await questions.createAnswer(props.questionId, { body: body.value.trim() })
    body.value = ''
    emit('posted', answer)
  } catch (err) {
    error.value = extractErrorMessage(err, t)
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.answer-composer {
  display: flex;
  align-items: center;
  gap: 8px;
}

.answer-input {
  flex: 1;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 10px 18px;
  font-family: var(--font-sans);
  font-size: 0.9rem;
  background: var(--color-surface);
  color: var(--color-ink);
}

.answer-input:focus {
  outline: none;
  border-color: var(--color-accent-secondary);
}

.answer-submit {
  flex-shrink: 0;
  background: var(--color-accent-primary);
  color: #fff;
  border: none;
  border-radius: var(--radius-pill);
  font-family: var(--font-sans);
  font-weight: 700;
  font-size: 0.85rem;
  padding: 10px 18px;
  cursor: pointer;
}

.answer-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.answer-composer-error {
  flex-basis: 100%;
  margin: 4px 0 0;
  color: var(--color-accent-primary);
  font-size: 0.8rem;
}
</style>
