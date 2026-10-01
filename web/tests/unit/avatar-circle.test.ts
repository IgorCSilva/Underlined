import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import AvatarCircle from '../../app/components/AvatarCircle.vue'

describe('AvatarCircle', () => {
  it('shows the first letter of the name when there is no avatar', () => {
    const wrapper = mount(AvatarCircle, { props: { name: 'Reader One' } })

    expect(wrapper.text()).toBe('R')
    expect(wrapper.find('img').exists()).toBe(false)
  })

  it('renders the avatar image when provided', () => {
    const wrapper = mount(AvatarCircle, {
      props: { name: 'Reader One', avatarUrl: 'https://example.com/avatar.jpg' },
    })

    expect(wrapper.find('img').attributes('src')).toBe('https://example.com/avatar.jpg')
  })

  it('defaults to a 36px size and respects a custom size', () => {
    const defaultSize = mount(AvatarCircle, { props: { name: 'Reader One' } })
    expect(defaultSize.attributes('style')).toContain('width: 36px')

    const customSize = mount(AvatarCircle, { props: { name: 'Reader One', size: 28 } })
    expect(customSize.attributes('style')).toContain('width: 28px')
  })
})
