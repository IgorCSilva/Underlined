export interface AuthUser {
  id: number
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
      await this.refresh()
      this.initialized = true
    },

    async updateProfile(payload: { name: string; bio: string }) {
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
