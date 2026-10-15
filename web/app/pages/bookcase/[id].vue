<template>
  <BookcaseView v-if="user" :user="user" :own="isOwnProfile" />
  <p v-else-if="pending" class="status-text">{{ t('bookcase.loading') }}</p>
  <p v-else class="status-text">{{ t('profile.userNotFound') }}</p>
</template>

<script setup lang="ts">
const { t } = useI18n()

interface BookcaseUser {
  id: string
  name: string
}

const route = useRoute()
const { data: user, pending } = await useApiFetch<BookcaseUser>(`/api/users/${route.params.id}`)

const auth = useAuthStore()
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
