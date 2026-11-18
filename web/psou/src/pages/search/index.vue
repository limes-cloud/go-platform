<script setup lang="ts">
import type { ResourcePlatform, SearchResultItem, TransferResourceReply } from '@/api/psou/type'
import { onLoad, onShow } from '@dcloudio/uni-app'
import { computed, ref, watch } from 'vue'
import { platformMap } from '@/api/psou/platform'
import { quickSearchResources, transferSearchResource } from '@/api/psou/service'
// #ifdef H5
import PsouDesktopShell from '@/components/psou-desktop-shell/psou-desktop-shell.vue'
import PsouEmpty from '@/components/psou-empty/psou-empty.vue'
import PsouLoading from '@/components/psou-loading/psou-loading.vue'
// #endif
import PsouMobileBackNav from '@/components/psou-mobile-back-nav/psou-mobile-back-nav.vue'
import PsouSearchField from '@/components/psou-search-field/psou-search-field.vue'
import PsouSearchResults from '@/components/psou-search-results/psou-search-results.vue'
import PsouTransferDialog from '@/components/psou-transfer-dialog/psou-transfer-dialog.vue'
import { useResponsive } from '@/composables/useResponsive'
import { goBackOrRoute, PSOU_ROUTES } from '@/library/navigation'
import { trackEvent, trackPageView } from '@/library/tracker'
import { useCatalogStore } from '@/stores/catalog'

definePage({
  style: {
    navigationBarTitleText: '搜索',
  },
})

const catalog = useCatalogStore()
const { isDesktop } = useResponsive()

const keyword = ref(catalog.searchKeyword)
const activePlatform = ref<ResourcePlatform | 'all'>('all')
const allResults = ref<SearchResultItem[]>([])
const loading = ref(false)
const error = ref('')
const searched = ref(false)
const extractingToken = ref('')
const transferVisible = ref(false)
const transferResource = ref<SearchResultItem | null>(null)
const transferState = ref<'loading' | 'success' | 'error'>('loading')
const transferResult = ref<TransferResourceReply | null>(null)
const transferError = ref('')
let requestId = 0
let transferRequestId = 0
let lastSubmit = { keyword: '', at: 0 }

const results = computed(() => {
  if (activePlatform.value === 'all')
    return allResults.value
  return allResults.value.filter(item => item.platform === activePlatform.value)
})
const tabs = computed(() => {
  const platformCounts = (['quark', 'baidu'] as ResourcePlatform[]).map(platform => ({
    key: platform,
    label: platformMap[platform].label,
    count: allResults.value.filter(item => item.platform === platform).length,
  }))
  return [
    { key: 'all' as const, label: '全部', count: allResults.value.length },
    ...platformCounts,
  ]
})

async function loadSearch(value = keyword.value) {
  const currentRequest = ++requestId
  const nextKeyword = value.trim()
  closeTransfer()
  keyword.value = nextKeyword
  error.value = ''
  activePlatform.value = 'all'
  extractingToken.value = ''

  if (!nextKeyword) {
    allResults.value = []
    loading.value = false
    searched.value = false
    return
  }

  const now = Date.now()
  if (lastSubmit.keyword !== nextKeyword || now - lastSubmit.at > 800) {
    lastSubmit = { keyword: nextKeyword, at: now }
    trackEvent('search_submit', { keywordLength: nextKeyword.length }, 'search')
  }
  const startedAt = Date.now()
  loading.value = true
  searched.value = true

  try {
    const data = await quickSearchResources(nextKeyword)
    if (currentRequest !== requestId)
      return
    allResults.value = Array.isArray(data.list) ? data.list : []
    trackEvent('search_result_loaded', {
      resultCount: allResults.value.length,
      quarkCount: allResults.value.filter(item => item.platform === 'quark').length,
      baiduCount: allResults.value.filter(item => item.platform === 'baidu').length,
      durationMs: Date.now() - startedAt,
    }, 'search')
  }
  catch (requestError) {
    if (currentRequest !== requestId)
      return
    error.value = requestError instanceof Error ? requestError.message : '搜索失败'
    allResults.value = []
  }
  finally {
    if (currentRequest === requestId)
      loading.value = false
  }
}

onLoad(() => {
  const initialKeyword = catalog.searchKeyword.trim()
  keyword.value = initialKeyword
  if (initialKeyword)
    void loadSearch(initialKeyword)
})
onShow(() => trackPageView('search'))
watch(() => catalog.searchKeyword, (value) => {
  if (value !== keyword.value)
    void loadSearch(value)
})

function submitSearch(value: string) {
  const next = value.trim()
  keyword.value = next
  if (next !== catalog.searchKeyword)
    catalog.setSearchKeyword(next)
  void loadSearch(next)
}

function submitCurrentKeyword() {
  submitSearch(keyword.value)
}

function selectPlatform(value: string) {
  activePlatform.value = value as ResourcePlatform | 'all'
}

