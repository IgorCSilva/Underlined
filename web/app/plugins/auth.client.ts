// Deferred to onNuxtReady (fires strictly after hydration completes), not
// run eagerly: the server never knows the auth state (no cookie check during
// SSR), so it always renders anonymous. If this ran immediately, the refresh
// request routinely resolves *during* Nuxt's hydration window (page-chunk
// loading in dev mode is slower than the /api/auth/refresh round trip), so
// the client's first render would already reflect a logged-in user while
// hydrating against the server's anonymous HTML — a hydration mismatch.
// Waiting for onNuxtReady guarantees hydration finishes first, so this only
// ever triggers a normal post-hydration reactive update (same pattern as the
// post-detail page's post-mount re-fetch).
export default defineNuxtPlugin(() => {
  const auth = useAuthStore()
  onNuxtReady(() => {
    auth.ensureInitialized()
  })
})
