import type { Book } from '~/stores/books'

export interface ClubMember {
  id: string
  name: string
  avatar_url: string | null
}

export interface Club {
  id: string
  name: string
  description: string | null
  book: Book
  creator: ClubMember
  member_count: number
  members_preview: ClubMember[]
  joined_by_user: boolean
  chapter_unit_label: string
  current_chapter_label: string | null
  inserted_at: string
}

export interface ClubChapter {
  id: string
  position: number
  label: string
  current: boolean
  inserted_at: string
}

export interface ClubPost {
  id: string
  body: string
  chapter: ClubChapter | null
  comment_count: number
  inserted_at: string
  updated_at: string
  user: ClubMember
}

export interface MembershipResult {
  joined: boolean
}

interface ClubResponse {
  data: Club
}

interface ClubListResponse {
  data: Club[]
}

interface MemberListResponse {
  data: ClubMember[]
}

interface MembershipResponse {
  data: MembershipResult
}

interface ClubChapterResponse {
  data: ClubChapter
}

interface ClubChapterListResponse {
  data: ClubChapter[]
}

interface ClubPostResponse {
  data: ClubPost
}

interface ClubPostListResponse {
  data: ClubPost[]
}

export const useClubsStore = defineStore('clubs', {
  actions: {
    async listClubsForBook(bookId: string): Promise<Club[]> {
      const { request } = useApi()
      const res = await request<ClubListResponse>(`/api/books/${bookId}/clubs`)
      return res.data
    },

    async listClubs(): Promise<Club[]> {
      const { request } = useApi()
      const res = await request<ClubListResponse>('/api/clubs')
      return res.data
    },

    async createClub(bookId: string, payload: { name: string; description?: string }): Promise<Club> {
      const { request } = useApi()
      const res = await request<ClubResponse>(`/api/books/${bookId}/clubs`, {
        method: 'POST',
        body: { club: payload },
      })
      return res.data
    },

    async getClub(clubId: string): Promise<Club> {
      const { request } = useApi()
      const res = await request<ClubResponse>(`/api/clubs/${clubId}`)
      return res.data
    },

    async listMembers(clubId: string): Promise<ClubMember[]> {
      const { request } = useApi()
      const res = await request<MemberListResponse>(`/api/clubs/${clubId}/members`)
      return res.data
    },

    async joinClub(clubId: string): Promise<MembershipResult> {
      const { request } = useApi()
      const res = await request<MembershipResponse>(`/api/clubs/${clubId}/membership`, { method: 'POST' })
      return res.data
    },

    async leaveClub(clubId: string): Promise<MembershipResult> {
      const { request } = useApi()
      const res = await request<MembershipResponse>(`/api/clubs/${clubId}/membership`, { method: 'DELETE' })
      return res.data
    },

    async listChapters(clubId: string): Promise<ClubChapter[]> {
      const { request } = useApi()
      const res = await request<ClubChapterListResponse>(`/api/clubs/${clubId}/chapters`)
      return res.data
    },

    async createChapter(
      clubId: string,
      payload: { label: string; chapter_unit_label?: string },
    ): Promise<ClubChapter> {
      const { request } = useApi()
      const res = await request<ClubChapterResponse>(`/api/clubs/${clubId}/chapters`, {
        method: 'POST',
        body: { chapter: payload },
      })
      return res.data
    },

    async setCurrentChapter(clubId: string, chapterId: string): Promise<ClubChapter> {
      const { request } = useApi()
      const res = await request<ClubChapterResponse>(`/api/clubs/${clubId}/chapters/${chapterId}/current`, {
        method: 'PUT',
      })
      return res.data
    },

    async listPosts(clubId: string): Promise<ClubPost[]> {
      const { request } = useApi()
      const res = await request<ClubPostListResponse>(`/api/clubs/${clubId}/posts`)
      return res.data
    },

    async createPost(clubId: string, payload: { body: string; chapter_id?: string | null }): Promise<ClubPost> {
      const { request } = useApi()
      const res = await request<ClubPostResponse>(`/api/clubs/${clubId}/posts`, {
        method: 'POST',
        body: { post: payload },
      })
      return res.data
    },
  },
})
