import type { GlobalExpose } from '@/library/global'

declare global {
  interface Uni {
    $g: GlobalExpose
  }
}

declare module 'vue' {
  interface ComponentCustomProperties {
    $g: GlobalExpose
  }
}

export {}
