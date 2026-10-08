import { describe, expect, it, vi } from 'vitest'
import { useCommentsStore } from '../../app/stores/comments'

const fakeComment = {
  id: 'c1',
  type: 'comment' as const,
  body: 'Great read!',
  inserted_at: '2026-10-01T00:00:00Z',
  updated_at: '2026-10-01T00:00:00Z',
  parent_comment_id: null,
  user: { id: 'u1', name: 'Reader One', avatar_url: null },
  replies: [],
}

describe('comments store', () => {
  it('createComment posts to basePath/comments and returns the created comment', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: fakeComment })
    vi.stubGlobal('$fetch', fetchMock)

    const comments = useCommentsStore()
    const result = await comments.createComment('/api/posts/post-1', { body: 'Great read!' })

    expect(result).toEqual(fakeComment)
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/posts/post-1/comments',
      expect.objectContaining({
        method: 'POST',
        body: { comment: { body: 'Great read!' } },
      }),
    )
  })

  it('posts a parent_comment_id when replying', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { ...fakeComment, type: 'reply', parent_comment_id: 'c1' } })
    vi.stubGlobal('$fetch', fetchMock)

    const comments = useCommentsStore()
    await comments.createComment('/api/posts/post-1', { body: 'Agreed!', parent_comment_id: 'c1' })

    expect(fetchMock).toHaveBeenCalledWith(
      '/api/posts/post-1/comments',
      expect.objectContaining({
        method: 'POST',
        body: { comment: { body: 'Agreed!', parent_comment_id: 'c1' } },
      }),
    )
  })

  it('propagates errors from the API', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue(new Error('validation failed')))

    const comments = useCommentsStore()
    await expect(comments.createComment('/api/posts/post-1', { body: '' })).rejects.toThrow('validation failed')
  })
})
