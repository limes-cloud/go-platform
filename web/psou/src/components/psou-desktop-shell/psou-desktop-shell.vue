<script setup lang="ts">
import type { Category, Channel, ChannelId } from '@/api/psou/type'
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import PsouBrand from '@/components/psou-brand/psou-brand.vue'
import PsouCategoryIcon from '@/components/psou-category-icon/psou-category-icon.vue'
import PsouSearchField from '@/components/psou-search-field/psou-search-field.vue'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  sidebar?: 'channels' | 'categories' | 'catalog' | 'none'
  overlay?: boolean
  flush?: boolean
  channels?: Channel[]
  catalogNodes?: Category[]
  homeCategory?: Category
  categories?: Category[]
  activeChannelId?: ChannelId
  activeCatalogId?: number
  activeCategory?: string
  searchKeyword?: string
  topbarFadeStart?: number
  back?: boolean
}>(), {
  sidebar: 'channels',
  overlay: false,
  flush: false,
  channels: () => [],
  catalogNodes: () => [],
  homeCategory: undefined,
  categories: () => [],
  activeCategory: '',
  searchKeyword: '',
  topbarFadeStart: 400,
  back: false,
})

const emit = defineEmits<{
  'home': []
  'select-channel': [channel: Channel]
  'select-catalog': [node: Category]
  'select-category': [category: Category]
  'select-parent': []
  'search': [value: string]
  'back': []
}>()

const keyword = ref(props.searchKeyword)
const scrollTop = ref(0)
let scrollFrame = 0

const showSidebar = computed(() => props.sidebar !== 'none')

watch(() => props.searchKeyword, (value) => {
  keyword.value = value
})

const homeCatalogNode = computed(() => props.catalogNodes.find(node => node.isHome))
const resolvedHomeCategory = computed(() => props.homeCategory || homeCatalogNode.value)
const catalogCategoryNodes = computed(() => props.catalogNodes.filter(node => !node.isHome))

function goHome() {
  emit('home')
}

function selectChannel(channel: Channel) {
  emit('select-channel', channel)
}

function selectCatalog(node: Category) {
  emit('select-catalog', node)
}

function selectHome() {
  if (isCatalogSidebar() && homeCatalogNode.value) {
    selectCatalog(homeCatalogNode.value)
    return
  }
  if (isCategorySidebar()) {
    emit('select-parent')
    return
  }
  goHome()
}

function selectCategory(category: Category) {
  emit('select-category', category)
}

function submitSearch(value: string) {
  emit('search', value)
}

function categoryActive(categoryId: string) {
  return props.activeCategory === String(categoryId)
}

function isCategorySidebar() {
  return props.sidebar === 'categories'
}

function isCatalogSidebar() {
  return props.sidebar === 'catalog'
}

const topbarProgress = computed(() => props.overlay
  ? Math.min(1, Math.max(0, (scrollTop.value - props.topbarFadeStart) / 40))
  : 1)
const topbarStyle = computed(() => {
  const progress = topbarProgress.value
  return {
    backgroundColor: `rgba(8, 11, 24, ${progress.toFixed(3)})`,
    borderBottomColor: `rgba(255, 255, 255, ${(progress * 0.1).toFixed(3)})`,
    boxShadow: `0 10px 30px rgba(0, 0, 0, ${(progress * 0.16).toFixed(3)})`,
    backdropFilter: progress > 0 ? `saturate(180%) blur(${Math.round(progress * 20)}px)` : 'none',
  }
})

function syncScrollTop() {
  const pageBody = document.querySelector<HTMLElement>('uni-page-body')
  scrollTop.value = Math.max(
    window.scrollY || 0,
    document.documentElement.scrollTop || 0,
    document.body.scrollTop || 0,
    pageBody?.scrollTop || 0,
  )
}

function handleWindowScroll() {
  if (scrollFrame)
    return
  scrollFrame = window.requestAnimationFrame(() => {
    syncScrollTop()
    scrollFrame = 0
  })
}

