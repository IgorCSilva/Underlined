import type { Post } from '~/stores/posts'

export interface ChainItem {
  id: string
  position: number
  post: Post
}

export interface Chain {
  id: string
  title: string
  inserted_at: string
  user: { id: string; name: string; avatar_url: string | null }
  items: ChainItem[]
}

interface ChainResponse {
  data: Chain
}

export const useChainsStore = defineStore('chains', {
  actions: {
    async createChain(title: string): Promise<Chain> {
      const { request } = useApi()
      const res = await request<ChainResponse>('/api/chains', {
        method: 'POST',
        body: { chain: { title } },
      })
      return res.data
    },

    async addChainItem(chainId: string, postId: string): Promise<Chain> {
      const { request } = useApi()
      const res = await request<ChainResponse>(`/api/chains/${chainId}/items`, {
        method: 'POST',
        body: { item: { post_id: postId } },
      })
      return res.data
    },

    async reorderChainItems(chainId: string, itemIds: string[]): Promise<Chain> {
      const { request } = useApi()
      const res = await request<ChainResponse>(`/api/chains/${chainId}/items`, {
        method: 'PUT',
        body: { item_ids: itemIds },
      })
      return res.data
    },
  },
})
