export interface Book {
  id: string
  title: string
  author: string
  cover_url: string | null
  genres: string[]
  series_name: string | null
  series_position: number | null
}

interface BookResponse {
  data: Book
}

interface GenresResponse {
  data: string[]
}

export const useBooksStore = defineStore('books', {
  actions: {
    async addBook(payload: {
      title: string
      author: string
      cover_url?: string
      genres?: string[]
      series_name?: string
      series_position?: number
    }): Promise<Book> {
      const { request } = useApi()
      const res = await request<BookResponse>('/api/books', {
        method: 'POST',
        body: { book: payload },
      })
      return res.data
    },

    async listGenres(): Promise<string[]> {
      const { request } = useApi()
      const res = await request<GenresResponse>('/api/books/genres')
      return res.data
    },
  },
})
