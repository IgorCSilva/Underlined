import { describe, expect, it, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import DebateCommentComposer from '../../app/components/debate/DebateCommentComposer.vue'
import { useDebateReplyTarget } from '../../app/composables/useDebateReplyTarget'
import type { Comment } from '../../app/stores/comments'

function makeComment(overrides: Partial<Comment> = {}): Comment {
  return {
    id: 'c1',
    type: 'comment',
    body: 'I disagree!',
    side: 'post_a',
    inserted_at: '2026-10-01T00:00:00Z',
    updated_at: '2026-10-01T00:00:00Z',
    parent_comment_id: null,
    user: { id: 'u1', name: 'Reader One', avatar_url: null },
    replies: [],
    ...overrides,
  }
}

beforeEach(() => {
  useDebateReplyTarget().clearReplyTarget()
})

describe('DebateCommentComposer', () => {
  it('posts the chosen side when a side button is clicked', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ data: makeComment({ id: 'new-1', side: 'post_b' }) })
    vi.stubGlobal('$fetch', fetchMock)

    const wrapper = mount(DebateCommentComposer, { props: { basePath: '/api/connections/conn-1' } })
    await wrapper.find('.debate-comment-input').setValue('I agree with the second post')
    await wrapper.find('.debate-side-btn.is-b').trigger('click')
    await flushPromises()

    expect(fetchMock).toHaveBeenCalledWith(
      '/api/connections/conn-1/comments',
      expect.objectContaining({
        method: 'POST',
        body: { comment: { body: 'I agree with the second post', parent_comment_id: null, side: 'post_b' } },
      }),
    )
    expect(wrapper.emitted('posted')?.[0]).toEqual([makeComment({ id: 'new-1', side: 'post_b' })])
    expect((wrapper.find('.debate-comment-input').element as HTMLInputElement).value).toBe('')
  })

  it('disables all three side buttons when the input is empty', () => {
    const wrapper = mount(DebateCommentComposer, { props: { basePath: '/api/connections/conn-1' } })

    expect(wrapper.find('.debate-side-btn.is-a').attributes('disabled')).toBeDefined()
    expect(wrapper.find('.debate-side-btn.is-neutral').attributes('disabled')).toBeDefined()
    expect(wrapper.find('.debate-side-btn.is-b').attributes('disabled')).toBeDefined()
  })

  it('shows a replying-to chip and includes parent_comment_id when a reply target is set', async () => {
    const target = makeComment({ id: 'parent-1', user: { id: 'u2', name: 'Other Reader', avatar_url: null } })
    useDebateReplyTarget().setReplyTarget(target)

    const fetchMock = vi.fn().mockResolvedValue({ data: makeComment({ id: 'reply-1', parent_comment_id: 'parent-1' }) })
    vi.stubGlobal('$fetch', fetchMock)

    const wrapper = mount(DebateCommentComposer, { props: { basePath: '/api/connections/conn-1' } })
    expect(wrapper.text()).toContain('Other Reader')

    await wrapper.find('.debate-comment-input').setValue('A reply')
    await wrapper.find('.debate-side-btn.is-neutral').trigger('click')
    await flushPromises()

    expect(fetchMock).toHaveBeenCalledWith(
      '/api/connections/conn-1/comments',
      expect.objectContaining({
        body: { comment: { body: 'A reply', parent_comment_id: 'parent-1', side: 'neutral' } },
      }),
    )
    expect(useDebateReplyTarget().replyTarget.value).toBeNull()
  })

  it('clears the reply target when its cancel button is clicked', async () => {
    useDebateReplyTarget().setReplyTarget(makeComment())

    const wrapper = mount(DebateCommentComposer, { props: { basePath: '/api/connections/conn-1' } })
    expect(wrapper.find('.debate-reply-reference').exists()).toBe(true)

    await wrapper.find('.debate-reply-cancel').trigger('click')
    expect(wrapper.find('.debate-reply-reference').exists()).toBe(false)
  })

  it('shows an error message when the request fails', async () => {
    vi.stubGlobal('$fetch', vi.fn().mockRejectedValue({ data: { errors: { detail: 'you are commenting too fast' } } }))

    const wrapper = mount(DebateCommentComposer, { props: { basePath: '/api/connections/conn-1' } })
    await wrapper.find('.debate-comment-input').setValue('Hello')
    await wrapper.find('.debate-side-btn.is-a').trigger('click')
    await flushPromises()

    expect(wrapper.find('.debate-composer-error').text()).toBe('you are commenting too fast')
  })
})
