<template>
  <CommunityHealthGate :available="available" class="contribution-level">
    <span class="seedlings">{{ available ? seedlings : '🌱' }}</span>
    <span v-if="trustLevel" class="trust-label">{{ t(`profile.trustLevels.${trustLevel}`) }}</span>
  </CommunityHealthGate>
</template>

<script setup lang="ts">
import CommunityHealthGate from './CommunityHealthGate.vue'

const props = defineProps<{ userId: string }>()
const { t } = useI18n()

interface CommunityHealthResponse {
  reputation_level: number | null
  trust_level: string | null
  community_health_available: boolean
}

// Fetched onMounted rather than via a blocking top-level `await`, same
// reasoning as ReportButton's CH-gated fetch — keeps this component (and
// anything that mounts it, like ProfileView) synchronous, no Suspense
// boundary required anywhere up the tree.
const available = ref(false)
const trustLevel = ref<string | null>(null)
const seedlings = ref('')

onMounted(async () => {
  try {
    const { request } = useApi()
    const res = await request<{ data: CommunityHealthResponse }>(`/api/users/${props.userId}/community_health`)
    available.value = res.data.community_health_available
    trustLevel.value = res.data.trust_level
    seedlings.value = '🌱'.repeat(res.data.reputation_level ?? 0)
  } catch {
    available.value = false
  }
})
</script>

<style scoped>
.contribution-level {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.seedlings {
  font-size: 1rem;
  letter-spacing: 1px;
}

.trust-label {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
}
</style>
