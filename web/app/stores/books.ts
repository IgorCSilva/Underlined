export interface Book {
  id: string
  title: string
  author: string
  cover_url: string | null
}

interface BookResponse {
  data: Book
}

export const useBooksStore = defineStore('books', {
  actions: {
    async addBook(payload: { title: string; author: string; cover_url?: string }): Promise<Book> {
      const { request } = useApi()
      const res = await request<BookResponse>('/api/books', {
        method: 'POST',
        body: { book: payload },
      })
      return res.data
    },
  },
})
