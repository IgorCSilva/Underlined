import { describe, expect, it, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import CommentComposer from '../../app/components/CommentComposer.vue'

describe('CommentComposer', () => {
  it('posts the typed body and emits the created comment', async () => {
    const fakeComment = {
      id: 'c1',
      type: 'comment',
      body: 'Great read!',
      inserted_at: '2026-10-01T00:00:00Z',
      parent_comment_id: null,
      user: { id: 'u1', name: 'Reader One', avatar_url: null },
      replies: [],
    }
    vi.stubGlobal('$fetch', vi.fn().mockResolvedValue({ data: fakeComment }))

    const wrapper = mount(CommentComposer, { props: { basePath: '/api/posts/post-1' } })
    await wrapper.find('.comment-input').setValue('Great read!')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(wrapper.emitted('posted')?.[0]).toEqual([fakeComment])
    expect((wrapper.find('.comment-input').element as HTMLInputElement).value).toBe('')
  })

  it('submits a parent_comment_id when replying', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      data: {
        id: 'c2',
        type: 'reply',
        body: 'Agreed!',
        inserted_at: '2026-10-01T00:00:00Z',
        parent_comment_id: 'c1',
        user: { id: 'u2', name: 'Replier', avatar_url: null },
        replies: [],
      },
    })
    vi.stubGlobal('$fetch', fetchMock)

    const wrapper = mount(CommentComposer, { props: { basePath: '/api/posts/post-1', parentCommentId: 'c1' } })
    await wrapper.find('.comment-input').setValue('Agreed!')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(fetchMock).toHaveBeenCalledWith(
      '/api/posts/post-1/comments',
      expect.objectContaining({
        method: 'POST',
        body: { comment: { body: 'Agreed!', parent_comment_id: 'c1' } },
      }),
    )
  })

  it('does not submit a blank comment', async () => {
    const fetchMock = vi.fn()
    vi.stubGlobal('$fetch', fetchMock)

    const wrapper = mount(CommentComposer, { props: { basePath: '/api/posts/post-1' } })
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(fetchMock).not.toHaveBeenCalled()
  })

  it('shows an error message when the request fails', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue({ data: { errors: { detail: 'you are commenting too fast' } } }))

    const wrapper = mount(CommentComposer, { props: { basePath: '/api/posts/post-1' } })
    await wrapper.find('.comment-input').setValue('Great read!')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(wrapper.find('.comment-composer-error').text()).toBe('you are commenting too fast')
  })
})
