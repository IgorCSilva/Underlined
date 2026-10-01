<template>
  <div class="composer-page">
    <div v-if="published" class="composer card success-card">
      <h2 class="serif">Published!</h2>
      <p class="status-text">Your post about "{{ published.book.title }}" is live.</p>
      <button class="btn-primary btn-publish" type="button" @click="reset">Write another</button>
    </div>

    <div v-else-if="!selectedBook" class="book-search">
      <h1 class="serif search-title">Pick a book to write about</h1>
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
        <button
          v-for="book in books ?? []"
          :key="book.id"
          type="button"
          class="book-select-tile"
          @click="selectBook(book)"
        >
          <BookTile :book="book" />
        </button>
      </div>
    </div>

    <div v-else-if="selectedBook" class="composer card">
      <button type="button" class="book-pill" @click="clearBook">
        <span class="book-thumb">
          <img v-if="selectedBook.cover_url" :src="selectedBook.cover_url" alt="" />
          <span v-else class="book-thumb-placeholder">📖</span>
        </span>
        <span class="book-pill-text">
          <span class="book-pill-title serif">{{ selectedBook.title }}</span>
          <span class="book-pill-author">{{ selectedBook.author }}</span>
        </span>
        <span class="book-pill-chevron" aria-hidden="true">⇄</span>
      </button>

      <form @submit.prevent="onSubmit">
        <div class="field">
          <label for="passage">The passage</label>
          <textarea
            id="passage"
            ref="passageInput"
            v-model="passageText"
            class="passage-input serif"
            rows="2"
            placeholder="Type or paste the passage you want to underline…"
            required
            @input="autoGrowPassage"
          />
        </div>

        <div class="field">
          <label for="thinking">What I think about it</label>
          <textarea
            id="thinking"
            v-model="thinking"
            rows="4"
            placeholder="What did this make you think?"
            required
          />
        </div>

        <div class="field">
          <label>Keywords</label>
          <KeywordChipInput v-model="keywords" />
        </div>

        <p v-if="error" class="form-error">{{ error }}</p>

        <div class="composer-footer">
          <button class="btn-primary btn-publish" type="submit" :disabled="saving">
            {{ saving ? 'Publishing…' : 'Publish' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Book } from '~/stores/books'
import type { Post } from '~/stores/posts'

definePageMeta({ middleware: 'auth' })

const route = useRoute()
const router = useRouter()
const posts = usePostsStore()

const selectedBook = ref<Book | null>(null)
const passageInput = ref<HTMLTextAreaElement | null>(null)
const passageText = ref('')
const thinking = ref('')
const keywords = ref<string[]>([])
const saving = ref(false)
const error = ref('')
const published = ref<Post | null>(null)

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

const bookId = route.query.bookId
if (typeof bookId === 'string') {
  const { data: preselected } = await useApiFetch<Book>(`/api/books/${bookId}`)
  if (preselected.value) selectedBook.value = preselected.value
}

function autoGrowPassage() {
  const el = passageInput.value
  if (!el) return
  el.style.height = 'auto'
  el.style.height = `${el.scrollHeight}px`
}

function selectBook(book: Book) {
  selectedBook.value = book
  router.replace({ query: { ...route.query, bookId: book.id } })
}

function clearBook() {
  selectedBook.value = null
  const { bookId: _drop, ...rest } = route.query
  router.replace({ query: rest })
}

async function onSubmit() {
  if (!selectedBook.value) return
  saving.value = true
  error.value = ''
  try {
    published.value = await posts.createPost({
      book_id: selectedBook.value.id,
      passage_text: passageText.value,
      thinking: thinking.value,
      keywords: keywords.value,
    })
  } catch (err) {
    error.value = extractErrorMessage(err)
  } finally {
    saving.value = false
  }
}

function reset() {
  published.value = null
  passageText.value = ''
  thinking.value = ''
  keywords.value = []
  router.replace({ query: {} })
}
</script>

<style scoped>
.composer-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.search-title {
  text-align: center;
  margin-bottom: 24px;
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

.book-select-tile {
  border: none;
  background: none;
  padding: 0;
  cursor: pointer;
  font: inherit;
  text-align: left;
}

.composer {
  padding: 28px;
  max-height: 82vh;
  overflow-y: auto;
}

.book-pill {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 6px 16px 6px 6px;
  margin-bottom: 24px;
  /* border: 1px solid var(--color-accent-secondary);
  border-radius: var(--radius-pill); */
  border: none;
  background: #fffceb;
  cursor: pointer;
  font: inherit;
  transition: box-shadow 0.15s ease;
}

.book-pill:hover {
  box-shadow: 0 2px 8px rgba(34, 37, 43, 0.04);
}

.book-thumb {
  width: 28px;
  height: 42px;
  border-radius: 4px;
  flex-shrink: 0;
  overflow: hidden;
  border: 1px solid var(--color-border);
  background: var(--color-chip-fill);
  display: flex;
  align-items: center;
  justify-content: center;
}

.book-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.book-thumb-placeholder {
  font-size: 0.9rem;
}

.book-pill-text {
  display: flex;
  flex-direction: column;
  line-height: 1.25;
  text-align: left;
}

.book-pill-title {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-ink);
}

.book-pill-author {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.book-pill-chevron {
  color: var(--color-accent-secondary);
  font-size: 0.8rem;
}

.passage-input {
  background: var(--color-highlight-fill);
  font-size: 1.1rem;
  line-height: 2;
  padding: 16px 18px;
  resize: none;
  overflow: hidden;
  text-decoration: underline solid var(--color-highlight) 2px;
  text-underline-offset: 6px;
}

.composer-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 8px;
}

.btn-publish {
  width: auto;
  padding: 12px 28px;
}

.success-card {
  margin-top: 24px;
  text-align: center;
}

.success-card .btn-publish {
  margin: 16px auto 0;
}
</style>
