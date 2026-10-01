import type { Book } from '~/stores/books'

export interface Post {
  id: string
  thinking: string
  inserted_at: string
  book: Book
  passage: { id: string; text: string }
  keywords: string[]
  like_count: number
  liked_by_user: boolean
  user: { id: string; name: string; avatar_url: string | null }
}

export interface LikeResult {
  liked: boolean
  like_count: number
}

interface PostResponse {
  data: Post
}

interface LikeResponse {
  data: LikeResult
}

export const usePostsStore = defineStore('posts', {
  actions: {
    async createPost(payload: {
      book_id: string
      passage_text: string
      thinking: string
      keywords?: string[]
    }): Promise<Post> {
      const { request } = useApi()
      const res = await request<PostResponse>('/api/posts', {
        method: 'POST',
        body: { post: payload },
      })
      return res.data
    },

    async likePost(postId: string): Promise<LikeResult> {
      const { request } = useApi()
      const res = await request<LikeResponse>(`/api/posts/${postId}/likes`, { method: 'POST' })
      return res.data
    },

    async unlikePost(postId: string): Promise<LikeResult> {
      const { request } = useApi()
      const res = await request<LikeResponse>(`/api/posts/${postId}/likes`, { method: 'DELETE' })
      return res.data
    },
  },
})
