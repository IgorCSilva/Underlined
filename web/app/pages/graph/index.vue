<template>
  <div class="graph-page">
    <div class="graph-header">
      <h1 class="serif underlined">{{ t('graph.title') }}</h1>
    </div>

    <p v-if="pending" class="status-text">{{ t('graph.loading') }}</p>
    <p v-else-if="!nodes.length" class="status-text">{{ t('graph.empty') }}</p>
    <GraphCanvas v-else :nodes="nodes" :edges="edges" class="graph-stage" />
  </div>
</template>

<script setup lang="ts">
import type { GraphEdgeData, GraphNodeData } from '~/components/GraphCanvas.vue'

definePageMeta({ middleware: 'auth' })

const { t } = useI18n()
const auth = useAuthStore()

const nodes = ref<GraphNodeData[]>([])
const edges = ref<GraphEdgeData[]>([])
const pending = ref(true)

interface GraphResponse {
  nodes: GraphNodeData[]
  edges: GraphEdgeData[]
}

// Fetched onMounted, not via a blocking top-level `await` — the auth
// middleware only redirects client-side (see app/middleware/auth.ts), so
// auth.user is never populated during SSR and a top-level fetch keyed on
// its id would run anonymous/wrong on the server, same reasoning as
// ProfileView's interests fetch.
onMounted(async () => {
  await auth.ensureInitialized()
  if (!auth.user) return

  try {
    const { request } = useApi()
    const res = await request<{ data: GraphResponse }>(`/api/users/${auth.user.id}/graph`)
    nodes.value = res.data.nodes
    edges.value = res.data.edges
  } finally {
    pending.value = false
  }
})
</script>

<style scoped>
.graph-page {
  display: flex;
  flex-direction: column;
  height: calc(100vh - var(--topbar-height));
}

.graph-header {
  padding: 24px 24px 0;
  flex-shrink: 0;
}

.graph-stage {
  flex: 1;
  min-height: 0;
}

.status-text {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text-secondary);
  padding: 48px 24px;
  text-align: center;
}
</style>
