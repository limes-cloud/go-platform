import type { TrackerAdapter, TrackerPageKey, TrackerProps } from './types'
import { init, setUserUuid, traceCustomEvent, traceError, tracePageView } from '@web-tracing/core'
import { getAPIBaseURL } from '@/library/config/runtime'
import { currentTrackerPage, normalizeTrackerPage } from './config'
import { sanitizeTrackerProps } from './sanitize'

interface H5TrackerOptions {
  appKey: string
  appName: string
  appVersion: string
  debug: boolean
  userId: string
}

const errorDedup = new Map<string, number>()
const flushPoints = new Set(['resource_netdisk_open', 'resource_qrcode_open'])
let globalErrorsBound = false

export async function createH5Tracker(options: H5TrackerOptions): Promise<TrackerAdapter> {
  const dsn = `${getAPIBaseURL()}/manager/api/tracker/collect`
  installTrackerAppHeader(options.appKey)
  const adapter: TrackerAdapter = {
    pageView(page, props) {
      tracePageView({ page, params: { page, ...sanitizeTrackerProps(props) } }, true)
    },
    event(point, page, props) {
      traceCustomEvent({ page, point, props: sanitizeTrackerProps(props) }, flushPoints.has(point))
    },
    error(page, props) {
      traceError({ page, point: '$error', props: sanitizeTrackerProps(props) }, true)
    },
    setUser(id) {
      setUserUuid(id)
    },
  }

  init({
    dsn,
    appName: options.appName,
    appCode: options.appKey,
    appVersion: options.appVersion,
    debug: options.debug,
    pv: false,
    event: false,
    error: false,
    performance: { core: false, firstResource: false, server: false },
    recordScreen: false,
    tracesSampleRate: 1,
    cacheMaxLength: 5,
    cacheWatingTime: 1000,
    maxQueueLength: 200,
    ext: { page: currentTrackerPage() },
    ignoreErrors: [/@web-tracing/, /stun:/, /RTCPeerConnection/],
    ignoreRequest: [/manager\/api\/tracker\/collect/],
    sendTypeByXmlBody: true,
    beforePushEventList: prepareEvents,
  })

  if (options.userId)
    setUserUuid(options.userId)

  bindGlobalErrors(adapter)
  return adapter
}

let trackerAppKey = ''
let trackerHeaderInstalled = false

function installTrackerAppHeader(appKey: string) {
  trackerAppKey = appKey
  if (trackerHeaderInstalled)
    return
  trackerHeaderInstalled = true

  const collectPath = '/manager/api/tracker/collect'
  const trackerRequests = new WeakSet<XMLHttpRequest>()
  const originalOpen = XMLHttpRequest.prototype.open
  const originalSend = XMLHttpRequest.prototype.send

  XMLHttpRequest.prototype.open = function (
    method: string,
    url: string | URL,
    asyncFlag: boolean = true,
    username?: string | null,
    password?: string | null,
  ) {
    if (typeof url === 'string' && url.includes(collectPath))
      trackerRequests.add(this)
    return originalOpen.call(this, method, url, asyncFlag, username, password)
  }

  XMLHttpRequest.prototype.send = function (body?: Document | XMLHttpRequestBodyInit | null) {
    if (trackerRequests.has(this) && trackerAppKey)
      this.setRequestHeader('X-App-Key', trackerAppKey)
    return originalSend.call(this, body)
  }
}

function prepareEvents(input: unknown) {
  const list = Array.isArray(input) ? input : [input]
  return list
    .filter((event): event is Record<string, unknown> => Boolean(event && typeof event === 'object'))
    .filter(event => ['pv', 'custom', 'error'].includes(String(event.eventType || '')))
    .map((event) => {
      const params = event.params && typeof event.params === 'object'
        ? sanitizeTrackerProps(event.params as Record<string, unknown>)
        : undefined
      const page = normalizeTrackerPage(String(event.page || params?.page || '')) || currentTrackerPage()
      const props = sanitizeTrackerProps(event.props as Record<string, unknown> | undefined)
      return {
        ...event,
        page,
        props,
        ...(params ? { params } : {}),
      }
    })
}

function bindGlobalErrors(adapter: TrackerAdapter) {
  if (globalErrorsBound || typeof window === 'undefined')
    return
  globalErrorsBound = true

  window.addEventListener('error', (event) => {
    if (!event.error)
      return
    const error = event.error as Error
    const message = String(error.message || event.message || '')
    if (isIgnoredError(message))
      return
    reportError(adapter, currentTrackerPage(), {
      message,
      stack: String(error.stack || ''),
      source: safeSource(event.filename),
      line: event.lineno || 0,
      column: event.colno || 0,
    })
  }, true)

  window.addEventListener('unhandledrejection', (event) => {
    const reason = event.reason
    const message = reason instanceof Error ? reason.message : String(reason || 'Unhandled rejection')
    if (isIgnoredError(message))
      return
    reportError(adapter, currentTrackerPage(), {
      message,
      stack: reason instanceof Error ? String(reason.stack || '') : '',
    })
  })
}

function reportError(adapter: TrackerAdapter, page: TrackerPageKey, props: TrackerProps) {
  const key = `${page}\n${props.message || ''}\n${props.stack || ''}`
  const now = Date.now()
  for (const [item, timestamp] of errorDedup) {
    if (now - timestamp > 10_000)
      errorDedup.delete(item)
  }
  if (now - (errorDedup.get(key) || 0) < 10_000)
    return
  errorDedup.set(key, now)
  adapter.error(page, props)
}

function isIgnoredError(message: string) {
  return /@web-tracing|RTCPeerConnection|stun:|manager\/api\/tracker\/collect|ResizeObserver loop/i.test(message)
}

function safeSource(value: string) {
  if (!value)
    return ''
  try {
    const url = new URL(value, window.location.href)
    return `${url.origin}${url.pathname}`
  }
  catch {
    return value.split('?')[0].slice(0, 256)
  }
}
