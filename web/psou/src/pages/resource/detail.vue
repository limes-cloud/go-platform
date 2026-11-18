<script setup lang="ts">
import type { CoverTone, ResourceDetailReply, ResourcePlatform } from '@/api/psou/type'
import { onLoad, onPageScroll, onShow } from '@dcloudio/uni-app'
import { computed, ref } from 'vue'
import { platformMap } from '@/api/psou/platform'
import { fetchResourceDetail, fetchResourceURL, incrementResourceClick } from '@/api/psou/service'
// #ifdef H5
import PsouDesktopShell from '@/components/psou-desktop-shell/psou-desktop-shell.vue'
// #endif
import PsouDisclaimer from '@/components/psou-disclaimer/psou-disclaimer.vue'
import PsouEmpty from '@/components/psou-empty/psou-empty.vue'
import PsouFileList from '@/components/psou-file-list/psou-file-list.vue'
import PsouFilterTabs from '@/components/psou-filter-tabs/psou-filter-tabs.vue'
import PsouInfoList from '@/components/psou-info-list/psou-info-list.vue'
import PsouLoading from '@/components/psou-loading/psou-loading.vue'
import PsouMobileBackNav from '@/components/psou-mobile-back-nav/psou-mobile-back-nav.vue'
import PsouSectionHeading from '@/components/psou-section-heading/psou-section-heading.vue'
import PsouToneHero from '@/components/psou-tone-hero/psou-tone-hero.vue'
import { useResponsive } from '@/composables/useResponsive'
import { formatUnixDate } from '@/library/format'
import { copy } from '@/library/global/copy'
import { openHomePage, openSearchPage } from '@/library/navigation'
import { trackEvent, trackPageView } from '@/library/tracker'
import { useCatalogStore } from '@/stores/catalog'

definePage({
  style: {
    navigationBarTitleText: '资源详情',
  },
})

const catalog = useCatalogStore()
const { isDesktop, isH5 } = useResponsive()
const coverTones: CoverTone[] = ['blue', 'teal', 'gold', 'rose', 'violet', 'indigo']

const resource = ref<ResourceDetailReply>()
const selectedPlatform = ref('')
const loading = ref(true)
const error = ref('')
const scrollTop = ref(0)
const qrVisible = ref(false)
const qrCodeUrl = ref('')
const qrLoading = ref(false)
const downloadLoading = ref(false)
const catalogId = ref<number>()

const availableNetdisks = computed(() => {
  const seen = new Set<string>()
  return (resource.value?.netdisks ?? []).filter((item) => {
    if (seen.has(item.platform))
      return false
    seen.add(item.platform)
    return true
  })
})
const platformCountText = computed(() => availableNetdisks.value.length
  ? `${availableNetdisks.value.length} 个平台`
  : '')
const selectedNetdisk = computed(() => {
  const list = resource.value?.netdisks ?? []
  return list.find(item => item.platform === selectedPlatform.value) ?? list[0]
})
const platformFilters = computed(() => availableNetdisks.value.map(item => ({
  key: item.platform,
  label: `${platformLabel(item.platform)}网盘`,
})))
const platform = computed(() => platformMeta(selectedNetdisk.value?.platform))
const selectedFiles = computed(() => selectedNetdisk.value?.files ?? [])
const selectedFileCount = computed(() => selectedNetdisk.value?.fileCount ?? selectedFiles.value.length)
const selectedSize = computed(() => selectedNetdisk.value?.size || '--')
const selectedFormat = computed(() => selectedNetdisk.value?.formatSummary || '未知')
const updateText = computed(() => formatUnixDate(resource.value?.updatedAt))
const scoreText = computed(() => {
  const score = resource.value?.score
  return score === null || score === undefined ? '' : Number(score).toFixed(1)
})
const tags = computed(() => resource.value?.tags ?? [])
const descriptionText = computed(() => resource.value?.description || resource.value?.summary || '暂无简介')
const coverTone = computed<CoverTone>(() => coverTones[(resource.value?.id ?? 0) % coverTones.length])
const glyph = computed(() => Array.from(resource.value?.title || '资')[0])
const hasNetdisk = computed(() => Boolean(selectedNetdisk.value))
const facts = computed(() => resource.value
  ? [
      { label: '大小', value: selectedSize.value },
      { label: '文件', value: `${selectedFileCount.value} 个` },
      { label: '格式', value: selectedFormat.value },
    ]
  : [])
const resourceInfo = computed(() => resource.value
  ? [
      { label: '大小', value: selectedSize.value },
      { label: '格式', value: selectedFormat.value },
      { label: '文件', value: `${selectedFileCount.value} 个` },
      { label: '网盘平台', value: platform.value.label },
      { label: '更新时间', value: updateText.value || '--' },
    ]
  : [])

