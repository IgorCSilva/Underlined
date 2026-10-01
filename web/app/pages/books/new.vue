<template>
  <AuthCard title="Add a book">
    <form @submit.prevent="onSubmit">
      <div class="field">
        <label for="title">Title</label>
        <input id="title" v-model="title" type="text" required />
      </div>
      <div class="field">
        <label for="author">Author</label>
        <input id="author" v-model="author" type="text" required />
      </div>
      <div class="field">
        <label for="cover_url">Cover image URL (optional)</label>
        <input id="cover_url" v-model="coverUrl" type="url" placeholder="https://…" />
      </div>
      <p v-if="error" class="form-error">{{ error }}</p>
      <button class="btn-primary" type="submit" :disabled="saving">
        {{ saving ? 'Adding…' : 'Add book' }}
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

async function onSubmit() {
  saving.value = true
  error.value = ''
  try {
    await books.addBook({ title: title.value, author: author.value, cover_url: coverUrl.value })
    router.push('/books')
  } catch (err) {
    error.value = extractErrorMessage(err)
  } finally {
    saving.value = false
  }
}
</script>
