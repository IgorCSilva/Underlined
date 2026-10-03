<template>
  <button
    type="button"
    class="like-button"
    :class="{ 'is-liked': liked, 'is-bouncing': bouncing }"
    :disabled="pending"
    :aria-pressed="liked"
    :aria-label="t('likes.ariaLabel')"
    @click.stop.prevent="toggle"
  >
    <span class="like-icon">{{ liked ? '♥' : '♡' }}</span>
    <span class="like-count" :class="{ 'is-liked': liked }">{{ count }}</span>
  </button>
</template>

<script setup lang="ts">
const props = defineProps<{ postId: string; likedByUser: boolean; likeCount: number }>()
const { t } = useI18n()

const liked = ref(props.likedByUser)
const count = ref(props.likeCount)
const pending = ref(false)
const bouncing = ref(false)

watch(
  () => [props.likedByUser, props.likeCount] as const,
  ([likedByUser, likeCount]) => {
    liked.value = likedByUser
    count.value = likeCount
  },
)

const posts = usePostsStore()

async function toggle() {
  if (pending.value) return
  pending.value = true

  const wasLiked = liked.value
  liked.value = !wasLiked
  count.value += wasLiked ? -1 : 1

  if (!wasLiked) {
    bouncing.value = false
    await nextTick()
    bouncing.value = true
  }

  try {
    const result = wasLiked ? await posts.unlikePost(props.postId) : await posts.likePost(props.postId)
    liked.value = result.liked
    count.value = result.like_count
  } catch {
    liked.value = wasLiked
    count.value += wasLiked ? 1 : -1
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.like-button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
  font-family: var(--font-sans);
}

.like-button:disabled {
  cursor: default;
}

.like-icon {
  font-size: 1.1rem;
  line-height: 1;
  color: var(--color-text-secondary);
  transition: color 0.15s ease;
  display: inline-block;
}

.like-button.is-liked .like-icon {
  color: var(--color-accent-primary);
}

.like-button.is-bouncing .like-icon {
  animation: like-bounce 0.35s ease;
}

@keyframes like-bounce {
  0% {
    transform: scale(1);
  }
  40% {
    transform: scale(1.35);
  }
  100% {
    transform: scale(1);
  }
}

.like-count {
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.like-count.is-liked {
  color: var(--color-accent-primary);
}
</style>
