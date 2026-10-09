<template>
  <button type="button" class="connect-button" @click.stop.prevent="open">
    {{ t('posts.connections.connectAction') }}
  </button>

  <Teleport to="body">
    <div v-if="isOpen" class="connect-overlay" @click.self="close">
      <div class="connect-modal card" role="dialog" aria-modal="true">
        <h3 class="serif connect-title">{{ t('posts.connections.modalTitle') }}</h3>

        <div class="field">
          <label for="connect-search">{{ t('posts.connections.searchLabel') }}</label>
          <input
            id="connect-search"
            v-model="query"
            type="text"
            :placeholder="t('posts.connections.searchPlaceholder')"
          />
        </div>

        <ul class="connect-results">
          <li v-if="!candidates.length" class="connect-empty">
            {{ t('posts.connections.noResults') }}
          </li>
          <li
            v-for="candidate in candidates"
            :key="candidate.id"
            class="connect-result"
            :class="{ 'is-selected': selectedPostId === candidate.id }"
            @click="selectedPostId = candidate.id"
          >
            <span class="connect-result-book serif">{{ candidate.book.title }}</span>
            <span class="connect-result-passage">{{ candidate.passage.text }}</span>
          </li>
        </ul>

        <div class="field">
          <label for="connect-relationship">{{ t('posts.connections.relationshipLabel') }}</label>
          <select id="connect-relationship" v-model="relationshipType">
            <option value="" disabled>{{ t('posts.connections.relationshipPlaceholder') }}</option>
            <option v-for="type in RELATIONSHIP_TYPES" :key="type" :value="type">
              {{ t(`posts.connections.types.${type}`) }}
            </option>
          </select>
        </div>

        <p v-if="error" class="form-error">{{ error }}</p>

        <div class="connect-actions">
          <button type="button" class="connect-cancel" @click="close">
            {{ t('posts.connections.cancel') }}
          </button>
          <button
            type="button"
            class="btn-primary connect-submit"
            :disabled="pending || !selectedPostId || !relationshipType"
            @click="submit"
          >
            {{ pending ? t('posts.connections.connecting') : t('posts.connections.connect') }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import type { Connection, Post, RelationshipType } from '~/stores/posts'

const RELATIONSHIP_TYPES: RelationshipType[] = [
  'similar_idea',
  'opposite_idea',
  'expands_on',
  'contradicts',
  'example_of',
  'personal_connection',
]

const props = defineProps<{ postId: string }>()
const emit = defineEmits<{ connected: [connection: Connection] }>()

const { t } = useI18n()
const posts = usePostsStore()

const isOpen = ref(false)
const query = ref('')
const relationshipType = ref<RelationshipType | ''>('')
const selectedPostId = ref('')
const pending = ref(false)
const error = ref('')
const allPosts = ref<Post[]>([])

const candidates = computed(() => {
  const q = query.value.trim().toLowerCase()
  return allPosts.value
    .filter((post) => post.id !== props.postId)
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
  relationshipType.value = ''
  selectedPostId.value = ''
  error.value = ''
}

async function submit() {
  if (!selectedPostId.value || !relationshipType.value || pending.value) return
  pending.value = true
  error.value = ''

  try {
    const connection = await posts.connectPosts(props.postId, selectedPostId.value, relationshipType.value)
    emit('connected', connection)
    close()
  } catch {
    error.value = t('posts.connections.error')
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.connect-button {
  display: inline-flex;
  align-items: center;
  background: none;
  border: 1.5px dashed var(--color-accent-secondary);
  border-radius: var(--radius-pill);
  color: var(--color-accent-secondary);
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 600;
  padding: 6px 16px;
  cursor: pointer;
}

.connect-overlay {
  position: fixed;
  inset: 0;
  background: rgba(34, 37, 43, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  z-index: 100;
}

.connect-modal {
  width: 100%;
  max-width: 480px;
  padding: 28px;
}

.connect-title {
  margin: 0 0 16px;
}

.connect-modal select {
  width: 100%;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 10px 14px;
  font-family: var(--font-sans);
  font-size: 1rem;
  background: var(--color-surface);
  color: var(--color-ink);
}

.connect-modal select:focus {
  outline: none;
  border-color: var(--color-accent-secondary);
}

.connect-results {
  list-style: none;
  margin: 0 0 16px;
  padding: 0;
  max-height: 220px;
  overflow-y: auto;
  border: 1px solid var(--color-border);
  border-radius: 8px;
}

.connect-empty {
  padding: 14px;
  font-size: 0.9rem;
  color: var(--color-text-secondary);
}

.connect-result {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 10px 14px;
  border-bottom: 1px solid var(--color-border);
  cursor: pointer;
}

.connect-result:last-child {
  border-bottom: none;
}

.connect-result.is-selected {
  background: var(--color-highlight-fill);
}

.connect-result-book {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--color-ink);
}

.connect-result-passage {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.connect-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 8px;
}

.connect-cancel {
  background: none;
  border: none;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 0.95rem;
  cursor: pointer;
}

.connect-submit {
  width: auto;
  padding: 10px 20px;
}
</style>
