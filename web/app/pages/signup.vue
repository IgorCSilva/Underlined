<template>
  <AuthCard title="Create your account">
    <template v-if="registered">
      <p class="form-success">
        Thanks for signing up! The person responsible for this application will send you an
        email to confirm that you own this email address. Once confirmed, you'll be able to log
        in.
      </p>
      <p class="auth-switch"><NuxtLink to="/login">Back to log in</NuxtLink></p>
    </template>
    <template v-else>
      <form @submit.prevent="onSubmit">
        <div class="field">
          <label for="name">Name</label>
          <input id="name" v-model="name" type="text" required autocomplete="name" />
        </div>
        <div class="field">
          <label for="email">Email</label>
          <input id="email" v-model="email" type="email" required autocomplete="email" />
        </div>
        <div class="field">
          <label for="password">Password</label>
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
          {{ loading ? 'Creating account…' : 'Sign up' }}
        </button>
      </form>
      <p class="auth-switch">Already have an account? <NuxtLink to="/login">Log in</NuxtLink></p>
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

async function onSubmit() {
  loading.value = true
  error.value = ''
  try {
    await auth.signup({ name: name.value, email: email.value, password: password.value })
    registered.value = true
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
