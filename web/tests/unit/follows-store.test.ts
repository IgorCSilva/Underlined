import { describe, expect, it, vi } from 'vitest'
import { useFollowsStore } from '../../app/stores/follows'

describe('follows store', () => {
  it('followUser posts to /api/users/:id/follow and returns the result', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { following: true } })
    vi.stubGlobal('$fetch', fetchMock)

    const follows = useFollowsStore()
    const result = await follows.followUser('user-1')

    expect(result).toEqual({ following: true })
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/users/user-1/follow',
      expect.objectContaining({ method: 'POST' }),
    )
  })

  it('unfollowUser deletes /api/users/:id/follow and returns the result', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { following: false } })
    vi.stubGlobal('$fetch', fetchMock)

    const follows = useFollowsStore()
    const result = await follows.unfollowUser('user-1')

    expect(result).toEqual({ following: false })
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/users/user-1/follow',
      expect.objectContaining({ method: 'DELETE' }),
    )
  })

  it('propagates errors from the API', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue(new Error('network error')))

    const follows = useFollowsStore()
    await expect(follows.followUser('user-1')).rejects.toThrow('network error')
  })
})
