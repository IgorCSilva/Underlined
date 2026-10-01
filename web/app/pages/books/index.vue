<template>
  <div class="books-page">
    <div class="search-hero">
      <span class="search-icon" aria-hidden="true">🔍</span>
      <input
        v-model="q"
        type="search"
        class="search-input"
        placeholder="Search by title or author…"
        aria-label="Search books"
      />
    </div>

    <p v-if="pending" class="status-text">Searching…</p>
    <div v-else class="book-grid">
      <BookTile v-for="book in books ?? []" :key="book.id" :book="book" />
      <NuxtLink to="/books/new" class="add-book-tile">
        <span class="add-book-plus" aria-hidden="true">+</span>
        <span>Add a book</span>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Book } from '~/stores/books'

const q = ref('')
const debouncedQ = ref('')
let debounceTimer: ReturnType<typeof setTimeout> | undefined

watch(q, (value) => {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    debouncedQ.value = value
  }, 300)
})

const { data: books, pending } = useApiFetch<Book[]>('/api/books', {
  query: { q: debouncedQ },
  watch: [debouncedQ],
})
</script>

<style scoped>
.books-page {
  max-width: 960px;
  margin: 0 auto;
  padding: 48px 24px;
}

.search-hero {
  position: relative;
  max-width: 560px;
  margin: 0 auto 40px;
}

.search-icon {
  position: absolute;
  left: 20px;
  top: 50%;
  transform: translateY(-50%);
  pointer-events: none;
}

.search-input {
  width: 100%;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 14px 20px 14px 48px;
  font-family: var(--font-sans);
  font-size: 1rem;
  background: var(--color-surface);
  color: var(--color-ink);
}

.search-input:focus {
  outline: none;
  border-color: var(--color-highlight);
  box-shadow: 0 2px 0 var(--color-highlight);
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
}

.book-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 24px;
}

.add-book-tile {
  aspect-ratio: 2 / 3;
  border: 2px dashed var(--color-border);
  border-radius: var(--radius-tile);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  color: var(--color-chip-text);
  text-decoration: none;
  font-size: 0.85rem;
  text-align: center;
}

.add-book-plus {
  font-size: 1.75rem;
  line-height: 1;
}
</style>
