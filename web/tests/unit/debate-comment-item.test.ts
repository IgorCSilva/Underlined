import { describe, expect, it, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import DebateCommentItem from '../../app/components/debate/DebateCommentItem.vue'
import { useDebateReplyTarget } from '../../app/composables/useDebateReplyTarget'
import type { Comment } from '../../app/stores/comments'

const stubs = { NuxtLink: { template: '<a><slot /></a>' }, AvatarCircle: true }

function makeComment(overrides: Partial<Comment> = {}): Comment {
  return {
    id: 'c1',
    type: 'comment',
    body: 'I disagree with this take.',
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

describe('DebateCommentItem', () => {
  it('renders the username, body, and side class', () => {
    const wrapper = mount(DebateCommentItem, {
      props: { comment: makeComment(), basePath: '/api/connections/conn-1', referencedComment: null },
      global: { stubs },
    })

    expect(wrapper.text()).toContain('Reader One')
    expect(wrapper.text()).toContain('I disagree with this take.')
    expect(wrapper.find('.debate-comment-item').classes()).toContain('side-post_a')
  })

  it('defaults to a neutral side class when side is absent', () => {
    const wrapper = mount(DebateCommentItem, {
      props: { comment: makeComment({ side: undefined }), basePath: '/api/connections/conn-1', referencedComment: null },
      global: { stubs },
    })

    expect(wrapper.find('.debate-comment-item').classes()).toContain('side-neutral')
  })

  it('shows Reply only on a top-level comment, not on a reply', () => {
    const topLevel = mount(DebateCommentItem, {
      props: { comment: makeComment(), basePath: '/api/connections/conn-1', referencedComment: null },
      global: { stubs },
    })
    expect(topLevel.find('.debate-comment-reply-toggle').exists()).toBe(true)

    const reply = mount(DebateCommentItem, {
      props: {
        comment: makeComment({ id: 'r1', type: 'reply', parent_comment_id: 'c1' }),
        basePath: '/api/connections/conn-1',
        referencedComment: null,
      },
      global: { stubs },
    })
    expect(reply.find('.debate-comment-reply-toggle').exists()).toBe(false)
  })

  it('sets the shared reply target and scrolls to the composer when Reply is clicked', async () => {
    document.body.innerHTML = '<div id="debate-composer"></div><input id="debate-composer-input" />'
    const scrollSpy = vi.fn()
    Element.prototype.scrollIntoView = scrollSpy

    const comment = makeComment()
    const wrapper = mount(DebateCommentItem, {
      props: { comment, basePath: '/api/connections/conn-1', referencedComment: null },
      global: { stubs },
    })

    await wrapper.find('.debate-comment-reply-toggle').trigger('click')

    expect(useDebateReplyTarget().replyTarget.value).toEqual(comment)
    expect(scrollSpy).toHaveBeenCalledWith(expect.objectContaining({ behavior: 'smooth' }))
  })

  it('renders a clickable reference chip that scrolls to the referenced comment', async () => {
    document.body.innerHTML = '<div id="debate-comment-parent-1"></div>'
    const scrollSpy = vi.fn()
    Element.prototype.scrollIntoView = scrollSpy

    const referenced = makeComment({ id: 'parent-1', body: 'The original point being replied to.' })
    const reply = makeComment({ id: 'r1', parent_comment_id: 'parent-1', side: 'post_b' })

    const wrapper = mount(DebateCommentItem, {
      props: { comment: reply, basePath: '/api/connections/conn-1', referencedComment: referenced },
      global: { stubs },
    })

    const reference = wrapper.find('.debate-comment-reference')
    expect(reference.exists()).toBe(true)
    expect(reference.text()).toContain('Reader One')
    expect(reference.text()).toContain('The original point being replied to.')

    await reference.trigger('click')
    expect(scrollSpy).toHaveBeenCalledWith(expect.objectContaining({ behavior: 'smooth' }))
  })

  it('shows an Edit toggle for your own comment but not for someone else\'s', () => {
    useAuthStore().user = { id: 'me', email: 'a@a.com', name: 'Me', bio: null, avatar_url: null, confirmed: true }

    const own = mount(DebateCommentItem, {
      props: {
        comment: makeComment({ user: { id: 'me', name: 'Me', avatar_url: null } }),
        basePath: '/api/connections/conn-1',
        referencedComment: null,
      },
      global: { stubs },
    })
    expect(own.find('.debate-comment-edit-toggle').exists()).toBe(true)

    const other = mount(DebateCommentItem, {
      props: { comment: makeComment(), basePath: '/api/connections/conn-1', referencedComment: null },
      global: { stubs },
    })
    expect(other.find('.debate-comment-edit-toggle').exists()).toBe(false)
  })
})
