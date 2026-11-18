import { ref } from 'vue'

export interface MobileHeaderScrollHandle {
  setScrollTop: (value: number) => void
}

export function useMobileHeaderScroll() {
  const headerRef = ref<MobileHeaderScrollHandle>()

  function handlePageScroll({ scrollTop }: { scrollTop: number }) {
    headerRef.value?.setScrollTop(scrollTop)
  }

  return { headerRef, handlePageScroll }
}
