<template>
  <div class="landing">
    <h1 class="serif underlined">Underlined</h1>
    <p style="font-size: 20px">{{ t('common.home.tagline') }}</p>
    <p>{{ t('common.home.tagline2') }}</p>
    <div class="landing-actions">
      <template v-if="!auth.user">
        <NuxtLink to="/signup" class="btn-primary">{{ t('nav.signup') }}</NuxtLink>
        <NuxtLink to="/login">{{ t('nav.login') }}</NuxtLink>
      </template>
      <NuxtLink v-else to="/profile">{{ t('common.home.goToProfile') }}</NuxtLink>
      <NuxtLink to="/feed">{{ t('common.home.seeFeed') }}</NuxtLink>
      <NuxtLink to="/books">{{ t('common.home.browseBooks') }}</NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
const auth = useAuthStore()
const { t } = useI18n()
</script>

<style scoped>
h1 {
  margin-bottom: 54px;
}
.landing {
  max-width: 520px;
  margin: 0 auto;
  padding: 96px 24px;
  text-align: center;
}

.landing-actions {
  margin-top: 62px;
  display: none;
  flex-direction: column;
  gap: 12px;
  align-items: center;
}
</style>
