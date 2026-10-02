import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import CommentThread from '../../app/components/CommentThread.vue'
import type { Comment } from '../../app/stores/comments'

const stubs = { NuxtLink: { template: '<a><slot /></a>' }, AvatarCircle: true }

function makeComment(overrides: Partial<Comment> = {}): Comment {
  return {
    id: 'c1',
    type: 'comment',
    body: 'Great read!',
    inserted_at: '2026-10-01T00:00:00Z',
    updated_at: '2026-10-01T00:00:00Z',
    parent_comment_id: null,
    user: { id: 'u1', name: 'Reader One', avatar_url: null },
    replies: [],
    ...overrides,
  }
}

describe('CommentThread', () => {
  it('renders the initial comments', () => {
    const wrapper = mount(CommentThread, {
      props: { postId: 'post-1', comments: [makeComment(), makeComment({ id: 'c2', body: 'Second!' })] },
      global: { stubs },
    })

    expect(wrapper.text()).toContain('Great read!')
    expect(wrapper.text()).toContain('Second!')
  })

  it('appends a newly posted top-level comment without refetching and emits comment-added', async () => {
    const wrapper = mount(CommentThread, { props: { postId: 'post-1', comments: [] }, global: { stubs } })

    expect(wrapper.findAllComponents({ name: 'CommentItem' })).toHaveLength(0)

    const newComment = makeComment({ id: 'new-1', body: 'Brand new comment' })
    await wrapper.findComponent({ name: 'CommentComposer' }).vm.$emit('posted', newComment)

    expect(wrapper.text()).toContain('Brand new comment')
    expect(wrapper.emitted('comment-added')).toHaveLength(1)
  })

  it('emits comment-added when a reply is posted on a child comment', async () => {
    const wrapper = mount(CommentThread, {
      props: { postId: 'post-1', comments: [makeComment()] },
      global: { stubs },
    })

    const commentItem = wrapper.findComponent({ name: 'CommentItem' })
    await commentItem.vm.$emit('posted', makeComment({ id: 'reply-1', type: 'reply' }))

    expect(wrapper.emitted('comment-added')).toHaveLength(1)
  })
})
