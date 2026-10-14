<template>
  <ol class="chain-timeline">
    <li
      v-for="(item, index) in items"
      :key="item.id"
      class="chain-step"
      :draggable="editable"
      @dragstart="onDragStart(index)"
      @dragover.prevent
      @drop="onDrop(index)"
    >
      <span v-if="editable" class="chain-grip" :aria-label="t('chains.dragToReorder')">⠿</span>

      <span class="chain-node">
        <img v-if="item.post.book.cover_url" :src="item.post.book.cover_url" alt="" class="chain-node-img" />
        <span v-else class="chain-node-placeholder">📖</span>
        <span class="chain-node-index">{{ index + 1 }}</span>
      </span>

      <NuxtLink :to="`/posts/${item.post.id}`" class="chain-card card">
        <span class="chain-card-book serif">{{ item.post.book.title }}</span>
        <p class="chain-card-passage serif">{{ item.post.passage.text }}</p>
      </NuxtLink>
    </li>
  </ol>
</template>

<script setup lang="ts">
import type { ChainItem } from '~/stores/chains'

const props = defineProps<{ items: ChainItem[]; editable?: boolean }>()
const emit = defineEmits<{ reorder: [itemIds: string[]] }>()
const { t } = useI18n()

let dragIndex: number | null = null

function onDragStart(index: number) {
  dragIndex = index
}

function onDrop(index: number) {
  if (dragIndex === null || dragIndex === index) {
    dragIndex = null
    return
  }

  const next = [...props.items]
  const [moved] = next.splice(dragIndex, 1)
  next.splice(index, 0, moved!)
  dragIndex = null
  emit('reorder', next.map((item) => item.id))
}
</script>

<style scoped>
.chain-timeline {
  position: relative;
  list-style: none;
  margin: 0;
  padding: 0;
}

.chain-timeline::before {
  content: '';
  position: absolute;
  left: 19px;
  top: 20px;
  bottom: 20px;
  width: 2px;
  background: var(--color-accent-secondary);
}

.chain-step {
  position: relative;
  display: flex;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 20px;
}

.chain-step:last-child {
  margin-bottom: 0;
}

.chain-grip {
  position: absolute;
  left: -22px;
  top: 10px;
  color: var(--color-text-secondary);
  font-size: 1rem;
  line-height: 1;
  opacity: 0;
  cursor: grab;
  transition: opacity 0.15s ease;
}

.chain-step:hover .chain-grip {
  opacity: 1;
}

.chain-node {
  position: relative;
  flex-shrink: 0;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  overflow: hidden;
  border: 2px solid var(--color-surface);
  outline: 2px solid var(--color-accent-secondary);
  background: var(--color-chip-fill);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1;
}

.chain-node-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.chain-node-placeholder {
  font-size: 1rem;
}

.chain-node-index {
  position: absolute;
  bottom: -2px;
  right: -2px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: var(--color-accent-secondary);
  color: #fff;
  font-family: var(--font-sans);
  font-size: 0.6rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}

.chain-card {
  flex: 1;
  display: block;
  padding: 14px 18px;
  text-decoration: none;
  color: inherit;
}

.chain-card-book {
  display: block;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-ink);
  margin-bottom: 4px;
}

.chain-card-passage {
  margin: 0;
  font-size: 1rem;
  line-height: 1.5;
  text-decoration: underline solid var(--color-highlight) 2px;
  text-underline-offset: 4px;
}
</style>
