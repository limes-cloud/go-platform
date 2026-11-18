const INITIAL_APP_KEY = String(import.meta.env.VITE_APP_KEY || '').trim()

let currentAppKey = INITIAL_APP_KEY
let appReady = false
let resolveAppReady: (() => void) | undefined

const appReadyPromise = new Promise<void>((resolve) => {
  resolveAppReady = resolve
})

// getAppKey 获取当前运行时的应用标识。
export function getAppKey(): string {
  return currentAppKey
}

// setAppKey 更新当前运行时的应用标识。
export function setAppKey(value?: string): void {
  const next = String(value || '').trim()
  if (next)
    currentAppKey = next
}

// markAppReady 标记当前应用的域名解析已经完成。
export function markAppReady(): void {
  if (appReady)
    return
  appReady = true
  resolveAppReady?.()
  resolveAppReady = undefined
}

// waitAppReady 等待当前应用解析完成，避免业务请求抢跑使用默认应用标识。
export function waitAppReady(): Promise<void> {
  return appReady ? Promise.resolve() : appReadyPromise
}

// getCurrentDomain 获取 H5 当前页面域名；非浏览器环境返回空。
export function getCurrentDomain(): string {
  try {
    return String(window.location?.hostname || '').trim().toLowerCase()
  }
  catch {
    return ''
  }
}
