import type { RequestMeta } from 'uview-pro'
import { http } from 'uview-pro'
import { notifyError, parseBody, refreshAccessToken, unwrapBody } from '@/common/http.interceptor'
import { getAppKey, waitAppReady } from '@/library/app-context'
import { auth } from '@/library/auth'
import { getAPIBaseURL } from '@/library/config/runtime'

const BASE_URL = getAPIBaseURL()

export interface CallOptions {
  params?: Record<string, any>
  header?: Record<string, any>
  meta?: RequestMeta
  timeout?: number
  custom?: {
    hideError?: boolean
  }
}

export interface UploadOptions {
  filePath: string
  name?: string
  formData?: Record<string, any>
  header?: Record<string, any>
  meta?: RequestMeta
  custom?: {
    hideError?: boolean
  }
}

interface ApiEnvelope {
  code?: number
  message?: string
  data?: any
}

const APP_BOOTSTRAP_PATHS = ['/manager/api/init', '/manager/api/sample/app']

function isAppBootstrapRequest(url: string) {
  const path = url.split('?')[0]
  return APP_BOOTSTRAP_PATHS.some(prefix => path.endsWith(prefix))
}

async function waitForAppContext(url: string) {
  if (isAppBootstrapRequest(url))
    return
  await waitAppReady()
}

function toMeta(options: CallOptions | UploadOptions): RequestMeta | undefined {
  if (options.meta)
    return options.meta
  if (options.custom?.hideError)
    return { toast: false }
  return undefined
}

function requestMeta(options: CallOptions | UploadOptions) {
  const meta = toMeta(options)
  return meta ? { meta } : {}
}

function absoluteUrl(path: string) {
  if (/^https?:\/\//.test(path))
    return path
  return `${BASE_URL}${path.startsWith('/') ? path : `/${path}`}`
}

function authHeader(header: Record<string, any> = {}) {
  const token = auth.getToken()
  const appKey = getAppKey()
  return {
    ...(appKey ? { 'X-App-Key': appKey } : {}),
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...header,
  }
}

function uploadOnce<T>(url: string, options: UploadOptions): Promise<T> {
  return new Promise((resolve, reject) => {
    uni.uploadFile({
      url: absoluteUrl(url),
      filePath: options.filePath,
      name: options.name || 'file',
      formData: options.formData || {},
      header: authHeader(options.header),
      success: (response) => {
        const body = parseBody(response.data) as ApiEnvelope | T
        const meta = toMeta(options)

        if (response.statusCode === 401) {
          reject(Object.assign(new Error('登录状态已失效'), { unauthorized: true }))
          return
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          const message = (body as ApiEnvelope)?.message || `上传失败[${response.statusCode}]`
          if (meta?.toast !== false)
            notifyError(message)
          reject(new Error(message))
          return
        }

        try {
          resolve(unwrapBody(body))
        }
        catch (error) {
          const message = error instanceof Error ? error.message : '上传失败'
          if (meta?.toast !== false)
            notifyError(message)
          reject(error)
        }
      },
      fail: (error) => {
        const meta = toMeta(options)
        const message = error.errMsg || '上传失败'
        if (meta?.toast !== false)
          notifyError(message)
        reject(error)
      },
    })
  })
}

async function upload<T>(url: string, options: UploadOptions): Promise<T> {
  await waitForAppContext(url)
  try {
    return await uploadOnce<T>(url, options)
  }
  catch (error: any) {
    if (error?.unauthorized) {
      try {
        await refreshAccessToken()
        return await uploadOnce<T>(url, options)
      }
      catch (refreshError) {
        auth.clearToken()
        const meta = toMeta(options)
        const message = refreshError instanceof Error ? refreshError.message : '登录状态已失效'
        if (meta?.toast !== false)
          notifyError(message)
        throw refreshError
      }
    }
    throw error
  }
}

export const request = {
  async get<T = unknown>(url: string, options: CallOptions = {}) {
    await waitForAppContext(url)
    return http.get<T>(url, options.params || {}, {
      header: options.header,
      ...(options.timeout ? { timeout: options.timeout } : {}),
      ...requestMeta(options),
    })
  },
  async post<T = unknown>(url: string, data: any = {}, options: CallOptions = {}) {
    await waitForAppContext(url)
    return http.post<T>(url, data, {
      header: options.header,
      ...(options.timeout ? { timeout: options.timeout } : {}),
      ...requestMeta(options),
    })
  },
  async put<T = unknown>(url: string, data: any = {}, options: CallOptions = {}) {
    await waitForAppContext(url)
    return http.put<T>(url, data, {
      header: options.header,
      ...(options.timeout ? { timeout: options.timeout } : {}),
      ...requestMeta(options),
    })
  },
  async delete<T = unknown>(url: string, data: any = {}, options: CallOptions = {}) {
    await waitForAppContext(url)
    return http.delete<T>(url, data, {
      header: options.header,
      ...(options.timeout ? { timeout: options.timeout } : {}),
      ...requestMeta(options),
    })
  },
  upload,
}

export { upload }
