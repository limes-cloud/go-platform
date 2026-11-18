import type { App } from 'vue'
import { useToast } from 'uview-pro'
import logo from '@/static/logo.png'
import { copy } from './copy'
import nav from './nav'
import time from './time'
import { rurl } from './url'

interface ToastOptions {
  title?: string
  type?: 'success' | 'error' | 'warning' | 'info' | 'primary' | 'none'
  duration?: number
  back?: boolean
}

export interface GlobalExpose {
  logo: string
  back: () => void
  to: (path: string) => void
  home: () => void
  logout: () => Promise<void>
  copy: (text: string, successText?: string) => void
  rurl: (url: string, w?: number, h?: number) => string
  utoast: {
    show: (options: ToastOptions) => void
    hide: () => void
  }
  parseTime: typeof time.parseTime
  formatTime: typeof time.formatTime
}

export function useGlobal(app: App<Element>) {
  const toast = useToast({ global: true })

  const global: GlobalExpose = {
    logo,
    ...nav,
    copy,
    rurl,
    ...time,
    utoast: {
      show(options: ToastOptions) {
        const type = options.type === 'none' ? undefined : options.type
        toast.show({
          title: options.title,
          type,
          duration: options.duration ?? 2000,
        })
        if (options.back) {
          setTimeout(() => nav.back(), 300)
        }
      },
      hide() {
        toast.close()
      },
    },
  }

  uni.$g = global
  app.config.globalProperties.$g = global
}
