<template>
  <AuthCard :title="t('auth.login.title')">
    <form @submit.prevent="onSubmit">
      <div class="field">
        <label for="email">{{ t('common.fields.email') }}</label>
        <input id="email" v-model="email" type="email" required autocomplete="email" />
      </div>
      <div class="field">
        <label for="password">{{ t('common.fields.password') }}</label>
        <input id="password" v-model="password" type="password" required autocomplete="current-password" />
      </div>
      <label class="checkbox-row">
        <input v-model="rememberMe" type="checkbox" />
        {{ t('auth.login.rememberMe') }}
      </label>
      <p v-if="error" class="form-error">{{ error }}</p>
      <button class="btn-primary" type="submit" :disabled="loading">
        {{ loading ? t('auth.login.submitting') : t('auth.login.submit') }}
      </button>
    </form>
    <p class="auth-switch">
      {{ t('auth.login.noAccount') }} <NuxtLink to="/signup">{{ t('auth.login.signupLink') }}</NuxtLink>
    </p>
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
const { t } = useI18n()

async function onSubmit() {
  loading.value = true
  error.value = ''
  try {
    await auth.login({ email: email.value, password: password.value, remember_me: rememberMe.value })
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/profile'
    router.push(redirect)
  } catch (err) {
    error.value = extractErrorMessage(err, t)
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
