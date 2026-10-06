import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import InterestProfile from '../../app/components/InterestProfile.vue'

describe('InterestProfile', () => {
  it('renders nothing when the profile is empty', () => {
    const wrapper = mount(InterestProfile, { props: { profile: [] } })
    expect(wrapper.find('.interest-profile').exists()).toBe(false)
  })

  it('renders one row per keyword with its post count', () => {
    const profile = [
      { keyword: 'attention', post_count: 9 },
      { keyword: 'psychology', post_count: 3 },
    ]

    const wrapper = mount(InterestProfile, { props: { profile } })
    const rows = wrapper.findAll('.interest-row')

    expect(rows).toHaveLength(2)
    expect(rows[0]?.text()).toContain('attention')
    expect(rows[0]?.text()).toContain('9')
    expect(rows[1]?.text()).toContain('psychology')
    expect(rows[1]?.text()).toContain('3')
  })

  it('scales each bar relative to the largest count, with the top entry at 100%', () => {
    const profile = [
      { keyword: 'attention', post_count: 10 },
      { keyword: 'psychology', post_count: 5 },
    ]

    const wrapper = mount(InterestProfile, { props: { profile } })
    const bars = wrapper.findAll('.interest-bar')

    expect(bars[0]?.attributes('style')).toContain('width: 100%')
    expect(bars[1]?.attributes('style')).toContain('width: 50%')
  })
})
