import type { ApiTransport, TransportRequest } from '@/api/psou/transport'
import type {
  CategoryDetailReply,
  CategoryIndexReply,
  ChannelListReply,
  ResourceDetailReply,
} from '@/api/psou/type'
import {
  getCategoryDetail,
  getCategoryIndex,
  getChannelList,
  getResourceDetail,
} from './fixtures'

const MOCK_DELAY = 120

function delay() {
  return new Promise(resolve => setTimeout(resolve, MOCK_DELAY))
}

function readParam(request: TransportRequest, key: string) {
  const value = request.params?.[key]
  return typeof value === 'string' ? value : undefined
}

function route(request: TransportRequest): unknown {
  const path = request.url.split('?')[0]

  if (request.method === 'GET' && path === '/psou/client/channels')
    return getChannelList() satisfies ChannelListReply

  if (request.method === 'GET' && path === '/psou/client/categories')
    return getCategoryIndex(readParam(request, 'channelId')) satisfies CategoryIndexReply

  const categoryMatch = path.match(/^\/psou\/client\/categories\/([^/]*)$/)
  if (request.method === 'GET' && categoryMatch) {
    return getCategoryDetail(
      readParam(request, 'channelId'),
      decodeURIComponent(categoryMatch[1]),
    ) satisfies CategoryDetailReply
  }

  if (request.method === 'GET' && path === '/psou/client/resource') {
    const result = getResourceDetail(readParam(request, 'resourceId'))
    if (!result)
      throw new Error('资源不存在或已下架')
    return result satisfies ResourceDetailReply
  }

  throw new Error(`Mock API 未实现：${request.method} ${path}`)
}

export const transport: ApiTransport = {
  async request<T>(request: TransportRequest) {
    await delay()
    return route(request) as T
  },
}
