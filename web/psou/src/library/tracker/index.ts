import type { TrackerAdapter, TrackerCall, TrackerPageKey, TrackerProps } from './types'
import { getAppKey } from '@/library/app-context'
import { useAppStore } from '@/stores/app'
import { currentTrackerPage, getTrackerRuntimeConfig, normalizeTrackerPage } from './config'
import { TrackerQueue } from './queue'
import { sanitizeTrackerProps } from './sanitize'

type TrackerState = 'idle' | 'starting' | 'ready' | 'disabled'

const queue = new TrackerQueue(20)
let state: TrackerState = 'idle'
let adapter: TrackerAdapter | null = null
let setupPromise: Promise<void> | null = null
let pendingUserId = ''
let lastPageView = { page: '', at: 0 }

export function setupTracker(): Promise<void> {
  // #ifdef H5
  if (setupPromise)
    return setupPromise
  state = 'starting'
  setupPromise = startH5Tracker()
  return setupPromise
  // #endif

  // #ifndef H5
  state = 'disabled'
  queue.clear()
  return Promise.resolve()
  // #endif
}

export function trackPageView(page: TrackerPageKey = currentTrackerPage(), props: TrackerProps = {}) {
  const normalized = normalizeTrackerPage(page) || currentTrackerPage()
  const now = Date.now()
  if (lastPageView.page === normalized && now - lastPageView.at < 200)
    return
  lastPageView = { page: normalized, at: now }
  dispatch({ type: 'page', page: normalized, props: sanitizeTrackerProps(props) })
}

export function trackEvent(point: string, props: TrackerProps = {}, page: TrackerPageKey = currentTrackerPage()) {
  const normalizedPoint = String(point || '').trim()
  if (!normalizedPoint)
    return
  dispatch({
    type: 'event',
    page: normalizeTrackerPage(page) || currentTrackerPage(),
    point: normalizedPoint,
    props: sanitizeTrackerProps(props),
  })
}

export function trackError(error: unknown, page: TrackerPageKey = currentTrackerPage()) {
  const normalizedPage = normalizeTrackerPage(page) || currentTrackerPage()
  const message = error instanceof Error ? error.message : String(error || 'Unknown error')
  const stack = error instanceof Error ? error.stack || '' : ''
  dispatch({
    type: 'error',
    page: normalizedPage,
    props: sanitizeTrackerProps({ message, stack }),
  })
}

export function setTrackerUser(id?: string | number) {
  pendingUserId = String(id || '').trim()
  if (state === 'ready' && adapter)
    adapter.setUser(pendingUserId)
}

function dispatch(call: TrackerCall) {
  if (state === 'disabled')
    return
  if (state === 'ready' && adapter) {
    if (call.type === 'page') {
      adapter.pageView(call.page, call.props)
      return
    }
    if (call.type === 'event') {
      adapter.event(call.point, call.page, call.props)
      return
    }
    adapter.error(call.page, call.props)
    return
  }
  queue.push(call)
}

// #ifdef H5
async function startH5Tracker() {
  const appStore = useAppStore()
  const runtime = getTrackerRuntimeConfig()
  const app = appStore.app
  const appKey = String(app.keyword || getAppKey()).trim()

  if (!runtime.enabled || !app.setting?.tracker?.enable || !appKey) {
    state = 'disabled'
    queue.clear()
    return
  }

  try {
    const { createH5Tracker } = await import('./h5')
    adapter = await createH5Tracker({
      appKey,
      appName: app.showName || app.name || appKey,
      appVersion: app.version || '',
      debug: runtime.debug,
      userId: pendingUserId,
    })
    state = 'ready'
    queue.flush(adapter)
  }
  catch (error) {
    state = 'disabled'
    queue.clear()
    if (runtime.debug)
      console.warn('[psou-tracker] init failed', error)
  }
}
// #endif
