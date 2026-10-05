// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  modules: ['@pinia/nuxt', '@nuxtjs/i18n'],
  css: ['~/assets/css/main.css'],
  components: [
    { path: '~/components', pathPrefix: false },
    // Everything specific to the Community Health integration (gate,
    // report UI) lives in its own folder so it's easy to find/remove
    // independently of core domain components — mirrors the backend's
    // api/lib/api/infrastructure/health/healthy_community grouping.
    { path: '~/components/health', pathPrefix: false },
  ],
  runtimeConfig: {
    // Server-side (SSR) requests run inside the docker network, so they use
    // the "api" service name; the browser can only reach the published port.
    apiBaseUrl: 'http://api:4000',
    public: {
      apiBaseUrl: 'http://localhost:4000',
    },
  },
  i18n: {
    baseUrl: 'http://localhost:3000',
    locales: [
      {
        code: 'en',
        language: 'en-US',
        name: 'English',
        files: ['en/common.json', 'en/nav.json', 'en/auth.json', 'en/feed.json', 'en/posts.json', 'en/books.json', 'en/comments.json', 'en/profile.json', 'en/errors.json', 'en/health.json', 'en/saved.json', 'en/keywords.json'],
      },
      {
        code: 'pt-BR',
        language: 'pt-BR',
        name: 'Português (Brasil)',
        files: ['pt-BR/common.json', 'pt-BR/nav.json', 'pt-BR/auth.json', 'pt-BR/feed.json', 'pt-BR/posts.json', 'pt-BR/books.json', 'pt-BR/comments.json', 'pt-BR/profile.json', 'pt-BR/errors.json', 'pt-BR/health.json', 'pt-BR/saved.json', 'pt-BR/keywords.json'],
      },
    ],
    defaultLocale: 'en',
    strategy: 'no_prefix',
    detectBrowserLanguage: {
      useCookie: true,
      cookieKey: 'locale',
      redirectOn: 'root',
    },
  },
})
