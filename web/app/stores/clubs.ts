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
  inserted_at: string
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

export const useClubsStore = defineStore('clubs', {
  actions: {
    async listClubsForBook(bookId: string): Promise<Club[]> {
      const { request } = useApi()
      const res = await request<ClubListResponse>(`/api/books/${bookId}/clubs`)
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
  },
})
