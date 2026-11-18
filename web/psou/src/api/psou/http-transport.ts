import type { ApiTransport } from './transport'
import { request } from '@/library/request'

export const transport: ApiTransport = {
  request({ method, url, params, data }) {
    switch (method) {
      case 'GET':
        return request.get(url, { params })
      case 'POST':
        return request.post(url, data)
      case 'PUT':
        return request.put(url, data)
      case 'DELETE':
        return request.delete(url, data)
    }
  },
}
