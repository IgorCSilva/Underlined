<template>
  <ProfileView v-if="user" :user="user" />
  <p v-else-if="pending" class="status-text">Loading…</p>
  <p v-else class="status-text">User not found.</p>
</template>

<script setup lang="ts">
const route = useRoute()
const { data: user, pending } = await useApiFetch<{
  id: number
  name: string
  bio: string | null
  avatar_url: string | null
}>(`/api/users/${route.params.id}`)
</script>

<style scoped>
.status-text {
  max-width: 680px;
  margin: 48px auto;
  padding: 0 24px;
  color: var(--color-text-secondary);
}
</style>
