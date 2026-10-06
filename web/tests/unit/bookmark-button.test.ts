import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { flushPromises } from '@vue/test-utils'
import BookmarkButton from '../../app/components/BookmarkButton.vue'

describe('BookmarkButton', () => {
  it('renders the outline ribbon at rest', () => {
    const wrapper = mount(BookmarkButton, { props: { postId: 'post-1', bookmarkedByUser: false } })

    expect(wrapper.find('path').attributes('fill')).toBe('none')
    expect(wrapper.classes()).not.toContain('is-saved')
  })

  it('renders the filled ribbon when already bookmarked by the user', () => {
    const wrapper = mount(BookmarkButton, { props: { postId: 'post-1', bookmarkedByUser: true } })

    expect(wrapper.find('path').attributes('fill')).toBe('currentColor')
    expect(wrapper.classes()).toContain('is-saved')
  })

  it('bookmarks the post optimistically', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { bookmarked: true } })
    vi.stubGlobal('$fetch', fetchMock)

    const wrapper = mount(BookmarkButton, { props: { postId: 'post-1', bookmarkedByUser: false } })
    await wrapper.find('button').trigger('click')

    expect(wrapper.classes()).toContain('is-saved')

    await flushPromises()
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/posts/post-1/bookmarks',
      expect.objectContaining({ method: 'POST' }),
    )
  })

  it('unbookmarks the post', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: { bookmarked: false } })
    vi.stubGlobal('$fetch', fetchMock)

    const wrapper = mount(BookmarkButton, { props: { postId: 'post-1', bookmarkedByUser: true } })
    await wrapper.find('button').trigger('click')
    await flushPromises()

    expect(wrapper.classes()).not.toContain('is-saved')
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/posts/post-1/bookmarks',
      expect.objectContaining({ method: 'DELETE' }),
    )
  })

  it('reverts the optimistic update if the request fails', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue(new Error('network error')))

    const wrapper = mount(BookmarkButton, { props: { postId: 'post-1', bookmarkedByUser: false } })
    await wrapper.find('button').trigger('click')
    await flushPromises()

    expect(wrapper.classes()).not.toContain('is-saved')
  })
})
