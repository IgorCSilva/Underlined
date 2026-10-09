<template>
  <div class="debate-comment-thread">
    <div class="debate-comment-grid">
      <DebateCommentItem
        v-for="item in list"
        :key="item.id"
        :comment="item"
        :base-path="basePath"
        :referenced-comment="referenceFor(item)"
      />
      <div id="debate-composer" class="debate-composer-wrapper">
        <DebateCommentComposer :base-path="basePath" @posted="onPosted" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Comment } from '~/stores/comments'
import DebateCommentItem from './DebateCommentItem.vue'
import DebateCommentComposer from './DebateCommentComposer.vue'

const props = defineProps<{ connectionId: string; basePath: string; comments: Comment[] }>()

const { clearReplyTarget } = useDebateReplyTarget()

// The API returns top-level comments with their replies nested one level
// deep; the debate layout treats every comment as a flat, independently
// side-colored item (a reply is not visually nested under its parent —
// only referenced via a chip), so the tree is flattened once up front.
const list = ref<Comment[]>(flattenDebateComments(props.comments))

const byId = computed(() => {
  const map = new Map<string, Comment>()
  for (const item of list.value) map.set(item.id, item)
  return map
})

function referenceFor(comment: Comment): Comment | null {
  if (!comment.parent_comment_id) return null
  return byId.value.get(comment.parent_comment_id) ?? null
}

function onPosted(comment: Comment) {
  list.value.push(comment)
}

// Guards against a stale "replying to X" chip surviving a client-side
// navigation from one debate straight into another.
onMounted(clearReplyTarget)
watch(() => props.connectionId, clearReplyTarget)
</script>

<style scoped>
.debate-comment-thread {
  margin-top: 8px;
}

.debate-comment-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px 24px;
}

.debate-comment-grid :deep(.debate-comment-item.side-post_a) {
  grid-column: 1;
}

.debate-comment-grid :deep(.debate-comment-item.side-post_b) {
  grid-column: 2;
}

.debate-comment-grid :deep(.debate-comment-item.side-neutral) {
  grid-column: 1 / -1;
  justify-self: center;
  width: 100%;
  max-width: 480px;
}

.debate-composer-wrapper {
  grid-column: 1 / -1;
  margin-top: 8px;
  padding-top: 16px;
  border-top: 1px solid var(--color-border);
}

@media (max-width: 720px) {
  .debate-comment-grid {
    grid-template-columns: 1fr;
  }

  /* Same class count as the desktop .side-post_a/.side-post_b/.side-neutral
     rules above, so this wins on source order instead of losing on
     specificity (a bare `.debate-comment-item` override here would have
     fewer classes than those and never take effect). */
  .debate-comment-grid :deep(.debate-comment-item.side-post_a),
  .debate-comment-grid :deep(.debate-comment-item.side-post_b),
  .debate-comment-grid :deep(.debate-comment-item.side-neutral) {
    grid-column: 1;
    justify-self: stretch;
    width: auto;
    max-width: none;
  }
}
</style>
