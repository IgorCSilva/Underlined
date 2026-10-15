<template>
  <div class="comment-item" :class="{ 'is-reply': isReply }">
    <NuxtLink :to="`/profile/${comment.user.id}`" class="comment-avatar-link">
      <AvatarCircle :name="comment.user.name" :avatar-url="comment.user.avatar_url" :size="28" />
    </NuxtLink>
    <div class="comment-body-col">
      <div class="comment-meta">
        <NuxtLink :to="`/profile/${comment.user.id}`" class="comment-username">{{ comment.user.name }}</NuxtLink>
        <span class="comment-date">{{ formattedDate }}</span>
        <span v-if="comment.updated_at !== comment.inserted_at" class="comment-edited">{{ t('comments.edited') }}</span>
      </div>

      <p v-if="!editing" class="comment-text">{{ comment.body }}</p>
      <form v-else class="comment-edit-form" @submit.prevent="onEditSave">
        <input
          v-model="editBody"
          type="text"
          class="comment-edit-input"
          :aria-label="t('comments.editAriaLabel')"
          :disabled="editPending"
        />
        <button type="submit" class="comment-edit-save" :disabled="editPending || !editBody.trim()">{{ t('comments.save') }}</button>
        <button type="button" class="comment-edit-cancel" @click="cancelEdit">{{ t('comments.cancel') }}</button>
        <p v-if="editError" class="comment-composer-error">{{ editError }}</p>
      </form>

      <div class="comment-actions-row">
        <button v-if="!isReply" type="button" class="comment-reply-toggle" @click="replying = !replying">
          {{ t('comments.reply') }}
        </button>
        <button v-if="isOwnComment && !editing" type="button" class="comment-edit-toggle" @click="startEdit">
          {{ t('comments.edit') }}
        </button>
        <ReportButton resource-type="comment" :resource-id="comment.id" />
      </div>

      <div v-if="replying" class="comment-reply-composer">
        <CommentComposer
          :base-path="basePath"
          :parent-comment-id="comment.id"
          :placeholder="t('comments.replyPlaceholder')"
          @posted="onReplyPosted"
        />
      </div>

      <div v-if="!isReply && comment.replies.length" class="comment-replies">
        <CommentItem
          v-for="reply in comment.replies"
          :key="reply.id"
          :comment="reply"
          :base-path="basePath"
          is-reply
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Comment } from '~/stores/comments'
import CommentComposer from './CommentComposer.vue'

const props = withDefaults(defineProps<{ comment: Comment; basePath: string; isReply?: boolean }>(), {
  isReply: false,
})

const emit = defineEmits<{ posted: [comment: Comment] }>()

const auth = useAuthStore()
const comments = useCommentsStore()
const { t } = useI18n()

const replying = ref(false)

const isOwnComment = computed(() => auth.user?.id === props.comment.user.id)

const editing = ref(false)
const editBody = ref('')
const editPending = ref(false)
const editError = ref('')

const { formatDate } = useLocaleFormat()

const formattedDate = computed(() =>
  formatDate(props.comment.inserted_at, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }),
)

function onReplyPosted(reply: Comment) {
  props.comment.replies.push(reply)
  replying.value = false
  emit('posted', reply)
}

function startEdit() {
  editBody.value = props.comment.body
  editError.value = ''
  editing.value = true
}

function cancelEdit() {
  editing.value = false
}

async function onEditSave() {
  if (editPending.value || !editBody.value.trim()) return
  editPending.value = true
  editError.value = ''
  try {
    const updated = await comments.updateComment(props.basePath, props.comment.id, { body: editBody.value.trim() })
    props.comment.body = updated.body
    props.comment.updated_at = updated.updated_at
    editing.value = false
  } catch (err) {
    editError.value = extractErrorMessage(err, t)
  } finally {
    editPending.value = false
  }
}
</script>

<style scoped>
.comment-item {
  display: flex;
  gap: 10px;
  padding: 16px 0;
  border-bottom: 1px solid var(--color-border);
}

.comment-item:last-child {
  border-bottom: none;
}

.comment-item.is-reply {
  padding: 12px 0 0;
  border-bottom: none;
}

.comment-body-col {
  flex: 1;
  min-width: 0;
}

.comment-meta {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 4px;
}

.comment-avatar-link {
  display: inline-flex;
  flex-shrink: 0;
}

.comment-username {
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--color-ink);
  text-decoration: none;
}

.comment-username:hover {
  text-decoration: underline;
}

.comment-date {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.comment-edited {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
  font-style: italic;
}

.comment-text {
  margin: 0 0 6px;
  font-size: 0.9rem;
  line-height: 1.5;
  color: var(--color-ink);
}

.comment-edit-form {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 6px;
  flex-wrap: wrap;
}

.comment-edit-input {
  flex: 1;
  min-width: 160px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 6px 14px;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  background: var(--color-surface);
  color: var(--color-ink);
}

.comment-edit-input:focus {
  outline: none;
  border-color: var(--color-accent-secondary);
}

.comment-edit-save,
.comment-edit-cancel {
  background: none;
  border: none;
  padding: 0;
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
}

.comment-edit-save {
  color: var(--color-accent-secondary);
}

.comment-edit-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.comment-edit-cancel {
  color: var(--color-text-secondary);
}

.comment-composer-error {
  flex-basis: 100%;
  margin: 4px 0 0;
  color: var(--color-accent-primary);
  font-size: 0.8rem;
}

.comment-actions-row {
  display: flex;
  gap: 12px;
}

.comment-reply-toggle,
.comment-edit-toggle {
  background: none;
  border: none;
  padding: 0;
  color: var(--color-accent-secondary);
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
}

.comment-reply-composer {
  margin-top: 10px;
}

.comment-replies {
  margin-top: 8px;
  padding-left: 16px;
  border-left: 2px solid var(--color-accent-secondary);
}
</style>
