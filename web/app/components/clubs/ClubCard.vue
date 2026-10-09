<template>
  <NuxtLink :to="`/clubs/${club.id}`" class="club-card card">
    <div class="club-cover">
      <img v-if="club.book.cover_url" :src="club.book.cover_url" alt="" class="club-cover-img" />
      <span v-else class="club-cover-placeholder">📖</span>
    </div>

    <div class="club-info">
      <h3 class="serif club-name">{{ club.name }}</h3>
      <div class="club-meta">
        <ClubMemberAvatarStack :members="club.members_preview" :total-count="club.member_count" :size="28" />
        <span class="club-member-count">{{ t('clubs.memberCount', { count: club.member_count }) }}</span>
      </div>
    </div>

    <ClubMembershipButton :club-id="club.id" :joined-by-user="club.joined_by_user" class="club-join" />
  </NuxtLink>
</template>

<script setup lang="ts">
import type { Club } from '~/stores/clubs'

defineProps<{ club: Club }>()
const { t } = useI18n()
</script>

<style scoped>
.club-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  text-decoration: none;
  color: inherit;
  transition: box-shadow 0.15s ease;
}

.club-card:hover {
  box-shadow: 0 2px 8px rgba(34, 37, 43, 0.04);
}

.club-cover {
  flex: 0 0 64px;
  aspect-ratio: 2 / 3;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background: var(--color-chip-fill);
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
}

.club-cover-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.club-cover-placeholder {
  font-size: 1.5rem;
}

.club-info {
  flex: 1;
  min-width: 0;
}

.club-name {
  margin: 0 0 8px;
  font-size: 1.1rem;
}

.club-meta {
  display: flex;
  align-items: center;
  gap: 10px;
}

.club-member-count {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
}

.club-join {
  flex-shrink: 0;
}
</style>
