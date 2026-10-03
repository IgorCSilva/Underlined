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
    </div>
  </div>
</template>

<script setup lang="ts">
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
</style>
