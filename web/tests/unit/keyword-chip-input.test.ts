import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import KeywordChipInput from '../../app/components/KeywordChipInput.vue'

describe('KeywordChipInput', () => {
  it('renders existing keywords as chips', () => {
    const wrapper = mount(KeywordChipInput, { props: { modelValue: ['attention', 'ecology'] } })
    expect(wrapper.text()).toContain('attention')
    expect(wrapper.text()).toContain('ecology')
  })

  it('emits an updated list when a new keyword is committed via Enter', async () => {
    const wrapper = mount(KeywordChipInput, { props: { modelValue: ['attention'] } })
    const input = wrapper.find('input')
    await input.setValue('slow-reading')
    await input.trigger('keydown.enter')

    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual([['attention', 'slow-reading']])
  })

  it('does not add a duplicate keyword (case-insensitive)', async () => {
    const wrapper = mount(KeywordChipInput, { props: { modelValue: ['attention'] } })
    const input = wrapper.find('input')
    await input.setValue('ATTENTION')
    await input.trigger('keydown.enter')

    expect(wrapper.emitted('update:modelValue')).toBeUndefined()
  })

  it('emits a list with the keyword removed when its remove button is clicked', async () => {
    const wrapper = mount(KeywordChipInput, { props: { modelValue: ['attention', 'ecology'] } })
    await wrapper.find('.chip-remove').trigger('click')

    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual([['ecology']])
  })

  it('hides the input once the max number of keywords is reached', () => {
    const wrapper = mount(KeywordChipInput, { props: { modelValue: ['a', 'b'], max: 2 } })
    expect(wrapper.find('input').exists()).toBe(false)
  })
})
