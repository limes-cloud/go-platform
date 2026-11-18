<script setup lang="ts">
import { computed } from 'vue'
import { getPlatform } from '@/library/utils/platform'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  title?: string
  variant?: 'overlay' | 'solid'
  fixed?: boolean
  fixedOnH5?: boolean
  scrollTop?: number
  fadeDistance?: number
  search?: boolean
}>(), {
  title: '',
  variant: 'overlay',
  fixed: false,
  fixedOnH5: false,
  scrollTop: 0,
  fadeDistance: 80,
  search: false,
})

const emit = defineEmits<{
  back: []
  search: []
}>()

const isH5 = getPlatform().startsWith('web')
const fadeEnabled = computed(() => props.fixed || (props.fixedOnH5 && isH5))
const isFixed = computed(() => props.variant === 'solid' || fadeEnabled.value)
const scrollProgress = computed(() => {
  if (!fadeEnabled.value)
    return 0
  return Math.min(1, Math.max(0, props.scrollTop / Math.max(1, props.fadeDistance)))
})
const navbarBackground = computed(() => {
  if (props.variant === 'solid') {
    return {
      background: 'rgba(8, 11, 24, 0.94)',
      backdropFilter: 'blur(18px)',
    }
  }
  if (isFixed.value) {
    return {
      background: `rgba(8, 11, 24, ${scrollProgress.value.toFixed(3)})`,
      backdropFilter: scrollProgress.value > 0 ? 'blur(18px)' : 'none',
    }
  }
  return { background: 'transparent' }
})

function handleBack() {
  emit('back')
}
</script>

<template>
  <view
    class="psou-mobile-back-nav"
    :class="`psou-mobile-back-nav--${variant}`"
  >
    <u-navbar
      :is-back="true"
      :is-fixed="isFixed"
      :border-bottom="false"
      :title="title"
      :z-index="9999"
      title-color="var(--psou-text)"
      :custom-back="handleBack"
      back-icon-size="16px"
      :back-icon-color="variant === 'solid' ? 'var(--psou-text)' : '#ffffff'"
      :background="navbarBackground"
    >
      <slot />
      <template #right>
        <view v-if="search" class="psou-mobile-back-nav__search" @click="emit('search')">
          <u-icon name="search" size="18px" color="var(--psou-text)" />
        </view>
      </template>
    </u-navbar>
  </view>
</template>

<style lang="scss" scoped>
.psou-mobile-back-nav--overlay {
  position: absolute;
  top: 0;
  right: 0;
  left: 0;
  z-index: 4;
}

.psou-mobile-back-nav--solid {
  position: relative;
  width: 100%;
}

.psou-mobile-back-nav {
  :deep(.u-navbar-content-title .u-title) {
    font-size: $font-md !important;
  }

  :deep(.u-back-wrap) {
    display: flex;
    width: 36px;
    height: 36px;
    min-width: 36px;
    align-items: center;
    justify-content: center;
    flex: 0 0 36px;
    padding: 0;
  }

  .psou-mobile-back-nav__search {
    display: flex;
    width: 36px;
    height: 36px;
    align-items: center;
    justify-content: center;
    margin-right: 8px;
  }
}
</style>
