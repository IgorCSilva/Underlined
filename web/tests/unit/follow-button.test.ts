import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { flushPromises } from '@vue/test-utils'
import FollowButton from '../../app/components/FollowButton.vue'

describe('FollowButton', () => {
  it('renders the outline "Follow" label at rest', () => {
    const wrapper = mount(FollowButton, { props: { userId: 'user-1', followedByUser: false } })

    expect(wrapper.text()).toBe('Follow')
    expect(wrapper.classes()).not.toContain('is-following')
  })

  it('renders the filled "Following" state when already followed', () => {
    const wrapper = mount(FollowButton, { props: { userId: 'user-1', followedByUser: true } })

    expect(wrapper.text()).toContain('Following')
    expect(wrapper.classes()).toContain('is-following')
  })

  it('follows the user optimistically', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { following: true } })
    vi.stubGlobal('$fetch', fetchMock)

    const wrapper = mount(FollowButton, { props: { userId: 'user-1', followedByUser: false } })
    await wrapper.find('button').trigger('click')

    expect(wrapper.classes()).toContain('is-following')

    await flushPromises()
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/users/user-1/follow',
      expect.objectContaining({ method: 'POST' }),
    )
  })

  it('unfollows the user optimistically', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { following: false } })
    vi.stubGlobal('$fetch', fetchMock)

    const wrapper = mount(FollowButton, { props: { userId: 'user-1', followedByUser: true } })
    await wrapper.find('button').trigger('click')
    await flushPromises()

    expect(wrapper.classes()).not.toContain('is-following')
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/users/user-1/follow',
      expect.objectContaining({ method: 'DELETE' }),
    )
  })

  it('reverts the optimistic update if the request fails', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue(new Error('network error')))

    const wrapper = mount(FollowButton, { props: { userId: 'user-1', followedByUser: false } })
    await wrapper.find('button').trigger('click')
    await flushPromises()

    expect(wrapper.classes()).not.toContain('is-following')
  })
})
