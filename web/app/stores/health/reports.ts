export interface ReportReason {
  code: string
  name: string
  description: string | null
  severity: string
}

interface ReasonsResponse {
  data: { rules: ReportReason[]; community_health_available: boolean }
}

export const useReportsStore = defineStore('reports', {
  state: () => ({
    reasons: [] as ReportReason[],
    // Fails closed by default — matches CommunityHealthNoop on the backend:
    // until a fetch proves otherwise, the gate stays shut.
    communityHealthAvailable: false,
    reasonsLoaded: false,
    loadingPromise: null as Promise<void> | null,
  }),

  actions: {
    // Multiple ReportButton instances on the same page (one per feed item)
    // call this on mount; memoized so only the first in-flight request
    // actually hits the network, every other caller awaits the same promise.
    ensureReasonsLoaded(): Promise<void> {
      if (this.reasonsLoaded) return Promise.resolve()
      if (this.loadingPromise) return this.loadingPromise

      const { request } = useApi()
      this.loadingPromise = request<ReasonsResponse>('/api/reports/reasons')
        .then((res) => {
          this.reasons = res.data.rules
          this.communityHealthAvailable = res.data.community_health_available
          this.reasonsLoaded = true
        })
        .catch(() => {
          this.reasons = []
          this.communityHealthAvailable = false
        })
        .finally(() => {
          this.loadingPromise = null
        })

      return this.loadingPromise
    },

    async submitReport(payload: {
      resourceType: 'post' | 'comment'
      resourceId: string
      reason: string
      description?: string
    }): Promise<void> {
      const { request } = useApi()
      await request('/api/reports', {
        method: 'POST',
        body: {
          report: {
            resource_type: payload.resourceType,
            resource_id: payload.resourceId,
            reason: payload.reason,
            description: payload.description,
          },
        },
      })
    },
  },
})
