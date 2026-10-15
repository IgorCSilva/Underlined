<template>
  <div class="feed-item">
    <span class="question-badge" aria-hidden="true">?</span>
    <div class="feed-meta">
      <NuxtLink :to="`/profile/${question.user.id}`" class="feed-avatar-link">
        <AvatarCircle :name="question.user.name" :avatar-url="question.user.avatar_url" :size="28" />
      </NuxtLink>
      <span class="feed-meta-text">
        <NuxtLink :to="`/profile/${question.user.id}`" class="feed-username">{{ question.user.name }}</NuxtLink>
        {{ t('feed.on') }}
        <NuxtLink :to="`/books/${question.book.id}`" class="feed-book-title">{{ question.book.title }}</NuxtLink>
      </span>
    </div>

    <NuxtLink :to="`/questions/${question.id}`" class="feed-content-link">
      <p class="feed-passage serif">{{ question.passage.text }}</p>
      <p class="feed-question-body">{{ question.body }}</p>
    </NuxtLink>

    <div class="feed-icon-row">
      <NuxtLink :to="`/questions/${question.id}`" class="feed-icon">🗨️ {{ question.answer_count }}</NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Question } from '~/stores/questions'

defineProps<{ question: Question }>()
const { t } = useI18n()
</script>

<style scoped>
.feed-item {
  position: relative;
  display: block;
  padding: 24px 0;
  border-bottom: 1px solid var(--color-border);
}

.feed-item:last-child {
  border-bottom: none;
}

.question-badge {
  position: absolute;
  top: 24px;
  left: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--color-accent-secondary);
  color: #fff;
  font-size: 0.75rem;
  font-weight: 700;
}

.feed-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  padding-left: 28px;
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.feed-avatar-link {
  display: inline-flex;
}

.feed-username {
  font-weight: 600;
  color: var(--color-ink);
  text-decoration: none;
}

.feed-username:hover {
  text-decoration: underline;
}

.feed-book-title {
  font-weight: 600;
  color: inherit;
  text-decoration: none;
}

.feed-book-title:hover {
  text-decoration: underline solid var(--color-highlight) 1px;
  text-underline-offset: 3px;
}

.feed-content-link {
  position: relative;
  display: block;
  padding-left: 28px;
  color: inherit;
  text-decoration: none;
}

.feed-passage {
  margin: 0 0 8px;
  font-size: 1.05rem;
  line-height: 1.6;
  white-space: pre-line;
  text-decoration: underline solid var(--color-highlight) 1px;
  text-underline-offset: 6px;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.feed-question-body {
  margin: 0 0 12px;
  font-weight: 600;
  font-size: 0.95rem;
  color: var(--color-ink);
  white-space: pre-line;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.feed-icon-row {
  display: flex;
  gap: 16px;
  padding-left: 28px;
  color: var(--color-accent-secondary);
  font-size: 0.85rem;
}

.feed-icon {
  color: inherit;
  text-decoration: none;
}
</style>
