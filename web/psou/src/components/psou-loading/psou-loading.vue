<script setup lang="ts">
defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  text?: string
  compact?: boolean
  variant?: 'spinner' | 'search'
}>(), {
  text: '加载中...',
  compact: false,
  variant: 'spinner',
})

const searchIcons = [
  '/static/loading/baidu.png',
  '/static/loading/xunlei.png',
  '/static/loading/uc.png',
  '/static/loading/kuake.png',
  '/static/loading/yidong.png',
  '/static/loading/tianyi.png',
  '/static/loading/123.png',
  '/static/loading/115.png',
  '/static/loading/magnet.png',
  '/static/loading/ali.png',
  '/static/loading/emule.png',
]
</script>

<template>
  <view
    class="psou-loading"
    :class="[`psou-loading--${variant}`, { 'psou-loading--compact': compact }]"
  >
    <template v-if="variant === 'search'">
      <view class="psou-loading__marquee">
        <view class="psou-loading__track">
          <view
            v-for="(icon, index) in [...searchIcons, ...searchIcons]"
            :key="`${icon}-${index}`"
            class="psou-loading__dot"
          >
            <image class="psou-loading__icon" :src="icon" mode="aspectFit" />
          </view>
        </view>
        <view class="psou-loading__fade psou-loading__fade--left" />
        <view class="psou-loading__fade psou-loading__fade--right" />
      </view>
      <text class="psou-loading__text">
        {{ text }}
      </text>
    </template>
    <template v-else>
      <u-loading mode="circle" color="var(--psou-accent)" :size="compact ? 18 : 24" />
      <text>{{ text }}</text>
    </template>
  </view>
</template>

<style lang="scss" scoped>
.psou-loading {
  display: flex;
  min-height: 220px;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  gap: 10px;
  color: var(--psou-text-3);
  font-size: $font-xs;
}

.psou-loading--compact {
  min-height: 120px;
}

.psou-loading--search {
  min-height: 260px;
  align-items: stretch;
  justify-content: flex-start;
  gap: 0;
  padding: 48px 18px 0;
}

.psou-loading__marquee {
  position: relative;
  width: 100%;
  max-width: 880px;
  margin: 0 auto;
  overflow: hidden;
}

.psou-loading__track {
  display: flex;
  width: 1760px;
  animation: psou-search-marquee 24s linear infinite;
}

.psou-loading__dot {
  display: flex;
  width: 58px;
  height: 58px;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  margin: 0 11px;
}

.psou-loading__icon {
  width: 100%;
  height: 100%;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.06);
  box-shadow: 0 6px 20px rgba(8, 10, 30, 0.4);
}

.psou-loading__fade {
  position: absolute;
  top: 0;
  bottom: 0;
  z-index: 2;
  width: 44px;
  pointer-events: none;
}

.psou-loading__fade--left {
  left: 0;
  background: linear-gradient(90deg, var(--psou-bg), rgba(5, 7, 15, 0));
}

.psou-loading__fade--right {
  right: 0;
  background: linear-gradient(270deg, var(--psou-bg), rgba(5, 7, 15, 0));
}

.psou-loading__text {
  margin-top: 20px;
  color: var(--psou-text-2);
  font-size: $font-md;
  text-align: center;
}

@keyframes psou-search-marquee {
  from {
    transform: translateX(0);
  }

  to {
    transform: translateX(-880px);
  }
}
</style>
