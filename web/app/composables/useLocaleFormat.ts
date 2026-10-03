export function useLocaleFormat() {
  const { locale } = useI18n()

  function formatDate(date: string | number | Date, options?: Intl.DateTimeFormatOptions): string {
    return new Date(date).toLocaleDateString(locale.value, options)
  }

  return { formatDate }
}
