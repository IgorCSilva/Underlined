import type { Book } from '~/stores/books'

export type BookcaseStatus = 'to_read' | 'reading' | 'read'

export interface UserBookEntry {
  id: string
  status: BookcaseStatus
  book: Book
}

interface UserBookResponse {
  data: UserBookEntry
}

interface UserBookListResponse {
  data: UserBookEntry[]
}

export const useUserBooksStore = defineStore('userBooks', {
  actions: {
    async listBookcase(userId: string): Promise<UserBookEntry[]> {
      const { request } = useApi()
      const res = await request<UserBookListResponse>(`/api/users/${userId}/bookcase`)
      return res.data
    },

    async setShelfStatus(bookId: string, status: BookcaseStatus): Promise<UserBookEntry> {
      const { request } = useApi()
      const res = await request<UserBookResponse>(`/api/books/${bookId}/shelf`, {
        method: 'PUT',
        body: { shelf: { status } },
      })
      return res.data
    },
  },
})