async function extractResource(resource: SearchResultItem, recordClick = true) {
  if (!resource.token || extractingToken.value)
    return

  if (recordClick) {
    trackEvent('search_result_extract_click', {
      platform: resource.platform,
      resultCount: allResults.value.length,
    }, 'search')
  }
  const currentTransfer = ++transferRequestId
  transferResource.value = resource
  transferState.value = 'loading'
  transferResult.value = null
  transferError.value = ''
  transferVisible.value = true
  extractingToken.value = resource.token

  try {
    const result = await transferSearchResource(resource.token)
    if (currentTransfer !== transferRequestId)
      return
    transferResult.value = result
    transferState.value = 'success'
  }
  catch (error) {
    if (currentTransfer !== transferRequestId)
      return
    transferState.value = 'error'
    const reason = (error as Error & { reason?: string })?.reason
    if (reason === 'SearchLinkInvalidError')
      transferError.value = '转存凭证已失效，请重新搜索该资源'
    else if (reason === 'TOO_MANY_REQUESTS')
      transferError.value = '请求过于频繁，请稍后再试'
    else if (reason === 'SearchShareExpiredError')
      transferError.value = '该分享已被取消或失效，请切换其他资源试试'
    else
      transferError.value = '系统抽了一下，重试看看～'
  }
  finally {
    if (currentTransfer === transferRequestId)
      extractingToken.value = ''
  }
}

function closeTransfer() {
  transferRequestId += 1
  transferVisible.value = false
  extractingToken.value = ''
}

function retryTransfer() {
  const resource = transferResource.value
  if (resource)
    void extractResource(resource, false)
}

function goBack() {
  goBackOrRoute(PSOU_ROUTES.home)
}
</script>

<template>
  <!-- #ifdef H5 -->
  <PsouDesktopShell
    v-if="isDesktop"
    sidebar="none"
    back
    :search-keyword="catalog.searchKeyword"
    @back="goBack"
    @search="submitSearch"
  >
    <PsouLoading v-if="loading" variant="search" text="盘搜 搜索中..." />
    <PsouEmpty v-else-if="error" mode="data" :text="error" />
    <view v-else class="pc-search-page">
      <PsouSearchResults
        :keyword="keyword"
        :total="allResults.length"
        :items="results"
        :tabs="tabs"
        :model-value="activePlatform"
        :searched="searched"
        :extracting-token="extractingToken"
        layout="desktop"
        @update:model-value="selectPlatform"
        @extract="extractResource"
      />

      <view class="pc-search-foot">
        PSOU RESOURCE SEARCH · 实时聚合检索
      </view>
    </view>
  </PsouDesktopShell>
  <!-- #endif -->

  <view v-if="!isDesktop" class="psou-mobile-page">
    <PsouMobileBackNav variant="solid" @back="goBack">
      <view class="m-search-nav">
        <view class="m-search-nav__field">
          <PsouSearchField v-model="keyword" size="compact" @search="submitSearch" />
        </view>
        <view
          class="m-search-nav__submit"
          :class="{ 'is-disabled': !keyword.trim() }"
          role="button"
          aria-label="搜索"
          @click="submitCurrentKeyword"
        >
          <u-icon name="search" color="#ffffff" size="18px" />
        </view>
      </view>
    </PsouMobileBackNav>
    <view class="m-search-page">
      <PsouLoading v-if="loading" variant="search" text="盘搜 搜索中..." />
      <PsouEmpty v-else-if="error" mode="data" :text="error" />
      <PsouSearchResults
        v-else
        :keyword="keyword"
        :total="allResults.length"
        :items="results"
        :tabs="tabs"
        :model-value="activePlatform"
        :searched="searched"
        :extracting-token="extractingToken"
        layout="mobile"
        @update:model-value="selectPlatform"
        @extract="extractResource"
      />
    </view>
  </view>

  <PsouTransferDialog
    :visible="transferVisible"
    :resource="transferResource"
    :state="transferState"
    :result="transferResult"
    :error-message="transferError"
    :is-desktop="isDesktop"
    @close="closeTransfer"
    @retry="retryTransfer"
  />
</template>

<style lang="scss" scoped>
.pc-search-page {
  width: min(860px, 100%);
  margin: 0 auto;
  padding-top: 6px;
}

.pc-search-foot {
  padding: 30px 0 10px;
  color: var(--psou-text-3);
  font-family: 'SFMono-Regular', Consolas, monospace;
  font-size: $font-xs;
  letter-spacing: 0.1em;
  text-align: center;
}

.m-search-page {
  padding: 0 0 24px;
}

.m-search-nav {
  display: flex;
  width: 100%;
  min-width: 0;
  align-items: center;
  gap: 8px;
  padding-right: 14px;
}

.m-search-nav__field {
  min-width: 0;
  flex: 1;
}

.m-search-nav__submit {
  display: flex;
  width: 36px;
  height: 36px;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  background: #4562ff;
}

.m-search-nav__submit.is-disabled {
  opacity: 0.45;
  pointer-events: none;
}
</style>
