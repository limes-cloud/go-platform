<script setup lang="ts">
import type { BannerItem, ChannelId, GetResourceHomeReply, HomeSection, ResourceItem } from '@/api/psou/type'
import { computed, ref, watch } from 'vue'
import { fetchResourceHome } from '@/api/psou/service'
import PsouButton from '@/components/psou-button/psou-button.vue'
import PsouCover from '@/components/psou-cover/psou-cover.vue'
import PsouEmpty from '@/components/psou-empty/psou-empty.vue'
import PsouLoading from '@/components/psou-loading/psou-loading.vue'
import PsouResourceGrid from '@/components/psou-resource-grid/psou-resource-grid.vue'
import PsouSectionHeading from '@/components/psou-section-heading/psou-section-heading.vue'
import PsouToneHero from '@/components/psou-tone-hero/psou-tone-hero.vue'
import { useResponsive } from '@/composables/useResponsive'
import { openCategoryDetailPage, openResourceDetailPage } from '@/library/navigation'
import { toResourceItem } from '@/library/resource-view'
import { trackEvent } from '@/library/tracker'
import { useAppStore } from '@/stores/app'
import { useCatalogStore } from '@/stores/catalog'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  catalogId?: number
  layout: 'desktop' | 'mobile'
  immersive?: boolean
  refreshKey?: number
}>(), {
  catalogId: undefined,
  immersive: false,
  refreshKey: 0,
})

const catalog = useCatalogStore()
const appStore = useAppStore()
const { isH5 } = useResponsive()

const aggregate = ref<GetResourceHomeReply>()
const banners = ref<BannerItem[]>([])
const sections = ref<HomeSection[]>([])
const loading = ref(true)
const error = ref('')
const activeBannerIndex = ref(0)
let requestId = 0

const heroButtonSize = computed(() => isH5 ? 'small' : 'default')
const mobileHeaderOffsetHeight = computed(() => `${appStore.app.navHeight || 64}px`)
const mobileHeroHeight = computed(() => props.immersive
  ? `calc(450rpx + ${appStore.app.navHeight || 0}px)`
  : '450rpx')
const activeBanner = computed(() => banners.value[activeBannerIndex.value] || banners.value[0])
const activeCategory = computed(() => aggregate.value?.category)
const hasContent = computed(() => banners.value.length > 0 || sections.value.length > 0)
const targetCatalogId = computed(() => props.catalogId ?? catalog.homeCategory?.id)
const channelIdByCatalogName: Record<string, ChannelId> = {
  影视: 'film',
  音乐: 'music',
  游戏: 'game',
  软件: 'software',
}

function toBanners(data: GetResourceHomeReply): BannerItem[] {
  return data.banners.map((resource, index) => ({
    resource: toResourceItem(resource, index, {
      channelId: channelIdByCatalogName[activeCategory.value?.name || ''] || 'film',
    }),
    tags: resource.tags,
  }))
}

function toSections(data: GetResourceHomeReply): HomeSection[] {
  return data.sections.map(section => ({
    category: section.category,
    resources: section.resources.map((resource, index) => toResourceItem(resource, index, {
      category: section.category,
      channelId: channelIdByCatalogName[activeCategory.value?.name || ''] || 'film',
    })),
  }))
}

async function loadAggregate(categoryId?: number) {
  const currentRequest = ++requestId
  if (!categoryId) {
    banners.value = []
    sections.value = []
    loading.value = false
    error.value = ''
    return
  }

  loading.value = true
  error.value = ''
  banners.value = []
  sections.value = []
  aggregate.value = undefined

  try {
    const data = await fetchResourceHome(categoryId)
    if (currentRequest !== requestId)
      return

    aggregate.value = data
    banners.value = toBanners(data)
    sections.value = toSections(data)
    activeBannerIndex.value = 0
  }
  catch (requestError) {
    if (currentRequest !== requestId)
      return
    error.value = requestError instanceof Error ? requestError.message : '频道加载失败'
  }
  finally {
    if (currentRequest === requestId)
      loading.value = false
  }
}

function refresh() {
  void loadAggregate(targetCatalogId.value)
}

function selectBanner(index: number) {
  activeBannerIndex.value = index
}

function handleBannerChange(event: { detail: { current: number } }) {
  selectBanner(event.detail.current)
}

