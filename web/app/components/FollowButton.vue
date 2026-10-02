<template>
  <button
    type="button"
    class="follow-button"
    :class="{ 'is-following': following }"
    :disabled="pending"
    :aria-pressed="following"
    @click.stop.prevent="toggle"
  >
    <span v-if="following" class="follow-check">✓</span>
    {{ following ? 'Following' : 'Follow' }}
  </button>
</template>

<script setup lang="ts">
const props = defineProps<{ userId: string; followedByUser: boolean }>()

const following = ref(props.followedByUser)
const pending = ref(false)

watch(
  () => props.followedByUser,
  (value) => {
    following.value = value
  },
)

const follows = useFollowsStore()

async function toggle() {
  if (pending.value) return
  pending.value = true

  const wasFollowing = following.value
  following.value = !wasFollowing

  try {
    const result = wasFollowing
      ? await follows.unfollowUser(props.userId)
      : await follows.followUser(props.userId)
    following.value = result.following
  } catch {
    following.value = wasFollowing
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.follow-button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: none;
  border: 1.5px solid var(--color-accent-secondary);
  border-radius: var(--radius-pill);
  padding: 8px 18px;
  font-family: var(--font-sans);
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--color-accent-secondary);
  cursor: pointer;
}

.follow-button:disabled {
  cursor: default;
  opacity: 0.8;
}

.follow-button.is-following {
  background: var(--color-accent-secondary);
  color: #fff;
}

.follow-check {
  font-size: 0.85rem;
  line-height: 1;
}
</style>
