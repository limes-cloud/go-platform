<script setup lang="ts">
import { computed, getCurrentInstance, nextTick, onMounted, ref, watch } from 'vue'
import { FONT_SIZE_NORMAL } from '@/common/typography'
import PsouCategoryIcon from '@/components/psou-category-icon/psou-category-icon.vue'

interface FilterTab {
  key: string
  label: string
  icon?: string
  count?: string | number
}

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  modelValue: string
  items: FilterTab[]
  variant?: 'line' | 'pills' | 'button'
  size?: 'default' | 'compact'
  height?: string
  fontSize?: string
  iconSize?: string
  scroll?: boolean
}>(), {
  variant: 'line',
  size: 'default',
  height: '31px',
  fontSize: FONT_SIZE_NORMAL,
  iconSize: '14px',
  scroll: false,
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  'change': [value: string]
}>()

const instance = getCurrentInstance()
const scrollLeft = ref(0)

const currentIndex = computed(() => {
  const index = props.items.findIndex(item => item.key === props.modelValue)
  return index < 0 ? 0 : index
})

const tabList = computed(() => props.items.map(item => ({
  name: item.count === undefined ? item.label : `${item.label} ${item.count}`,
})))
const hasIcons = computed(() => props.items.some(item => Boolean(item.icon)))

function handleScroll(event: { detail: { scrollLeft: number } }) {
  scrollLeft.value = event.detail.scrollLeft
}

function centerActive() {
  if (props.variant !== 'line' || !hasIcons.value)
    return

  nextTick(() => {
    setTimeout(() => {
      const query = uni.createSelectorQuery().in(instance?.proxy)
      query.select('.psou-filter-tabs__line-scroll').boundingClientRect()
      query.selectAll('.psou-filter-tabs__line-item').boundingClientRect()
      query.exec((result: any[]) => {
        const container = result?.[0]
        const items = result?.[1]
        if (!container || !Array.isArray(items))
          return

        const active = items[currentIndex.value]
        if (!active)
          return

        const target = scrollLeft.value
          + (active.left - container.left)
          + active.width / 2
          - container.width / 2
        scrollLeft.value = Math.max(0, target)
      })
    }, 0)
  })
}

watch(() => props.modelValue, centerActive)
watch(() => props.items, centerActive, { deep: true })
onMounted(() => {
  setTimeout(centerActive, 80)
})

function selectAt(index: number) {
  const item = props.items[index]
  if (!item)
    return
  emit('update:modelValue', item.key)
  emit('change', item.key)
}
</script>

<template>
  <view class="psou-filter-tabs" :class="[`psou-filter-tabs--${variant}`, `psou-filter-tabs--${size}`]">
    <u-tabs
      v-if="variant === 'line' && !hasIcons"
      :list="tabList"
      :current="currentIndex"
      name="name"
      :is-scroll="scroll"
      :height="height"
      :font-size="fontSize"
      gutter="10px"
      bar-width="12px"
      bar-height="2px"
      bg-color="transparent"
      active-color="var(--psou-accent)"
      inactive-color="var(--psou-text-2)"
      @change="selectAt"
    />

    <scroll-view
      v-else-if="variant === 'line'"
      class="psou-filter-tabs__line-scroll"
      scroll-x
      scroll-with-animation
      :scroll-left="scrollLeft"
      :show-scrollbar="false"
      @scroll="handleScroll"
    >
      <view class="psou-filter-tabs__line">
        <view
          v-for="(item, index) in items"
          :key="item.key"
          class="psou-filter-tabs__line-item"
          :class="{ 'is-active': item.key === modelValue }"
          :style="{ height, fontSize }"
          @click="selectAt(index)"
        >
          <PsouCategoryIcon
            v-if="item.icon"
            :icon="item.icon"
            :size="iconSize"
            fallback="grid"
            :color="item.key === modelValue ? 'var(--psou-accent)' : 'var(--psou-text-3)'"
          />
          <view class="psou-filter-tabs__line-label">
            <text>{{ item.label }}</text>
            <view v-if="item.key === modelValue" class="psou-filter-tabs__line-bar" />
          </view>
          <text v-if="item.count !== undefined" class="psou-filter-tabs__line-count">
            {{ item.count }}
          </text>
        </view>
      </view>
    </scroll-view>

    <view v-else-if="variant === 'pills'" class="psou-filter-tabs__pills">
      <view
        v-for="(item, index) in items"
        :key="item.key"
        class="psou-filter-tabs__pill"
        :class="{ 'is-active': item.key === modelValue }"
        @click="selectAt(index)"
      >
        <text>{{ item.label }}</text>
        <text v-if="item.count !== undefined" class="psou-filter-tabs__count">
          {{ item.count }}
        </text>
      </view>
    </view>

    <u-subsection
      v-else
      :list="tabList"
      :current="currentIndex"
      mode="button"
      :height="height"
      :font-size="fontSize"
      active-color="var(--psou-accent)"
      inactive-color="var(--psou-text-2)"
      bg-color="var(--psou-surface)"
      button-color="var(--psou-active-bg)"
      @change="selectAt"
    />
  </view>
