export type TransportMethod = 'GET' | 'POST' | 'PUT' | 'DELETE'

export interface TransportRequest<T = unknown> {
  method: TransportMethod
  url: string
  params?: Record<string, unknown>
  data?: T
}

export interface ApiTransport {
  request: <T>(options: TransportRequest) => Promise<T>
}
