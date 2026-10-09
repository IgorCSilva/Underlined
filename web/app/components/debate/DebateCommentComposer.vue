<template>
  <div class="debate-composer-inner">
    <div v-if="replyTarget" class="debate-reply-reference">
      <span>{{ t('debates.comments.replyingTo', { name: replyTarget.user.name }) }}</span>
      <button
        type="button"
        class="debate-reply-cancel"
        :aria-label="t('debates.comments.cancelReply')"
        @click="clearReplyTarget"
      >
        ✕
      </button>
    </div>

    <input
      id="debate-composer-input"
      v-model="body"
      type="text"
      class="debate-comment-input"
      :placeholder="t('debates.comments.addPlaceholder')"
      :aria-label="t('debates.comments.addPlaceholder')"
      :disabled="pending"
    />

    <div class="debate-side-buttons">
      <button
        type="button"
        class="debate-side-btn is-a"
        :disabled="pending || !body.trim()"
        @click="submitSide('post_a')"
      >
        {{ t('debates.comments.agreeA') }}
      </button>
      <button
        type="button"
        class="debate-side-btn is-neutral"
        :disabled="pending || !body.trim()"
        @click="submitSide('neutral')"
      >
        {{ t('debates.comments.neutral') }}
      </button>
      <button
        type="button"
        class="debate-side-btn is-b"
        :disabled="pending || !body.trim()"
        @click="submitSide('post_b')"
      >
        {{ t('debates.comments.agreeB') }}
      </button>
    </div>

    <p v-if="error" class="debate-composer-error">{{ error }}</p>
  </div>
</template>

<script setup lang="ts">
import type { Comment } from '~/stores/comments'

const props = defineProps<{ basePath: string }>()
const emit = defineEmits<{ posted: [comment: Comment] }>()

const comments = useCommentsStore()
const { t } = useI18n()
const { replyTarget, clearReplyTarget } = useDebateReplyTarget()

const body = ref('')
const pending = ref(false)
const error = ref('')

async function submitSide(side: 'post_a' | 'post_b' | 'neutral') {
  if (pending.value || !body.value.trim()) return
  pending.value = true
  error.value = ''
  try {
    const comment = await comments.createComment(props.basePath, {
      body: body.value.trim(),
      parent_comment_id: replyTarget.value?.id ?? null,
      side,
    })
    body.value = ''
    clearReplyTarget()
    emit('posted', comment)
  } catch (err) {
    error.value = extractErrorMessage(err, t)
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.debate-composer-inner {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-width: 560px;
  margin: 0 auto;
}

.debate-reply-reference {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  background: var(--color-chip-fill);
  color: var(--color-chip-text);
  border-radius: var(--radius-pill);
  padding: 6px 14px;
  font-size: 0.8rem;
}

.debate-reply-cancel {
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
  color: inherit;
  font-size: 0.9rem;
  line-height: 1;
}

.debate-comment-input {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 10px 18px;
  font-family: var(--font-sans);
  font-size: 0.9rem;
  background: var(--color-surface);
  color: var(--color-ink);
}

.debate-comment-input:focus {
  outline: none;
  border-color: var(--color-accent-secondary);
}

.debate-side-buttons {
  display: flex;
  justify-content: center;
  gap: 12px;
  flex-wrap: wrap;
}

.debate-side-btn {
  border: none;
  border-radius: var(--radius-pill);
  padding: 8px 18px;
  font-family: var(--font-sans);
  font-weight: 700;
  font-size: 0.85rem;
  color: #fff;
  cursor: pointer;
}

.debate-side-btn.is-a {
  background: var(--color-accent-secondary);
}

.debate-side-btn.is-neutral {
  background: var(--color-text-secondary);
}

.debate-side-btn.is-b {
  background: var(--color-accent-primary);
}

.debate-side-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.debate-composer-error {
  margin: 0;
  color: var(--color-accent-primary);
  font-size: 0.8rem;
  text-align: center;
}
</style>
