<template>
  <div class="chapter-strip-wrap">
    <div v-if="chapters.length" class="chapter-strip" role="list">
      <button
        v-for="chapter in chapters"
        :key="chapter.id"
        type="button"
        role="listitem"
        class="chapter-pill"
        :class="statusClass(chapter)"
        :disabled="!canManage || pendingId === chapter.id"
        @click="selectCurrent(chapter)"
      >
        {{ chapter.label }}
      </button>

      <button
        v-if="canManage && !addingChapter"
        type="button"
        class="chapter-pill chapter-add-trigger"
        @click="addingChapter = true"
      >
        + {{ t('clubs.chapters.add', { unit: unitLabel }) }}
      </button>
    </div>

    <p v-else-if="!canManage" class="chapter-strip-empty">{{ t('clubs.chapters.none', { unit: unitLabel }) }}</p>

    <form v-if="canManage && (addingChapter || !chapters.length)" class="chapter-add-form" @submit.prevent="onSubmit">
      <input
        v-model="newLabel"
        type="text"
        class="chapter-add-input"
        :placeholder="t('clubs.chapters.labelPlaceholder', { unit: unitLabel })"
        :aria-label="t('clubs.chapters.labelPlaceholder', { unit: unitLabel })"
        :disabled="pendingCreate"
      />
      <input
        v-if="!chapters.length"
        v-model="newUnitLabel"
        type="text"
        class="chapter-add-input chapter-unit-input"
        :placeholder="t('clubs.chapters.unitPlaceholder')"
        :aria-label="t('clubs.chapters.unitPlaceholder')"
        :disabled="pendingCreate"
      />
      <button type="submit" class="chapter-add-submit" :disabled="pendingCreate || !newLabel.trim()">
        {{ t('clubs.chapters.save') }}
      </button>
      <button v-if="chapters.length" type="button" class="chapter-add-cancel" @click="addingChapter = false">
        {{ t('clubs.chapters.cancel') }}
      </button>
      <p v-if="error" class="chapter-add-error">{{ error }}</p>
    </form>
  </div>
</template>

<script setup lang="ts">
import type { ClubChapter } from '~/stores/clubs'

const props = defineProps<{ clubId: string; chapters: ClubChapter[]; unitLabel: string; canManage: boolean }>()
const emit = defineEmits<{ 'chapter-added': [chapter: ClubChapter]; 'current-changed': [chapter: ClubChapter] }>()

const { t } = useI18n()
const clubs = useClubsStore()

const addingChapter = ref(false)
const newLabel = ref('')
const newUnitLabel = ref('')
const pendingCreate = ref(false)
const pendingId = ref<string | null>(null)
const error = ref('')

const currentPosition = computed(() => props.chapters.find((c) => c.current)?.position ?? null)

function statusClass(chapter: ClubChapter) {
  if (chapter.current) return 'is-current'
  if (currentPosition.value !== null && chapter.position < currentPosition.value) return 'is-completed'
  return 'is-upcoming'
}

async function onSubmit() {
  if (pendingCreate.value || !newLabel.value.trim()) return
  pendingCreate.value = true
  error.value = ''
  try {
    const chapter = await clubs.createChapter(props.clubId, {
      label: newLabel.value.trim(),
      chapter_unit_label: newUnitLabel.value.trim() || undefined,
    })
    newLabel.value = ''
    newUnitLabel.value = ''
    addingChapter.value = false
    emit('chapter-added', chapter)
  } catch (err) {
    error.value = extractErrorMessage(err, t)
  } finally {
    pendingCreate.value = false
  }
}

async function selectCurrent(chapter: ClubChapter) {
  if (!props.canManage || chapter.current || pendingId.value) return
  pendingId.value = chapter.id
  try {
    const updated = await clubs.setCurrentChapter(props.clubId, chapter.id)
    emit('current-changed', updated)
  } finally {
    pendingId.value = null
  }
}
</script>

<style scoped>
.chapter-strip-wrap {
  margin-bottom: 24px;
}

.chapter-strip {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  padding-bottom: 4px;
}

.chapter-pill {
  flex-shrink: 0;
  background: none;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 8px 16px;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-text-secondary);
  cursor: pointer;
  white-space: nowrap;
}

.chapter-pill:disabled {
  cursor: default;
}

.chapter-pill.is-completed {
  border-color: var(--color-success);
  color: var(--color-success);
}

.chapter-pill.is-current {
  background: var(--color-accent-secondary);
  border-color: var(--color-accent-secondary);
  color: #fff;
}

.chapter-pill.is-upcoming {
  color: var(--color-text-secondary);
  opacity: 0.7;
}

.chapter-add-trigger {
  color: var(--color-accent-primary);
  border-style: dashed;
  border-color: var(--color-accent-primary);
  opacity: 1;
}

.chapter-strip-empty {
  color: var(--color-text-secondary);
  font-size: 0.9rem;
  margin: 0 0 12px;
}

.chapter-add-form {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin-top: 12px;
}

.chapter-add-input {
  flex: 1;
  min-width: 160px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 8px 16px;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  background: var(--color-surface);
  color: var(--color-ink);
}

.chapter-unit-input {
  flex: 0 0 140px;
}

.chapter-add-input:focus {
  outline: none;
  border-color: var(--color-accent-secondary);
}

.chapter-add-submit {
  background: var(--color-accent-primary);
  color: #fff;
  border: none;
  border-radius: var(--radius-pill);
  font-family: var(--font-sans);
  font-weight: 700;
  font-size: 0.85rem;
  padding: 8px 16px;
  cursor: pointer;
}

.chapter-add-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.chapter-add-cancel {
  background: none;
  border: none;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 0.85rem;
  cursor: pointer;
}

.chapter-add-error {
  flex-basis: 100%;
  margin: 4px 0 0;
  color: var(--color-accent-primary);
  font-size: 0.8rem;
}
</style>