onMounted(() => {
  syncScrollTop()
  window.addEventListener('scroll', handleWindowScroll, { passive: true })
  document.querySelector('uni-page-body')?.addEventListener('scroll', handleWindowScroll, { passive: true })
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', handleWindowScroll)
  document.querySelector('uni-page-body')?.removeEventListener('scroll', handleWindowScroll)
  if (scrollFrame)
    window.cancelAnimationFrame(scrollFrame)
})
</script>

<template>
  <view
    class="psou-pc" :class="{
      'psou-pc--overlay': overlay,
      'psou-pc--no-sidebar': !showSidebar,
      'psou-pc--flush': flush,
    }"
  >
    <aside v-if="showSidebar" class="psou-pc__sidebar">
      <view class="psou-pc__brand">
        <PsouBrand @click="goHome" />
      </view>

      <view class="psou-pc__nav">
        <view
          class="psou-pc__nav-item psou-pc__nav-item--home"
          :class="{ 'is-active': isCatalogSidebar() && activeCatalogId === homeCatalogNode?.id }"
          @click="selectHome"
        >
          <view v-if="resolvedHomeCategory?.icon" class="psou-pc__nav-icon">
            <PsouCategoryIcon
              :icon="resolvedHomeCategory.icon"
              size="18px"
              fallback="home"
              color="var(--psou-accent)"
            />
          </view>
          <u-icon v-else name="home" size="18px" color="var(--psou-accent)" />
          <text>{{ resolvedHomeCategory?.name || '首页' }}</text>
        </view>

        <template v-if="isCatalogSidebar()">
          <view class="psou-pc__nav-label">
            频道
          </view>
          <view
            v-for="node in catalogCategoryNodes"
            :key="node.id"
            class="psou-pc__nav-item"
            :class="{ 'is-active': activeCatalogId === node.id }"
            @click="selectCatalog(node)"
          >
            <view class="psou-pc__nav-icon">
              <u-image
                v-if="node.icon"
                :src="node.icon"
                width="18px"
                height="18px"
                mode="aspectFit"
                bg-color="transparent"
                :show-loading="false"
              />
              <u-icon
                v-else
                name="grid"
                size="18px"
                :color="activeCatalogId === node.id ? 'var(--psou-accent)' : 'var(--psou-text-3)'"
              />
            </view>
            <text>{{ node.name }}</text>
          </view>
        </template>

        <template v-else-if="isCategorySidebar()">
          <view class="psou-pc__nav-label">
            资源分类
          </view>
          <view
            v-for="category in categories"
            :key="category.id"
            class="psou-pc__nav-item psou-pc__nav-item--sub"
            :class="{ 'is-active': categoryActive(String(category.id)) }"
            @click="selectCategory(category)"
          >
            <view class="psou-pc__nav-icon">
              <PsouCategoryIcon
                :icon="category.icon || 'grid'"
                size="18px"
                fallback="grid"
                :color="categoryActive(String(category.id)) ? 'var(--psou-accent)' : 'var(--psou-text-3)'"
              />
            </view>
            <text>{{ category.name }}</text>
          </view>
        </template>

        <template v-else>
          <view class="psou-pc__nav-label">
            频道
          </view>
          <view
            v-for="channel in channels"
            :key="channel.id"
            class="psou-pc__nav-item"
            :class="{ 'is-active': activeChannelId === channel.id }"
            @click="selectChannel(channel)"
          >
            <u-icon
              :name="channel.icon"
              size="18px"
              :color="activeChannelId === channel.id ? 'var(--psou-accent)' : 'var(--psou-text-3)'"
            />
            <text>{{ channel.name }}</text>
            <text class="psou-pc__count">
              {{ channel.count }}
            </text>
          </view>
        </template>
      </view>
    </aside>

    <view class="psou-pc__main">
      <header class="psou-pc__topbar" :style="topbarStyle">
        <view v-if="!showSidebar" class="psou-pc__topbar-brand">
          <view v-if="back" class="psou-pc__back" @click="emit('back')">
            <u-icon name="arrow-left" size="18px" color="#ffffff" />
          </view>
          <PsouBrand v-else @click="goHome" />
        </view>
        <view class="psou-pc__topbar-search">
          <PsouSearchField
            v-model="keyword"
            show-kbd
            @search="submitSearch"
          />
        </view>
      </header>
      <main class="psou-pc__content">
        <slot />
      </main>
    </view>
  </view>