onLoad(async (query) => {
  const targetCatalogId = Number(query?.catalogId)
  if (Number.isInteger(targetCatalogId) && targetCatalogId > 0)
    catalogId.value = targetCatalogId

  loading.value = true
  error.value = ''
  try {
    if (!query?.resourceId)
      throw new Error('缺少资源 ID')

    resource.value = await fetchResourceDetail(query.resourceId)
    selectedPlatform.value = resource.value.netdisks[0]?.platform || ''
  }
  catch (requestError) {
    error.value = requestError instanceof Error ? requestError.message : '资源加载失败'
  }
  finally {
    loading.value = false
  }
})
onShow(() => trackPageView('resource_detail'))

onPageScroll(({ scrollTop: value }) => {
  scrollTop.value = value
})

async function trackResourceClick() {
  const id = Number(resource.value?.id)
  if (!id)
    return
  try {
    await incrementResourceClick(id)
  }
  catch {
    // 点击统计失败不阻断用户打开资源
  }
}

async function fetchSelectedResourceURL(): Promise<string> {
  const netdisk = selectedNetdisk.value
  const resourceId = Number(resource.value?.id)
  if (!netdisk || !resourceId) {
    uni.$g.utoast.show({ title: '暂无可用网盘副本', type: 'none' })
    return ''
  }
  if (downloadLoading.value)
    return ''

  downloadLoading.value = true
  try {
    const reply = await fetchResourceURL(resourceId, netdisk.id)
    if (!reply?.url) {
      uni.$g.utoast.show({ title: '资源地址不存在', type: 'none' })
      return ''
    }
    return reply.url
  }
  catch {
    return ''
  }
  finally {
    downloadLoading.value = false
  }
}

async function openResource() {
  const netdisk = selectedNetdisk.value
  if (!netdisk) {
    uni.$g.utoast.show({ title: '暂无可用网盘副本', type: 'none' })
    return
  }
  const shareUrl = await fetchSelectedResourceURL()
  if (!shareUrl)
    return

  trackEvent('resource_netdisk_open', {
    resourceId: resource.value?.id,
    platform: netdisk.platform,
  }, 'resource_detail')
  // #ifdef H5
  void trackResourceClick()
  const link = document.createElement('a')
  link.href = shareUrl
  link.target = '_self'
  link.rel = 'noopener noreferrer'
  link.referrerPolicy = 'no-referrer'
  document.body.appendChild(link)
  link.click()
  link.remove()
  // #endif

  // #ifndef H5
  await trackResourceClick()
  copy(shareUrl)
  uni.$g.utoast.show({ title: '链接已复制，请到浏览器打开', type: 'none', duration: 2500 })
  // #endif
}

function selectPlatform(value: string) {
  selectedPlatform.value = value
  qrVisible.value = false
}

async function openQrCode() {
  const netdisk = selectedNetdisk.value
  if (!netdisk) {
    uni.$g.utoast.show({ title: '暂无可用网盘副本', type: 'none' })
    return
  }
  const shareUrl = await fetchSelectedResourceURL()
  if (!shareUrl)
    return

  trackEvent('resource_qrcode_open', {
    resourceId: resource.value?.id,
    platform: netdisk.platform,
  }, 'resource_detail')
  await trackResourceClick()

  qrVisible.value = true
  qrCodeUrl.value = ''
  qrLoading.value = true
  try {
    // #ifdef H5
    const { toDataURL } = await import('qrcode')
    qrCodeUrl.value = await toDataURL(shareUrl, {
      width: 220,
      margin: 1,
      errorCorrectionLevel: 'M',
      color: { dark: '#05070f', light: '#ffffff' },
    })
    // #endif
  }
  catch {
    qrVisible.value = false
    uni.$g.utoast.show({ title: '二维码生成失败', type: 'none' })
  }
  finally {
    qrLoading.value = false
  }
}

function platformMeta(value?: string) {
  if (!value)
    return { label: '网盘', glyph: '盘' }
  return platformMap[value as ResourcePlatform] ?? { label: value, glyph: '盘' }
}

function platformLabel(value: string) {
  return platformMeta(value).label
}

function goBack() {
  if (getCurrentPages().length > 1) {
    uni.navigateBack()
    return
  }
  openHomePage(catalogId.value)
}

