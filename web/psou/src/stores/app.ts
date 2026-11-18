import type { App } from '@/api/system/type'
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { GetSampleApp, InitApp } from '@/api/system/api'
import { getAppKey, getCurrentDomain, markAppReady, setAppKey } from '@/library/app-context'
import { rurl } from '@/library/global/url'
import { getPlatform } from '@/library/utils/platform'
import { getRuntimeAppId } from '@/library/utils/runtime-app'
import { setWebIcon } from '@/library/utils/utils'

type SystemApp = App & {
  navHeight?: number
  statusBarHeight?: number
  version: string
}

function fallbackApp(): SystemApp {
  return {
    id: 0,
    type: 'client',
    logo: '/static/logo.png',
    favicon: '',
    keyword: import.meta.env.VITE_APP_KEY || '',
    name: import.meta.env.VITE_APP_NAME || 'PSou',
    showName: import.meta.env.VITE_APP_NAME || 'PSou',
    description: 'PSou 客户端',
    private: false,
    status: true,
    createdAt: 0,
    updatedAt: 0,
    version: import.meta.env.VITE_VERSION || 'v0.1.0',
  }
}

export const useAppStore = defineStore('appStore', () => {
  const keyword = ref(getAppKey())
  const app = ref<SystemApp>(fallbackApp())
  const platform = ref(getPlatform())
  const initialized = ref(false)
  let initPromise: Promise<void> | null = null

  async function initializeApp() {
    try {
      const systemInfo = uni.getSystemInfoSync()
      const windowInfo = uni.getWindowInfo()
      const navBarHeight = systemInfo.platform === 'ios' ? 44 : 48

      app.value.navHeight = navBarHeight + Number(windowInfo.statusBarHeight || 0)
      app.value.statusBarHeight = Number(windowInfo.statusBarHeight || 0)
    }
    catch {
      // getSystemInfoSync may be unavailable during SSR or early bootstrap.
    }

    try {
      let data: App | undefined
      data = await InitApp({
        domain: getCurrentDomain(),
        appId: getRuntimeAppId(),
        platform: platform.value,
      }).catch(() => undefined)
      if (!data && keyword.value) {
        data = await GetSampleApp({ keyword: keyword.value })
      }
      if (data) {
        keyword.value = data.keyword || keyword.value
        setAppKey(keyword.value)
        Object.assign(app.value, {
          id: data.id,
          name: data.showName || data.name || app.value.name,
          showName: data.showName || data.name || app.value.showName,
          logo: data.logo || app.value.logo,
          favicon: data.favicon || '',
          keyword: data.keyword || app.value.keyword,
          description: data.description || app.value.description,
          setting: data.setting,
          copyright: data.setting?.web?.copyright || '',
          watermark: data.setting?.web?.watermark,
          private: data.private,
          selectTenant: data.setting?.tenant?.mode === 'select',
        })
      }
    }
    catch {
      // PSou search APIs are public. The app metadata endpoint is optional.
    }

    app.value.version = import.meta.env.VITE_VERSION || 'v0.1.0'

    // #ifdef H5
    if (app.value.favicon) {
      setWebIcon(rurl(app.value.favicon))
    }
    if (typeof document !== 'undefined') {
      document.title = app.value.showName || app.value.name || document.title
    }
    // #endif
  }

  function initApp(): Promise<void> {
    if (initPromise)
      return initPromise
    initialized.value = true
    initPromise = initializeApp().finally(markAppReady)
    return initPromise
  }

  return {
    platform,
    keyword,
    app,
    initialized,
    initApp,
  }
})
