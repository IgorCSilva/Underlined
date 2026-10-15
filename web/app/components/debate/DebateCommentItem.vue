<template>
  <div :id="`debate-comment-${comment.id}`" class="debate-comment-item" :class="sideClass">
    <button
      v-if="referencedComment"
      type="button"
      class="debate-comment-reference"
      :aria-label="t('debates.comments.replyReferenceAriaLabel')"
      @click="scrollToReference"
    >
      ↪ {{ referencedComment.user.name }}: "{{ referenceSnippet }}"
    </button>

    <div class="debate-comment-main">
      <NuxtLink :to="`/profile/${comment.user.id}`" class="debate-comment-avatar-link">
        <AvatarCircle :name="comment.user.name" :avatar-url="comment.user.avatar_url" :size="28" />
      </NuxtLink>
      <div class="debate-comment-body-col">
        <div class="debate-comment-meta">
          <NuxtLink :to="`/profile/${comment.user.id}`" class="debate-comment-username">{{ comment.user.name }}</NuxtLink>
          <span class="debate-comment-date">{{ formattedDate }}</span>
          <span v-if="comment.updated_at !== comment.inserted_at" class="debate-comment-edited">{{ t('comments.edited') }}</span>
        </div>

        <p v-if="!editing" class="debate-comment-text">{{ comment.body }}</p>
        <form v-else class="debate-comment-edit-form" @submit.prevent="onEditSave">
          <input
            v-model="editBody"
            type="text"
            class="debate-comment-edit-input"
            :aria-label="t('comments.editAriaLabel')"
            :disabled="editPending"
          />
          <button type="submit" class="debate-comment-edit-save" :disabled="editPending || !editBody.trim()">
            {{ t('comments.save') }}
          </button>
          <button type="button" class="debate-comment-edit-cancel" @click="cancelEdit">{{ t('comments.cancel') }}</button>
          <p v-if="editError" class="debate-comment-composer-error">{{ editError }}</p>
        </form>

        <div class="debate-comment-actions-row">
          <button v-if="!comment.parent_comment_id" type="button" class="debate-comment-reply-toggle" @click="onReplyClick">
            {{ t('comments.reply') }}
          </button>
          <button v-if="isOwnComment && !editing" type="button" class="debate-comment-edit-toggle" @click="startEdit">
            {{ t('comments.edit') }}
          </button>
          <ReportButton resource-type="comment" :resource-id="comment.id" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Comment } from '~/stores/comments'

const props = defineProps<{ comment: Comment; basePath: string; referencedComment: Comment | null }>()

const auth = useAuthStore()
const comments = useCommentsStore()
const { t } = useI18n()
const { setReplyTarget } = useDebateReplyTarget()
const { formatDate } = useLocaleFormat()

const editing = ref(false)
const editBody = ref('')
const editPending = ref(false)
const editError = ref('')

const isOwnComment = computed(() => auth.user?.id === props.comment.user.id)
const sideClass = computed(() => `side-${props.comment.side ?? 'neutral'}`)

const formattedDate = computed(() =>
  formatDate(props.comment.inserted_at, { year: 'numeric', month: 'short', day: 'numeric' }),
)

const referenceSnippet = computed(() => {
  const body = props.referencedComment?.body ?? ''
  return body.length > 80 ? `${body.slice(0, 80)}…` : body
})

function onReplyClick() {
  setReplyTarget(props.comment)
  document.getElementById('debate-composer')?.scrollIntoView({ behavior: 'smooth', block: 'center' })
  nextTick(() => {
    document.getElementById('debate-composer-input')?.focus()
  })
}

function scrollToReference() {
  if (!props.comment.parent_comment_id) return
  document.getElementById(`debate-comment-${props.comment.parent_comment_id}`)?.scrollIntoView({ behavior: 'smooth', block: 'center' })
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
.debate-comment-item {
  border-top: 4px solid transparent;
  background: var(--color-surface);
  border-radius: var(--radius-card);
  padding: 14px 16px;
}

.debate-comment-item.side-post_a {
  border-top-color: var(--color-accent-secondary);
}

.debate-comment-item.side-post_b {
  border-top-color: var(--color-accent-primary);
}

.debate-comment-item.side-neutral {
  border-top-color: var(--color-text-secondary);
}

.debate-comment-reference {
  display: block;
  width: 100%;
  background: var(--color-chip-fill);
  color: var(--color-chip-text);
  border: none;
  border-radius: var(--radius-card);
  padding: 6px 10px;
  margin-bottom: 10px;
  font-size: 0.78rem;
  text-align: left;
  cursor: pointer;
}

.debate-comment-main {
  display: flex;
  gap: 10px;
}

.debate-comment-avatar-link {
  display: inline-flex;
  flex-shrink: 0;
}

.debate-comment-body-col {
  flex: 1;
  min-width: 0;
}

.debate-comment-meta {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 4px;
  flex-wrap: wrap;
}

.debate-comment-username {
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--color-ink);
  text-decoration: none;
}

.debate-comment-username:hover {
  text-decoration: underline;
}

.debate-comment-date {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.debate-comment-edited {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
  font-style: italic;
}

.debate-comment-text {
  margin: 0 0 6px;
  font-size: 0.9rem;
  line-height: 1.5;
  color: var(--color-ink);
}

.debate-comment-edit-form {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 6px;
  flex-wrap: wrap;
}

.debate-comment-edit-input {
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

.debate-comment-edit-input:focus {
  outline: none;
  border-color: var(--color-accent-secondary);
}

.debate-comment-edit-save,
.debate-comment-edit-cancel {
  background: none;
  border: none;
  padding: 0;
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
}

.debate-comment-edit-save {
  color: var(--color-accent-secondary);
}

.debate-comment-edit-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.debate-comment-edit-cancel {
  color: var(--color-text-secondary);
}

.debate-comment-composer-error {
  flex-basis: 100%;
  margin: 4px 0 0;
  color: var(--color-accent-primary);
  font-size: 0.8rem;
}

.debate-comment-actions-row {
  display: flex;
  gap: 12px;
}

.debate-comment-reply-toggle,
.debate-comment-edit-toggle {
  background: none;
  border: none;
  padding: 0;
  color: var(--color-accent-secondary);
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
}
</style>
