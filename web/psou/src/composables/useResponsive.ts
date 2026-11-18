import { computed, onMounted, onUnmounted, ref } from 'vue'
import { getPlatform } from '@/library/utils/platform'

const PC_BREAKPOINT = 1024

export function getViewportWidth() {
  // #ifdef H5
  if (typeof window !== 'undefined')
    return window.innerWidth
  // #endif
  return uni.getWindowInfo().windowWidth
}

export function useResponsive() {
  const platform = getPlatform()
  const isH5 = platform.startsWith('web')
  const windowWidth = ref(getViewportWidth())

  const isDesktop = computed(() => isH5 && windowWidth.value >= PC_BREAKPOINT)

  function handleWindowResize() {
    windowWidth.value = getViewportWidth()
  }

  onMounted(() => {
    if (isH5)
      uni.onWindowResize(handleWindowResize)
  })

  onUnmounted(() => {
    if (isH5)
      uni.offWindowResize(handleWindowResize)
  })

  return {
    isDesktop,
    isH5,
    windowWidth,
  }
}
