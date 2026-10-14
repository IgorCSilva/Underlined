<template>
  <div class="chains-page">
    <div class="chains-header">
      <h1 class="serif chains-title">{{ t('chains.browseTitle') }}</h1>
      <NuxtLink v-if="auth.user" to="/chains/new" class="btn-primary chains-new-link">
        {{ t('chains.newChain') }}
      </NuxtLink>
    </div>

    <p v-if="!chains?.length" class="status-text">{{ t('chains.empty') }}</p>
    <div v-else class="chains-list">
      <NuxtLink v-for="chain in chains" :key="chain.id" :to="`/chains/${chain.id}`" class="chain-summary card">
        <h2 class="serif chain-summary-title">{{ chain.title }}</h2>
        <p class="chain-summary-meta">
          {{ t('chains.by', { name: chain.user.name }) }} ·
          {{ t('chains.stepCount', { count: chain.items.length }) }}
        </p>
        <div v-if="chain.items.length" class="chain-summary-covers">
          <span v-for="item in chain.items.slice(0, 5)" :key="item.id" class="chain-summary-cover">
            <img v-if="item.post.book.cover_url" :src="item.post.book.cover_url" alt="" />
            <span v-else class="chain-summary-cover-placeholder">📖</span>
          </span>
        </div>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Chain } from '~/stores/chains'

const { t } = useI18n()
const auth = useAuthStore()

const { data: chains } = await useApiFetch<Chain[]>('/api/chains')
</script>

<style scoped>
.chains-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.chains-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 24px;
}

.chains-title {
  margin: 0;
}

.chains-new-link {
  width: auto;
  padding: 10px 20px;
  flex-shrink: 0;
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
}

.chains-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.chain-summary {
  display: block;
  padding: 20px 24px;
  text-decoration: none;
  color: inherit;
  transition: box-shadow 0.15s ease;
}

.chain-summary:hover {
  box-shadow: 0 2px 8px rgba(34, 37, 43, 0.06);
}

.chain-summary-title {
  margin: 0 0 6px;
}

.chain-summary-meta {
  margin: 0 0 14px;
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.chain-summary-covers {
  display: flex;
  gap: -8px;
}

.chain-summary-cover {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  overflow: hidden;
  border: 2px solid var(--color-surface);
  outline: 1px solid var(--color-border);
  background: var(--color-chip-fill);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: -10px;
  font-size: 0.8rem;
}

.chain-summary-cover:first-child {
  margin-left: 0;
}

.chain-summary-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
</style>
