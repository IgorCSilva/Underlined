export function extractErrorMessage(err: unknown): string {
  const data = (err as any)?.data ?? (err as any)?.response?._data
  const errors = data?.errors

  if (!errors) return 'Something went wrong. Please try again.'
  if (typeof errors.detail === 'string') return errors.detail

  const [field, messages] = Object.entries(errors)[0] ?? []
  if (field && Array.isArray(messages)) return `${field} ${messages[0]}`

  return 'Something went wrong. Please try again.'
}
