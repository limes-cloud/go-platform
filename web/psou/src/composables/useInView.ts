import type { Ref } from 'vue'
import { onBeforeUnmount, onMounted, ref } from 'vue'

export interface InViewOptions {
  /** 进入视口前提前加载的距离，默认上下各提前 300px。 */
  rootMargin?: string
  /** 触发阈值，默认 0。 */
  threshold?: number
  /** 关闭懒加载时直接视为已进入视口。 */
  enabled?: boolean
}

/** H5 下 ref 拿到的是 uni 组件实例，优先取真实 DOM 节点。 */
function resolveElement(target: unknown): Element | null {
  if (!target)
    return null

  const node = target as { $el?: unknown, getBoundingClientRect?: () => DOMRect }
  if (typeof node.getBoundingClientRect === 'function')
    return node as unknown as Element

  const el = node.$el
  if (el && typeof (el as Element).getBoundingClientRect === 'function')
    return el as Element

  return null
}

/** 监听元素是否进入视口，用于图片/模块懒加载；不支持 IntersectionObserver 时直接放行。 */
export function useInView(target: Ref<unknown>, options: InViewOptions = {}) {
  const { rootMargin = '300px 0px', threshold = 0, enabled = true } = options
  const inView = ref(!enabled)
  let observer: IntersectionObserver | null = null

  onMounted(() => {
    if (!enabled)
      return

    const el = resolveElement(target.value)
    if (typeof IntersectionObserver === 'undefined' || !el) {
      inView.value = true
      return
    }

    observer = new IntersectionObserver((entries) => {
      if (!entries.some(entry => entry.isIntersecting))
        return
      inView.value = true
      observer?.disconnect()
      observer = null
    }, { rootMargin, threshold })
    observer.observe(el)
  })

  onBeforeUnmount(() => {
    observer?.disconnect()
    observer = null
  })

  return { inView }
}