function goDetail(resource: ResourceItem) {
  trackEvent('resource_card_click', {
    resourceId: resource.id,
    categoryId: resource.categoryId,
    platform: resource.platform,
    source: 'feed',
  })
  openResourceDetailPage(resource.id, { catalogId: targetCatalogId.value })
}

function goCategory(category: HomeSection['category']) {
  trackEvent('category_card_click', { categoryId: category.id, source: 'feed_more' })
  catalog.setCategoryParent(category.id, category.parentId)
  openCategoryDetailPage(category.id)
}

watch(targetCatalogId, categoryId => void loadAggregate(categoryId), { immediate: true })
watch(() => props.refreshKey, refresh)

defineExpose({ refresh })
</script>

<template>
  <!-- #ifdef H5 -->
  <view v-if="layout === 'desktop'" class="pc-catalog-feed">
    <PsouLoading v-if="loading" />
    <PsouEmpty v-else-if="error" fill mode="data" :text="error" />
    <view v-else-if="hasContent" class="pc-home">
      <view v-if="activeBanner" class="pc-hero">
        <view class="pc-hero__swiper">
          <swiper
            :current="activeBannerIndex"
            :autoplay="banners.length > 1"
            :interval="5200"
            :duration="500"
            circular
            style="height: 100%"
            @change="handleBannerChange"
          >
            <swiper-item v-for="(banner, index) in banners" :key="banner.resource.id">
              <view class="pc-hero__slide-item">
                <view class="pc-hero__slide">
                  <PsouToneHero
                    :cover="banner.resource.cover"
                    :tone="banner.resource.coverTone"
                    :glyph="banner.resource.glyph"
                    :focus-x="banner.resource.bannerFocusX"
                    :focus-y="banner.resource.bannerFocusY"
                    :lazy="index > 0"
                    variant="slide-desktop"
                  >
                    <view class="pc-hero__copy">
                      <view class="pc-hero__title-row">
                        <text class="pc-hero__title">
                          {{ banner.resource.title }}
                        </text>
                        <text v-if="banner.resource.score" class="pc-hero__score">
                          {{ banner.resource.score }}
                        </text>
                      </view>
                      <view class="pc-hero__meta">
                        <view class="pc-hero__tags">
                          <text
                            v-for="tag in banner.tags"
                            :key="tag"
                            class="pc-hero__tag"
                          >
                            {{ tag }}
                          </text>
                        </view>
                      </view>
                      <text class="pc-hero__desc">
                        {{ banner.resource.description }}
                      </text>
                      <view class="pc-hero__actions">
                        <PsouButton :size="heroButtonSize" @click="goDetail(banner.resource)">
                          <u-icon name="play-right-fill" size="15px" color="#fff" />
                          <text class="hero-action-text">
                            立即查看
                          </text>
                        </PsouButton>
                      </view>
                    </view>
                  </PsouToneHero>
                </view>
              </view>
            </swiper-item>
          </swiper>
        </view>
        <view class="pc-hero__thumbs">
          <view
            v-for="(banner, index) in banners"
            :key="banner.resource.id"
            class="pc-hero__thumb"
            :class="{ 'is-active': activeBannerIndex === index }"
            @click="selectBanner(index)"
          >
            <PsouCover
              :cover="banner.resource.cover"
              :tone="banner.resource.coverTone"
              :glyph="banner.resource.glyph"
            />
          </view>
        </view>
      </view>
      <view v-else class="pc-home__nav-placeholder" />

      <view class="pc-home__body">
        <view v-for="section in sections" :key="section.category.id" class="pc-home__section">
          <view class="pc-section-head">
            <PsouSectionHeading
              :title="section.category.name"
              :icon="section.category.icon || 'grid'"
              icon-size="18px"
              variant="icon"
              more-text="查看全部"
              @more="goCategory(section.category)"
            />
          </view>
          <PsouResourceGrid
            :resources="section.resources"
            layout="desktop"
            density="compact"
            :max-rows="2"
            @select="goDetail"
          />
        </view>
      </view>
    </view>
    <PsouEmpty v-else fill mode="data" text="暂无推荐内容" />
  </view>
  <!-- #endif -->

  <view v-if="layout === 'mobile'" class="m-catalog-feed">
    <view
      v-if="immersive && !activeBanner"
      class="m-home__nav-placeholder"
      :style="{ height: mobileHeaderOffsetHeight }"
    />
    <PsouLoading v-if="loading" />
    <PsouEmpty v-else-if="error" fill mode="data" :text="error" />
    <template v-else-if="hasContent">
      <view v-if="activeBanner" class="m-home__hero" :style="{ height: mobileHeroHeight }">
        <view class="m-home__swiper">
          <swiper
            :current="activeBannerIndex"
            :autoplay="banners.length > 1"
            :interval="5200"
            :duration="500"
            circular
            style="height: 100%"
            @change="handleBannerChange"
          >
            <swiper-item v-for="(banner, index) in banners" :key="banner.resource.id">
              <view class="m-home__slide-item">
                <view class="m-home__slide">
                  <PsouToneHero
                    :cover="banner.resource.cover"
                    :tone="banner.resource.coverTone"
                    :glyph="banner.resource.glyph"
                    :focus-x="banner.resource.bannerFocusX"
                    :focus-y="banner.resource.bannerFocusY"
                    :lazy="index > 0"
                    variant="slide"
                  >
                    <view class="m-home__copy">
                      <view class="m-home__title-row">
                        <text class="m-home__title">
                          {{ banner.resource.title }}
                        </text>
                        <text v-if="banner.resource.score" class="m-home__score">
                          {{ banner.resource.score }}
                        </text>
                      </view>
                      <view v-if="banner.tags.length" class="m-home__meta">
                        <view class="m-home__tags">
                          <text
                            v-for="tag in banner.tags"
                            :key="tag"
                            class="m-home__tag"
                          >
                            {{ tag }}
                          </text>
                        </view>
                      </view>
                      <text class="m-home__desc">
                        {{ banner.resource.description }}
                      </text>
                      <view class="m-home__actions">
                        <PsouButton :size="heroButtonSize" @click="goDetail(banner.resource)">
                          <u-icon name="play-right-fill" size="16px" color="#fff" />
                          <text class="hero-action-text">
                            立即查看
                          </text>
                        </PsouButton>
                      </view>
                    </view>
                  </PsouToneHero>
                </view>
              </view>
            </swiper-item>
          </swiper>
        </view>

        <view class="m-home__dots">
          <view
            v-for="(banner, index) in banners"
            :key="banner.resource.id"
            class="m-home__dot"
            :class="{ 'is-active': activeBannerIndex === index }"
            @click="selectBanner(index)"
          />
        </view>
      </view>

      <view class="m-home__body">
        <section v-for="section in sections" :key="section.category.id" class="m-home__section">
          <view class="m-home__section-head">
            <PsouSectionHeading
              :title="section.category.name"
              :icon="section.category.icon || 'grid'"
              variant="icon"
              more-text="查看全部"
              @more="goCategory(section.category)"
            />
          </view>
          <PsouResourceGrid
            :resources="section.resources"
            layout="mobile"
            density="compact"
            :max-rows="2"
            @select="goDetail"
          />
        </section>
      </view>
    </template>
    <PsouEmpty v-else fill mode="data" text="暂无推荐内容" />
  </view>
