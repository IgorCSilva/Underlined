import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import RelatedPosts from '../../app/components/RelatedPosts.vue'
import type { Post } from '../../app/stores/posts'

const makePost = (overrides: Partial<Post>): Post => ({
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
  ...overrides,
  spoiler: overrides.spoiler ?? false,
})

const stubs = { NuxtLink: { template: '<a><slot /></a>' } }

describe('RelatedPosts', () => {
  it('renders nothing when there are no related posts', () => {
    const wrapper = mount(RelatedPosts, { props: { posts: [] }, global: { stubs } })
    expect(wrapper.find('.related-posts').exists()).toBe(false)
  })

  it('renders a row with the passage snippet and book title for each related post', () => {
    const posts = [
      makePost({ id: 'post-1', book: { id: 'book-1', title: 'Sapiens', author: 'Yuval Noah Harari', cover_url: null } }),
      makePost({
        id: 'post-2',
        passage: { id: 'passage-2', text: 'Attention is a kind of care.' },
        book: { id: 'book-2', title: 'Deep Work', author: 'Cal Newport', cover_url: null },
      }),
    ]

    const wrapper = mount(RelatedPosts, { props: { posts }, global: { stubs } })
    const rows = wrapper.findAll('.related-post-row')

    expect(rows).toHaveLength(2)
    expect(rows[1]?.text()).toContain('Attention is a kind of care.')
    expect(rows[1]?.text()).toContain('Deep Work')
  })

  it('links each row to its own post detail page', () => {
    const posts = [makePost({ id: 'post-42' })]
    const wrapper = mount(RelatedPosts, { props: { posts }, global: { stubs } })
    const row = wrapper.find('.related-post-row')

    expect(row.attributes('to')).toBe('/posts/post-42')
  })

  it('shows the "Related ideas" label', () => {
    const wrapper = mount(RelatedPosts, { props: { posts: [makePost({})] }, global: { stubs } })
    expect(wrapper.text()).toContain('Related ideas')
  })
})
