export interface AuthUser {
  id: string
  email: string
  name: string
  bio: string | null
  avatar_url: string | null
  confirmed: boolean
}

interface SessionResponse {
  data: { access_token: string; user: AuthUser }
}

interface UserResponse {
  data: AuthUser
}

// Dedupes concurrent refresh() callers (the client auth plugin, route
// middleware, and useApi()'s 401 retry can all land at once — e.g. a page
// firing several authenticated requests whose access token expires
// together) so they share a single /api/auth/refresh call instead of
// racing. The backend rotates the refresh token on each call, so a second
// concurrent call would read the now-stale cookie value, fail, and wrongly
// clear the session the first call just established — even though that
// first call succeeded.
//
// Plain module-level variables rather than a WeakMap keyed by store
// instance: in Nuxt dev mode, `useAuthStore()` has been observed to hand
// back two reactive proxies that read/write the same underlying state
// (same values visible through both) but fail a `===` check against each
// other — so a WeakMap keyed on `this` silently misses the second call and
// doesn't dedupe at all. There is only ever one "auth" store for the app's
// lifetime, so a plain variable is both simpler and immune to that.
let refreshPromise: Promise<boolean> | null = null
let initPromise: Promise<void> | null = null

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null as AuthUser | null,
    accessToken: null as string | null,
    initialized: false,
  }),

  actions: {
    /**
     * Registration no longer starts a session: new accounts are created
     * disabled and stay that way until the responsible party confirms the
     * email address and flips it on manually (see deploy/specifications.md).
     */
    async signup(payload: { name: string; email: string; password: string }) {
      await $fetch<UserResponse>('/api/auth/register', {
        method: 'POST',
        baseURL: apiBaseUrl(),
        credentials: 'include',
        body: { user: payload },
      })
    },

    async login(payload: { email: string; password: string; remember_me: boolean }) {
      const res = await $fetch<SessionResponse>('/api/auth/login', {
        method: 'POST',
        baseURL: apiBaseUrl(),
        credentials: 'include',
        body: payload,
      })
      this.applySession(res)
    },

    async logout() {
      try {
        await $fetch('/api/auth/logout', {
          method: 'DELETE',
          baseURL: apiBaseUrl(),
          credentials: 'include',
        })
      } finally {
        this.clearSession()
      }
    },

    /** Exchanges the HttpOnly refresh cookie for a fresh access token. */
    async refresh(): Promise<boolean> {
      if (!refreshPromise) {
        refreshPromise = this.performRefresh().finally(() => {
          refreshPromise = null
        })
      }
      return refreshPromise
    },

    async performRefresh(): Promise<boolean> {
      try {
        const res = await $fetch<SessionResponse>('/api/auth/refresh', {
          method: 'POST',
          baseURL: apiBaseUrl(),
          credentials: 'include',
        })
        this.applySession(res)
        return true
      } catch {
        this.clearSession()
        return false
      }
    },

    async ensureInitialized() {
      if (this.initialized) return
      if (!initPromise) {
        initPromise = this.refresh()
          .then(() => {
            this.initialized = true
          })
          .finally(() => {
            initPromise = null
          })
      }
      await initPromise
    },

    async updateProfile(payload: { name: string; bio: string; avatar_url?: string | null }) {
      const { request } = useApi()
      const res = await request<{ data: AuthUser }>('/api/me', {
        method: 'PUT',
        body: { user: payload },
      })
      this.user = res.data
    },

    async uploadAvatar(file: File) {
      const { request } = useApi()
      const form = new FormData()
      form.append('avatar', file)
      const res = await request<{ data: AuthUser }>('/api/me/avatar', {
        method: 'PUT',
        body: form,
      })
      this.user = res.data
    },

    applySession(res: SessionResponse) {
      this.accessToken = res.data.access_token
      this.user = res.data.user
      this.initialized = true
    },

    clearSession() {
      this.accessToken = null
      this.user = null
    },
  },
})
