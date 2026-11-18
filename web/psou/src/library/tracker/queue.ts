import type { TrackerAdapter, TrackerCall } from './types'

export class TrackerQueue {
  private items: TrackerCall[] = []

  constructor(private readonly limit = 20) {}

  push(call: TrackerCall) {
    if (this.items.length >= this.limit)
      this.items.shift()
    this.items.push(call)
  }

  flush(adapter: TrackerAdapter) {
    const pending = this.items
    this.items = []
    pending.forEach((call) => {
      if (call.type === 'page') {
        adapter.pageView(call.page, call.props)
        return
      }
      if (call.type === 'event') {
        adapter.event(call.point, call.page, call.props)
        return
      }
      adapter.error(call.page, call.props)
    })
  }

  clear() {
    this.items = []
  }
}