</template>

<style lang="scss" scoped>
.pc-home {
  min-height: 100vh;
  background: var(--psou-bg);
}

.pc-hero {
  position: relative;
  width: 100%;
  overflow: hidden;
  isolation: isolate;
  aspect-ratio: 12 / 5;
  color: #fff;
}

.pc-hero__swiper {
  position: absolute;
  inset: 0;
}

.pc-hero__slide-item {
  width: 100%;
  height: 100%;
}

.pc-hero__slide {
  position: relative;
  width: 100%;
  height: 100%;
  overflow: hidden;
  isolation: isolate;
  color: #fff;
}

.pc-hero__copy {
  position: absolute;
  bottom: 30px;
  left: 246px;
  z-index: 3;
  max-width: 435px;
}

.pc-hero__title {
  display: block;
  margin: 0;
  font-size: $font-lgxx;
  font-weight: 700;
  letter-spacing: -0.04em;
  line-height: 1.18;
}

.pc-hero__title-row {
  display: flex;
  align-items: baseline;
  gap: 10px;
  margin-bottom: 9px;
  flex-wrap: wrap;
}

.pc-hero__meta {
  display: flex;
  align-items: center;
  gap: 7px;
  color: rgba(255, 255, 255, 0.7);
  font-size: $font-xs;
}

