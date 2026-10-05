<template>
  <header class="top-bar" ref="rootEl">
    <div class="top-bar-inner">
      <NuxtLink to="/" class="top-bar-brand serif underlined">Underlined</NuxtLink>

      <nav class="top-bar-nav" :aria-label="t('nav.primary')">
        <NuxtLink v-for="link in links" :key="link.to" :to="link.to" class="top-bar-link">
          {{ link.label }}
        </NuxtLink>
      </nav>

      <LocaleSwitcher class="top-bar-locale" />

      <button
        type="button"
        class="top-bar-menu-toggle"
        :aria-expanded="menuOpen"
        :aria-label="t('nav.toggleMenu')"
        @click="menuOpen = !menuOpen"
      >
        <span class="menu-bar" />
        <span class="menu-bar" />
        <span class="menu-bar" />
      </button>
    </div>

    <nav v-if="menuOpen" class="top-bar-mobile-menu" :aria-label="t('nav.primary')">
      <NuxtLink
        v-for="link in links"
        :key="link.to"
        :to="link.to"
        class="top-bar-mobile-link"
        @click="menuOpen = false"
      >
        {{ link.label }}
      </NuxtLink>
      <LocaleSwitcher class="top-bar-mobile-locale" />
    </nav>
  </header>
</template>

<script setup lang="ts">
interface NavLink {
  to: string
  label: string
}

const { t } = useI18n()
const auth = useAuthStore()
const route = useRoute()
const rootEl = ref<HTMLElement | null>(null)
const menuOpen = ref(false)

watch(
  () => route.fullPath,
  () => {
    menuOpen.value = false
  },
)

const links = computed<NavLink[]>(() => {
  const common: NavLink[] = [
    { to: '/feed', label: t('nav.feed') },
    { to: '/books', label: t('nav.books') },
  ]

  if (auth.user) {
    return [
      ...common,
      // { to: '/posts/new', label: 'New post' },
      { to: '/books/new', label: t('nav.addBook') },
      { to: '/saved', label: t('nav.saved') },
      { to: '/profile', label: t('nav.profile') },
    ]
  }

  return [...common, { to: '/login', label: t('nav.login') }, { to: '/signup', label: t('nav.signup') }]
})

function onDocumentClick(event: MouseEvent) {
  if (menuOpen.value && rootEl.value && !rootEl.value.contains(event.target as Node)) {
    menuOpen.value = false
  }
}

onMounted(() => document.addEventListener('click', onDocumentClick))
onUnmounted(() => document.removeEventListener('click', onDocumentClick))
</script>

<style scoped>
.top-bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: var(--topbar-height);
  background: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
  z-index: 100;
}

.top-bar-inner {
  height: 100%;
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 0 24px;
}

.top-bar-brand {
  flex-shrink: 0;
  font-weight: 700;
  font-size: 1.2rem;
  color: var(--color-ink);
  text-decoration: none;
}

.top-bar-locale {
  flex-shrink: 0;
}

.top-bar-mobile-locale {
  margin-top: 8px;
}

.top-bar-nav {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 4px;
  overflow-x: auto;
  scrollbar-width: thin;
  min-width: 0;
}

.top-bar-link {
  flex-shrink: 0;
  white-space: nowrap;
  padding: 8px 14px;
  border-radius: var(--radius-pill);
  color: var(--color-text-secondary);
  text-decoration: none;
  font-size: 0.9rem;
}

.top-bar-link:hover {
  color: var(--color-ink);
  background: var(--color-highlight-fill);
}

.top-bar-link.router-link-active {
  color: var(--color-accent-secondary);
  background: var(--color-chip-fill);
}

.top-bar-menu-toggle {
  display: none;
  flex-shrink: 0;
  margin-left: auto;
  flex-direction: column;
  justify-content: center;
  gap: 4px;
  width: 36px;
  height: 36px;
  border: none;
  background: none;
  cursor: pointer;
  padding: 0;
}

.menu-bar {
  display: block;
  height: 2px;
  width: 100%;
  background: var(--color-ink);
  border-radius: 1px;
}

.top-bar-mobile-menu {
  display: flex;
  flex-direction: column;
  background: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
  padding: 8px 16px 16px;
}

.top-bar-mobile-link {
  padding: 12px 8px;
  color: var(--color-ink);
  text-decoration: none;
  font-size: 1rem;
  border-bottom: 1px solid var(--color-border);
}

.top-bar-mobile-link:last-child {
  border-bottom: none;
}

.top-bar-mobile-link.router-link-active {
  color: var(--color-accent-secondary);
}

@media (max-width: 640px) {
  .top-bar-nav {
    display: none;
  }

  .top-bar-locale {
    display: none;
  }

  .top-bar-menu-toggle {
    display: flex;
  }
}
</style>
