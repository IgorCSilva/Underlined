<template>
  <button
    type="button"
    class="bookmark-button"
    :class="{ 'is-saved': saved }"
    :disabled="pending"
    :aria-pressed="saved"
    :aria-label="t('bookmarks.ariaLabel')"
    @click.stop.prevent="toggle"
  >
    <svg viewBox="0 0 24 24" class="bookmark-icon" aria-hidden="true">
      <path
        d="M6 2.5A1.5 1.5 0 0 0 4.5 4v18l7.5-4.7 7.5 4.7V4A1.5 1.5 0 0 0 18 2.5H6Z"
        :fill="saved ? 'currentColor' : 'none'"
        stroke="currentColor"
        stroke-width="1.5"
      />
    </svg>
  </button>
</template>

<script setup lang="ts">
const props = defineProps<{ postId: string; bookmarkedByUser: boolean }>()
const { t } = useI18n()

const saved = ref(props.bookmarkedByUser)
const pending = ref(false)

watch(
  () => props.bookmarkedByUser,
  (value) => {
    saved.value = value
  },
)

const posts = usePostsStore()

async function toggle() {
  if (pending.value) return
  pending.value = true

  const wasSaved = saved.value
  saved.value = !wasSaved

  try {
    const result = wasSaved
      ? await posts.unbookmarkPost(props.postId)
      : await posts.bookmarkPost(props.postId)
    saved.value = result.bookmarked
  } catch {
    saved.value = wasSaved
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.bookmark-button {
  display: inline-flex;
  align-items: center;
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
  color: var(--color-text-secondary);
}

.bookmark-button:disabled {
  cursor: default;
  opacity: 0.8;
}

.bookmark-button.is-saved {
  color: var(--color-chip-text);
}

.bookmark-icon {
  width: 18px;
  height: 18px;
}
</style>
