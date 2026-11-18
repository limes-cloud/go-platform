<script setup lang="ts">
import type { Category } from '@/api/psou/type'
import { onLoad, onPageScroll, onShow } from '@dcloudio/uni-app'
import { computed, ref } from 'vue'
import PsouCatalogFeed from '@/components/psou-catalog-feed/psou-catalog-feed.vue'
// #ifdef H5
import PsouDesktopShell from '@/components/psou-desktop-shell/psou-desktop-shell.vue'
// #endif
import PsouEmpty from '@/components/psou-empty/psou-empty.vue'
import PsouLoading from '@/components/psou-loading/psou-loading.vue'
import PsouMobileBackNav from '@/components/psou-mobile-back-nav/psou-mobile-back-nav.vue'
import PsouMobileTabbar from '@/components/psou-mobile-tabbar/psou-mobile-tabbar.vue'
import { useResponsive } from '@/composables/useResponsive'
import {
  goBackOrRoute,
  openHomePage,
  openSearchPage,
  PSOU_ROUTES,
  syncCatalogQuery,
} from '@/library/navigation'
import { trackEvent, trackPageView } from '@/library/tracker'
import { useCatalogStore } from '@/stores/catalog'

definePage({
  style: {
    navigationBarTitleText: '分类频道',
  },
})

const catalog = useCatalogStore()
const { isDesktop } = useResponsive()

const catalogNodes = computed(() => catalog.rootCategories)
const selectedCatalogId = ref<number>()
const loading = ref(true)
const error = ref('')
const scrollTop = ref(0)
const currentCategory = computed(() => catalogNodes.value.find(node => node.id === selectedCatalogId.value))
const pageTitle = computed(() => currentCategory.value?.name || '分类频道')

async function loadPage(catalogId?: string) {
  loading.value = true
  error.value = ''

  try {
    const nodes = await catalog.ensureRootCategories()
    const targetCatalogId = Number(catalogId)
    if (!Number.isInteger(targetCatalogId) || targetCatalogId <= 0)
      throw new Error('缺少分类参数')

    const node = nodes.find(item => item.id === targetCatalogId)
    if (!node)
      throw new Error('分类不存在或已隐藏')

    selectedCatalogId.value = targetCatalogId
  }
  catch (requestError) {
    error.value = requestError instanceof Error ? requestError.message : '分类加载失败'
  }
  finally {
    loading.value = false
  }
}

onLoad((query) => {
  void loadPage(query?.catalogId)
})
onShow(() => trackPageView('category_channel'))

onPageScroll(({ scrollTop: value }) => {
  scrollTop.value = value
})

function selectCatalog(node: Category) {
  if (node.isHome) {
    goHome()
    return
  }
  if (node.id === selectedCatalogId.value)
    return

  trackEvent('home_category_switch', { categoryId: node.id, target: 'channel' }, 'category_channel')
  selectedCatalogId.value = node.id
  syncCatalogQuery(node.id)
  uni.pageScrollTo({ scrollTop: 0, duration: 0 })
}

function goBack() {
  goBackOrRoute(PSOU_ROUTES.category)
}

function goHome() {
  openHomePage()
}

function submitSearch(value: string) {
  catalog.setSearchKeyword(value)
  openSearchPage()
}
</script>

<template>
  <!-- #ifdef H5 -->
  <PsouDesktopShell
    v-if="isDesktop"
    sidebar="catalog"
    overlay
    flush
    :topbar-fade-start="100"
    :catalog-nodes="catalogNodes"
    :active-catalog-id="selectedCatalogId"
    :search-keyword="catalog.searchKeyword"
    @home="goHome"
    @select-catalog="selectCatalog"
    @search="submitSearch"
  >
    <PsouLoading v-if="loading" />
    <PsouEmpty v-else-if="error" fill mode="data" :text="error" />
    <PsouCatalogFeed
      v-else-if="selectedCatalogId"
      layout="desktop"
      :catalog-id="selectedCatalogId"
    />
  </PsouDesktopShell>
  <!-- #endif -->

  <view v-if="!isDesktop" class="psou-mobile-page with-tabbar">
    <PsouMobileBackNav
      fixed
      :title="pageTitle"
      :scroll-top="scrollTop"
      @back="goBack"
    />
    <PsouLoading v-if="loading" />
    <PsouEmpty v-else-if="error" fill mode="data" :text="error" />
    <PsouCatalogFeed
      v-else-if="selectedCatalogId"
      layout="mobile"
      :catalog-id="selectedCatalogId"
      immersive
    />

    <PsouMobileTabbar current="category" />
  </view>
</template>
