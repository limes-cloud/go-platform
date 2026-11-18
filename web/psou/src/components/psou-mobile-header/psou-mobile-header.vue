<script setup lang="ts">
import { computed, ref } from 'vue'
import { FONT_SIZE_NORMAL } from '@/common/typography'
import PsouBrand from '@/components/psou-brand/psou-brand.vue'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  modelValue?: string
  readonly?: boolean
  tone?: 'default' | 'hero'
  fixed?: boolean
  immersive?: boolean
  fadeStart?: number
  fadeDistance?: number
  back?: boolean
}>(), {
  modelValue: '',
  readonly: false,
  tone: 'default',
  fixed: true,
  immersive: false,
  fadeStart: 0,
  fadeDistance: 160,
  back: false,
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  'search': [value: string]
  'open': []
  'home': []
  'back': []
}>()

const scrollTop = ref(0)
const scrollProgress = computed(() => {
  const progress = (scrollTop.value - props.fadeStart) / Math.max(1, props.fadeDistance)
  return Math.min(1, Math.max(0, progress))
})
const navbarBackground = computed(() => `rgba(8, 11, 24, ${scrollProgress.value.toFixed(3)})`)
const navbarShadow = computed(() => `0 10px 30px rgba(0, 0, 0, ${(scrollProgress.value * 0.14).toFixed(3)})`)
const navbarStyle = computed(() => ({
  backgroundColor: navbarBackground.value,
  boxShadow: navbarShadow.value,
  transition: 'background-color 0.1s linear, box-shadow 0.1s linear',
}))
const searchValue = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
})
const searchColors = {
  bg: 'var(--psou-search-bg)',
  border: 'var(--psou-search-border)',
  text: '#ffffff',
  placeholder: 'rgba(255, 255, 255, 0.8)',
}

function handleSearch(value: string) {
  if (!props.readonly)
    emit('search', value)
}

function handleClick() {
  if (props.readonly)
    emit('open')
}

function setScrollTop(value: number) {
  scrollTop.value = Math.max(0, value)
}

defineExpose({ setScrollTop })
</script>

<template>
  <view class="psou-mobile-header" :class="`psou-mobile-header--${tone}`">
    <u-navbar
      :is-back="false"
      :is-fixed="fixed"
      :immersive="immersive"
      :border-bottom="false"
      :background="navbarStyle"
    >
      <view class="psou-mobile-header__inner">
        <view
          v-if="back"
          class="psou-mobile-header__back"
          @click="emit('back')"
        >
          <u-icon name="arrow-left" size="18px" color="#ffffff" />
        </view>
        <PsouBrand v-else icon-only @click="emit('home')" />
        <view class="psou-mobile-header__search">
          <u-search
            v-model="searchValue"
            shape="square"
            height="36px"
            :show-action="false"
            :disabled="readonly"
            :clearabled="!readonly"
            placeholder="搜索影视、音乐、游戏、软件…"
            :bg-color="searchColors.bg"
            :border-color="searchColors.border"
            :color="searchColors.text"
            :placeholder-color="searchColors.placeholder"
            search-icon-color="var(--psou-accent)"
            :input-style="{ fontSize: FONT_SIZE_NORMAL, backgroundColor: 'transparent' }"
            @click="handleClick"
            @search="handleSearch"
          />
        </view>
      </view>
    </u-navbar>
  </view>
</template>

<style lang="scss" scoped>
.psou-mobile-header {
  width: 100%;

  :deep(.u-navbar) {
    border: 0;
  }
}

.psou-mobile-header__inner {
  display: flex;
  width: 100%;
  align-items: center;
  gap: 10px;
  padding: 0 18px;
}

.psou-mobile-header__search {
  min-width: 0;
  flex: 1;
}

.psou-mobile-header__back {
  display: flex;
  width: 36px;
  height: 36px;
  flex: 0 0 36px;
  align-items: center;
  justify-content: center;
}

.psou-mobile-header__search :deep(.u-content) {
  gap: 8px;
  padding: 0 12px;
}

.psou-mobile-header__search :deep(.u-input) {
  margin: 0;
}
</style>
