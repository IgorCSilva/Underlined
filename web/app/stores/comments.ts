export interface Comment {
  id: string
  type: 'comment' | 'reply'
  body: string
  inserted_at: string
  parent_comment_id: string | null
  user: { id: string; name: string; avatar_url: string | null }
  replies: Comment[]
}

interface CommentResponse {
  data: Comment
}

export const useCommentsStore = defineStore('comments', {
  actions: {
    async createComment(
      postId: string,
      payload: { body: string; parent_comment_id?: string | null },
    ): Promise<Comment> {
      const { request } = useApi()
      const res = await request<CommentResponse>(`/api/posts/${postId}/comments`, {
        method: 'POST',
        body: { comment: payload },
      })
      return res.data
    },
  },
})
