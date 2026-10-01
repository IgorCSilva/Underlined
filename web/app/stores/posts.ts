import type { Book } from '~/stores/books'

export interface Post {
  id: string
  thinking: string
  inserted_at: string
  book: Book
  passage: { id: string; text: string }
  keywords: string[]
  user: { id: string; name: string; avatar_url: string | null }
}

interface PostResponse {
  data: Post
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
  },
})
