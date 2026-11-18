export type TrackerPageKey
  = | 'home'
    | 'category_index'
    | 'category_detail'
    | 'category_channel'
    | 'resource_detail'
    | 'search'

export type TrackerProps = Record<string, unknown>

export interface TrackerAdapter {
  pageView: (page: TrackerPageKey, props: TrackerProps) => void
  event: (point: string, page: TrackerPageKey, props: TrackerProps) => void
  error: (page: TrackerPageKey, props: TrackerProps) => void
  setUser: (id: string) => void
}

export type TrackerCall
  = | { type: 'page', page: TrackerPageKey, props: TrackerProps }
    | { type: 'event', page: TrackerPageKey, point: string, props: TrackerProps }
    | { type: 'error', page: TrackerPageKey, props: TrackerProps }
