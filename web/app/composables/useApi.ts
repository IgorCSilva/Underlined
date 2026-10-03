export function apiBaseUrl(): string {
  const config = useRuntimeConfig()
  return import.meta.server ? config.apiBaseUrl : config.public.apiBaseUrl
}

/**
 * Authenticated request helper: attaches the in-memory access token and
 * retries once via a refresh-token cookie exchange on a 401.
 *
 * Called from Pinia store actions, watchers, and other places that don't
 * reliably run inside an active Vue component instance — so it reads the
 * locale via `useNuxtApp().$i18n` rather than `useI18n()`. `useI18n()`
 * throws ("Must be called at the top of a setup function") whenever
 * `getCurrentInstance()` is null, which Vue does not guarantee outside a
 * component's synchronous setup body (e.g. inside `watch()` callbacks or,
 * unpredictably depending on build/timing, DOM event handlers).
 */
export function useApi() {
  const auth = useAuthStore()
  const nuxtApp = useNuxtApp()

  async function request<T>(path: string, opts: Record<string, any> = {}, retried = false): Promise<T> {
    const headers: Record<string, string> = {
      'Accept-Language': nuxtApp.$i18n.locale.value,
      ...(opts.headers || {}),
    }
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
