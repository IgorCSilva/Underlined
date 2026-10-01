<template>
  <div>
    <TopBar />
    <main class="app-main">
      <slot />
    </main>
  </div>
</template>

<style scoped>
.app-main {
  padding-top: var(--topbar-height);
}
</style>
