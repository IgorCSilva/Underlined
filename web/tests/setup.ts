// Nuxt auto-imports everything used in app/** at build time, but plain
// Vitest doesn't know about that. This stubs the handful of auto-imported
// globals our composables/stores/components rely on, so those files can be
// tested exactly as written (no test-only imports scattered through app/**).
import { beforeEach, vi } from 'vitest'
import { createPinia, defineStore, setActivePinia } from 'pinia'
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import enAuth from '../i18n/locales/en/auth.json'
import enBooks from '../i18n/locales/en/books.json'
import enComments from '../i18n/locales/en/comments.json'
import enCommon from '../i18n/locales/en/common.json'
import enErrors from '../i18n/locales/en/errors.json'
import enFeed from '../i18n/locales/en/feed.json'
import enNav from '../i18n/locales/en/nav.json'
import enPosts from '../i18n/locales/en/posts.json'
import enProfile from '../i18n/locales/en/profile.json'

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

// Real `@nuxtjs/i18n` resolves messages merged from `i18n/locales/en/*.json`;
// this re-merges the same files so `t('nav.feed')` etc. resolve to the same
// English strings components render in production, keeping existing
// assertions on literal text valid without duplicating copy in tests.
const messages: Record<string, unknown> = {
  ...enAuth,
  ...enBooks,
  ...enComments,
  ...enCommon,
  ...enErrors,
  ...enFeed,
  ...enNav,
  ...enPosts,
  ...enProfile,
}

function resolveMessage(key: string): unknown {
  return key.split('.').reduce<unknown>((obj, part) => {
    return obj && typeof obj === 'object' ? (obj as Record<string, unknown>)[part] : undefined
  }, messages)
}

function t(key: string, params?: Record<string, unknown>): string {
  const value = resolveMessage(key)
  if (typeof value !== 'string') return key
  if (!params) return value
  return value.replace(/\{(\w+)\}/g, (_, name) => String(params[name] ?? ''))
}

vi.stubGlobal('useI18n', () => ({
  t,
  locale: ref('en'),
  locales: ref([
    { code: 'en', name: 'English' },
    { code: 'pt-BR', name: 'Português (Brasil)' },
  ]),
  setLocale: vi.fn(),
}))

vi.stubGlobal('useLocaleFormat', () => ({
  formatDate: (date: string | number | Date, options?: Intl.DateTimeFormatOptions) =>
    new Date(date).toLocaleDateString('en', options),
}))

// Individual tests override this via `vi.stubGlobal('$fetch', ...)`.
vi.stubGlobal('$fetch', vi.fn())

// `stores/auth.ts` calls `defineStore(...)` at module scope, so the globals
// above must exist before it's evaluated — a dynamic import (after the stubs
// run) guarantees that ordering; a static import would not.
const { useAuthStore } = await import('../app/stores/auth')
const { useApi, apiBaseUrl } = await import('../app/composables/useApi')
const { useBooksStore } = await import('../app/stores/books')
const { usePostsStore } = await import('../app/stores/posts')
const { useCommentsStore } = await import('../app/stores/comments')
const { useFollowsStore } = await import('../app/stores/follows')
const { extractErrorMessage } = await import('../app/utils/errors')

vi.stubGlobal('useAuthStore', useAuthStore)
vi.stubGlobal('useApi', useApi)
vi.stubGlobal('apiBaseUrl', apiBaseUrl)
vi.stubGlobal('useBooksStore', useBooksStore)
vi.stubGlobal('usePostsStore', usePostsStore)
vi.stubGlobal('useCommentsStore', useCommentsStore)
vi.stubGlobal('useFollowsStore', useFollowsStore)
vi.stubGlobal('extractErrorMessage', extractErrorMessage)

beforeEach(() => {
  setActivePinia(createPinia())
})
