import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import TopBar from '../../app/components/TopBar.vue'

const stubs = { NuxtLink: { template: '<a><slot /></a>' }, LocaleSwitcher: true }

describe('TopBar', () => {
  it('shows the brand name and public links when logged out', () => {
    const wrapper = mount(TopBar, { global: { stubs } })

    expect(wrapper.text()).toContain('Underlined')
    expect(wrapper.text()).toContain('Feed')
    expect(wrapper.text()).toContain('Books')
    expect(wrapper.text()).toContain('Log in')
    expect(wrapper.text()).toContain('Sign up')
    expect(wrapper.text()).not.toContain('Profile')
  })

  it('shows authenticated-only links and hides login/signup when logged in', () => {
    const wrapper = mount(TopBar, { global: { stubs } })
    const auth = useAuthStore()
    auth.user = { id: '1', email: 'a@example.com', name: 'Reader', bio: null, avatar_url: null, confirmed: true }

    return wrapper.vm.$nextTick().then(() => {
      // expect(wrapper.text()).toContain('New post')
      expect(wrapper.text()).toContain('Add book')
      expect(wrapper.text()).toContain('Profile')
      expect(wrapper.text()).not.toContain('Log in')
      expect(wrapper.text()).not.toContain('Sign up')
    })
  })

  it('toggles the mobile menu via the hamburger button', async () => {
    const wrapper = mount(TopBar, { global: { stubs } })

    expect(wrapper.find('.top-bar-mobile-menu').exists()).toBe(false)

    await wrapper.find('.top-bar-menu-toggle').trigger('click')
    expect(wrapper.find('.top-bar-mobile-menu').exists()).toBe(true)

    await wrapper.find('.top-bar-menu-toggle').trigger('click')
    expect(wrapper.find('.top-bar-mobile-menu').exists()).toBe(false)
  })
})
