import { describe, expect, it } from 'vitest'
import { extractErrorMessage } from '../../app/utils/errors'

describe('extractErrorMessage', () => {
  it('returns the detail message when present', () => {
    const err = { data: { errors: { detail: 'invalid email or password' } } }
    expect(extractErrorMessage(err)).toBe('invalid email or password')
  })

  it('builds a message from the first field error', () => {
    const err = { data: { errors: { email: ['has already been taken'] } } }
    expect(extractErrorMessage(err)).toBe('email has already been taken')
  })

  it('falls back to a generic message when there is nothing to parse', () => {
    expect(extractErrorMessage({})).toBe('Something went wrong. Please try again.')
    expect(extractErrorMessage(null)).toBe('Something went wrong. Please try again.')
  })
})
