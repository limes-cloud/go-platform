<script setup lang="ts">
import type { Category } from '@/api/psou/type'
import { onLoad, onPageScroll, onPullDownRefresh, onShow } from '@dcloudio/uni-app'
import { computed, ref } from 'vue'
import PsouCatalogFeed from '@/components/psou-catalog-feed/psou-catalog-feed.vue'
// #ifdef H5
import PsouDesktopShell from '@/components/psou-desktop-shell/psou-desktop-shell.vue'
// #endif
import PsouEmpty from '@/components/psou-empty/psou-empty.vue'
import PsouLoading from '@/components/psou-loading/psou-loading.vue'
import PsouMobileHeader from '@/components/psou-mobile-header/psou-mobile-header.vue'
import PsouMobileTabbar from '@/components/psou-mobile-tabbar/psou-mobile-tabbar.vue'
import PsouSiteFooter from '@/components/psou-site-footer/psou-site-footer.vue'
import { useMobileHeaderScroll } from '@/composables/useMobileHeaderScroll'
import { useResponsive } from '@/composables/useResponsive'
import { openHomePage, openSearchPage, syncCatalogQuery } from '@/library/navigation'
import { trackEvent, trackPageView } from '@/library/tracker'
import { useCatalogStore } from '@/stores/catalog'

definePage({
  type: 'home',
  style: {
    navigationBarTitleText: 'PSou',
    enablePullDownRefresh: true,
  },
})

const catalog = useCatalogStore()
const { isDesktop } = useResponsive()
const { headerRef: mobileHeaderRef, handlePageScroll } = useMobileHeaderScroll()

const catalogNodes = computed(() => catalog.rootCategories)
const selectedCatalogId = ref<number>()
const catalogLoading = ref(true)
const catalogError = ref('')
const refreshKey = ref(0)
const activeCatalogId = computed(() => selectedCatalogId.value ?? catalogNodes.value.find(node => node.isHome)?.id)

async function loadHomePage(preferredCatalogId?: string, force = false) {
  catalogLoading.value = true
  catalogError.value = ''

  try {
    const nodes = await catalog.ensureRootCategories(force)
    const homeCategory = nodes.find(node => node.isHome) || nodes[0]
    if (!homeCategory) {
      catalogError.value = '暂无可用分类'
      return
    }

    const targetCatalogId = Number(preferredCatalogId)
    selectedCatalogId.value = Number.isInteger(targetCatalogId) && nodes.some(node => node.id === targetCatalogId)
      ? targetCatalogId
      : homeCategory.id
  }
  catch (requestError) {
    catalogError.value = requestError instanceof Error ? requestError.message : '首页加载失败'
  }
  finally {
    catalogLoading.value = false
  }
}

onLoad((query) => {
  void loadHomePage(query?.catalogId)
})
onShow(() => trackPageView('home'))
onPageScroll(handlePageScroll)

onPullDownRefresh(async () => {
  await loadHomePage(selectedCatalogId.value ? String(selectedCatalogId.value) : undefined, true)
  refreshKey.value += 1
  uni.stopPullDownRefresh()
})

function selectCatalog(node: Category) {
  if (node.isHome) {
    selectHome()
    return
  }
  if (selectedCatalogId.value === node.id)
    return

  trackEvent('home_category_switch', { categoryId: node.id, target: 'catalog' }, 'home')
  selectedCatalogId.value = node.id
  syncCatalogQuery(node.id)
}

function selectHome() {
  const homeCategory = catalogNodes.value.find(node => node.isHome) || catalogNodes.value[0]
  if (!homeCategory)
    return

  if (selectedCatalogId.value !== homeCategory.id)
    trackEvent('home_category_switch', { categoryId: homeCategory.id, target: 'home' }, 'home')
  selectedCatalogId.value = homeCategory.id
  syncCatalogQuery(undefined)
  uni.pageScrollTo({ scrollTop: 0, duration: 200 })
}

function openSearch() {
  openSearchPage()
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
    :active-catalog-id="activeCatalogId"
    :search-keyword="catalog.searchKeyword"
    @home="goHome"
    @select-catalog="selectCatalog"
    @search="submitSearch"
  >
    <PsouLoading v-if="catalogLoading" />
    <PsouEmpty v-else-if="catalogError" fill mode="data" :text="catalogError" />
    <PsouCatalogFeed
      v-else-if="selectedCatalogId"
      layout="desktop"
      :catalog-id="selectedCatalogId"
      :refresh-key="refreshKey"
    />
    <PsouSiteFooter layout="desktop" />
  </PsouDesktopShell>
  <!-- #endif -->

  <view v-if="!isDesktop" class="psou-mobile-page with-tabbar">
    <PsouMobileHeader
      ref="mobileHeaderRef"
      immersive
      readonly
      tone="hero"
      :fade-distance="80"
      @home="goHome"
      @open="openSearch"
    />
    <PsouLoading v-if="catalogLoading" />
    <PsouEmpty v-else-if="catalogError" fill mode="data" :text="catalogError" />
    <PsouCatalogFeed
      v-else-if="selectedCatalogId"
      layout="mobile"
      :catalog-id="selectedCatalogId"
      :refresh-key="refreshKey"
      immersive
    />

    <PsouSiteFooter />

    <PsouMobileTabbar current="home" />
  </view>
</template>
