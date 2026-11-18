<script setup lang="ts">
import type { Category, ChannelId, ResourceItem } from '@/api/psou/type'
import { onLoad, onReachBottom, onShow } from '@dcloudio/uni-app'
import { computed, ref } from 'vue'
import { fetchCategoryResources } from '@/api/psou/service'
// #ifdef H5
import PsouDesktopShell from '@/components/psou-desktop-shell/psou-desktop-shell.vue'
// #endif
import PsouEmpty from '@/components/psou-empty/psou-empty.vue'
import PsouLoading from '@/components/psou-loading/psou-loading.vue'
import PsouMobileBackNav from '@/components/psou-mobile-back-nav/psou-mobile-back-nav.vue'
import PsouMobileTabbar from '@/components/psou-mobile-tabbar/psou-mobile-tabbar.vue'
import PsouPageHeading from '@/components/psou-page-heading/psou-page-heading.vue'
import PsouResourceGrid from '@/components/psou-resource-grid/psou-resource-grid.vue'
import { useResponsive } from '@/composables/useResponsive'
import {
  goBackOrRoute,
  openHomePage,
  openResourceDetailPage,
  openSearchPage,
  PSOU_ROUTES,
} from '@/library/navigation'
import { toResourceItem } from '@/library/resource-view'
import { trackEvent, trackPageView } from '@/library/tracker'
import { useCatalogStore } from '@/stores/catalog'

definePage({
  style: {
    navigationBarTitleText: '分类资源',
  },
})

const catalog = useCatalogStore()
const { isDesktop } = useResponsive()

const selectedCategoryId = ref('')
const rootCategory = ref<Category>()
const categories = ref<Category[]>([])
const selectedCategory = ref<Category>()
const resources = ref<ResourceItem[]>([])
const currentPage = ref(1)
const total = ref(0)
const loading = ref(true)
const switching = ref(false)
const loadingMore = ref(false)
const error = ref('')
const pageSize = 20
let requestId = 0
let pageRequestId = 0

const homeCategory = computed(() => catalog.homeCategory)
const channelIdByCategoryName: Record<string, ChannelId> = {
  影视: 'film',
  音乐: 'music',
  游戏: 'game',
  软件: 'software',
}

const totalPages = computed(() => Math.max(1, Math.ceil(total.value / pageSize)))
const hasMore = computed(() => resources.value.length < total.value)
const pageNumbers = computed(() => {
  const count = totalPages.value
  const visibleCount = Math.min(7, count)
  let start = Math.max(1, currentPage.value - Math.floor(visibleCount / 2))
  start = Math.min(start, count - visibleCount + 1)
  return Array.from({ length: visibleCount }, (_, index) => start + index)
})

async function loadResources(category: Category, page: number, append: boolean, currentRequest: number) {
  const currentPageRequest = ++pageRequestId
  if (append)
    loadingMore.value = true
  try {
    const data = await fetchCategoryResources(category.id, page, pageSize)
    if (currentRequest !== requestId || currentPageRequest !== pageRequestId)
      return

    const offset = append ? resources.value.length : 0
    const items = data.resources.map((resource, index) => toResourceItem(resource, offset + index, {
      category,
      channelId: channelIdByCategoryName[rootCategory.value?.name || ''] || catalog.channelId,
    }))
    resources.value = append ? [...resources.value, ...items] : items
    currentPage.value = data.pagination.page
    total.value = data.pagination.total
  }
  finally {
    if (currentRequest === requestId && currentPageRequest === pageRequestId)
      loadingMore.value = false
  }
}

async function loadCategory(categoryId?: string) {
  const currentRequest = ++requestId
  loading.value = true
  switching.value = false
  loadingMore.value = false
  error.value = ''
  resources.value = []
  currentPage.value = 1
  total.value = 0

  try {
    const targetCategoryId = Number(categoryId)
    if (!Number.isInteger(targetCategoryId) || targetCategoryId <= 0)
      throw new Error('缺少分类参数')

    await catalog.ensureRootCategories()
    const rootId = await catalog.resolveRootCategoryId(targetCategoryId)
    const root = catalog.rootCategories.find(category => category.id === rootId)
    if (!root)
      throw new Error('分类不存在或已隐藏')

    const children = await catalog.ensureCategoryChildren(root.id)
    const current = children.find(category => category.id === targetCategoryId) || children[0]
    if (!current)
      throw new Error('当前分类暂无二级分类')

    rootCategory.value = root
    categories.value = children
    selectedCategory.value = current
    selectedCategoryId.value = String(current.id)
    catalog.setCategoryParent(current.id, root.id)
    await loadResources(current, 1, false, currentRequest)
  }
  catch (requestError) {
    if (currentRequest !== requestId)
      return
    error.value = requestError instanceof Error ? requestError.message : '分类加载失败'
  }
  finally {
    if (currentRequest === requestId)
      loading.value = false
  }
}

