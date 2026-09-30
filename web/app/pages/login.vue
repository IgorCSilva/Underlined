<template>
  <AuthCard title="Log in">
    <form @submit.prevent="onSubmit">
      <div class="field">
        <label for="email">Email</label>
        <input id="email" v-model="email" type="email" required autocomplete="email" />
      </div>
      <div class="field">
        <label for="password">Password</label>
        <input id="password" v-model="password" type="password" required autocomplete="current-password" />
      </div>
      <label class="checkbox-row">
        <input v-model="rememberMe" type="checkbox" />
        Remember me
      </label>
      <p v-if="error" class="form-error">{{ error }}</p>
      <button class="btn-primary" type="submit" :disabled="loading">
        {{ loading ? 'Logging in…' : 'Log in' }}
      </button>
    </form>
    <p class="auth-switch">Don't have an account? <NuxtLink to="/signup">Sign up</NuxtLink></p>
  </AuthCard>
</template>

<script setup lang="ts">
const email = ref('')
const password = ref('')
const rememberMe = ref(false)
const loading = ref(false)
const error = ref('')

const auth = useAuthStore()
const router = useRouter()
const route = useRoute()

async function onSubmit() {
  loading.value = true
  error.value = ''
  try {
    await auth.login({ email: email.value, password: password.value, remember_me: rememberMe.value })
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/profile'
    router.push(redirect)
  } catch (err) {
    error.value = extractErrorMessage(err)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-switch {
  margin-top: 20px;
  font-size: 0.9rem;
  color: var(--color-text-secondary);
}
</style>
