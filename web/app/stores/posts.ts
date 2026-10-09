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
  bookmarked_by_user: boolean
  comment_count: number
  user: { id: string; name: string; avatar_url: string | null }
  spoiler: boolean
}

export interface LikeResult {
  liked: boolean
  like_count: number
}

export interface BookmarkResult {
  bookmarked: boolean
}

export type RelationshipType =
  | 'similar_idea'
  | 'opposite_idea'
  | 'expands_on'
  | 'contradicts'
  | 'example_of'
  | 'personal_connection'

export interface Connection {
  id: string
  relationship_type: RelationshipType
  inserted_at: string
  connected_post: Post
}

interface PostResponse {
  data: Post
}

interface LikeResponse {
  data: LikeResult
}

interface BookmarkResponse {
  data: BookmarkResult
}

interface ConnectionResponse {
  data: Connection
}

export const usePostsStore = defineStore('posts', {
  actions: {
    async createPost(payload: {
      book_id: string
      passage_text: string
      thinking: string
      keywords?: string[]
      spoiler?: boolean
    }): Promise<Post> {
      const { request } = useApi()
      const res = await request<PostResponse>('/api/posts', {
        method: 'POST',
        body: { post: payload },
      })
      return res.data
    },

    async updatePost(
      postId: string,
      payload: { passage_text: string; thinking: string; spoiler?: boolean },
    ): Promise<Post> {
      const { request } = useApi()
      const res = await request<PostResponse>(`/api/posts/${postId}`, {
        method: 'PUT',
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

    async bookmarkPost(postId: string): Promise<BookmarkResult> {
      const { request } = useApi()
      const res = await request<BookmarkResponse>(`/api/posts/${postId}/bookmarks`, { method: 'POST' })
      return res.data
    },

    async unbookmarkPost(postId: string): Promise<BookmarkResult> {
      const { request } = useApi()
      const res = await request<BookmarkResponse>(`/api/posts/${postId}/bookmarks`, { method: 'DELETE' })
      return res.data
    },

    async connectPosts(
      postId: string,
      relatedPostId: string,
      relationshipType: RelationshipType,
    ): Promise<Connection> {
      const { request } = useApi()
      const res = await request<ConnectionResponse>(`/api/posts/${postId}/connections`, {
        method: 'POST',
        body: { connection: { related_post_id: relatedPostId, relationship_type: relationshipType } },
      })
      return res.data
    },
  },
})