async function switchCategory(category: Category) {
  const currentRequest = ++requestId
  switching.value = true
  loadingMore.value = false
  error.value = ''

  try {
    await loadResources(category, 1, false, currentRequest)
  }
  catch (requestError) {
    if (currentRequest !== requestId)
      return
    error.value = requestError instanceof Error ? requestError.message : '资源加载失败'
  }
  finally {
    if (currentRequest === requestId)
      switching.value = false
  }
}

async function goPage(target: number, append = false) {
  const category = selectedCategory.value
  if (!category || loading.value || switching.value || loadingMore.value || target < 1 || target > totalPages.value)
    return
  if (!append && target === currentPage.value)
    return

  try {
    await loadResources(category, target, append, requestId)
    if (!append)
      uni.pageScrollTo({ scrollTop: 0, duration: 0 })
  }
  catch (loadError) {
    if (!resources.value.length)
      error.value = loadError instanceof Error ? loadError.message : '资源加载失败'
  }
}

onReachBottom(() => {
  if (isDesktop.value || switching.value || !hasMore.value || loadingMore.value)
    return
  void goPage(currentPage.value + 1, true)
})

onLoad((query) => {
  selectedCategoryId.value = query?.category || ''
  void loadCategory(query?.category)
})
onShow(() => trackPageView('category_detail'))

function goBack() {
  goBackOrRoute(PSOU_ROUTES.category)
}

function openSearch() {
  openSearchPage()
}

function goDetail(resource: ResourceItem) {
  trackEvent('resource_card_click', {
    resourceId: resource.id,
    categoryId: selectedCategory.value?.id,
    platform: resource.platform,
  }, 'category_detail')
  openResourceDetailPage(resource.id, { catalogId: rootCategory.value?.id })
}

function goHome() {
  openHomePage()
}

function goCatalogHome() {
  openHomePage(rootCategory.value?.id)
}

function replaceCategoryQuery(categoryId: string) {
  // #ifdef H5
  if (typeof window === 'undefined')
    return

  const url = new URL(window.location.href)
  if (url.hash) {
    const [hashPath, hashQuery = ''] = url.hash.slice(1).split('?')
    const params = new URLSearchParams(hashQuery)
    params.set('category', categoryId)
    url.hash = `${hashPath}?${params.toString()}`
  }
  else {
    url.searchParams.set('category', categoryId)
  }
  window.history.replaceState(window.history.state, '', url)
  // #endif
}

