export interface FollowResult {
  following: boolean
}

interface FollowResponse {
  data: FollowResult
}

export const useFollowsStore = defineStore('follows', {
  actions: {
    async followUser(userId: string): Promise<FollowResult> {
      const { request } = useApi()
      const res = await request<FollowResponse>(`/api/users/${userId}/follow`, { method: 'POST' })
      return res.data
    },

    async unfollowUser(userId: string): Promise<FollowResult> {
      const { request } = useApi()
      const res = await request<FollowResponse>(`/api/users/${userId}/follow`, { method: 'DELETE' })
      return res.data
    },
  },
})
