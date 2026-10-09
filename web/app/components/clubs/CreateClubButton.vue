<template>
  <button type="button" class="create-club-button" @click="open">
    <span aria-hidden="true">+</span> {{ t('clubs.create') }}
  </button>

  <Teleport to="body">
    <div v-if="isOpen" class="create-club-overlay" @click.self="close">
      <div class="create-club-modal card" role="dialog" aria-modal="true">
        <h3 class="serif create-club-title">{{ t('clubs.new.title') }}</h3>

        <form @submit.prevent="submit">
          <div class="field">
            <label for="club-name">{{ t('clubs.new.nameLabel') }}</label>
            <input id="club-name" v-model="name" type="text" required maxlength="100" />
          </div>
          <div class="field">
            <label for="club-description">{{ t('clubs.new.descriptionLabel') }}</label>
            <textarea id="club-description" v-model="description" rows="3" maxlength="500" />
          </div>

          <p v-if="error" class="form-error">{{ error }}</p>

          <div class="create-club-actions">
            <button type="button" class="create-club-cancel" @click="close">
              {{ t('clubs.new.cancel') }}
            </button>
            <button type="submit" class="btn-primary create-club-submit" :disabled="pending">
              {{ pending ? t('clubs.new.creating') : t('clubs.new.submit') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import type { Club } from '~/stores/clubs'

const props = defineProps<{ bookId: string }>()
const emit = defineEmits<{ created: [club: Club] }>()

const { t } = useI18n()
const clubs = useClubsStore()

const isOpen = ref(false)
const name = ref('')
const description = ref('')
const pending = ref(false)
const error = ref('')

function open() {
  isOpen.value = true
  error.value = ''
}

function close() {
  isOpen.value = false
  name.value = ''
  description.value = ''
  error.value = ''
}

async function submit() {
  if (pending.value) return
  pending.value = true
  error.value = ''

  try {
    const club = await clubs.createClub(props.bookId, { name: name.value, description: description.value })
    emit('created', club)
    close()
  } catch {
    error.value = t('clubs.new.error')
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.create-club-button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: none;
  border: 1.5px dashed var(--color-accent-primary);
  border-radius: var(--radius-pill);
  color: var(--color-accent-primary);
  font-family: var(--font-sans);
  font-size: 0.9rem;
  font-weight: 600;
  padding: 8px 18px;
  cursor: pointer;
}

.create-club-overlay {
  position: fixed;
  inset: 0;
  background: rgba(34, 37, 43, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  z-index: 100;
}

.create-club-modal {
  width: 100%;
  max-width: 420px;
  padding: 28px;
}

.create-club-title {
  margin: 0 0 16px;
}

.create-club-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 8px;
}

.create-club-cancel {
  background: none;
  border: none;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 0.95rem;
  cursor: pointer;
}

.create-club-submit {
  width: auto;
  padding: 10px 20px;
}
</style>
