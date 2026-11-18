import type { TrackerPageKey } from './types'

const routePageMap: Record<string, TrackerPageKey> = {
  '/pages/index/index': 'home',
  '/pages/category/index': 'category_index',
  '/pages/category/detail': 'category_detail',
  '/pages/category/channel': 'category_channel',
  '/pages/resource/detail': 'resource_detail',
  '/pages/search/index': 'search',
}

export function normalizeTrackerPage(value?: string): TrackerPageKey | '' {
  const key = String(value || '').trim()
  if (!key)
    return ''
  if (routePageMap[key])
    return routePageMap[key]
  const normalized = key.startsWith('/') ? key : `/${key}`
  return routePageMap[normalized] || ''
}

export function currentTrackerPage(): TrackerPageKey {
  try {
    const pages = getCurrentPages()
    const route = pages[pages.length - 1]?.route || ''
    return normalizeTrackerPage(route) || 'home'
  }
  catch {
    return 'home'
  }
}

export function getTrackerRuntimeConfig() {
  const runtime = typeof window !== 'undefined' ? window.__PSOU_WEB_CONFIG__?.tracker : undefined
  return {
    enabled: runtime?.enable !== false,
    debug: Boolean(runtime?.debug),
  }
}
