import { describe, expect, it, vi } from 'vitest'
import { usePostsStore } from '../../app/stores/posts'

const fakePost = {
  id: '1',
  thinking: 'This changed how I think.',
  inserted_at: '2026-10-01T00:00:00Z',
  book: { id: 'b1', title: 'Sapiens', author: 'Yuval Noah Harari', cover_url: null },
  passage: { id: 'p1', text: 'A short passage.' },
  keywords: ['attention', 'nature-writing'],
  user: { id: 'u1', name: 'Reader One' },
}

describe('posts store', () => {
  it('createPost posts to /api/posts and returns the created post', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: fakePost })
    vi.stubGlobal('$fetch', fetchMock)

    const posts = usePostsStore()
    const payload = {
      book_id: 'b1',
      passage_text: 'A short passage.',
      thinking: 'This changed how I think.',
      keywords: ['attention', 'nature-writing'],
    }
    const result = await posts.createPost(payload)

    expect(result).toEqual(fakePost)
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/posts',
      expect.objectContaining({
        method: 'POST',
        body: { post: payload },
      }),
    )
  })

  it('propagates errors from the API', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue(new Error('validation failed')))

    const posts = usePostsStore()
    await expect(
      posts.createPost({ book_id: 'b1', passage_text: '', thinking: '' }),
    ).rejects.toThrow('validation failed')
  })
})