function goHome() {
  openHomePage(catalogId.value)
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
    sidebar="none"
    overlay
    flush
    :topbar-fade-start="24"
    :search-keyword="catalog.searchKeyword"
    @home="goHome"
    @search="submitSearch"
  >
    <PsouLoading v-if="loading" />
    <PsouEmpty v-else-if="error" mode="data" :text="error" />
    <view v-else-if="resource" class="pc-detail">
      <view class="pc-detail__hero">
        <PsouToneHero
          :cover="resource.cover"
          :tone="coverTone"
          :glyph="glyph"
          variant="desktop"
          height="390px"
        >
          <view class="pc-detail__hero-copy">
            <view class="pc-detail__title-row">
              <text class="pc-detail__title">
                {{ resource.title }}
              </text>
              <text v-if="scoreText" class="pc-detail__score">
                {{ scoreText }}
              </text>
            </view>
            <view v-if="tags.length" class="pc-detail__tags">
              <text v-for="tag in tags" :key="tag" class="pc-detail__tag">
                {{ tag }}
              </text>
            </view>
            <text v-if="resource.summary" class="pc-detail__summary">
              {{ resource.summary }}
            </text>
          </view>
        </PsouToneHero>
      </view>

      <view class="pc-detail__layout">
        <view class="pc-detail__main">
          <view class="pc-detail__netdisk">
            <view class="pc-detail__section">
              <PsouSectionHeading
                title="网盘资源"
                icon="/static/icons/cloud.png"
                variant="icon"
              />
            </view>
            <view v-if="platformFilters.length > 1" class="pc-detail__source-filters">
              <PsouFilterTabs
                :model-value="selectedPlatform"
                :items="platformFilters"
                variant="pills"
                size="compact"
                @update:model-value="selectPlatform"
              />
            </view>

            <aside class="pc-detail__rail">
              <PsouInfoList :items="resourceInfo" />
              <view class="pc-detail__download-row">
                <text>下载地址</text>
                <view
                  class="pc-detail__resource-link"
                  :class="{ 'is-disabled': !hasNetdisk || downloadLoading }"
                  @click="openQrCode"
                >
                  <u-icon name="download" size="13px" color="var(--psou-accent)" />
                  <text>{{ downloadLoading ? '获取中...' : '资源获取' }}</text>
                </view>
              </view>
            </aside>

            <view v-if="hasNetdisk" class="pc-detail__file-head">
              <PsouSectionHeading
                title="文件清单"
                icon="list-dot"
                variant="icon"
                :note="`${selectedFileCount} 个文件`"
              />
            </view>
            <PsouFileList
              v-if="selectedFiles.length"
              :files="selectedFiles"
              show-type
              max-height="220px"
            />
            <PsouEmpty v-else-if="hasNetdisk" mode="list" text="暂无文件清单" />
            <PsouEmpty v-else mode="data" text="暂无可用网盘副本" />
          </view>

          <view class="pc-detail__section-space">
            <PsouSectionHeading title="资源简介" icon="file-text" variant="icon" />
          </view>
          <text class="pc-detail__desc">
            {{ descriptionText }}
          </text>

          <view class="pc-detail__disclaimer">
            <PsouDisclaimer />
          </view>
        </view>
      </view>
    </view>
  </PsouDesktopShell>

  <u-popup
    v-model="qrVisible"
    mode="center"
    :border-radius="16"
    :z-index="10000"
    @close="qrVisible = false"
  >
    <view class="pc-qr-popup">
      <view class="pc-qr-popup__close" @click="qrVisible = false">
        <u-icon name="close" size="14px" color="#ffffff" />
      </view>
      <text class="pc-qr-popup__title">
        获取资源
      </text>
      <text class="pc-qr-popup__subtitle">
        {{ resource?.title }} · {{ platform.label }}网盘
      </text>
      <view class="pc-qr-popup__code">
        <image v-if="qrCodeUrl" class="pc-qr-popup__image" :src="qrCodeUrl" mode="aspectFit" />
        <PsouLoading v-else-if="qrLoading" compact text="生成二维码..." />
      </view>
      <text class="pc-qr-popup__hint">
        使用手机网盘扫码打开
      </text>
    </view>
  </u-popup>
  <!-- #endif -->

  <view v-if="!isDesktop" class="psou-mobile-page">
    <!-- #ifdef H5 -->
    <PsouMobileBackNav
      fixed-on-h5
      :title="resource?.title || '资源详情'"
      :scroll-top="scrollTop"
      @back="goBack"
    />
    <!-- #endif -->
    <PsouLoading v-if="loading" />
    <PsouEmpty v-else-if="error" mode="data" :text="error" />
    <view v-else-if="resource" class="m-detail">
      <view class="m-detail__hero">
        <PsouToneHero
          :cover="resource.cover"
          :tone="coverTone"
          :glyph="glyph"
          height="252px"
        >
          <!-- #ifndef H5 -->
          <PsouMobileBackNav
            :title="resource.title || '资源详情'"
            @back="goBack"
          />
          <!-- #endif -->
          <view class="m-detail__hero-copy">
            <view class="m-detail__title-row">
              <text class="m-detail__title">
                {{ resource.title }}
              </text>
              <text v-if="scoreText" class="m-detail__score">
                {{ scoreText }}
              </text>
            </view>
            <view v-if="tags.length" class="m-detail__tags">
              <text v-for="tag in tags" :key="tag" class="m-detail__tag">
                {{ tag }}
              </text>
            </view>
            <text v-if="resource.summary" class="m-detail__summary">
              {{ resource.summary }}
            </text>
          </view>
        </PsouToneHero>
      </view>

      <view class="m-detail__body">
        <view class="m-detail__section">
          <PsouSectionHeading
            title="网盘资源"
            icon="/static/icons/cloud.png"
            :note="platformCountText"
          />
        </view>
        <view v-if="platformFilters.length > 1" class="m-detail__sources">
          <PsouFilterTabs
            :model-value="selectedPlatform"
            :items="platformFilters"
            variant="button"
            height="29px"
            @update:model-value="selectPlatform"
          />
        </view>
        <view class="m-detail__facts">
          <PsouInfoList :items="facts" layout="facts" />
        </view>
        <view v-if="hasNetdisk" class="m-detail__file-head">
          <PsouSectionHeading
            title="文件清单"
            icon="list-dot"
            variant="icon"
            :note="`${selectedFileCount} 个文件`"
          />
        </view>
        <PsouFileList
          v-if="selectedFiles.length"
          :files="selectedFiles"
          icon-size="16px"
          :max-height="isH5 ? '150px' : '80px'"
        />
        <PsouEmpty v-else-if="hasNetdisk" mode="list" text="暂无文件清单" />
        <PsouEmpty v-else mode="data" text="暂无可用网盘副本" />

        <view class="m-detail__section">
          <PsouSectionHeading title="资源简介" icon="file-text" variant="icon" />
        </view>
        <text class="m-detail__desc">
          {{ descriptionText }}
        </text>

        <view class="m-detail__disclaimer">
          <PsouDisclaimer />
        </view>
      </view>
    </view>

    <view v-if="resource" class="m-detail__bar">
      <u-button
        type="primary"
        :text="downloadLoading ? '获取中...' : '获取资源'"
        :disabled="!hasNetdisk || downloadLoading"
        :loading="downloadLoading"
        :hair-line="false"
        :custom-style="{
          flex: '1',
          borderColor: 'var(--psou-accent)',
          borderRadius: '10px',
          color: '#ffffff',
          fontWeight: 600,
          background: 'var(--psou-accent)',
        }"
        @click="openResource"
      />
    </view>
  </view>
