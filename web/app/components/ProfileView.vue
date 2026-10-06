<template>
  <div class="profile-page">
    <div class="profile-header">
      <div class="avatar-ring">
        <img v-if="user.avatar_url" :src="user.avatar_url" alt="" class="avatar-img" />
        <span v-else class="avatar-placeholder">{{ initial }}</span>
      </div>
      <div class="profile-identity">
        <h1 class="serif profile-name">{{ user.name }}</h1>
        <p v-if="user.bio" class="profile-bio">{{ user.bio }}</p>
      </div>
      <div v-if="own" class="profile-actions">
        <NuxtLink to="/profile/edit" class="edit-link">{{ t('profile.editProfile') }}</NuxtLink>
        <button type="button" class="logout-link" @click="onLogout">{{ t('profile.logOut') }}</button>
      </div>
      <div v-else-if="canFollow" class="profile-actions">
        <FollowButton :user-id="user.id" :followed-by-user="!!user.followed_by_user" />
      </div>
      <ContributionLevel :user-id="user.id" />
    </div>

    <div v-if="interestProfile.length" class="profile-section">
      <h2 class="profile-section-title">{{ t('profile.interests.title') }}</h2>
      <InterestProfile :profile="interestProfile" />
    </div>

    <div v-if="similarReaders.length" class="profile-section">
      <h2 class="profile-section-title">{{ t('profile.similarReaders.title') }}</h2>
      <SimilarReaders :readers="similarReaders" />
    </div>
  </div>
</template>

<script setup lang="ts">
import InterestProfile from './InterestProfile.vue'
import SimilarReaders from './SimilarReaders.vue'
import ContributionLevel from './health/ContributionLevel.vue'
import type { InterestEntry } from './InterestProfile.vue'
import type { SimilarReader } from './SimilarReaders.vue'

const props = defineProps<{
  user: {
    id: string
    name: string
    bio: string | null
    avatar_url: string | null
    followed_by_user?: boolean
  }
  own?: boolean
}>()

const auth = useAuthStore()
const router = useRouter()
const { t } = useI18n()

const initial = computed(() => props.user.name?.[0]?.toUpperCase() ?? '?')
const canFollow = computed(() => !props.own && !!auth.user && auth.user.id !== props.user.id)

interface InterestsResponse {
  interest_profile: InterestEntry[]
  similar_readers: SimilarReader[]
}

const interestProfile = ref<InterestEntry[]>([])
const similarReaders = ref<SimilarReader[]>([])

// Fetched onMounted, not via a blocking top-level `await` — ProfileView is
// mounted directly by two pages (profile/index.vue and profile/[id].vue)
// with no Suspense boundary, same reasoning as ContributionLevel's fetch.
onMounted(async () => {
  try {
    const { request } = useApi()
    const res = await request<{ data: InterestsResponse }>(`/api/users/${props.user.id}/interests`)
    interestProfile.value = res.data.interest_profile
    similarReaders.value = res.data.similar_readers
  } catch {
    interestProfile.value = []
    similarReaders.value = []
  }
})

async function onLogout() {
  await auth.logout()
  router.push('/')
}
</script>

<style scoped>
.profile-page {
  max-width: 680px;
  margin: 0 auto;
  padding: 48px 24px;
}

.profile-header {
  display: flex;
  align-items: flex-start;
  gap: 20px;
}

.avatar-ring {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  border: 2px solid var(--color-chip-text);
  overflow: hidden;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-chip-fill);
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-placeholder {
  font-family: var(--font-serif);
  font-size: 2rem;
  color: var(--color-chip-text);
}

.profile-identity {
  flex: 1;
}

.profile-name {
  margin: 0 0 8px;
  font-size: 1.75rem;
}

.profile-bio {
  margin: 0;
  color: var(--color-text-secondary);
}

.profile-actions {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 8px;
}

.edit-link,
.logout-link {
  color: var(--color-accent-secondary);
  font-size: 0.9rem;
  text-decoration: none;
}

.logout-link {
  background: none;
  border: none;
  padding: 0;
  font-family: inherit;
  cursor: pointer;
}

.edit-link:hover,
.logout-link:hover {
  text-decoration: underline;
}

.profile-section {
  margin-top: 32px;
}

.profile-section-title {
  margin: 0 0 16px;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-ink);
}
</style>
