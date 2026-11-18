<script setup lang="ts">
import { computed } from 'vue'
import { FONT_SIZE_XS } from '@/common/typography'
import { PSOU_ROUTES } from '@/library/navigation'

type MobileTabKey = 'home' | 'category' | 'search'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = defineProps<{
  current: MobileTabKey
}>()

const allItems: Array<{
  key: MobileTabKey
  text: string
  iconPath: string
  selectedIconPath: string
  url: string
}> = [
  { key: 'home', text: '首页', iconPath: 'home', selectedIconPath: 'home-fill', url: PSOU_ROUTES.home },
  { key: 'category', text: '分类', iconPath: 'grid', selectedIconPath: 'grid-fill', url: PSOU_ROUTES.category },
]

const items = allItems
const currentIndex = computed(() => items.findIndex(item => item.key === props.current))

function switchPage(index: number) {
  const item = items[index]
  if (!item)
    return
  const pages = getCurrentPages()
  const route = pages[pages.length - 1]?.route || ''
  if (route === item.url.replace(/^\//, ''))
    return
  uni.reLaunch({ url: item.url })
}
</script>

<template>
  <view class="psou-mobile-tabbar">
    <view class="psou-mobile-tabbar__safe-area" />
    <u-tabbar
      :model-value="currentIndex"
      :list="items"
      height="64px"
      icon-size="22px"
      :text-size="FONT_SIZE_XS"
      gap="4px"
      :border-top="false"
      :hide-tab-bar="false"
      bg-color="#080b18"
      active-color="var(--psou-accent)"
      inactive-color="var(--psou-text-3)"
      @change="switchPage"
    />
  </view>
</template>

<style lang="scss" scoped>
.psou-mobile-tabbar {
  &__safe-area {
    position: fixed;
    right: 0;
    bottom: 0;
    left: 0;
    z-index: 997;
    width: 100%;
    height: constant(safe-area-inset-bottom);
    height: env(safe-area-inset-bottom);
    background: #080b18;
    pointer-events: none;
  }

  :deep(.u-tabbar__content) {
    right: 0;
    left: 0;
    width: 100%;
    background: #080b18;
    border: 0;
    backdrop-filter: saturate(180%) blur(20px);
  }

  :deep(.u-tabbar__content__item) {
    padding-top: 8px;
    padding-bottom: 6px;
  }

  :deep(.u-tabbar__content__item__text) {
    font-size: $font-xs;
    line-height: 14px;
  }

  :deep(.u-fixed-placeholder) {
    display: none;
  }
}
</style>
