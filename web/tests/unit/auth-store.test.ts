import { describe, expect, it, vi } from 'vitest'
import { useAuthStore } from '../../app/stores/auth'

const fakeUser = {
  id: '1',
  email: 'reader@example.com',
  name: 'Reader One',
  bio: null,
  avatar_url: null,
  confirmed: false,
}

describe('auth store', () => {
  it('login stores the access token and user on success', async () => {
    vi.stubGlobal(
      '$fetch',
      vi.fn().mockResolvedValue({ data: { access_token: 'token-123', user: fakeUser } }),
    )

    const auth = useAuthStore()
    await auth.login({ email: fakeUser.email, password: 'supersecret', remember_me: false })

    expect(auth.accessToken).toBe('token-123')
    expect(auth.user?.email).toBe(fakeUser.email)
    expect(auth.initialized).toBe(true)
  })

  it('signup does not start a session (accounts are disabled until confirmed manually)', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockResolvedValue({ data: fakeUser }))

    const auth = useAuthStore()
    await auth.signup({ name: fakeUser.name, email: fakeUser.email, password: 'supersecret' })

    expect(auth.accessToken).toBeNull()
    expect(auth.user).toBeNull()
  })

  it('logout clears the local session even if the request fails', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue(new Error('network down')))

    const auth = useAuthStore()
    auth.accessToken = 'token-123'
    auth.user = fakeUser

    await expect(auth.logout()).rejects.toThrow('network down')
    expect(auth.accessToken).toBeNull()
    expect(auth.user).toBeNull()
  })

  it('refresh clears the session and returns false when the cookie is invalid', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue(new Error('unauthorized')))

    const auth = useAuthStore()
    const ok = await auth.refresh()

    expect(ok).toBe(false)
    expect(auth.accessToken).toBeNull()
    expect(auth.user).toBeNull()
  })

  it('ensureInitialized only calls refresh once', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { access_token: 'token-789', user: fakeUser } })
    vi.stubGlobal('$fetch', fetchMock)

    const auth = useAuthStore()
    await auth.ensureInitialized()
    await auth.ensureInitialized()

    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(auth.accessToken).toBe('token-789')
  })

  it('concurrent ensureInitialized calls share a single refresh request', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { access_token: 'token-789', user: fakeUser } })
    vi.stubGlobal('$fetch', fetchMock)

    const auth = useAuthStore()
    await Promise.all([auth.ensureInitialized(), auth.ensureInitialized()])

    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(auth.accessToken).toBe('token-789')
    expect(auth.initialized).toBe(true)
  })
})
