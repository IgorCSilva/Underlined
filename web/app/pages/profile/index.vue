<template>
  <ProfileView v-if="auth.user" :user="auth.user" :own="true" />
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })
const auth = useAuthStore()
</script>
