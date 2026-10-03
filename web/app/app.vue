<template>
  <div>
    <NuxtRouteAnnouncer />
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </div>
</template>

<script setup lang="ts">
const head = useLocaleHead()
useHead({
  htmlAttrs: computed(() => head.value.htmlAttrs),
})
</script>
