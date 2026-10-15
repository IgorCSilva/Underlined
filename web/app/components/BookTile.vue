<template>
  <div class="book-tile">
    <div class="book-cover">
      <img v-if="book.cover_url" :src="book.cover_url" alt="" class="book-cover-img" />
      <span v-else class="book-cover-placeholder">📖</span>
    </div>
    <h3 class="serif book-title">{{ book.title }}</h3>
    <p class="book-author">{{ book.author }}</p>
    <div v-if="book.genres?.length" class="genre-chips">
      <span v-for="genre in book.genres" :key="genre" class="genre-chip">{{ genre }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  book: { title: string; author: string; cover_url: string | null; genres?: string[] }
}>()
</script>

<style scoped>
.book-tile {
  transition: box-shadow 0.15s ease;
}

.book-tile:hover {
  box-shadow: 0 2px 8px rgba(34, 37, 43, 0.04);
}

.book-cover {
  aspect-ratio: 2 / 3;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-tile);
  background: var(--color-chip-fill);
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 10px;
}

.book-cover-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.book-cover-placeholder {
  font-size: 2rem;
}

.book-title {
  margin: 0 0 4px;
  font-size: 1rem;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.book-author {
  margin: 0;
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.genre-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-top: 6px;
}

.genre-chip {
  display: inline-block;
  border: 1px solid var(--color-chip-text);
  border-radius: var(--radius-pill);
  padding: 2px 8px;
  color: var(--color-chip-text);
  background: transparent;
  font-size: 0.7rem;
}
</style>
