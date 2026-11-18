<script setup lang="ts">
defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  icon?: string
  iconSize?: string
}>(), {
  icon: 'info-circle',
  iconSize: '14px',
})
</script>

<template>
  <view class="psou-notice">
    <u-icon :name="icon" :size="iconSize" color="var(--psou-accent)" />
    <view class="psou-notice__content">
      <slot />
    </view>
  </view>
</template>

<style lang="scss" scoped>
.psou-notice {
  display: flex;
  align-items: flex-start;
  gap: 6px;
  padding: 8px 12px;
  border: 1px solid var(--psou-border);
  border-radius: 8px;
  color: var(--psou-text-2);
  font-size: $font-normal;
  line-height: 1.6;
  background: var(--psou-surface);
}

.psou-notice__content {
  min-width: 0;
  flex: 1;
}
</style>
