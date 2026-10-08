<template>
  <button type="button" class="add-item-button" @click.stop.prevent="open">
    {{ t('chains.addAction') }}
  </button>

  <Teleport to="body">
    <div v-if="isOpen" class="add-item-overlay" @click.self="close">
      <div class="add-item-modal card" role="dialog" aria-modal="true">
        <h3 class="serif add-item-title">{{ t('chains.addModalTitle') }}</h3>

        <div class="field">
          <label for="chain-item-search">{{ t('chains.searchLabel') }}</label>
          <input
            id="chain-item-search"
            v-model="query"
            type="text"
            :placeholder="t('chains.searchPlaceholder')"
          />
        </div>

        <ul class="add-item-results">
          <li v-if="!candidates.length" class="add-item-empty">
            {{ t('chains.noResults') }}
          </li>
          <li
            v-for="candidate in candidates"
            :key="candidate.id"
            class="add-item-result"
            :class="{ 'is-selected': selectedPostId === candidate.id }"
            @click="selectedPostId = candidate.id"
          >
            <span class="add-item-result-book serif">{{ candidate.book.title }}</span>
            <span class="add-item-result-passage">{{ candidate.passage.text }}</span>
          </li>
        </ul>

        <p v-if="error" class="form-error">{{ error }}</p>

        <div class="add-item-actions">
          <button type="button" class="add-item-cancel" @click="close">
            {{ t('chains.cancel') }}
          </button>
          <button
            type="button"
            class="btn-primary add-item-submit"
            :disabled="pending || !selectedPostId"
            @click="submit"
          >
            {{ pending ? t('chains.adding') : t('chains.add') }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import type { Chain } from '~/stores/chains'
import type { Post } from '~/stores/posts'

const props = defineProps<{ chainId: string; excludePostIds: string[] }>()
const emit = defineEmits<{ added: [chain: Chain] }>()

const { t } = useI18n()
const chains = useChainsStore()

const isOpen = ref(false)
const query = ref('')
const selectedPostId = ref('')
const pending = ref(false)
const error = ref('')
const allPosts = ref<Post[]>([])

const candidates = computed(() => {
  const q = query.value.trim().toLowerCase()
  return allPosts.value
    .filter((post) => !props.excludePostIds.includes(post.id))
    .filter((post) => !q || post.book.title.toLowerCase().includes(q) || post.thinking.toLowerCase().includes(q))
    .slice(0, 8)
})

async function open() {
  isOpen.value = true
  error.value = ''
  if (!allPosts.value.length) {
    const { request } = useApi()
    const res = await request<{ data: Post[] }>('/api/posts')
    allPosts.value = res.data
  }
}

function close() {
  isOpen.value = false
  query.value = ''
  selectedPostId.value = ''
  error.value = ''
}

async function submit() {
  if (!selectedPostId.value || pending.value) return
  pending.value = true
  error.value = ''

  try {
    const chain = await chains.addChainItem(props.chainId, selectedPostId.value)
    emit('added', chain)
    close()
  } catch {
    error.value = t('chains.error')
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.add-item-button {
  display: inline-flex;
  align-items: center;
  background: none;
  border: 1.5px dashed var(--color-accent-secondary);
  border-radius: var(--radius-pill);
  color: var(--color-accent-secondary);
  font-family: var(--font-sans);
  font-size: 0.85rem;
  font-weight: 600;
  padding: 8px 18px;
  cursor: pointer;
}

.add-item-overlay {
  position: fixed;
  inset: 0;
  background: rgba(34, 37, 43, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  z-index: 100;
}

.add-item-modal {
  width: 100%;
  max-width: 480px;
  padding: 28px;
}

.add-item-title {
  margin: 0 0 16px;
}

.add-item-results {
  list-style: none;
  margin: 0 0 16px;
  padding: 0;
  max-height: 260px;
  overflow-y: auto;
  border: 1px solid var(--color-border);
  border-radius: 8px;
}

.add-item-empty {
  padding: 14px;
  font-size: 0.9rem;
  color: var(--color-text-secondary);
}

.add-item-result {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 10px 14px;
  border-bottom: 1px solid var(--color-border);
  cursor: pointer;
}

.add-item-result:last-child {
  border-bottom: none;
}

.add-item-result.is-selected {
  background: var(--color-highlight-fill);
}

.add-item-result-book {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--color-ink);
}

.add-item-result-passage {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.add-item-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 8px;
}

.add-item-cancel {
  background: none;
  border: none;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 0.95rem;
  cursor: pointer;
}

.add-item-submit {
  width: auto;
  padding: 10px 20px;
}
</style>
