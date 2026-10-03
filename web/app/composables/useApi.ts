export function apiBaseUrl(): string {
  const config = useRuntimeConfig()
  return import.meta.server ? config.apiBaseUrl : config.public.apiBaseUrl
}

/**
 * Authenticated request helper: attaches the in-memory access token and
 * retries once via a refresh-token cookie exchange on a 401.
 */
export function useApi() {
  const auth = useAuthStore()
  const { locale } = useI18n()

  async function request<T>(path: string, opts: Record<string, any> = {}, retried = false): Promise<T> {
    const headers: Record<string, string> = { 'Accept-Language': locale.value, ...(opts.headers || {}) }
    if (auth.accessToken) headers.Authorization = `Bearer ${auth.accessToken}`

    try {
      return await $fetch<T>(path, {
        baseURL: apiBaseUrl(),
        credentials: 'include',
        ...opts,
        headers,
      })
    } catch (err: any) {
      if (err?.response?.status === 401 && !retried) {
        const refreshed = await auth.refresh()
        if (refreshed) return request<T>(path, opts, true)
      }
      throw err
    }
  }

  return { request }
}
