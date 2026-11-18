import * as Pinia from 'pinia'
import uViewPro, { httpPlugin } from 'uview-pro'
import { createSSRApp } from 'vue'
import themes from '@/common/uview-pro.theme'
import { useGlobal } from '@/library/global'
import { setupTracker } from '@/library/tracker'
import { autoUpgradeVersion } from '@/library/upgrade'
import store from '@/stores'
import { useAppStore } from '@/stores/app'
import { useUserStore } from '@/stores/user'
import App from './App.vue'
import { httpInterceptor, httpRequestConfig } from './common/http.interceptor'
import 'uno.css'

export function createApp() {
  const app = createSSRApp(App)

  autoUpgradeVersion()

  app.use(uViewPro, {
    theme: {
      themes,
      defaultTheme: 'psou',
      defaultDarkMode: 'dark',
      isForce: true,
    },
  })
  app.use(httpPlugin, {
    requestConfig: httpRequestConfig,
    interceptor: httpInterceptor,
  })
  app.use(store)

  useGlobal(app)

  void useAppStore().initApp().finally(() => {
    void useUserStore().initUser()
    void setupTracker()
  })

  return {
    app,
    Pinia,
  }
}
