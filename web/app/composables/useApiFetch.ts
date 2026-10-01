/**
 * SSR/CSR-friendly GET helper for public endpoints (no auth token needed).
 * Unwraps the API's `{ data: ... }` envelope automatically.
 */
export function useApiFetch<T>(path: string, opts: Record<string, any> = {}) {
  // The access token only ever lives in client-side Pinia state (see
  // auth.client.ts), so this is always undefined during SSR — these requests
  // render anonymous on the server and personalize once hydrated client-side.
  const auth = useAuthStore()
  const authHeaders = auth.accessToken ? { Authorization: `Bearer ${auth.accessToken}` } : undefined

  return useFetch<T>(path, {
    baseURL: apiBaseUrl(),
    // The server and client resolve different baseURLs (api:4000 vs
    // localhost:4000). useFetch's default key is derived from the resolved
    // URL, so without an explicit key that's stable across both, the client
    // can't recognize the SSR payload as the same request, refetches from
    // scratch on hydration, and — if that refetch resolves after the initial
    // paint — produces a hydration mismatch.
    key: `api:${path}:${JSON.stringify(opts.query ?? {})}`,
    headers: authHeaders,
    ...opts,
    transform: (res: any) => res?.data ?? null,
  })
}
