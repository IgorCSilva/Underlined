import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ProfileView from '../../app/components/ProfileView.vue'

const user = {
  id: 'user-1',
  name: 'Reader One',
  bio: 'Avid reader of nonfiction.',
  avatar_url: null,
}

const stubs = { NuxtLink: { template: '<a><slot /></a>' }, FollowButton: true }

describe('ProfileView', () => {
  it('renders the name, bio, and an avatar initial when there is no avatar', () => {
    const wrapper = mount(ProfileView, { props: { user }, global: { stubs } })

    expect(wrapper.text()).toContain('Reader One')
    expect(wrapper.text()).toContain('Avid reader of nonfiction.')
    expect(wrapper.text()).toContain('R')
  })

  it('shows an "Edit profile" link only when viewing your own profile', () => {
    const own = mount(ProfileView, { props: { user, own: true }, global: { stubs } })
    expect(own.text()).toContain('Edit profile')

    const other = mount(ProfileView, { props: { user, own: false }, global: { stubs } })
    expect(other.text()).not.toContain('Edit profile')
  })

  it('shows a FollowButton for another logged-in user\'s profile, not your own', () => {
    const auth = useAuthStore()
    auth.user = { id: 'viewer-1', email: 'viewer@example.com', name: 'Viewer', bio: null, avatar_url: null, confirmed: true }

    const other = mount(ProfileView, { props: { user, own: false }, global: { stubs } })
    expect(other.findComponent({ name: 'FollowButton' }).exists()).toBe(true)

    const own = mount(ProfileView, { props: { user: { ...user, id: 'viewer-1' }, own: true }, global: { stubs } })
    expect(own.findComponent({ name: 'FollowButton' }).exists()).toBe(false)
  })

  it('hides the FollowButton for an anonymous visitor', () => {
    const auth = useAuthStore()
    auth.user = null

    const wrapper = mount(ProfileView, { props: { user, own: false }, global: { stubs } })
    expect(wrapper.findComponent({ name: 'FollowButton' }).exists()).toBe(false)
  })
})