</template>

<style lang="scss" scoped>
.psou-filter-tabs {
  min-width: 0;
}

.psou-filter-tabs__line-scroll {
  display: block;
  width: 100%;
  max-width: 100%;
  white-space: nowrap;
}

.psou-filter-tabs__line {
  display: inline-flex;
  min-width: 100%;
  align-items: stretch;
  gap: 18px;
  padding: 0 2px;
}

.psou-filter-tabs__line-item {
  position: relative;
  display: inline-flex;
  flex: 0 0 auto;
  align-items: center;
  gap: 5px;
  padding: 0 2px;
  color: var(--psou-text-2);
  font-size: $font-normal;
  cursor: pointer;
}

.psou-filter-tabs__line-item.is-active {
  color: var(--psou-accent);
  font-weight: 500;
}

.psou-filter-tabs__line-label {
  position: relative;
  display: inline-flex;
  align-self: stretch;
  align-items: center;
}

.psou-filter-tabs__line-count {
  color: var(--psou-text-3);
  font-size: $font-xs;
  font-weight: 400;
}

.psou-filter-tabs__line-item.is-active .psou-filter-tabs__line-count {
  color: var(--psou-accent);
}

.psou-filter-tabs__line-bar {
  position: absolute;
  bottom: 1px;
  left: 0;
  width: 100%;
  height: 2px;
  border-radius: 2px;
  background: var(--psou-accent);
}

.psou-filter-tabs__pills {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.psou-filter-tabs__pill {
  display: inline-flex;
  height: 35px;
  align-items: center;
  gap: 7px;
  padding: 0 16px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 20px;
  color: var(--psou-text-2);
  font-size: $font-normal;
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(14px);
  cursor: pointer;
}

.psou-filter-tabs--compact .psou-filter-tabs__pill {
  height: 29px;
  padding: 0 11px;
  border-radius: 7px;
}

.psou-filter-tabs__pill.is-active {
  border-color: transparent;
  color: #fff;
  background: linear-gradient(135deg, #22c7d8, #246bfd);
  box-shadow: 0 4px 18px rgba(36, 107, 253, 0.4);
  font-weight: 500;
}

.psou-filter-tabs__count {
  display: inline-flex;
  min-width: 18px;
  height: 18px;
  align-items: center;
  justify-content: center;
  padding: 0 5px;
  border-radius: 9px;
  color: var(--psou-text-2);
  font-size: $font-xs;
  background: rgba(255, 255, 255, 0.1);
}

.psou-filter-tabs__pill.is-active .psou-filter-tabs__count {
  color: #fff;
  background: rgba(255, 255, 255, 0.25);
}
</style>