</template>

<style lang="scss" scoped>
.pc-detail {
  min-height: 100vh;
  background: var(--psou-bg);
}

.pc-detail__hero {
  position: relative;
  height: 390px;
  overflow: hidden;
  isolation: isolate;
  color: #fff;
}

.pc-detail__hero-copy {
  position: absolute;
  bottom: 42px;
  left: 54px;
  z-index: 3;
  max-width: 760px;
}

.pc-detail__title-row {
  display: flex;
  align-items: baseline;
  gap: 8px;
  flex-wrap: wrap;
}

.pc-detail__title {
  display: block;
  font-size: $font-lgxx;
  font-weight: 700;
  letter-spacing: -0.04em;
  line-height: 1.18;
}

.pc-detail__score {
  flex: 0 0 auto;
  color: #fff;
  font-size: $font-xs;
  font-weight: 700;
}

.pc-detail__summary {
  display: -webkit-box;
  overflow: hidden;
  margin-top: 9px;
  color: rgba(255, 255, 255, 0.72);
  font-size: $font-normal;
  line-height: 1.65;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.pc-detail__layout {
  padding: 24px 54px 48px;
}

.pc-detail__main {
  min-width: 0;
}

.pc-detail__netdisk {
  min-width: 0;
}

.pc-detail__section-space {
  display: flex;
  margin-top: 24px;
  margin-bottom: 20px;
}

.pc-detail__section {
  margin-bottom: 20px;
}

.pc-detail__desc {
  display: block;
  color: var(--psou-text-2);
  font-size: $font-normal;
  line-height: 1.9;
}

.pc-detail__tags {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-top: 10px;
}

.pc-detail__tag {
  padding: 3px 8px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 5px;
  color: rgba(255, 255, 255, 0.76);
  font-size: $font-xs;
  background: rgba(255, 255, 255, 0.08);
}

.pc-detail__file-head {
  margin: 18px 0 20px;
}

.pc-detail__source-filters {
  margin-bottom: 13px;
}

.pc-detail__rail {
  margin: 14px 0 16px;
}

.pc-detail__download-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 5px 0;
  font-size: $font-normal;
}

