import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import BookTile from '../../app/components/BookTile.vue'

const book = { title: 'Sapiens', author: 'Yuval Noah Harari', cover_url: null as string | null }

describe('BookTile', () => {
  it('renders the title and author', () => {
    const wrapper = mount(BookTile, { props: { book } })

    expect(wrapper.text()).toContain('Sapiens')
    expect(wrapper.text()).toContain('Yuval Noah Harari')
  })

  it('shows a placeholder when there is no cover image', () => {
    const wrapper = mount(BookTile, { props: { book } })
    expect(wrapper.find('img').exists()).toBe(false)
  })

  it('renders the cover image when provided', () => {
    const withCover = { ...book, cover_url: 'https://example.com/cover.jpg' }
    const wrapper = mount(BookTile, { props: { book: withCover } })
    expect(wrapper.find('img').attributes('src')).toBe('https://example.com/cover.jpg')
  })
})
