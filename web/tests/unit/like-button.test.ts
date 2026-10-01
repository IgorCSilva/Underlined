import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { flushPromises } from '@vue/test-utils'
import LikeButton from '../../app/components/LikeButton.vue'

describe('LikeButton', () => {
  it('renders the outline heart and count at rest', () => {
    const wrapper = mount(LikeButton, { props: { postId: 'post-1', likedByUser: false, likeCount: 3 } })

    expect(wrapper.find('.like-icon').text()).toBe('♡')
    expect(wrapper.find('.like-count').text()).toBe('3')
    expect(wrapper.classes()).not.toContain('is-liked')
  })

  it('renders the filled heart when already liked by the user', () => {
    const wrapper = mount(LikeButton, { props: { postId: 'post-1', likedByUser: true, likeCount: 4 } })

    expect(wrapper.find('.like-icon').text()).toBe('♥')
    expect(wrapper.classes()).toContain('is-liked')
  })

  it('likes the post and increments the count optimistically', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { liked: true, like_count: 4 } })
    vi.stubGlobal('$fetch', fetchMock)

    const wrapper = mount(LikeButton, { props: { postId: 'post-1', likedByUser: false, likeCount: 3 } })
    await wrapper.find('button').trigger('click')

    expect(wrapper.find('.like-count').text()).toBe('4')
    expect(wrapper.classes()).toContain('is-liked')

    await flushPromises()
    expect(fetchMock).toHaveBeenCalledWith('/api/posts/post-1/likes', expect.objectContaining({ method: 'POST' }))
  })

  it('unlikes the post and decrements the count', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { liked: false, like_count: 3 } })
    vi.stubGlobal('$fetch', fetchMock)

    const wrapper = mount(LikeButton, { props: { postId: 'post-1', likedByUser: true, likeCount: 4 } })
    await wrapper.find('button').trigger('click')
    await flushPromises()

    expect(wrapper.find('.like-count').text()).toBe('3')
    expect(wrapper.classes()).not.toContain('is-liked')
    expect(fetchMock).toHaveBeenCalledWith('/api/posts/post-1/likes', expect.objectContaining({ method: 'DELETE' }))
  })

  it('reverts the optimistic update if the request fails', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue(new Error('network error')))

    const wrapper = mount(LikeButton, { props: { postId: 'post-1', likedByUser: false, likeCount: 3 } })
    await wrapper.find('button').trigger('click')
    await flushPromises()

    expect(wrapper.find('.like-count').text()).toBe('3')
    expect(wrapper.classes()).not.toContain('is-liked')
  })
})
