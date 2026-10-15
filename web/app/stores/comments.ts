export interface Comment {
  id: string
  type: 'comment' | 'reply'
  body: string
  // Only present on a connection's (debate) comment thread — which debate
  // post this comment agrees with. Absent on a post's own comment thread.
  side?: 'post_a' | 'post_b' | 'neutral'
  inserted_at: string
  updated_at: string
  parent_comment_id: string | null
  user: { id: string; name: string; avatar_url: string | null }
  replies: Comment[]
}

interface CommentResponse {
  data: Comment
}

export const useCommentsStore = defineStore('comments', {
  actions: {
    // `basePath` is the parent resource's own API path (e.g. `/api/posts/:id`
    // or `/api/connections/:id`) — a comment thread can be scoped to either,
    // and the two are otherwise identical (same reply nesting, same rate
    // limit), so the store only needs to know where to nest `/comments`.
    async createComment(
      basePath: string,
      payload: { body: string; parent_comment_id?: string | null; side?: 'post_a' | 'post_b' | 'neutral' },
    ): Promise<Comment> {
      const { request } = useApi()
      const res = await request<CommentResponse>(`${basePath}/comments`, {
        method: 'POST',
        body: { comment: payload },
      })
      return res.data
    },

    async updateComment(basePath: string, commentId: string, payload: { body: string }): Promise<Comment> {
      const { request } = useApi()
      const res = await request<CommentResponse>(`${basePath}/comments/${commentId}`, {
        method: 'PUT',
        body: { comment: payload },
      })
      return res.data
    },
  },
})
