<template>
  <div v-if="connections.length" class="post-connections">
    <NuxtLink
      v-for="connection in connections"
      :key="connection.id"
      :to="`/posts/${connection.connected_post.id}`"
      class="connection-row"
    >
      <span class="connection-pill" :class="`is-${connection.relationship_type}`">
        <span class="connection-icon" aria-hidden="true">{{ icon(connection.relationship_type) }}</span>
        {{ t(`posts.connections.types.${connection.relationship_type}`) }}
      </span>
      <span class="connection-book">{{ connection.connected_post.book.title }}</span>
    </NuxtLink>
  </div>
</template>

<script setup lang="ts">
import type { Connection, RelationshipType } from '~/stores/posts'

defineProps<{ connections: Connection[] }>()
const { t } = useI18n()

const ICONS: Record<RelationshipType, string> = {
  similar_idea: '↔',
  opposite_idea: '⇌',
  expands_on: '→',
  contradicts: '⇌',
  example_of: '→',
  personal_connection: '⤳',
}

function icon(type: RelationshipType): string {
  return ICONS[type]
}
</script>

<style scoped>
.post-connections {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  margin-top: 16px;
}

.connection-row {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: inherit;
}

.connection-pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  color: #fff;
  font-family: var(--font-sans);
  font-size: 0.75rem;
  font-weight: 600;
  padding: 4px 12px;
  border-radius: var(--radius-pill);
  white-space: nowrap;
}

.connection-icon {
  line-height: 1;
}

.connection-pill.is-similar_idea {
  background: var(--color-success);
}

.connection-pill.is-opposite_idea,
.connection-pill.is-contradicts {
  background: var(--color-accent-primary);
}

.connection-pill.is-expands_on,
.connection-pill.is-example_of {
  background: var(--color-accent-secondary);
}

.connection-pill.is-personal_connection {
  background: var(--color-chip-text);
}

.connection-book {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
}
</style>
