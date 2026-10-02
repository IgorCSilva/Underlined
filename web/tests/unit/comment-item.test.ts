import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import CommentItem from '../../app/components/CommentItem.vue'
import type { Comment } from '../../app/stores/comments'

const stubs = { AvatarCircle: true, CommentComposer: true }

function makeComment(overrides: Partial<Comment> = {}): Comment {
  return {
    id: 'c1',
    type: 'comment',
    body: 'Great read!',
    inserted_at: '2026-10-01T00:00:00Z',
    parent_comment_id: null,
    user: { id: 'u1', name: 'Reader One', avatar_url: null },
    replies: [],
    ...overrides,
  }
}

describe('CommentItem', () => {
  it('renders the username and body', () => {
    const wrapper = mount(CommentItem, { props: { comment: makeComment(), postId: 'post-1' }, global: { stubs } })

    expect(wrapper.text()).toContain('Reader One')
    expect(wrapper.text()).toContain('Great read!')
  })

  it('shows a Reply toggle on a top-level comment but not on a reply', () => {
    const topLevel = mount(CommentItem, { props: { comment: makeComment(), postId: 'post-1' }, global: { stubs } })
    expect(topLevel.find('.comment-reply-toggle').exists()).toBe(true)

    const reply = mount(CommentItem, {
      props: { comment: makeComment(), postId: 'post-1', isReply: true },
      global: { stubs },
    })
    expect(reply.find('.comment-reply-toggle').exists()).toBe(false)
  })

  it('renders indented replies for a top-level comment', () => {
    const replyComment = makeComment({
      id: 'r1',
      type: 'reply',
      body: 'Agreed!',
      parent_comment_id: 'c1',
      user: { id: 'u2', name: 'Replier', avatar_url: null },
    })
    const wrapper = mount(CommentItem, {
      props: { comment: makeComment({ replies: [replyComment] }), postId: 'post-1' },
      global: { stubs },
    })

    const nested = wrapper.find('.comment-replies')
    expect(nested.exists()).toBe(true)
    expect(nested.text()).toContain('Replier')
    expect(nested.text()).toContain('Agreed!')
    expect(nested.find('.comment-reply-toggle').exists()).toBe(false)
  })

  it('toggles the reply composer when Reply is clicked', async () => {
    const wrapper = mount(CommentItem, { props: { comment: makeComment(), postId: 'post-1' }, global: { stubs } })

    expect(wrapper.find('.comment-reply-composer').exists()).toBe(false)
    await wrapper.find('.comment-reply-toggle').trigger('click')
    expect(wrapper.find('.comment-reply-composer').exists()).toBe(true)
  })

  it('adds a posted reply to the local replies list and emits posted', async () => {
    const comment = makeComment()
    const wrapper = mount(CommentItem, { props: { comment, postId: 'post-1' }, global: { stubs } })

    await wrapper.find('.comment-reply-toggle').trigger('click')
    const reply = makeComment({ id: 'r1', type: 'reply', body: 'Agreed!', parent_comment_id: 'c1' })
    await wrapper.findComponent({ name: 'CommentComposer' }).vm.$emit('posted', reply)

    expect(comment.replies).toContain(reply)
    expect(wrapper.emitted('posted')?.[0]).toEqual([reply])
    expect(wrapper.find('.comment-reply-composer').exists()).toBe(false)
  })
})
