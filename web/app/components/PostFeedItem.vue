<template>
  <div class="feed-item">
    <span v-if="showSavedBadge" class="feed-saved-badge" aria-hidden="true">🔖</span>
    <div class="feed-meta">
      <NuxtLink :to="`/profile/${post.user.id}`" class="feed-avatar-link">
        <AvatarCircle :name="post.user.name" :avatar-url="post.user.avatar_url" :size="28" />
      </NuxtLink>
      <span class="feed-meta-text">
        <NuxtLink :to="`/profile/${post.user.id}`" class="feed-username">{{ post.user.name }}</NuxtLink>
        {{ t('feed.on') }}
        <NuxtLink :to="`/books/${post.book.id}`" class="feed-book-title">{{ post.book.title }}</NuxtLink>
      </span>
    </div>

    <div v-if="showSpoilerBlur" class="feed-content-link">
      <p class="feed-passage serif is-spoiler">{{ post.passage.text }}</p>
      <p class="feed-thinking serif is-spoiler">{{ post.thinking }}</p>
      <button type="button" class="feed-spoiler-hint" @click="revealed = true">
        {{ t('posts.detail.spoilerHint') }}
      </button>
    </div>
    <NuxtLink v-else :to="`/posts/${post.id}`" class="feed-content-link">
      <p class="feed-passage serif">{{ post.passage.text }}</p>
      <p class="feed-thinking serif">{{ post.thinking }}</p>
    </NuxtLink>

    <div v-if="post.keywords.length" class="feed-keywords">
      <NuxtLink
        v-for="keyword in post.keywords"
        :key="keyword"
        :to="`/keywords/${encodeURIComponent(keyword)}`"
        class="feed-keyword-chip"
      >
        {{ keyword }}
      </NuxtLink>
    </div>

    <div class="feed-icon-row">
      <LikeButton :post-id="post.id" :liked-by-user="post.liked_by_user" :like-count="post.like_count" />
      <BookmarkButton :post-id="post.id" :bookmarked-by-user="post.bookmarked_by_user" />
      <NuxtLink :to="`/posts/${post.id}`" class="feed-icon">💬 {{ post.comment_count }}</NuxtLink>
      <ReportButton resource-type="post" :resource-id="post.id" />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Post } from '~/stores/posts'

const props = withDefaults(defineProps<{ post: Post; showSavedBadge?: boolean }>(), {
  showSavedBadge: false,
})
const { t } = useI18n()

const revealed = ref(false)
const showSpoilerBlur = computed(() => props.post.spoiler && !revealed.value)
</script>

<style scoped>
.feed-item {
  position: relative;
  display: block;
  padding: 24px 0;
  border-bottom: 1px solid var(--color-border);
}

.feed-saved-badge {
  position: absolute;
  top: 24px;
  right: 0;
  font-size: 0.85rem;
}

.feed-item:last-child {
  border-bottom: none;
}

.feed-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
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
  color: inherit;
  text-decoration: none;
}

.feed-content-link .is-spoiler {
  filter: blur(6px);
  user-select: none;
}

.feed-spoiler-hint {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 6px 14px;
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--color-ink);
  box-shadow: 0 2px 8px rgba(34, 37, 43, 0.12);
  white-space: nowrap;
  z-index: 1;
  cursor: pointer;
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

.feed-thinking {
  margin: 0 0 12px;
  font-style: italic;
  font-size: 0.95rem;
  color: var(--color-ink);
  white-space: pre-line;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.feed-keywords {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 12px;
}

.feed-keyword-chip {
  background: var(--color-chip-fill);
  color: var(--color-chip-text);
  padding: 4px 10px;
  border-radius: var(--radius-pill);
  font-size: 0.75rem;
  text-decoration: none;
}

.feed-keyword-chip:hover {
  text-decoration: underline solid var(--color-highlight) 2px;
  text-underline-offset: 3px;
}

.feed-icon-row {
  display: flex;
  gap: 16px;
  color: var(--color-accent-secondary);
  font-size: 0.85rem;
}

.feed-icon {
  color: inherit;
  text-decoration: none;
}
</style>
