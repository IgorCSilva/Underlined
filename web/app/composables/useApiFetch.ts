/**
 * SSR/CSR-friendly GET helper for public endpoints (no auth token needed).
 * Unwraps the API's `{ data: ... }` envelope automatically.
 */
export function useApiFetch<T>(path: string, opts: Record<string, any> = {}) {
  return useFetch<T>(path, {
    baseURL: apiBaseUrl(),
    ...opts,
    transform: (res: any) => res?.data ?? null,
  })
}
