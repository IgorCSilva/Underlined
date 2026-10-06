import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import SimilarReaders from '../../app/components/SimilarReaders.vue'

const stubs = { NuxtLink: { template: '<a><slot /></a>' }, AvatarCircle: true }

describe('SimilarReaders', () => {
  it('renders nothing when there are no similar readers', () => {
    const wrapper = mount(SimilarReaders, { props: { readers: [] }, global: { stubs } })
    expect(wrapper.find('.similar-readers').exists()).toBe(false)
  })

  it('renders an avatar and a shared-ideas pill for each reader', () => {
    const readers = [
      { id: 'user-2', name: 'Reader Two', avatar_url: null, shared_score: 18 },
      { id: 'user-3', name: 'Reader Three', avatar_url: null, shared_score: 4 },
    ]

    const wrapper = mount(SimilarReaders, { props: { readers }, global: { stubs } })
    const rows = wrapper.findAll('.similar-reader')

    expect(rows).toHaveLength(2)
    expect(rows[0]?.text()).toContain('18 shared ideas')
    expect(rows[1]?.text()).toContain('4 shared ideas')
  })

  it('links each reader to their own profile', () => {
    const readers = [{ id: 'user-2', name: 'Reader Two', avatar_url: null, shared_score: 18 }]
    const wrapper = mount(SimilarReaders, { props: { readers }, global: { stubs } })

    expect(wrapper.find('.similar-reader').attributes('to')).toBe('/profile/user-2')
  })
})
