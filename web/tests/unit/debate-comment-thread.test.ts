import { describe, expect, it, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import DebateCommentThread from '../../app/components/debate/DebateCommentThread.vue'
import { useDebateReplyTarget } from '../../app/composables/useDebateReplyTarget'
import type { Comment } from '../../app/stores/comments'

const stubs = { NuxtLink: { template: '<a><slot /></a>' }, AvatarCircle: true }

function makeComment(overrides: Partial<Comment> = {}): Comment {
  return {
    id: 'c1',
    type: 'comment',
    body: 'Top-level take.',
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
  Element.prototype.scrollIntoView = vi.fn()
  useDebateReplyTarget().clearReplyTarget()
})

describe('DebateCommentThread', () => {
  it('flattens nested replies into the flat grid', () => {
    const reply = makeComment({
      id: 'r1',
      type: 'reply',
      body: 'A reply.',
      side: 'post_b',
      parent_comment_id: 'c1',
      user: { id: 'u2', name: 'Replier', avatar_url: null },
    })
    const wrapper = mount(DebateCommentThread, {
      props: {
        connectionId: 'conn-1',
        basePath: '/api/connections/conn-1',
        comments: [makeComment({ replies: [reply] })],
      },
      global: { stubs },
    })

    const items = wrapper.findAllComponents({ name: 'DebateCommentItem' })
    expect(items).toHaveLength(2)
    expect(wrapper.text()).toContain('Top-level take.')
    expect(wrapper.text()).toContain('A reply.')
  })

  it("passes the parent comment as a reply's referencedComment", () => {
    const reply = makeComment({ id: 'r1', type: 'reply', parent_comment_id: 'c1' })
    const wrapper = mount(DebateCommentThread, {
      props: {
        connectionId: 'conn-1',
        basePath: '/api/connections/conn-1',
        comments: [makeComment({ replies: [reply] })],
      },
      global: { stubs },
    })

    const items = wrapper.findAllComponents({ name: 'DebateCommentItem' })
    const replyItem = items.find((item) => item.props('comment').id === 'r1')
    expect(replyItem?.props('referencedComment')?.id).toBe('c1')

    const topLevelItem = items.find((item) => item.props('comment').id === 'c1')
    expect(topLevelItem?.props('referencedComment')).toBeNull()
  })

  it('appends a newly posted comment from the composer', async () => {
    const wrapper = mount(DebateCommentThread, {
      props: { connectionId: 'conn-1', basePath: '/api/connections/conn-1', comments: [] },
      global: { stubs },
    })

    expect(wrapper.findAllComponents({ name: 'DebateCommentItem' })).toHaveLength(0)

    const newComment = makeComment({ id: 'new-1', body: 'Brand new comment', side: 'neutral' })
    await wrapper.findComponent({ name: 'DebateCommentComposer' }).vm.$emit('posted', newComment)

    expect(wrapper.text()).toContain('Brand new comment')
  })

  it('clears a stale reply target on mount', () => {
    useDebateReplyTarget().setReplyTarget(makeComment())

    mount(DebateCommentThread, {
      props: { connectionId: 'conn-1', basePath: '/api/connections/conn-1', comments: [] },
      global: { stubs },
    })

    expect(useDebateReplyTarget().replyTarget.value).toBeNull()
  })
})
