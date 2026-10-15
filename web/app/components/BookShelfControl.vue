<template>
  <div class="shelf-control" role="group" :aria-label="t('bookcase.shelfControl.label')">
    <button
      v-for="option in OPTIONS"
      :key="option"
      type="button"
      class="shelf-segment"
      :class="{ [`is-active-${option}`]: status === option }"
      :disabled="pending"
      :aria-pressed="status === option"
      @click="select(option)"
    >
      {{ t(`bookcase.status.${option}`) }}
    </button>
  </div>
</template>

<script setup lang="ts">
import type { BookcaseStatus } from '~/stores/userBooks'

const OPTIONS: BookcaseStatus[] = ['to_read', 'reading', 'read']

const props = defineProps<{ bookId: string }>()

const { t } = useI18n()
const auth = useAuthStore()
const userBooks = useUserBooksStore()

const status = ref<BookcaseStatus | null>(null)
const pending = ref(false)

// There's no "get my status for one book" endpoint — only the whole
// bookcase (GET /api/users/:id/bookcase) — so the current shelf is found
// by matching this book's id in that list, rather than adding a new
// backend endpoint just for this one lookup.
onMounted(async () => {
  await auth.ensureInitialized()
  if (!auth.user) return
  const entries = await userBooks.listBookcase(auth.user.id)
  status.value = entries.find((entry) => entry.book.id === props.bookId)?.status ?? null
})

async function select(option: BookcaseStatus) {
  if (pending.value || status.value === option) return
  pending.value = true
  const previous = status.value
  status.value = option

  try {
    const entry = await userBooks.setShelfStatus(props.bookId, option)
    status.value = entry.status
  } catch {
    status.value = previous
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.shelf-control {
  display: inline-flex;
  border-radius: var(--radius-pill);
  overflow: hidden;
  border: 1.5px solid var(--color-border);
}

.shelf-segment {
  background: none;
  border: none;
  border-left: 1.5px solid var(--color-border);
  padding: 8px 14px;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.shelf-segment:first-child {
  border-left: none;
}

.shelf-segment:disabled {
  cursor: default;
}

.shelf-segment.is-active-to_read {
  background: var(--color-chip-fill);
  color: var(--color-chip-text);
}

.shelf-segment.is-active-reading {
  background: var(--color-accent-secondary);
  color: #fff;
}

.shelf-segment.is-active-read {
  background: var(--color-success);
  color: #fff;
}
</style>
