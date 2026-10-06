import { describe, expect, it, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import ContributionLevel from '../../app/components/health/ContributionLevel.vue'

describe('ContributionLevel', () => {
  it('renders greyed-out (unavailable) until the fetch resolves, then shows seedlings + trust', async () => {
    vi.stubGlobal(
      '$fetch',
      vi.fn().mockResolvedValue({
        data: { reputation_level: 3, trust_level: 'medium', community_health_available: true },
      }),
    )

    const wrapper = mount(ContributionLevel, { props: { userId: 'user-1' } })
    expect(wrapper.classes()).toContain('is-unavailable')

    await flushPromises()

    expect(wrapper.classes()).not.toContain('is-unavailable')
    expect(wrapper.text()).toContain('🌱🌱🌱')
    expect(wrapper.text()).toContain('Medium trust')
  })

  it('fails closed (stays greyed-out) when Community Health is unavailable', async () => {
    vi.stubGlobal(
      '$fetch',
      vi.fn().mockResolvedValue({
        data: { reputation_level: null, trust_level: null, community_health_available: false },
      }),
    )

    const wrapper = mount(ContributionLevel, { props: { userId: 'user-1' } })
    await flushPromises()

    expect(wrapper.classes()).toContain('is-unavailable')
  })

  it('fails closed when the request errors', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue(new Error('network error')))

    const wrapper = mount(ContributionLevel, { props: { userId: 'user-1' } })
    await flushPromises()

    expect(wrapper.classes()).toContain('is-unavailable')
  })
})
