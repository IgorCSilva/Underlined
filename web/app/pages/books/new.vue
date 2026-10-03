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
const saving = ref(false)
const error = ref('')

const books = useBooksStore()
const router = useRouter()
const { t } = useI18n()

async function onSubmit() {
  saving.value = true
  error.value = ''
  try {
    await books.addBook({ title: title.value, author: author.value, cover_url: coverUrl.value })
    router.push('/books')
  } catch (err) {
    error.value = extractErrorMessage(err, t)
  } finally {
    saving.value = false
  }
}
</script>
