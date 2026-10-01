import { describe, expect, it, vi } from 'vitest'
import { useBooksStore } from '../../app/stores/books'

const fakeBook = { id: '1', title: 'Sapiens', author: 'Yuval Noah Harari', cover_url: null }

describe('books store', () => {
  it('addBook posts to /api/books and returns the created book', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: fakeBook })
    vi.stubGlobal('$fetch', fetchMock)

    const books = useBooksStore()
    const result = await books.addBook({ title: fakeBook.title, author: fakeBook.author })

    expect(result).toEqual(fakeBook)
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/books',
      expect.objectContaining({
        method: 'POST',
        body: { book: { title: fakeBook.title, author: fakeBook.author } },
      }),
    )
  })

  it('propagates errors from the API', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue(new Error('validation failed')))

    const books = useBooksStore()
    await expect(books.addBook({ title: '', author: '' })).rejects.toThrow('validation failed')
  })
})
