<template>
  <div v-if="chain" class="chain-page">
    <h1 class="serif chain-title underlined">{{ chain.title }}</h1>
    <p class="chain-meta">{{ t('chains.by', { name: chain.user.name }) }}</p>

    <p v-if="!chain.items.length" class="status-text">{{ t('chains.noItems') }}</p>
    <ChainTimeline
      v-else
      :items="chain.items"
      :editable="isOwner"
      class="chain-page-timeline"
      @reorder="onReorder"
    />

    <AddChainItemButton
      v-if="isOwner"
      :chain-id="chain.id"
      :exclude-post-ids="chain.items.map((item) => item.post.id)"
      @added="onItemAdded"
    />

    <p v-if="reorderError" class="form-error">{{ reorderError }}</p>
  </div>
  <p v-else class="status-text">{{ t('chains.notFound') }}</p>
</template>

<script setup lang="ts">
import type { Chain } from '~/stores/chains'

const route = useRoute()
const { t } = useI18n()
const auth = useAuthStore()
const chains = useChainsStore()

const { data: chain } = await useApiFetch<Chain>(`/api/chains/${route.params.id}`)

const isOwner = computed(() => !!chain.value && auth.user?.id === chain.value.user.id)

const reorderError = ref('')

function onItemAdded(updated: Chain) {
  chain.value = updated
}

async function onReorder(itemIds: string[]) {
  if (!chain.value) return
  reorderError.value = ''
  try {
    chain.value = await chains.reorderChainItems(chain.value.id, itemIds)
  } catch (err) {
    reorderError.value = extractErrorMessage(err, t)
  }
}
</script>

<style scoped>
.chain-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.chain-title {
  margin: 0 0 4px;
}

.chain-meta {
  margin: 0 0 32px;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
}

.chain-page-timeline {
  margin-bottom: 24px;
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
  padding: 48px 24px;
}
</style>
