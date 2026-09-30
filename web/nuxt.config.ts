// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  modules: ['@pinia/nuxt'],
  css: ['~/assets/css/main.css'],
  runtimeConfig: {
    // Server-side (SSR) requests run inside the docker network, so they use
    // the "api" service name; the browser can only reach the published port.
    apiBaseUrl: 'http://api:4000',
    public: {
      apiBaseUrl: 'http://localhost:4000',
    },
  },
})
