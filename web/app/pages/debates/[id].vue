<template>
  <div v-if="debate" class="debate-page">
    <div class="debate-cards">
      <div class="debate-card is-a card">
        <PostFeedItem :post="debate.post_a" />
      </div>
      <div class="debate-divider" aria-hidden="true">
        <span class="debate-badge">{{ t('posts.connections.types.contradicts') }}</span>
      </div>
      <div class="debate-card is-b card">
        <PostFeedItem :post="debate.post_b" />
      </div>
    </div>

    <DebateCommentThread
      :connection-id="debate.id"
      :base-path="`/api/connections/${debate.id}`"
      :comments="comments ?? []"
      class="debate-discussion"
    />
  </div>
  <p v-else class="status-text">{{ t('debates.notFound') }}</p>
</template>

<script setup lang="ts">
import type { Post } from '~/stores/posts'
import type { Comment } from '~/stores/comments'

interface Debate {
  id: string
  relationship_type: string
  inserted_at: string
  post_a: Post
  post_b: Post
}

const route = useRoute()
const { t } = useI18n()

const { data: debate } = await useApiFetch<Debate>(`/api/connections/${route.params.id}`)
const { data: comments } = await useApiFetch<Comment[]>(`/api/connections/${route.params.id}/comments`)
</script>

<style scoped>
.debate-page {
  max-width: 900px;
  margin: 0 auto;
  padding: 48px 24px;
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
  padding: 48px 24px;
}

.debate-cards {
  display: flex;
  align-items: stretch;
  gap: 24px;
  margin-bottom: 32px;
}

.debate-card {
  flex: 1;
  min-width: 0;
  padding: 8px 20px;
  border-top: 4px solid transparent;
}

.debate-card.is-a {
  border-top-color: var(--color-accent-secondary);
}

.debate-card.is-b {
  border-top-color: var(--color-accent-primary);
}

.debate-card :deep(.feed-item) {
  border-bottom: none;
  padding: 16px 0;
}

.debate-divider {
  position: relative;
  flex: 0 0 auto;
  width: 1px;
  border-left: 2px dashed var(--color-border);
}

.debate-badge {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  white-space: nowrap;
  background: var(--color-surface);
  border: 1.5px solid var(--color-accent-primary);
  border-radius: var(--radius-pill);
  color: var(--color-accent-primary);
  font-family: var(--font-sans);
  font-size: 0.75rem;
  font-weight: 700;
  padding: 6px 14px;
}

.debate-discussion {
  margin-top: 8px;
}

@media (max-width: 720px) {
  .debate-cards {
    flex-direction: column;
    gap: 32px;
  }

  .debate-divider {
    width: auto;
    height: 1px;
    border-left: none;
    border-top: 2px dashed var(--color-border);
  }
}
</style>
