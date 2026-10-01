// Nuxt auto-imports everything used in app/** at build time, but plain
// Vitest doesn't know about that. This stubs the handful of auto-imported
// globals our composables/stores/components rely on, so those files can be
// tested exactly as written (no test-only imports scattered through app/**).
import { beforeEach, vi } from 'vitest'
import { createPinia, defineStore, setActivePinia } from 'pinia'
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'

vi.stubGlobal('defineStore', defineStore)
vi.stubGlobal('ref', ref)
vi.stubGlobal('computed', computed)
vi.stubGlobal('reactive', reactive)
vi.stubGlobal('watch', watch)
vi.stubGlobal('nextTick', nextTick)
vi.stubGlobal('onMounted', onMounted)
vi.stubGlobal('onUnmounted', onUnmounted)

vi.stubGlobal('useRuntimeConfig', () => ({
  apiBaseUrl: 'http://api:4000',
  public: { apiBaseUrl: 'http://localhost:4000' },
}))

vi.stubGlobal('useRouter', () => ({ push: vi.fn(), replace: vi.fn() }))
vi.stubGlobal('useRoute', () => reactive({ fullPath: '/', params: {}, query: {} }))

// Individual tests override this via `vi.stubGlobal('$fetch', ...)`.
vi.stubGlobal('$fetch', vi.fn())

// `stores/auth.ts` calls `defineStore(...)` at module scope, so the globals
// above must exist before it's evaluated — a dynamic import (after the stubs
// run) guarantees that ordering; a static import would not.
const { useAuthStore } = await import('../app/stores/auth')
const { useApi, apiBaseUrl } = await import('../app/composables/useApi')
const { useBooksStore } = await import('../app/stores/books')
const { usePostsStore } = await import('../app/stores/posts')

vi.stubGlobal('useAuthStore', useAuthStore)
vi.stubGlobal('useApi', useApi)
vi.stubGlobal('apiBaseUrl', apiBaseUrl)
vi.stubGlobal('useBooksStore', useBooksStore)
vi.stubGlobal('usePostsStore', usePostsStore)

beforeEach(() => {
  setActivePinia(createPinia())
})