</template>

<style lang="scss" scoped>
.psou-pc {
  box-sizing: border-box;
  min-height: 100vh;
  color: var(--psou-text);
  background: var(--psou-bg);
}

.psou-pc__sidebar {
  box-sizing: border-box;
  position: fixed;
  top: 0;
  bottom: 0;
  left: 0;
  z-index: 30;
  display: flex;
  width: 216px;
  flex-direction: column;
  padding: 14px 10px 10px;
  overflow-y: auto;
  border-right: 1px solid var(--psou-border);
  background: var(--psou-bg-soft);
  scrollbar-width: none;
}

.psou-pc__sidebar::-webkit-scrollbar {
  display: none;
}

.psou-pc--overlay .psou-pc__sidebar {
  border-right: 0;
  background: linear-gradient(90deg, rgba(5, 7, 15, 0.86) 0%, rgba(5, 7, 15, 0.5) 62%, rgba(5, 7, 15, 0) 100%);
}

.psou-pc__brand {
  display: flex;
  min-height: 48px;
  align-items: center;
  margin-bottom: 14px;
  padding: 0 8px;
}

.psou-pc__nav {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.psou-pc__nav-label {
  padding: 13px 9px 5px;
  color: var(--psou-text-3);
  font-family: 'SFMono-Regular', Consolas, monospace;
  font-size: $font-xs;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.psou-pc__nav-item {
  position: relative;
  display: flex;
  height: 48px;
  align-items: center;
  gap: 9px;
  padding: 0 9px;
  border-radius: 6px;
  color: var(--psou-text-2);
  font-size: $font-md;
  cursor: pointer;
  transition: background 0.18s ease, color 0.18s ease;
}

.psou-pc__nav-item:hover {
  color: var(--psou-text);
  background: var(--psou-hover);
}

.psou-pc__nav-item.is-active {
  color: var(--psou-text);
  font-weight: 500;
  background: var(--psou-active-bg);
}

.psou-pc__nav-item--home {
  color: var(--psou-text);
}

.psou-pc__nav-icon {
  display: flex;
  width: 18px;
  height: 18px;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
}

.psou-pc__count {
  margin-left: auto;
  color: var(--psou-text-3);
  font-size: $font-xs;
  font-variant-numeric: tabular-nums;
}

.psou-pc__main {
  box-sizing: border-box;
  min-height: 100vh;
  margin-left: 216px;
  padding-top: 76px;
}

.psou-pc--overlay .psou-pc__main,
.psou-pc--no-sidebar .psou-pc__main {
  margin-left: 0;
}

.psou-pc--overlay .psou-pc__main {
  padding-top: 0;
}

.psou-pc__topbar {
  box-sizing: border-box;
  position: fixed;
  top: 0;
  right: 0;
  left: 216px;
  z-index: 20;
  display: flex;
  height: 76px;
  align-items: center;
  gap: 16px;
  padding: 14px 20px;
  border-bottom: 1px solid var(--psou-border);
  background: rgba(8, 11, 24, 0);
  backdrop-filter: saturate(180%) blur(20px);
  transition: background-color 0.1s linear, border-color 0.1s linear, box-shadow 0.1s linear;
}

.psou-pc--overlay .psou-pc__topbar,
.psou-pc--no-sidebar .psou-pc__topbar {
  left: 0;
}

.psou-pc--overlay .psou-pc__topbar {
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.psou-pc--no-sidebar .psou-pc__topbar {
  padding-left: 24px;
}

.psou-pc__topbar-brand {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  margin-right: 8px;
}

.psou-pc__back {
  display: flex;
  width: 36px;
  height: 36px;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: opacity 0.18s ease;
}

.psou-pc__back:hover {
  opacity: 0.72;
}

.psou-pc__topbar-search {
  width: 100%;
  max-width: 480px;
  flex: 0 1 480px;
  margin-left: auto;
}

.psou-pc__content {
  padding: 0 24px 32px;
}

.psou-pc--no-sidebar .psou-pc__content {
  padding-left: 24px;
}

.psou-pc--flush .psou-pc__content {
  padding: 0;
}
</style>
