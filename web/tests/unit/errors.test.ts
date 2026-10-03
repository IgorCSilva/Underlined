import { describe, expect, it } from 'vitest'
import { extractErrorMessage } from '../../app/utils/errors'

const t = (key: string) => (key === 'errors.generic' ? 'Something went wrong. Please try again.' : key)

describe('extractErrorMessage', () => {
  it('returns the detail message when present', () => {
    const err = { data: { errors: { detail: 'invalid email or password' } } }
    expect(extractErrorMessage(err, t)).toBe('invalid email or password')
  })

  it('builds a message from the first field error', () => {
    const err = { data: { errors: { email: ['has already been taken'] } } }
    expect(extractErrorMessage(err, t)).toBe('email has already been taken')
  })

  it('falls back to a generic message when there is nothing to parse', () => {
    expect(extractErrorMessage({}, t)).toBe('Something went wrong. Please try again.')
    expect(extractErrorMessage(null, t)).toBe('Something went wrong. Please try again.')
  })
})
