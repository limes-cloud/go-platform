<script setup lang="ts">
import type { SearchResultItem } from '@/api/psou/type'
import PsouEmpty from '@/components/psou-empty/psou-empty.vue'
import PsouFilterTabs from '@/components/psou-filter-tabs/psou-filter-tabs.vue'
import PsouNotice from '@/components/psou-notice/psou-notice.vue'
import PsouSearchResultItem from '@/components/psou-search-result-item/psou-search-result-item.vue'

interface SearchTab {
  key: string
  label: string
  count?: string | number
}

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  keyword: string
  total: number
  items: SearchResultItem[]
  tabs: SearchTab[]
  modelValue: string
  searched?: boolean
  extractingToken?: string
  layout?: 'desktop' | 'mobile'
}>(), {
  searched: false,
  extractingToken: '',
  layout: 'mobile',
})

defineEmits<{
  'update:modelValue': [value: string]
  'extract': [resource: SearchResultItem]
}>()
</script>

<template>
  <view class="psou-search-results" :class="`psou-search-results--${layout}`">
    <view class="psou-search-results__meta">
      <text v-if="keyword.trim()" class="psou-search-results__keyword">
        {{ keyword }}
      </text>
      <text v-else>
        资源搜索
      </text>
      <text v-if="searched">
        共找到 <b>{{ total }}</b> 条资源
      </text>
      <text v-else>
        输入关键词开始搜索
      </text>
    </view>

    <view class="psou-search-results__notice">
      <PsouNotice>
        <template v-if="layout === 'desktop'">
          当前检索结果来源于网络公开分享，本站仅做聚合展示，<b class="psou-notice__strong">不存储任何资源内容</b>。链接有效性以分享方为准。
        </template>
        <template v-else>
          当前检索结果来源于网络公开分享，本站仅做聚合展示，不存储任何资源内容。
        </template>
      </PsouNotice>
    </view>

    <view v-if="searched" class="psou-search-results__tabs">
      <PsouFilterTabs
        :model-value="modelValue"
        :items="tabs"
        :variant="layout === 'desktop' ? 'pills' : 'line'"
        @update:model-value="$emit('update:modelValue', $event)"
      />
    </view>

    <view v-if="items.length" class="psou-search-results__list">
      <PsouSearchResultItem
        v-for="(resource, index) in items"
        :key="`${resource.token}-${index}`"
        :resource="resource"
        :detailed="layout === 'desktop'"
        :extracting="extractingToken === resource.token"
        @extract="$emit('extract', resource)"
      />
    </view>
    <PsouEmpty
      v-else
      mode="search"
      :text="searched ? '没有找到匹配的资源，换个关键词试试' : '输入关键词开始搜索'"
    />
  </view>
</template>

<style lang="scss" scoped>
.psou-search-results__meta {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px;
  color: var(--psou-text-2);
  font-size: $font-sm;
  line-height: 1.6;
}

.psou-search-results--mobile .psou-search-results__meta {
  padding: 16px 18px 8px;
}

.psou-search-results--mobile .psou-search-results__notice {
  padding: 0 18px;
}

.psou-search-results__keyword,
.psou-search-results__meta b {
  color: var(--psou-accent);
  font-weight: 600;
}

.psou-search-results__tabs {
  padding: 12px 0 16px;
}

.psou-search-results--mobile .psou-search-results__tabs {
  padding: 8px 18px 10px;
}

.psou-search-results__list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.psou-notice__strong {
  color: var(--psou-text);
  font-weight: 600;
}

.psou-search-results--mobile .psou-search-results__list {
  padding: 0 18px;
}

.psou-search-results--mobile :deep(.psou-empty) {
  padding-right: 18px;
  padding-left: 18px;
}
</style>
