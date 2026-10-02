<template>
  <ProfileView v-if="user" :user="user" :own="isOwnProfile" />
  <p v-else-if="pending" class="status-text">Loading…</p>
  <p v-else class="status-text">User not found.</p>
</template>

<script setup lang="ts">
interface ProfileUser {
  id: string
  name: string
  bio: string | null
  avatar_url: string | null
  followed_by_user: boolean
}

const route = useRoute()
const { data: user, pending } = await useApiFetch<ProfileUser>(`/api/users/${route.params.id}`)

// SSR always renders anonymous, so followed_by_user is always false in the
// hydrated payload for a logged-in viewer — same reasoning as feed.vue's
// post-hydration reconciliation of liked_by_user.
const auth = useAuthStore()
onMounted(async () => {
  if (!auth.accessToken || !user.value) return
  const { request } = useApi()
  const fresh = await request<{ data: ProfileUser }>(`/api/users/${route.params.id}`)
  user.value = fresh.data
})

// A profile link (feed, post detail, comments) can point at your own id just
// as easily as someone else's — this route doesn't know which until it's
// loaded, so it can't assume "not own" the way /profile (index) can.
const isOwnProfile = computed(() => !!auth.user && auth.user.id === user.value?.id)
</script>

<style scoped>
.status-text {
  max-width: 680px;
  margin: 48px auto;
  padding: 0 24px;
  color: var(--color-text-secondary);
}
</style>
