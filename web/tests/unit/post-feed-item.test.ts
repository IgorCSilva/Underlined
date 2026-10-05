import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import PostFeedItem from '../../app/components/PostFeedItem.vue'
import type { Post } from '../../app/stores/posts'

const post: Post = {
  id: 'post-1',
  thinking: 'This rewired how I pay attention.',
  inserted_at: '2026-01-01T00:00:00Z',
  book: { id: 'book-1', title: 'Sapiens', author: 'Yuval Noah Harari', cover_url: null },
  passage: { id: 'passage-1', text: 'The forest doesn’t end where the trees stop.' },
  keywords: ['attention', 'nature-writing'],
  like_count: 2,
  liked_by_user: false,
  bookmarked_by_user: false,
  comment_count: 3,
  user: { id: 'user-1', name: 'Reader One', avatar_url: null },
}

const stubs = {
  NuxtLink: { template: '<a><slot /></a>' },
  AvatarCircle: true,
  LikeButton: true,
  BookmarkButton: true,
}

describe('PostFeedItem', () => {
  it('renders the author, book, passage, and thinking', () => {
    const wrapper = mount(PostFeedItem, { props: { post }, global: { stubs } })

    expect(wrapper.text()).toContain('Reader One')
    expect(wrapper.text()).toContain('Sapiens')
    expect(wrapper.text()).toContain('The forest doesn’t end where the trees stop.')
    expect(wrapper.text()).toContain('This rewired how I pay attention.')
  })

  it('renders a chip per keyword', () => {
    const wrapper = mount(PostFeedItem, { props: { post }, global: { stubs } })
    const chips = wrapper.findAll('.feed-keyword-chip')

    expect(chips).toHaveLength(2)
    expect(chips.map((c) => c.text())).toEqual(['attention', 'nature-writing'])
  })

  it('omits the keyword row when there are no keywords', () => {
    const wrapper = mount(PostFeedItem, { props: { post: { ...post, keywords: [] } }, global: { stubs } })
    expect(wrapper.find('.feed-keywords').exists()).toBe(false)
  })

  it('links to the post detail page', () => {
    const wrapper = mount(PostFeedItem, { props: { post }, global: { stubs } })
    expect(wrapper.find('a').exists()).toBe(true)
  })
})
