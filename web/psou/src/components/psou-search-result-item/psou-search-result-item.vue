<script setup lang="ts">
import type { SearchResultItem } from '@/api/psou/type'
import { computed } from 'vue'
import { platformMap } from '@/api/psou/platform'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  resource: SearchResultItem
  detailed?: boolean
  extracting?: boolean
}>(), {
  detailed: false,
  extracting: false,
})

defineEmits<{
  extract: [resource: SearchResultItem]
}>()

interface PlatformDisplay {
  label: string
  glyph: string
  color: string
  icon?: string
}

const platform = computed<PlatformDisplay>(() => platformMap[props.resource.platform as keyof typeof platformMap] || {
  label: props.resource.platform || '未知平台',
  glyph: '链',
  color: '#68707f',
})

const sourceName = computed(() => {
  const source = props.resource.source?.trim() || ''
  const separatorIndex = source.indexOf(':')
  return separatorIndex > 0 ? source.slice(separatorIndex + 1) : source
})
</script>

<template>
  <view class="psou-result" :class="{ 'psou-result--detailed': detailed }">
    <view class="psou-result__top">
      <view class="psou-result__platform" :style="{ backgroundColor: platform.color }">
        <image
          v-if="platform.icon"
          class="psou-result__platform-icon"
          :src="platform.icon"
          mode="aspectFill"
        />
        <text v-else class="psou-result__platform-glyph">
          {{ platform.glyph }}
        </text>
      </view>
      <text class="psou-result__title">
        {{ resource.title }}
      </text>
      <view
        class="psou-result__action"
        :class="{ 'is-loading': extracting }"
        @click.stop="$emit('extract', resource)"
      >
        {{ extracting ? '提取中' : '提取' }}
      </view>
    </view>
    <view v-if="sourceName" class="psou-result__promo">
      <text class="psou-result__promo-text">
        数据来源于 {{ sourceName }}，本站只做聚合搜索，不存储任何资源内容。
      </text>
    </view>
  </view>
</template>

<style lang="scss" scoped>
.psou-result {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 14px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.055);
  box-shadow: 0 10px 36px rgba(0, 0, 0, 0.28), inset 0 1px 0 rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(22px) saturate(140%);
  transition: border-color 0.2s ease, background 0.2s ease, box-shadow 0.2s ease, transform 0.2s ease;
}

.psou-result--detailed {
  padding: 16px 18px;
}

.psou-result--detailed:hover {
  border-color: rgba(56, 214, 228, 0.35);
  background: rgba(255, 255, 255, 0.09);
  box-shadow: 0 14px 44px rgba(0, 86, 107, 0.24), inset 0 1px 0 rgba(255, 255, 255, 0.1);
  transform: translateY(-2px);
}

.psou-result__top {
  display: flex;
  min-width: 0;
  align-items: center;
  gap: 12px;
}

.psou-result__platform {
  display: flex;
  width: 40px;
  height: 40px;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  color: #fff;
  font-size: $font-sm;
  font-weight: 700;
}

.psou-result__platform-icon {
  display: block;
  width: 100%;
  height: 100%;
}

.psou-result__platform-glyph {
  color: #fff;
}

.psou-result__title {
  min-width: 0;
  flex: 1;
  color: var(--psou-text);
  font-size: $font-md;
  font-weight: 600;
  line-height: 1.4;
  overflow-wrap: anywhere;
  word-break: break-word;
}

.psou-result__action {
  display: inline-flex;
  height: 34px;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  padding: 0 14px;
  border-radius: 9px;
  color: #fff;
  font-size: $font-normal;
  font-weight: 500;
  background: linear-gradient(135deg, #22c7d8, #246bfd);
  box-shadow: 0 4px 14px rgba(36, 107, 253, 0.35);
  white-space: nowrap;
  transition: filter 0.18s ease, opacity 0.18s ease;
}

.psou-result--detailed .psou-result__action:hover {
  filter: brightness(1.12);
}

.psou-result__action.is-loading {
  opacity: 0.58;
  pointer-events: none;
}

.psou-result__promo {
  display: flex;
  align-items: flex-start;
  padding: 6px 10px;
  border: 1px solid rgba(251, 191, 36, 0.25);
  border-radius: 8px;
  color: #fcd34d;
  font-size: $font-normal;
  line-height: 1.55;
  background: rgba(251, 191, 36, 0.1);
}

.psou-result__promo-text {
  min-width: 0;
  flex: 1;
  overflow-wrap: anywhere;
  word-break: break-word;
}

@media (max-width: 767px) {
  .psou-result__title {
    font-size: $font-normal;
  }

  .psou-result__promo {
    padding: 5px 8px;
    font-size: $font-normal;
  }
}
</style>
