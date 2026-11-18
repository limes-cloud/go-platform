interface RuntimeAccountInfo {
  miniProgram?: {
    appId?: string
  }
}

interface RuntimeEnvInfo {
  microapp?: {
    appId?: string
  }
}

interface RuntimeUniAPI {
  getAccountInfoSync?: () => RuntimeAccountInfo
  getEnvInfoSync?: () => RuntimeEnvInfo
}

// getRuntimeAppId 返回当前小程序平台的 AppID；H5/App 端返回空。
export function getRuntimeAppId(): string {
  const api = uni as unknown as RuntimeUniAPI
  try {
    const appId = String(api.getAccountInfoSync?.().miniProgram?.appId || '').trim()
    if (appId)
      return appId
  }
  catch {
    // 部分平台不支持该 API，继续尝试其它方式。
  }
  try {
    return String(api.getEnvInfoSync?.().microapp?.appId || '').trim()
  }
  catch {
    return ''
  }
}
