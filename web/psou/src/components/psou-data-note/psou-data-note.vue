<script setup lang="ts">
defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  text: string
  boxed?: boolean
  icon?: string
  iconSize?: string
}>(), {
  boxed: false,
  icon: 'server',
  iconSize: '16px',
})
</script>

<template>
  <view class="psou-data-note" :class="{ 'psou-data-note--boxed': boxed }">
    <u-icon :name="icon" :size="iconSize" />
    <text>{{ text }}</text>
  </view>
</template>

<style lang="scss" scoped>
.psou-data-note {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--psou-text-3);
  font-size: $font-xs;
  line-height: 1.6;
}

.psou-data-note--boxed {
  padding: 8px 9px;
  border: 1px solid var(--psou-border);
  border-radius: 9px;
  background: var(--psou-surface);
}
</style>
