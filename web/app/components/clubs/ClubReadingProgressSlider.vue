<template>
  <div class="progress-slider-wrap">
    <div class="progress-slider-row">
      <p class="progress-slider-label">{{ t('clubs.readingProgress.label') }}</p>
      <p class="progress-slider-current">{{ currentLabel }}</p>
    </div>
    <input
        type="range"
        class="progress-slider"
        min="0"
        :max="chapters.length"
        step="1"
        :value="position"
        :disabled="pending"
        @input="onInput"
        @change="onChange"
      />
    <div class="progress-slider-ticks" aria-hidden="true">
      <span
        v-for="step in chapters.length + 1"
        :key="step - 1"
        class="progress-slider-tick"
        :class="{ 'is-current': step - 1 === position }"
      >
        {{ step - 1 }}
      </span>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { ClubChapter } from '~/stores/clubs'

const props = defineProps<{ clubId: string; chapters: ClubChapter[]; currentChapterId: string | null }>()
const emit = defineEmits<{ 'progress-changed': [chapter: ClubChapter | null] }>()

const { t } = useI18n()
const clubs = useClubsStore()
const pending = ref(false)

const sorted = computed(() => [...props.chapters].sort((a, b) => a.position - b.position))

function positionFor(chapterId: string | null) {
  if (!chapterId) return 0
  const index = sorted.value.findIndex((c) => c.id === chapterId)
  return index === -1 ? 0 : index + 1
}

const position = ref(positionFor(props.currentChapterId))

watch(
  () => props.currentChapterId,
  (chapterId) => {
    position.value = positionFor(chapterId)
  },
)

const currentLabel = computed(() => {
  if (position.value === 0) return t('clubs.readingProgress.notStarted')
  return sorted.value[position.value - 1]?.label ?? t('clubs.readingProgress.notStarted')
})

function onInput(event: Event) {
  position.value = Number((event.target as HTMLInputElement).value)
}

async function onChange() {
  if (pending.value) return
  pending.value = true
  const chapter = position.value === 0 ? null : (sorted.value[position.value - 1] ?? null)
  try {
    await clubs.setReadingProgress(props.clubId, chapter?.id ?? null)
    emit('progress-changed', chapter)
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.progress-slider-wrap {
  margin-bottom: 24px;
  padding: 16px;
  border: 1px solid var(--color-border);
  border-radius: 12px;
  background: var(--color-surface);
}

.progress-slider-label {
  margin: 0 0 10px;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-text-secondary);
}

.progress-slider-row {
  display: flex;
  align-items: center;
  gap: 14px;
}

.progress-slider {
  flex: 1;
  -webkit-appearance: none;
  appearance: none;
  height: 4px;
  border-radius: var(--radius-pill);
  background: var(--color-chip-fill);
  accent-color: var(--color-accent-secondary);
  width: 100%;
}

.progress-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--color-accent-secondary);
  cursor: pointer;
}

.progress-slider::-moz-range-thumb {
  width: 18px;
  height: 18px;
  border: none;
  border-radius: 50%;
  background: var(--color-accent-secondary);
  cursor: pointer;
}

.progress-slider-current {
  flex-shrink: 0;
  max-width: 45%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-family: var(--font-sans);
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-accent-secondary);
  margin-top: 3px;
}

.progress-slider-ticks {
  display: flex;
  justify-content: space-between;
  margin-top: 4px;
  padding: 0 2px;
}

.progress-slider-tick {
  font-family: var(--font-sans);
  font-size: 0.7rem;
  color: var(--color-text-secondary);
  opacity: 0.7;
}

.progress-slider-tick.is-current {
  color: var(--color-accent-secondary);
  font-weight: 700;
  opacity: 1;
}
</style>
