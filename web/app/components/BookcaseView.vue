<template>
  <div class="bookcase-page">
    <h1 class="serif underlined">
      {{ own ? t('bookcase.yourTitle') : t('bookcase.title', { name: user.name }) }}
    </h1>

    <div class="bookcase-tabs" role="tablist">
      <button
        v-for="tab in TABS"
        :key="tab"
        type="button"
        class="bookcase-tab"
        :class="{ 'is-active': activeTab === tab }"
        role="tab"
        :aria-selected="activeTab === tab"
        @click="activeTab = tab"
      >
        {{ t(`bookcase.tabs.${tab}`) }}
      </button>
    </div>

    <p v-if="pending" class="status-text">{{ t('bookcase.loading') }}</p>
    <p v-else-if="!filteredEntries.length" class="status-text">{{ t('bookcase.empty') }}</p>
    <div v-else class="bookcase-grid">
      <NuxtLink
        v-for="entry in filteredEntries"
        :key="entry.id"
        :to="`/books/${entry.book.id}`"
        class="bookcase-tile-link"
      >
        <div class="bookcase-tile-wrap">
          <BookTile :book="entry.book" />
          <span v-if="entry.status" class="shelf-tag" :class="`is-${entry.status}`">
            {{ t(`bookcase.status.${entry.status}`) }}
          </span>
          <span v-else class="wish-tag" aria-hidden="true">♥</span>
        </div>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Book } from '~/stores/books'
import type { BookcaseStatus, UserBookEntry } from '~/stores/userBooks'
import type { WishlistEntry } from '~/stores/wishlist'

interface DisplayEntry {
  id: string
  book: Book
  status: BookcaseStatus | null
}

const TABS = ['all', 'read', 'reading', 'to_read', 'wish'] as const

const props = defineProps<{ user: { id: string; name: string }; own: boolean }>()

const { t } = useI18n()
const userBooks = useUserBooksStore()
const wishlistStore = useWishlistStore()

const entries = ref<UserBookEntry[]>([])
const wishEntries = ref<WishlistEntry[]>([])
const pending = ref(true)
const activeTab = ref<(typeof TABS)[number]>('all')

const filteredEntries = computed<DisplayEntry[]>(() => {
  if (activeTab.value === 'wish') {
    return wishEntries.value.map((entry) => ({ id: entry.id, book: entry.book, status: null }))
  }
  if (activeTab.value === 'all') return entries.value
  return entries.value.filter((entry) => entry.status === (activeTab.value as BookcaseStatus))
})

async function load() {
  pending.value = true
  try {
    const [bookcase, wishlist] = await Promise.all([
      userBooks.listBookcase(props.user.id),
      wishlistStore.listWishlist(props.user.id),
    ])
    entries.value = bookcase
    wishEntries.value = wishlist
  } finally {
    pending.value = false
  }
}

watch(() => props.user.id, load)
onMounted(load)
</script>

<style scoped>
.bookcase-page {
  max-width: 960px;
  margin: 0 auto;
  padding: 48px 24px;
}

.bookcase-page h1 {
  margin: 0 0 24px;
}

.bookcase-tabs {
  display: flex;
  gap: 24px;
  margin-bottom: 32px;
  border-bottom: 1px solid var(--color-border);
}

.bookcase-tab {
  background: none;
  border: none;
  padding: 4px 0 12px;
  font-family: var(--font-sans);
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.bookcase-tab.is-active {
  color: var(--color-ink);
  text-decoration: underline solid var(--color-highlight) 3px;
  text-underline-offset: 6px;
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
  padding: 48px 24px;
}

.bookcase-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 24px;
}

.bookcase-tile-link {
  color: inherit;
  text-decoration: none;
}

.bookcase-tile-wrap {
  position: relative;
}

.shelf-tag {
  position: absolute;
  top: 8px;
  right: 8px;
  border-radius: var(--radius-pill);
  padding: 3px 10px;
  font-family: var(--font-sans);
  font-size: 0.7rem;
  font-weight: 700;
}

.shelf-tag.is-to_read {
  background: var(--color-chip-fill);
  color: var(--color-chip-text);
}

.shelf-tag.is-reading {
  background: var(--color-accent-secondary);
  color: #fff;
}

.shelf-tag.is-read {
  background: var(--color-success);
  color: #fff;
}

.wish-tag {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-accent-primary);
  color: #fff;
  font-size: 0.85rem;
}
</style>
