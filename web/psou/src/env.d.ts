/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_BASE_URL: string
  readonly VITE_APP_KEY?: string
  readonly VITE_APP_NAME: string
  readonly VITE_VERSION: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

interface Window {
  __PSOU_WEB_CONFIG__?: {
    apiBaseUrl?: string
    tracker?: {
      enable?: boolean
      debug?: boolean
    }
  }
}

declare module '*.vue' {
  import type { DefineComponent } from 'vue'

  const component: DefineComponent<Record<string, unknown>, Record<string, unknown>, any>
  export default component
}
