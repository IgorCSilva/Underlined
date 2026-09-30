export default defineNuxtRouteMiddleware(async (to) => {
  if (import.meta.server) return

  const auth = useAuthStore()
  if (!auth.initialized) await auth.ensureInitialized()

  if (!auth.user) {
    return navigateTo({ path: '/login', query: { redirect: to.fullPath } })
  }
})