.pc-detail__download-row > text {
  color: var(--psou-text-3);
}

.pc-detail__resource-link {
  display: flex;
  align-items: center;
  gap: 5px;
  color: var(--psou-accent);
  font-size: $font-normal;
  font-weight: 500;
  cursor: pointer;
}

.pc-detail__resource-link:hover {
  color: #72e9f2;
}

.pc-detail__resource-link.is-disabled {
  opacity: 0.45;
  pointer-events: none;
}

.pc-detail__disclaimer {
  margin-top: 22px;
}

.pc-qr-popup {
  position: relative;
  display: flex;
  width: 292px;
  align-items: center;
  flex-direction: column;
  padding: 26px 24px 22px;
  background: var(--psou-bg-soft);
}

.pc-qr-popup__close {
  position: absolute;
  top: 10px;
  right: 10px;
  z-index: 2;
  display: flex;
  width: 28px;
  height: 28px;
  align-items: center;
  justify-content: center;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.06);
  cursor: pointer;
}

.pc-qr-popup__close:hover {
  background: rgba(255, 255, 255, 0.12);
}

.pc-qr-popup__title {
  color: var(--psou-text);
  font-size: $font-lgx;
  font-weight: 600;
}

.pc-qr-popup__subtitle {
  max-width: 100%;
  overflow: hidden;
  margin-top: 6px;
  color: var(--psou-text-3);
  font-size: $font-xs;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.pc-qr-popup__code {
  display: flex;
  width: 236px;
  height: 236px;
  align-items: center;
  justify-content: center;
  margin-top: 18px;
  border-radius: 10px;
  background: #fff;
}

.pc-qr-popup__image {
  width: 220px;
  height: 220px;
}

.pc-qr-popup__hint {
  margin-top: 14px;
  color: var(--psou-text-3);
  font-size: $font-xs;
}

.m-detail {
  padding-bottom: calc(78px + env(safe-area-inset-bottom));
}

.m-detail__hero {
  position: relative;
  height: 252px;
  overflow: hidden;
  isolation: isolate;
  color: #fff;
}

.m-detail__hero-copy {
  position: absolute;
  right: 18px;
  bottom: 20px;
  left: 18px;
  z-index: 3;
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.m-detail__title-row {
  display: flex;
  align-items: baseline;
  gap: 8px;
  flex-wrap: wrap;
}

.m-detail__title {
  display: -webkit-box;
  overflow: hidden;
  min-width: 0;
  font-size: $font-lgxx;
  font-weight: 700;
  letter-spacing: -0.03em;
  line-height: 1.28;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.m-detail__score {
  flex: 0 0 auto;
  color: #fff;
  font-size: $font-xs;
  font-weight: 700;
}

.m-detail__body {
  padding: 16px 18px 24px;
}

.m-detail__section {
  margin: 25px 0 14px;
}

.m-detail__desc {
  display: block;
  color: var(--psou-text-2);
  font-size: $font-normal;
  line-height: 1.8;
}

.m-detail__tags {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-top: 8px;
}

.m-detail__tag {
  padding: 3px 8px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 5px;
  color: rgba(255, 255, 255, 0.76);
  font-size: $font-xs;
  background: rgba(255, 255, 255, 0.08);
}

.m-detail__summary {
  display: -webkit-box;
  overflow: hidden;
  margin-top: 8px;
  color: rgba(255, 255, 255, 0.7);
  font-size: $font-normal;
  line-height: 1.55;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.m-detail__sources {
  margin-bottom: 14px;
}

.m-detail__facts {
  margin: 2px 0 10px;
}

.m-detail__file-head {
  margin: 25px 0 14px;
}

.m-detail__disclaimer {
  margin-top: 22px;
}

.m-detail__bar {
  position: fixed;
  right: 0;
  bottom: 0;
  left: 0;
  z-index: 60;
  display: flex;
  width: 100%;
  height: calc(64px + env(safe-area-inset-bottom));
  align-items: center;
  gap: 8px;
  padding: 8px 14px env(safe-area-inset-bottom);
  border-top: 1px solid var(--psou-border);
  background: var(--psou-tabbar-bg);
  backdrop-filter: saturate(180%) blur(20px);
}
</style>
