type Translate = (key: string) => string

/**
 * `t` is passed in rather than calling `useI18n()` here, since this runs
 * from `catch` blocks inside nested async handlers where Vue's current
 * component instance isn't reliably active.
 */
export function extractErrorMessage(err: unknown, t: Translate): string {
  const data = (err as any)?.data ?? (err as any)?.response?._data
  const errors = data?.errors

  if (!errors) return t('errors.generic')

  if (typeof errors.code === 'string') {
    const key = `errors.codes.${errors.code}`
    const translated = t(key)
    if (translated !== key) return translated
  }

  if (typeof errors.detail === 'string') return errors.detail

  const [field, messages] = Object.entries(errors)[0] ?? []
  if (field && Array.isArray(messages)) return `${field} ${messages[0]}`

  return t('errors.generic')
}
