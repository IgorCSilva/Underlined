<template>
  <div class="schedule-view">
    <p v-if="!chapters.length" class="schedule-empty">{{ t('clubs.schedule.empty', { unit: unitLabel }) }}</p>

    <ol v-else class="schedule-list">
      <li v-for="(chapter, index) in chapters" :key="chapter.id" class="schedule-row" :class="statusClass(chapter)">
        <template v-if="editingId === chapter.id">
          <form class="schedule-edit-form" @submit.prevent="onSaveEdit(chapter)">
            <input
              v-model="editLabel"
              type="text"
              class="schedule-edit-input"
              :placeholder="t('clubs.schedule.labelPlaceholder', { unit: unitLabel })"
              :disabled="pendingEdit"
            />
            <input
              v-model="editTargetDate"
              type="date"
              class="schedule-edit-date"
              :aria-label="t('clubs.schedule.targetDatePlaceholder')"
              :disabled="pendingEdit"
            />
            <button type="submit" class="schedule-edit-save" :disabled="pendingEdit || !editLabel.trim()">
              {{ t('clubs.schedule.save') }}
            </button>
            <button type="button" class="schedule-edit-cancel" :disabled="pendingEdit" @click="cancelEdit">
              {{ t('clubs.schedule.cancel') }}
            </button>
            <p v-if="editError" class="schedule-edit-error">{{ editError }}</p>
          </form>
        </template>

        <template v-else>
          <span class="schedule-status-dot" aria-hidden="true" />
          <div class="schedule-row-main">
            <span class="schedule-row-label">{{ chapter.label }}</span>
            <span v-if="chapter.target_date" class="schedule-row-date">
              {{ t('clubs.schedule.targetDate', { date: formatDate(chapter.target_date) }) }}
            </span>
          </div>
          <div v-if="canManage" class="schedule-row-actions">
            <button
              type="button"
              class="schedule-move-btn"
              :disabled="index === 0 || !!pendingMoveId"
              :aria-label="t('clubs.schedule.moveUp')"
              @click="onMove(chapter, 'up')"
            >
              ↑
            </button>
            <button
              type="button"
              class="schedule-move-btn"
              :disabled="index === chapters.length - 1 || !!pendingMoveId"
              :aria-label="t('clubs.schedule.moveDown')"
              @click="onMove(chapter, 'down')"
            >
              ↓
            </button>
            <button type="button" class="schedule-edit-trigger" @click="startEdit(chapter)">
              {{ t('clubs.schedule.edit') }}
            </button>
          </div>
        </template>
      </li>
    </ol>

    <form v-if="canManage && chapters.length" class="schedule-add-form" @submit.prevent="onAdd">
      <input
        v-model="newLabel"
        type="text"
        class="schedule-edit-input"
        :placeholder="t('clubs.schedule.labelPlaceholder', { unit: unitLabel })"
        :disabled="pendingAdd"
      />
      <input
        v-model="newTargetDate"
        type="date"
        class="schedule-edit-date"
        :aria-label="t('clubs.schedule.targetDatePlaceholder')"
        :disabled="pendingAdd"
      />
      <button type="submit" class="schedule-edit-save" :disabled="pendingAdd || !newLabel.trim()">
        {{ t('clubs.schedule.add', { unit: unitLabel }) }}
      </button>
      <p v-if="addError" class="schedule-edit-error">{{ addError }}</p>
    </form>
  </div>
</template>

<script setup lang="ts">
import type { ClubChapter } from '~/stores/clubs'

const props = defineProps<{ clubId: string; chapters: ClubChapter[]; unitLabel: string; canManage: boolean }>()
const emit = defineEmits<{ 'chapter-changed': [chapter: ClubChapter]; 'chapter-added': [chapter: ClubChapter] }>()

const { t } = useI18n()
const { formatDate } = useLocaleFormat()
const clubs = useClubsStore()

const currentPosition = computed(() => props.chapters.find((c) => c.current)?.position ?? null)

function statusClass(chapter: ClubChapter) {
  if (chapter.current) return 'is-current'
  if (currentPosition.value !== null && chapter.position < currentPosition.value) return 'is-completed'
  return 'is-upcoming'
}

const pendingMoveId = ref<string | null>(null)

