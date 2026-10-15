<template>
  <button
    type="button"
    class="membership-button"
    :class="{ 'is-joined': joined }"
    :disabled="pending"
    :aria-pressed="joined"
    @click.stop.prevent="toggle"
  >
    <span v-if="joined" class="membership-check">✓</span>
    {{ joined ? t('clubs.joined') : t('clubs.join') }}
  </button>
</template>

<script setup lang="ts">
const props = defineProps<{ clubId: string; joinedByUser: boolean }>()
const emit = defineEmits<{ changed: [joined: boolean] }>()
const { t } = useI18n()

const joined = ref(props.joinedByUser)
const pending = ref(false)

watch(
  () => props.joinedByUser,
  (value) => {
    joined.value = value
  },
)

const clubs = useClubsStore()

async function toggle() {
  if (pending.value) return
  pending.value = true

  const wasJoined = joined.value
  joined.value = !wasJoined

  try {
    const result = wasJoined ? await clubs.leaveClub(props.clubId) : await clubs.joinClub(props.clubId)
    joined.value = result.joined
    emit('changed', joined.value)
  } catch {
    joined.value = wasJoined
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.membership-button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: none;
  border: 1.5px solid var(--color-accent-primary);
  border-radius: var(--radius-pill);
  padding: 8px 18px;
  font-family: var(--font-sans);
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--color-accent-primary);
  cursor: pointer;
}

.membership-button:disabled {
  cursor: default;
  opacity: 0.8;
}

.membership-button.is-joined {
  background: var(--color-accent-primary);
  color: #fff;
}

.membership-check {
  font-size: 0.85rem;
  line-height: 1;
}
</style>
