import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ProfileView from '../../app/components/ProfileView.vue'

const user = {
  name: 'Reader One',
  bio: 'Avid reader of nonfiction.',
  avatar_url: null,
}

const stubs = { NuxtLink: { template: '<a><slot /></a>' } }

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
})
