<script setup lang="ts">
import { FONT_SIZE_NORMAL } from '@/common/typography'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  mode?: 'data' | 'search' | 'list'
  text: string
  fill?: boolean
}>(), {
  mode: 'data',
  fill: false,
})
</script>

<template>
  <view class="psou-empty" :class="{ 'psou-empty--fill': fill }">
    <u-empty
      :mode="mode"
      :text="text"
      icon-size="48px"
      :font-size="FONT_SIZE_NORMAL"
      color="var(--psou-text-3)"
      icon-color="var(--psou-text-3)"
    />
  </view>
</template>

<style lang="scss" scoped>
.psou-empty {
  box-sizing: border-box;
  display: flex;
  width: 100%;
  align-items: center;
  justify-content: center;
  padding: 50px 0;
}

.psou-empty--fill {
  min-height: calc(100vh - 160px);
}
</style>
