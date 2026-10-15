<template>
  <button
    type="button"
    class="wishlist-button"
    :class="{ 'is-wishlisted': wishlisted, 'is-bouncing': bouncing }"
    :disabled="pending"
    :aria-pressed="wishlisted"
    :aria-label="t('bookcase.wishlist.ariaLabel')"
    @click.stop.prevent="toggle"
  >
    <span class="wishlist-icon">{{ wishlisted ? '♥' : '♡' }}</span>
  </button>
</template>

<script setup lang="ts">
const props = defineProps<{ bookId: string }>()
const { t } = useI18n()
const auth = useAuthStore()
const wishlist = useWishlistStore()

const wishlisted = ref(false)
const pending = ref(false)
const bouncing = ref(false)

// There's no "is this one book wishlisted" endpoint — only the whole
// wishlist (GET /api/users/:id/wishlist) — so the current state is found
// by matching this book's id in that list, same approach
// BookShelfControl.vue uses for its own shelf status.
onMounted(async () => {
  await auth.ensureInitialized()
  if (!auth.user) return
  await wishlist.ensureLoaded(auth.user.id)
  wishlisted.value = wishlist.isWishlisted(props.bookId)
})

async function toggle() {
  if (pending.value) return
  pending.value = true

  const was = wishlisted.value
  wishlisted.value = !was

  if (!was) {
    bouncing.value = false
    await nextTick()
    bouncing.value = true
  }

  try {
    wishlisted.value = was
      ? await wishlist.removeFromWishlist(props.bookId)
      : await wishlist.addToWishlist(props.bookId)
  } catch {
    wishlisted.value = was
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.wishlist-button {
  display: inline-flex;
  align-items: center;
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
  font-family: var(--font-sans);
}

.wishlist-button:disabled {
  cursor: default;
}

.wishlist-icon {
  font-size: 1.1rem;
  line-height: 1;
  color: var(--color-text-secondary);
  transition: color 0.15s ease;
  display: inline-block;
}

.wishlist-button.is-wishlisted .wishlist-icon {
  color: var(--color-accent-primary);
}

.wishlist-button.is-bouncing .wishlist-icon {
  animation: wishlist-bounce 0.35s ease;
}

@keyframes wishlist-bounce {
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
</style>