async function onMove(chapter: ClubChapter, direction: 'up' | 'down') {
  if (pendingMoveId.value) return
  pendingMoveId.value = chapter.id
  try {
    const updated = await clubs.moveChapter(props.clubId, chapter.id, direction)
    emit('chapter-changed', updated)
  } finally {
    pendingMoveId.value = null
  }
}

const editingId = ref<string | null>(null)
const editLabel = ref('')
const editTargetDate = ref('')
const pendingEdit = ref(false)
const editError = ref('')

function startEdit(chapter: ClubChapter) {
  editingId.value = chapter.id
  editLabel.value = chapter.label
  editTargetDate.value = chapter.target_date ?? ''
  editError.value = ''
}

function cancelEdit() {
  editingId.value = null
}

async function onSaveEdit(chapter: ClubChapter) {
  if (pendingEdit.value || !editLabel.value.trim()) return
  pendingEdit.value = true
  editError.value = ''
  try {
    const updated = await clubs.updateChapter(props.clubId, chapter.id, {
      label: editLabel.value.trim(),
      target_date: editTargetDate.value || null,
    })
    editingId.value = null
    emit('chapter-changed', updated)
  } catch (err) {
    editError.value = extractErrorMessage(err, t)
  } finally {
    pendingEdit.value = false
  }
}

const newLabel = ref('')
const newTargetDate = ref('')
const pendingAdd = ref(false)
const addError = ref('')

async function onAdd() {
  if (pendingAdd.value || !newLabel.value.trim()) return
  pendingAdd.value = true
  addError.value = ''
  try {
    const chapter = await clubs.createChapter(props.clubId, {
      label: newLabel.value.trim(),
      target_date: newTargetDate.value || null,
    })
    newLabel.value = ''
    newTargetDate.value = ''
    emit('chapter-added', chapter)
  } catch (err) {
    addError.value = extractErrorMessage(err, t)
  } finally {
    pendingAdd.value = false
  }
}
</script>

<style scoped>
.schedule-view {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.schedule-empty {
  color: var(--color-text-secondary);
  font-size: 0.9rem;
  margin: 0;
}

.schedule-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.schedule-row {
  display: flex;
  align-items: center;
  gap: 12px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  padding: 12px 16px;
  background: var(--color-surface);
}

.schedule-status-dot {
  flex-shrink: 0;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  border: 2px solid var(--color-text-secondary);
  background: transparent;
}

.schedule-row.is-completed .schedule-status-dot {
  border-color: var(--color-success);
  background: var(--color-success);
}

.schedule-row.is-current .schedule-status-dot {
  border-color: var(--color-accent-secondary);
  background: var(--color-accent-secondary);
}

.schedule-row.is-completed {
  border-color: var(--color-success);
}

.schedule-row.is-current {
  border-color: var(--color-accent-secondary);
}

.schedule-row.is-upcoming {
  opacity: 0.75;
}

.schedule-row-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.schedule-row-label {
  font-family: var(--font-sans);
  font-weight: 600;
  color: var(--color-ink);
}

.schedule-row-date {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
}

.schedule-row-actions {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}

.schedule-move-btn {
  background: none;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  width: 28px;
  height: 28px;
  line-height: 1;
  cursor: pointer;
  color: var(--color-text-secondary);
}

.schedule-move-btn:disabled {
  opacity: 0.4;
  cursor: default;
}

.schedule-edit-trigger {
  background: none;
  border: none;
  color: var(--color-accent-primary);
  font-family: var(--font-sans);
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
}

.schedule-edit-form,
.schedule-add-form {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  width: 100%;
}

.schedule-add-form {
  border: 1px dashed var(--color-border);
  border-radius: 10px;
  padding: 12px 16px;
}

.schedule-edit-input {
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

.schedule-edit-date {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 7px 12px;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  background: var(--color-surface);
  color: var(--color-ink);
}

.schedule-edit-input:focus,
.schedule-edit-date:focus {
  outline: none;
  border-color: var(--color-accent-secondary);
}

.schedule-edit-save {
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

.schedule-edit-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.schedule-edit-cancel {
  background: none;
  border: none;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 0.85rem;
  cursor: pointer;
}

.schedule-edit-error {
  flex-basis: 100%;
  margin: 0;
  color: var(--color-accent-primary);
  font-size: 0.8rem;
}
</style>
