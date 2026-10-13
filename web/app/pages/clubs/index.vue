<template>
  <div class="clubs-page">
    <h1 class="serif clubs-page-title">{{ t('clubs.browse.title') }}</h1>

    <p v-if="!clubs.length" class="status-text">{{ t('clubs.browse.empty') }}</p>
    <div v-else class="club-list">
      <ClubCard v-for="club in clubs" :key="club.id" :club="club" />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Club } from '~/stores/clubs'

const { t } = useI18n()
const clubsStore = useClubsStore()

const { data: clubsData } = await useApiFetch<Club[]>('/api/clubs')
const clubs = ref<Club[]>(clubsData.value ?? [])

// SSR always renders anonymous (no access token is available server-side),
// so a logged-in viewer's own `joined_by_user` never shows up in the
// hydrated payload. Once the client is ready, re-fetch with the auth header
// to correct it — same pattern as the book page's club section.
const auth = useAuthStore()
onMounted(async () => {
  await auth.ensureInitialized()
  if (!auth.accessToken) return
  clubs.value = await clubsStore.listClubs()
})
</script>

<style scoped>
.clubs-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.clubs-page-title {
  margin: 0 0 32px;
  font-size: 2rem;
}

.club-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
  padding: 48px 24px;
}
</style>
