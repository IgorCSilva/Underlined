<template>
  <AuthCard :title="t('books.addABook')">
    <form @submit.prevent="onSubmit">
      <div class="field">
        <label for="title">{{ t('books.new.titleLabel') }}</label>
        <input id="title" v-model="title" type="text" required />
      </div>
      <div class="field">
        <label for="author">{{ t('books.new.authorLabel') }}</label>
        <input id="author" v-model="author" type="text" required />
      </div>
      <div class="field">
        <label for="cover_url">{{ t('books.new.coverUrlLabel') }}</label>
        <input id="cover_url" v-model="coverUrl" type="url" :placeholder="t('books.new.coverUrlPlaceholder')" />
      </div>
      <div class="field">
        <label>{{ t('books.new.genresLabel') }}</label>
        <KeywordChipInput
          v-model="genres"
          list="genre-options"
          :placeholder="t('books.new.genresPlaceholder')"
          :aria-label="t('books.new.genresAriaLabel')"
          :remove-aria-label="(genre) => t('books.new.removeGenre', { genre })"
        />
        <datalist id="genre-options">
          <option v-for="option in genreOptions" :key="option" :value="option" />
        </datalist>
      </div>

      <button
        type="button"
        class="series-toggle"
        :class="{ 'is-active': hasSeries }"
        :aria-pressed="hasSeries"
        @click="hasSeries = !hasSeries"
      >
        {{ t('books.new.seriesToggleLabel') }}
      </button>

      <div v-if="hasSeries" class="series-fields">
        <div class="field">
          <label for="series_name">{{ t('books.new.seriesNameLabel') }}</label>
          <input id="series_name" v-model="seriesName" type="text" />
        </div>
        <div class="field">
          <label for="series_position">{{ t('books.new.seriesPositionLabel') }}</label>
          <input id="series_position" v-model="seriesPosition" type="number" min="1" step="1" />
        </div>
      </div>

      <p v-if="error" class="form-error">{{ error }}</p>
      <button class="btn-primary" type="submit" :disabled="saving">
        {{ saving ? t('books.new.adding') : t('books.new.submit') }}
      </button>
    </form>
  </AuthCard>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const title = ref('')
const author = ref('')
const coverUrl = ref('')
const genres = ref<string[]>([])
const hasSeries = ref(false)
const seriesName = ref('')
const seriesPosition = ref('')
const saving = ref(false)
const error = ref('')
const genreOptions = ref<string[]>([])

const books = useBooksStore()
const router = useRouter()
const { t } = useI18n()

onMounted(async () => {
  genreOptions.value = await books.listGenres()
})

async function onSubmit() {
  saving.value = true
  error.value = ''
  try {
    const payload: Parameters<typeof books.addBook>[0] = {
      title: title.value,
      author: author.value,
      cover_url: coverUrl.value,
      genres: genres.value,
    }
    if (hasSeries.value && seriesName.value) {
      payload.series_name = seriesName.value
      if (seriesPosition.value) payload.series_position = Number(seriesPosition.value)
    }
    await books.addBook(payload)
    router.push('/books')
  } catch (err) {
    error.value = extractErrorMessage(err, t)
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.series-toggle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
  padding: 8px 20px;
  border: 1.5px solid var(--color-accent-secondary);
  border-radius: var(--radius-pill);
  background: var(--color-surface);
  color: var(--color-accent-secondary);
  font-family: var(--font-sans);
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s ease, color 0.15s ease;
}

.series-toggle.is-active {
  background: var(--color-accent-secondary);
  color: #ffffff;
}

.series-fields {
  margin-bottom: 16px;
}
</style>