.pc-hero__tags {
  display: flex;
  align-items: center;
  gap: 5px;
}

.pc-hero__tag {
  display: inline-flex;
  height: 22px;
  align-items: center;
  padding: 0 8px;
  border: 1px solid rgba(255, 255, 255, 0.16);
  border-radius: 5px;
  color: rgba(255, 255, 255, 0.8);
  font-size: $font-xs;
  letter-spacing: 0.04em;
  background: rgba(255, 255, 255, 0.08);
}

.pc-hero__score {
  color: #fff;
  font-size: $font-xs;
  font-weight: 700;
  line-height: 1;
}

.pc-hero__desc {
  display: -webkit-box;
  overflow: hidden;
  max-width: 420px;
  margin-top: 13px;
  color: rgba(255, 255, 255, 0.72);
  font-size: $font-normal;
  line-height: 1.7;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.pc-hero__actions {
  display: flex;
  gap: 8px;
  margin-top: 16px;
}

.pc-hero__thumbs {
  position: absolute;
  right: 18px;
  bottom: 22px;
  z-index: 3;
  display: flex;
  gap: 7px;
}

.pc-hero__thumb {
  width: 48px;
  height: 64px;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 4px;
  cursor: pointer;
  opacity: 0.72;
  transition: opacity 0.18s ease, border-color 0.18s ease;
}

.pc-hero__thumb.is-active {
  border-color: #fff;
  box-shadow: 0 0 0 1px #fff;
  opacity: 1;
}

.pc-hero__thumb :deep(.psou-cover__glyph) {
  font-size: $font-lgx;
}

.pc-home__nav-placeholder {
  height: 76px;
}

.pc-home__body {
  padding: 14px 18px 0 236px;
}

.pc-home__section {
  margin-bottom: 14px;
}

.pc-section-head {
  display: flex;
  align-items: center;
  margin-bottom: 15px;
}

.m-home__hero {
  position: relative;
  width: 100%;
  height: 450rpx;
  overflow: hidden;
  isolation: isolate;
  color: #fff;
}

.m-home__nav-placeholder {
  flex: 0 0 auto;
}

.m-home__swiper {
  position: absolute;
  inset: 0;
}

.m-home__slide-item {
  width: 100%;
  height: 100%;
}

.m-home__slide {
  position: relative;
  width: 100%;
  height: 100%;
  overflow: hidden;
  isolation: isolate;
  color: #fff;
}

.m-home__copy {
  position: absolute;
  right: 18px;
  bottom: 18px;
  left: 18px;
  z-index: 3;
}

.m-home__title-row {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin: 0 0 6px;
  flex-wrap: wrap;
}

.m-home__title {
  display: block;
  margin: 0;
  font-size: $font-lgxx;
  font-weight: 700;
  letter-spacing: -0.03em;
  line-height: 1.24;
}

.m-home__meta {
  display: flex;
  align-items: center;
  gap: 8px;
  color: rgba(255, 255, 255, 0.68);
  font-size: $font-xs;
}

.m-home__score {
  color: #fff;
  font-size: $font-xs;
  font-weight: 700;
}

.m-home__tags {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 4px;
}

.m-home__tag {
  display: inline-flex;
  height: 19px;
  align-items: center;
  padding: 0 6px;
  border: 1px solid rgba(255, 255, 255, 0.16);
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.8);
  font-size: $font-xs;
  letter-spacing: 0.04em;
}

.m-home__desc {
  display: -webkit-box;
  overflow: hidden;
  max-width: 280px;
  margin-top: 7px;
  color: rgba(255, 255, 255, 0.66);
  font-size: $font-normal;
  line-height: 1.55;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.m-home__actions {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 12px;
}

.hero-action-text {
  color: #fff;
}

.m-home__dots {
  position: absolute;
  right: 18px;
  bottom: 18px;
  z-index: 4;
  display: flex;
  align-items: center;
  gap: 5px;
}

.m-home__dot {
  width: 5px;
  height: 5px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.36);
  transition: width 0.22s ease, background 0.22s ease;
}

.m-home__dot.is-active {
  width: 16px;
  background: #fff;
}

.m-home__body {
  padding: 16px 18px 22px;
}

.m-home__section {
  margin-bottom: 25px;
}

.m-home__section-head {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}
</style>
