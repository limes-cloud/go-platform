function normalizeBaseURL(value?: string): string {
  return String(value || '').trim().replace(/\/+$/, '')
}

export function getAPIBaseURL(): string {
  if (typeof window !== 'undefined') {
    const runtimeValue = window.__PSOU_WEB_CONFIG__?.apiBaseUrl
    if (typeof runtimeValue === 'string')
      return normalizeBaseURL(runtimeValue)
  }
  return normalizeBaseURL(import.meta.env.VITE_BASE_URL)
}
