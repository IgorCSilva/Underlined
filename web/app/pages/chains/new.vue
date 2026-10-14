<template>
  <div class="new-chain-page">
    <div class="new-chain card">
      <h1 class="serif new-chain-title">{{ t('chains.newChainTitle') }}</h1>
      <p class="new-chain-hint">{{ t('chains.newChainHint') }}</p>

      <form @submit.prevent="onSubmit">
        <div class="field">
          <label for="chain-title">{{ t('chains.titleLabel') }}</label>
          <input
            id="chain-title"
            v-model="title"
            type="text"
            maxlength="200"
            :placeholder="t('chains.titlePlaceholder')"
            required
          />
        </div>

        <p v-if="error" class="form-error">{{ error }}</p>

        <button class="btn-primary" type="submit" :disabled="pending || !title.trim()">
          {{ pending ? t('chains.creating') : t('chains.create') }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { t } = useI18n()
const router = useRouter()
const chains = useChainsStore()

const title = ref('')
const pending = ref(false)
const error = ref('')

async function onSubmit() {
  const trimmed = title.value.trim()
  if (!trimmed || pending.value) return

  pending.value = true
  error.value = ''
  try {
    const chain = await chains.createChain(trimmed)
    await router.push(`/chains/${chain.id}`)
  } catch (err) {
    error.value = extractErrorMessage(err, t)
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.new-chain-page {
  max-width: 560px;
  margin: 0 auto;
  padding: 48px 24px;
}

.new-chain {
  padding: 32px;
}

.new-chain-title {
  margin: 0 0 8px;
}

.new-chain-hint {
  margin: 0 0 24px;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
}
</style>
