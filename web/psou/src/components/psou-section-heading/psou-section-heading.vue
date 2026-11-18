<script setup lang="ts">
import { computed } from 'vue'

defineOptions({
  options: {
    addGlobalClass: true,
    // #ifndef MP-TOUTIAO
    virtualHost: true,
    // #endif
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  title: string
  count?: string | number
  note?: string
  icon?: string
  iconSize?: string
  moreText?: string
  variant?: 'bar' | 'icon'
}>(), {
  count: '',
  note: '',
  icon: '',
  iconSize: '',
  moreText: '',
  variant: 'bar',
})

defineEmits<{
  more: []
}>()

const iconIsImage = computed(() => /^(?:https?:\/\/|\/|data:image\/)/i.test(props.icon))
const resolvedIconSize = computed(() => props.iconSize || '18px')
const resolvedRowHeight = computed(() => props.iconSize || '18px')
</script>

<template>
  <view class="psou-heading" :class="[`psou-heading--${variant}`, { 'psou-heading--with-icon': icon }]">
    <view class="psou-heading__main">
      <view
        v-if="icon"
        class="psou-heading__icon"
        :style="{ width: resolvedIconSize, height: resolvedRowHeight, lineHeight: 0 }"
      >
        <u-image
          v-if="iconIsImage"
          :src="icon"
          :width="resolvedIconSize"
          :height="resolvedIconSize"
          mode="aspectFit"
          bg-color="transparent"
          :show-loading="false"
          :custom-style="{ display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 0 }"
        />
        <u-icon v-else :name="icon" :size="resolvedIconSize" color="var(--psou-accent)" />
      </view>
      <text class="psou-heading__title" :style="{ lineHeight: resolvedRowHeight }">
        {{ title }}
      </text>
      <text v-if="count" class="psou-heading__count">
        {{ count }}
      </text>
    </view>
    <text v-if="note" class="psou-heading__note">
      {{ note }}
    </text>
    <view v-if="moreText" class="psou-heading__more" @click="$emit('more')">
      <text>{{ moreText }}</text>
      <u-icon name="arrow-right" size="12px" color="#fff" />
    </view>
  </view>
</template>

<style lang="scss" scoped>
.psou-heading {
  display: flex;
  width: 100%;
  gap: 12px;
  align-items: center;
  min-width: 0;
  color: var(--psou-text);
}

.psou-heading__main {
  display: flex;
  flex: 1;
  min-height: 18px;
  min-width: 0;
  align-items: center;
  gap: 7px;
}

.psou-heading--bar .psou-heading__main::before {
  width: 3px;
  height: 11px;
  flex: 0 0 auto;
  border-radius: 2px;
  background: var(--psou-accent);
  content: '';
}

.psou-heading--bar.psou-heading--with-icon .psou-heading__main::before {
  display: none;
}

.psou-heading__icon {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
}

.psou-heading__title {
  display: block;
  overflow: hidden;
  min-width: 0;
  color: var(--psou-text);
  font-size: $font-md;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.psou-heading__count {
  flex: 0 0 auto;
  color: var(--psou-text-3);
  font-size: $font-xs;
  font-weight: 400;
}

.psou-heading__note {
  flex: 0 0 auto;
  margin-left: auto;
  color: var(--psou-text-3);
  font-size: $font-xs;
}

.psou-heading__more {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  gap: 2px;
  margin-left: auto;
  color: #fff;
  font-size: $font-xs;
  cursor: pointer;
}

.psou-heading__more:hover {
  color: #fff;
  opacity: 0.8;
}
</style>
