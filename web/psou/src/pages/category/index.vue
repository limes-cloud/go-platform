<script setup lang="ts">
import type { Category } from '@/api/psou/type'
import { onLoad, onPageScroll, onShow } from '@dcloudio/uni-app'
import { computed, ref } from 'vue'
import PsouCatalogCard from '@/components/psou-catalog-card/psou-catalog-card.vue'
// #ifdef H5
import PsouDesktopShell from '@/components/psou-desktop-shell/psou-desktop-shell.vue'
import PsouEmpty from '@/components/psou-empty/psou-empty.vue'
import PsouLoading from '@/components/psou-loading/psou-loading.vue'
// #endif
import PsouMobileHeader from '@/components/psou-mobile-header/psou-mobile-header.vue'
import PsouMobileTabbar from '@/components/psou-mobile-tabbar/psou-mobile-tabbar.vue'
import PsouPageHeading from '@/components/psou-page-heading/psou-page-heading.vue'
import { useMobileHeaderScroll } from '@/composables/useMobileHeaderScroll'
import { useResponsive } from '@/composables/useResponsive'
import { openCatalogChannelPage, openHomePage, openSearchPage } from '@/library/navigation'
import { trackEvent, trackPageView } from '@/library/tracker'
import { useCatalogStore } from '@/stores/catalog'

definePage({
  style: {
    navigationBarTitleText: '资源分类',
  },
})

const catalog = useCatalogStore()
const { isDesktop, isH5 } = useResponsive()
const { headerRef: mobileHeaderRef, handlePageScroll } = useMobileHeaderScroll()
const categories = ref<Category[]>([])
const loading = ref(true)
const error = ref('')
const visibleCategories = computed(() => {
  const list = Array.isArray(categories.value) ? categories.value : []
  return list.filter(category => !category.isHome)
})

async function loadCategories() {
  loading.value = true
  error.value = ''
  try {
    const list = await catalog.ensureRootCategories()
    categories.value = Array.isArray(list) ? list : []
  }
  catch (requestError) {
    error.value = requestError instanceof Error ? requestError.message : '分类加载失败'
  }
  finally {
    loading.value = false
  }
}

onLoad(loadCategories)
onShow(() => trackPageView('category_index'))
onPageScroll(handlePageScroll)

function selectCategory(category: Category, source: 'card' | 'sidebar' = 'card') {
  if (category.isHome) {
    goHome()
    return
  }
  trackEvent('category_card_click', { categoryId: category.id, source }, 'category_index')
  openCatalogChannelPage(category.id)
}

function selectCatalog(node: Category) {
  if (node.isHome) {
    goHome()
    return
  }
  selectCategory(node, 'sidebar')
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
    :catalog-nodes="categories"
    :search-keyword="catalog.searchKeyword"
    @home="goHome"
    @select-catalog="selectCatalog"
    @search="submitSearch"
  >
    <PsouLoading v-if="loading" />
    <PsouEmpty v-else-if="error" fill mode="data" :text="error" />
    <view v-else class="pc-category-index">
      <view class="pc-category-index__head">
        <PsouPageHeading
          eyebrow="RESOURCE CATEGORIES"
          title="资源分类"
          description="一级分类由后台配置并实时加载，首页分类不会在此重复展示。"
        />
      </view>
      <view class="pc-category-index__grid">
        <PsouCatalogCard
          v-for="(category, index) in visibleCategories"
          :key="category.id"
          :node="category"
          :tone="index"
          icon-tint
          layout="desktop"
          @select="selectCategory"
        />
      </view>
    </view>
  </PsouDesktopShell>
  <!-- #endif -->

  <view v-if="!isDesktop" class="psou-mobile-page with-tabbar">
    <PsouLoading v-if="loading" />
    <PsouEmpty v-else-if="error" fill mode="data" :text="error" />
    <view v-else class="m-category-index">
      <view
        class="m-category-index__nav"
        :class="{ 'm-category-index__nav--title': isH5 }"
      >
        <view v-if="isH5" class="m-category-index__titlebar">
          <text class="m-category-index__title">
            资源分类
          </text>
        </view>
        <PsouMobileHeader
          v-else
          ref="mobileHeaderRef"
          readonly
          @home="goHome"
          @open="openSearch"
        />
      </view>

      <view class="m-category-index__content">
        <view class="m-category-index__list">
          <PsouCatalogCard
            v-for="(category, index) in visibleCategories"
            :key="category.id"
            :node="category"
            :tone="index"
            icon-tint
            layout="mobile"
            @select="selectCategory"
          />
        </view>
      </view>
    </view>

    <PsouMobileTabbar current="category" />
  </view>
</template>

<style lang="scss" scoped>
.pc-category-index {
  padding-top: 28px;
}

.pc-category-index__head {
  margin-bottom: 22px;
}

.pc-category-index__grid {
  display: grid;
  gap: 12px;
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.m-category-index {
  padding-bottom: 24px;
}

.m-category-index__nav--title {
  height: calc(44px + env(safe-area-inset-top));
}

.m-category-index__titlebar {
  position: fixed;
  right: 0;
  top: 0;
  left: 0;
  z-index: 10;
  display: flex;
  height: calc(44px + env(safe-area-inset-top));
  box-sizing: border-box;
  align-items: center;
  justify-content: center;
  padding-top: env(safe-area-inset-top);
  background: rgba(8, 11, 24, 0.94);
  backdrop-filter: blur(18px);
}

.m-category-index__title {
  color: var(--psou-text);
  font-size: $font-md;
  font-weight: 600;
}

.m-category-index__content {
  padding: 16px 18px 0;
}

.m-category-index__list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
</style>
