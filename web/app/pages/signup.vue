<template>
  <AuthCard :title="t('auth.signup.title')">
    <template v-if="registered">
      <p class="form-success">
        {{ t('auth.signup.successMessage') }}
      </p>
      <p class="auth-switch"><NuxtLink to="/login">{{ t('auth.signup.backToLogin') }}</NuxtLink></p>
    </template>
    <template v-else>
      <form @submit.prevent="onSubmit">
        <div class="field">
          <label for="name">{{ t('common.fields.name') }}</label>
          <input id="name" v-model="name" type="text" required autocomplete="name" />
        </div>
        <div class="field">
          <label for="email">{{ t('common.fields.email') }}</label>
          <input id="email" v-model="email" type="email" required autocomplete="email" />
        </div>
        <div class="field">
          <label for="password">{{ t('common.fields.password') }}</label>
          <input
            id="password"
            v-model="password"
            type="password"
            required
            minlength="8"
            autocomplete="new-password"
          />
        </div>
        <p v-if="error" class="form-error">{{ error }}</p>
        <button class="btn-primary" type="submit" :disabled="loading">
          {{ loading ? t('auth.signup.submitting') : t('auth.signup.submit') }}
        </button>
      </form>
      <p class="auth-switch">
        {{ t('auth.signup.hasAccount') }} <NuxtLink to="/login">{{ t('auth.signup.loginLink') }}</NuxtLink>
      </p>
    </template>
  </AuthCard>
</template>

<script setup lang="ts">
const name = ref('')
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')
const registered = ref(false)

const auth = useAuthStore()
const { t } = useI18n()

async function onSubmit() {
  loading.value = true
  error.value = ''
  try {
    await auth.signup({ name: name.value, email: email.value, password: password.value })
    registered.value = true
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
