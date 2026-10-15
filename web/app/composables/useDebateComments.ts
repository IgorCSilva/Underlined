import type { Comment } from '~/stores/comments'

// The backend only allows one level of nesting (a reply's parent must
// itself be a top-level comment), so a single flatMap is enough to turn
// the thread into one flat, chronological list — each item keeps its own
// `side` and `parent_comment_id`, which is all the debate layout needs to
// place it in a column and resolve its "replying to" reference.
export function flattenDebateComments(comments: Comment[]): Comment[] {
  return comments.flatMap((comment) => [comment, ...comment.replies])
}
