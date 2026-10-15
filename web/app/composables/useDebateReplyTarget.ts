import type { Comment } from '~/stores/comments'

// Module-scoped, not inside the composable function: the "Reply" button on
// a DebateCommentItem and the single shared DebateCommentComposer at the
// bottom of the thread are siblings, not parent/child, so they need one
// shared target rather than a prop/emit chain through DebateCommentThread.
const replyTarget = ref<Comment | null>(null)

export function useDebateReplyTarget() {
  function setReplyTarget(comment: Comment) {
    replyTarget.value = comment
  }

  function clearReplyTarget() {
    replyTarget.value = null
  }

  return { replyTarget, setReplyTarget, clearReplyTarget }
}
