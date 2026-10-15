import type { Book } from '~/stores/books'

export interface WishlistEntry {
  id: string
  book: Book
}

interface WishlistListResponse {
  data: WishlistEntry[]
}

interface WishlistToggleResponse {
  data: { wishlisted: boolean }
}

export const useWishlistStore = defineStore('wishlist', {
  state: () => ({
    ids: new Set<string>(),
    loadedUserId: null as string | null,
    loadPromise: null as Promise<void> | null,
  }),
  actions: {
    async listWishlist(userId: string): Promise<WishlistEntry[]> {
      const { request } = useApi()
      const res = await request<WishlistListResponse>(`/api/users/${userId}/wishlist`)
      return res.data
    },

    // Many WishlistButton instances can mount on one page (every tile in
    // the catalog grid) — this caches the viewer's own wishlisted book ids
    // so they share a single request instead of each fetching the whole
    // list themselves.
    async ensureLoaded(userId: string) {
      if (this.loadedUserId === userId) return

      if (!this.loadPromise) {
        this.loadPromise = this.listWishlist(userId).then((entries) => {
          this.ids = new Set(entries.map((entry) => entry.book.id))
          this.loadedUserId = userId
        })
      }

      await this.loadPromise
      this.loadPromise = null
    },

    isWishlisted(bookId: string): boolean {
      return this.ids.has(bookId)
    },

    async addToWishlist(bookId: string): Promise<boolean> {
      const { request } = useApi()
      const res = await request<WishlistToggleResponse>(`/api/books/${bookId}/wishlist`, {
        method: 'POST',
      })
      if (res.data.wishlisted) this.ids.add(bookId)
      else this.ids.delete(bookId)
      return res.data.wishlisted
    },

    async removeFromWishlist(bookId: string): Promise<boolean> {
      const { request } = useApi()
      const res = await request<WishlistToggleResponse>(`/api/books/${bookId}/wishlist`, {
        method: 'DELETE',
      })
      if (res.data.wishlisted) this.ids.add(bookId)
      else this.ids.delete(bookId)
      return res.data.wishlisted
    },
  },
})
