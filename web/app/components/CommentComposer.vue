<template>
  <form class="comment-composer" @submit.prevent="onSubmit">
    <input
      v-model="body"
      type="text"
      class="comment-input"
      :placeholder="placeholder ?? t('comments.addPlaceholder')"
      :aria-label="placeholder ?? t('comments.addPlaceholder')"
      :disabled="pending"
    />
    <button type="submit" class="comment-submit" :disabled="pending || !body.trim()">{{ t('comments.post') }}</button>
    <p v-if="error" class="comment-composer-error">{{ error }}</p>
  </form>
</template>

<script setup lang="ts">
import type { Comment } from '~/stores/comments'

const props = withDefaults(
  defineProps<{
    basePath: string
    parentCommentId?: string | null
    placeholder?: string
  }>(),
  { parentCommentId: null },
)

const emit = defineEmits<{ posted: [comment: Comment] }>()

const comments = useCommentsStore()
const body = ref('')
const pending = ref(false)
const error = ref('')
const { t } = useI18n()

async function onSubmit() {
  if (pending.value || !body.value.trim()) return
  pending.value = true
  error.value = ''
  try {
    const comment = await comments.createComment(props.basePath, {
      body: body.value.trim(),
      parent_comment_id: props.parentCommentId,
    })
    body.value = ''
    emit('posted', comment)
  } catch (err) {
    error.value = extractErrorMessage(err, t)
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.comment-composer {
  display: flex;
  align-items: center;
  gap: 8px;
}

.comment-input {
  flex: 1;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 10px 18px;
  font-family: var(--font-sans);
  font-size: 0.9rem;
  background: var(--color-surface);
  color: var(--color-ink);
}

.comment-input:focus {
  outline: none;
  border-color: var(--color-accent-secondary);
}

.comment-submit {
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

.comment-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.comment-composer-error {
  flex-basis: 100%;
  margin: 4px 0 0;
  color: var(--color-accent-primary);
  font-size: 0.8rem;
}
</style>