async function selectShellCategory(category: Category) {
  if (!rootCategory.value || selectedCategoryId.value === String(category.id))
    return

  trackEvent('category_tab_switch', {
    categoryId: category.id,
    fromCategoryId: selectedCategoryId.value,
  }, 'category_detail')
  catalog.setCategoryParent(category.id, rootCategory.value.id)
  selectedCategoryId.value = String(category.id)
  selectedCategory.value = category
  replaceCategoryQuery(String(category.id))
  await switchCategory(category)
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
    sidebar="categories"
    :categories="categories"
    :home-category="rootCategory || homeCategory"
    :active-category="selectedCategoryId"
    :search-keyword="catalog.searchKeyword"
    @home="goHome"
    @select-parent="goCatalogHome"
    @select-category="selectShellCategory"
    @search="submitSearch"
  >
    <PsouLoading v-if="loading" />
    <PsouEmpty v-else-if="error && !selectedCategory" fill mode="data" :text="error" />
    <view v-else-if="selectedCategory" class="pc-cat-page">
      <view class="pc-cat-page__head">
        <PsouPageHeading
          :title="selectedCategory.name"
          :icon="selectedCategory.icon"
          :count="switching ? '加载中...' : `${total} 份资源`"
        />
      </view>

      <view
        class="pc-cat-grid"
        :class="{ 'is-switching': switching }"
        :aria-busy="switching"
      >
        <PsouEmpty v-if="error" fill mode="data" :text="error" />
        <PsouResourceGrid
          v-else-if="resources.length"
          :resources="resources"
          layout="desktop"
          @select="goDetail"
        />
        <PsouEmpty v-else-if="!switching" fill mode="data" text="当前分类暂无资源" />
      </view>

      <PsouLoading
        v-if="switching && !resources.length && !error"
        compact
        text="正在切换分类..."
      />

      <view v-if="totalPages > 1 && !switching" class="pc-pager">
        <text
          class="pc-pager__item"
          :class="{ 'is-disabled': currentPage <= 1 }"
          @click="goPage(currentPage - 1)"
        >
          上一页
        </text>
        <text
          v-for="pageNumber in pageNumbers"
          :key="pageNumber"
          class="pc-pager__item"
          :class="{ 'is-active': currentPage === pageNumber }"
          @click="goPage(pageNumber)"
        >
          {{ pageNumber }}
        </text>
        <text
          class="pc-pager__item"
          :class="{ 'is-disabled': currentPage >= totalPages }"
          @click="goPage(currentPage + 1)"
        >
          下一页
        </text>
      </view>
    </view>
  </PsouDesktopShell>
  <!-- #endif -->

  <view v-if="!isDesktop" class="psou-mobile-page with-tabbar">
    <PsouMobileBackNav
      variant="solid"
      :title="selectedCategory?.name || rootCategory?.name || '分类资源'"
      search
      @back="goBack"
      @search="openSearch"
    />
    <PsouLoading v-if="loading" />
    <PsouEmpty v-else-if="error && !selectedCategory" fill mode="data" :text="error" />
    <view v-else-if="selectedCategory" class="m-cat-page">
      <view
        class="m-cat-grid"
        :class="{ 'is-switching': switching }"
        :aria-busy="switching"
      >
        <PsouEmpty v-if="error" fill mode="data" :text="error" />
        <PsouResourceGrid
          v-else-if="resources.length"
          :resources="resources"
          layout="mobile"
          @select="goDetail"
        />
        <PsouEmpty v-else-if="!switching" fill mode="data" text="当前分类暂无资源" />
      </view>

      <PsouLoading
        v-if="switching && !resources.length && !error"
        compact
        text="正在切换分类..."
      />

      <PsouLoading v-if="loadingMore" compact text="加载更多..." />
      <text v-else-if="!switching && resources.length && !hasMore" class="m-cat-end">
        已加载全部资源
      </text>
    </view>

    <PsouMobileTabbar current="category" />
  </view>
</template>

<style lang="scss" scoped>
.pc-cat-page {
  padding-top: 24px;
}

.pc-cat-page__head {
  margin-bottom: 18px;
}

.pc-cat-page__head :deep(.psou-page-heading__count) {
  font-size: $font-normal;
}

.pc-cat-grid {
  min-height: 120px;
  transition: opacity 0.15s ease;
}

.pc-cat-grid.is-switching {
  pointer-events: none;
  opacity: 0.45;
}

.pc-pager {
  display: flex;
  justify-content: center;
  gap: 6px;
  padding: 30px 0 8px;
}

.pc-pager__item {
  display: inline-flex;
  min-width: 30px;
  height: 30px;
  align-items: center;
  justify-content: center;
  padding: 0 9px;
  border: 1px solid var(--psou-border);
  border-radius: 7px;
  color: var(--psou-text-2);
  font-size: $font-xs;
  background: var(--psou-surface);
}

.pc-pager__item.is-active {
  border-color: rgba(56, 214, 228, 0.38);
  color: var(--psou-accent);
  background: var(--psou-active-bg);
}

.pc-pager__item.is-disabled {
  color: var(--psou-text-3);
  cursor: not-allowed;
  opacity: 0.55;
}

.pc-pager__item:not(.is-disabled):not(.is-active):hover {
  border-color: var(--psou-border-strong);
  color: var(--psou-text);
}

.m-cat-page {
  padding: 14px 0 22px;
}

.m-cat-grid {
  min-height: 120px;
  padding: 0 18px;
  transition: opacity 0.15s ease;
}

.m-cat-grid.is-switching {
  pointer-events: none;
  opacity: 0.45;
}

.m-cat-end {
  display: block;
  padding: 20px 18px 0;
  color: var(--psou-text-3);
  font-size: $font-xs;
  text-align: center;
}
</style>
