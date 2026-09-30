<template>
  <div class="landing">
    <h1 class="serif">Underlined</h1>
    <p>A place to share what you're reading and thinking about.</p>
    <div class="landing-actions">
      <template v-if="!auth.user">
        <NuxtLink to="/signup" class="btn-primary">Sign up</NuxtLink>
        <NuxtLink to="/login">Log in</NuxtLink>
      </template>
      <NuxtLink v-else to="/profile">Go to your profile</NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
const auth = useAuthStore()
</script>

<style scoped>
.landing {
  max-width: 480px;
  margin: 0 auto;
  padding: 96px 24px;
  text-align: center;
}

.landing-actions {
  margin-top: 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  align-items: center;
}
</style>
