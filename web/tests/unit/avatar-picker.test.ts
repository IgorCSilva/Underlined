import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import AvatarPicker from '../../app/components/AvatarPicker.vue'

describe('AvatarPicker', () => {
  it('renders the 10 preset avatars', () => {
    const wrapper = mount(AvatarPicker, { props: { modelValue: null } })
    const options = wrapper.findAll('.avatar-option')

    expect(options).toHaveLength(10)
    expect(options[0]?.find('img').attributes('src')).toBe('/avatars/avatar1.jpg')
  })

  it('marks the selected avatar', () => {
    const wrapper = mount(AvatarPicker, { props: { modelValue: '/avatars/avatar3.jpg' } })
    const options = wrapper.findAll('.avatar-option')

    expect(options[2]?.classes()).toContain('is-selected')
    expect(options[0]?.classes()).not.toContain('is-selected')
  })

  it('emits update:modelValue with the chosen avatar path', async () => {
    const wrapper = mount(AvatarPicker, { props: { modelValue: null } })
    await wrapper.findAll('.avatar-option')[4]?.trigger('click')

    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['/avatars/avatar5.jpg'])
  })
})
