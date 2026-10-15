<template>
  <div v-if="club" class="club-page">
    <div class="club-header">
      <div class="club-cover">
        <img v-if="club.book.cover_url" :src="club.book.cover_url" alt="" />
        <span v-else class="club-cover-placeholder">📖</span>
      </div>
      <div class="club-header-info">
        <h1 class="serif club-title">{{ club.name }}</h1>
        <p class="club-book-title">{{ club.book.title }}</p>
        <p v-if="club.description" class="club-description">{{ club.description }}</p>
        <div class="club-header-meta">
          <ClubMemberAvatarStack :members="club.members_preview" :total-count="club.member_count" />
          <span class="club-member-count">{{ t('clubs.memberCount', { count: club.member_count }) }}</span>
          <ClubMembershipButton :club-id="club.id" :joined-by-user="club.joined_by_user" />
        </div>
      </div>
    </div>

    <div class="club-tabs" role="tablist">
      <button
        v-for="tab in TABS"
        :key="tab"
        type="button"
        class="club-tab"
        :class="{ 'is-active': activeTab === tab }"
        role="tab"
        :aria-selected="activeTab === tab"
        @click="activeTab = tab"
      >
        {{ t(`clubs.tabs.${tab}`) }}
      </button>
    </div>

    <p v-if="activeTab === 'discussion'" class="status-text">{{ t('clubs.discussionComingSoon') }}</p>
    <p v-else-if="activeTab === 'schedule'" class="status-text">{{ t('clubs.scheduleComingSoon') }}</p>
    <ul v-else class="club-member-list">
      <li v-for="member in members" :key="member.id" class="club-member-row">
        <AvatarCircle :name="member.name" :avatar-url="member.avatar_url" :size="40" />
        <span class="club-member-name">{{ member.name }}</span>
      </li>
    </ul>
  </div>
  <p v-else class="status-text">{{ t('clubs.notFound') }}</p>
</template>

<script setup lang="ts">
import type { Club, ClubMember } from '~/stores/clubs'

const TABS = ['discussion', 'members', 'schedule'] as const

const route = useRoute()
const { t } = useI18n()
const clubsStore = useClubsStore()

const { data: club } = await useApiFetch<Club>(`/api/clubs/${route.params.id}`)

// SSR always renders anonymous (no access token is available server-side),
// so a logged-in viewer's own `joined_by_user` never shows up in the
// hydrated payload. Once the client is ready, re-fetch with the auth header
// to correct it — same pattern as the book page's post list.
const auth = useAuthStore()
onMounted(async () => {
  await auth.ensureInitialized()
  if (!auth.accessToken || !club.value) return
  club.value = await clubsStore.getClub(club.value.id)
})

const activeTab = ref<(typeof TABS)[number]>('discussion')
const members = ref<ClubMember[]>([])
const membersLoaded = ref(false)

watch(activeTab, async (tab) => {
  if (tab !== 'members' || membersLoaded.value || !club.value) return
  members.value = await clubsStore.listMembers(club.value.id)
  membersLoaded.value = true
})
</script>

<style scoped>
.club-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.club-header {
  display: flex;
  gap: 24px;
  align-items: flex-start;
  margin-bottom: 32px;
}

.club-cover {
  flex: 0 0 160px;
  aspect-ratio: 2 / 3;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  background: var(--color-chip-fill);
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
}

.club-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.club-cover-placeholder {
  font-size: 2.5rem;
}

.club-header-info {
  flex: 1;
  padding-top: 8px;
}

.club-title {
  margin: 0 0 6px;
  font-size: 2rem;
}

.club-book-title {
  margin: 0 0 12px;
  color: var(--color-text-secondary);
}

.club-description {
  margin: 0 0 16px;
  color: var(--color-ink);
}

.club-header-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.club-member-count {
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.club-tabs {
  display: flex;
  gap: 24px;
  margin-bottom: 24px;
  border-bottom: 1px solid var(--color-border);
}

.club-tab {
  background: none;
  border: none;
  padding: 4px 0 12px;
  font-family: var(--font-sans);
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.club-tab.is-active {
  color: var(--color-ink);
  text-decoration: underline solid var(--color-highlight) 3px;
  text-underline-offset: 6px;
}

.status-text {
  text-align: center;
  color: var(--color-text-secondary);
  padding: 48px 24px;
}

.club-member-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.club-member-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.club-member-name {
  font-family: var(--font-sans);
  color: var(--color-ink);
}
</style>
