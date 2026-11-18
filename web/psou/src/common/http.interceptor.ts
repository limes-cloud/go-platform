import type { RequestConfig, RequestInterceptor, RequestMeta, RequestOptions } from 'uview-pro'
import { http, useToast } from 'uview-pro'
import { getAppKey } from '@/library/app-context'
import { auth } from '@/library/auth'
import { getAPIBaseURL } from '@/library/config/runtime'

const BASE_URL = getAPIBaseURL()
const REFRESH_TOKEN_PATH = '/manager/api/authorize/token/refresh'

interface ApiEnvelope<T = unknown> {
  code?: number
  msg?: string
  message?: string
  data?: T
  reason?: string
}

let loadingCount = 0
let refreshPromise: Promise<string> | null = null

const toast = useToast({ global: true })

function startLoading(meta: RequestMeta) {
  if (!meta.loading)
    return
  if (loadingCount === 0) {
    uni.showLoading({ title: '加载中...', mask: true })
  }
  loadingCount += 1
}

function stopLoading(meta: RequestMeta) {
  if (!meta.loading)
    return
  loadingCount = Math.max(0, loadingCount - 1)
  if (loadingCount === 0) {
    uni.hideLoading()
  }
}

export function notifyError(message: string) {
  const title = message || '服务器开小差了～'
  try {
    toast.show({ title, type: 'error', duration: 2400 })
  }
  catch {
    uni.showToast({ title, icon: 'none', duration: 2400 })
  }
}

export function unwrapBody<T = unknown>(body: ApiEnvelope<T> | T): T {
  if (body && typeof body === 'object' && 'code' in body) {
    const envelope = body as ApiEnvelope<T>
    if (envelope.code !== undefined && envelope.code !== 200) {
      const error = new Error(envelope.message || `请求失败[${envelope.code}]`) as Error & ApiEnvelope
      Object.assign(error, envelope)
      throw error
    }
    return (envelope.data ?? {}) as T
  }
  return body as T
}

function isUnauthorized(statusCode: number, body: ApiEnvelope) {
  return statusCode === 401 || body?.code === 401 || body?.reason === 'UNAUTHORIZED'
}

function requestRaw<T>(options: UniApp.RequestOptions): Promise<T> {
  return new Promise((resolve, reject) => {
    uni.request({
      ...options,
      success: response => resolve(response as T),
      fail: reject,
    })
  })
}

export async function refreshAccessToken(): Promise<string> {
  if (!refreshPromise) {
    refreshPromise = (async () => {
      const appKey = getAppKey()
      const response = await requestRaw<UniApp.RequestSuccessCallbackResult>({
        url: `${BASE_URL}${REFRESH_TOKEN_PATH}`,
        method: 'POST',
        header: {
          'content-type': 'application/json',
          ...(appKey ? { 'X-App-Key': appKey } : {}),
          ...(auth.getToken() ? { Authorization: `Bearer ${auth.getToken()}` } : {}),
        },
        data: {},
      })

      const body = parseBody(response.data) as ApiEnvelope<{ token?: string }>
      const token = response.statusCode >= 200 && response.statusCode < 300
        ? body?.data?.token
        : undefined

      if (!token) {
        throw new Error(body?.message || '登录状态已失效')
      }

      auth.setToken(token)
      return token
    })().finally(() => {
      refreshPromise = null
    })
  }

  return refreshPromise
}

export function parseBody(data: unknown): unknown {
  if (typeof data !== 'string')
    return data
  try {
    return JSON.parse(data)
  }
  catch {
    return data
  }
}

function retryRequest(config: RequestOptions) {
  const retryConfig = { ...config, _authRetried: true } as RequestOptions
  delete retryConfig.complete
  return http.request(retryConfig)
}

const httpRequestConfig: RequestConfig = {
  baseUrl: BASE_URL,
  timeout: 20000,
  header: {
    'content-type': 'application/json',
  },
  meta: {
    originalData: true,
    toast: true,
    loading: false,
  },
}

const httpInterceptor: RequestInterceptor = {
  request: (config: RequestOptions) => {
    const meta = config.meta || {}
    startLoading(meta)

    config.header = config.header || {}
    const appKey = getAppKey()
    if (appKey)
      config.header['X-App-Key'] = appKey

    const token = auth.getToken()
    if (token) {
      config.header.Authorization = `Bearer ${token}`
    }

    return config
  },
  response: async (response: UniApp.RequestSuccessCallbackResult & { config: RequestOptions }) => {
    const config = response.config
    const meta = config?.meta || {}
    stopLoading(meta)

    const body = parseBody(response.data) as ApiEnvelope
    const unauthorized = isUnauthorized(response.statusCode, body)

    if (unauthorized && !config?._authRetried) {
      try {
        await refreshAccessToken()
        return await retryRequest(config)
      }
      catch (error) {
        auth.clearToken()
        const message = error instanceof Error ? error.message : '登录状态已失效'
        if (meta.toast !== false)
          notifyError(message)
        throw error
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      const message = body?.message || body?.msg || response.errMsg || `请求错误[${response.statusCode}]`
      const error = new Error(message) as Error & ApiEnvelope
      Object.assign(error, body)
      if (meta.toast !== false)
        notifyError(message)
      throw error
    }

    try {
      return unwrapBody(body)
    }
    catch (error) {
      const message = error instanceof Error ? error.message : '请求失败'
      if (unauthorized)
        auth.clearToken()
      if (meta.toast !== false)
        notifyError(message)
      throw error
    }
  },
}

export { httpInterceptor, httpRequestConfig }
