<script setup lang="ts">
import { computed, ref, watch } from 'vue'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  icon?: string
  size?: string
  fallback?: string
  color?: string
}>(), {
  icon: '',
  size: '16px',
  fallback: 'grid',
  color: 'var(--psou-text-3)',
})

const failed = ref(false)
const isImage = computed(() => /^(?:https?:\/\/|\/|data:image\/)/i.test(props.icon))

watch(() => props.icon, () => {
  failed.value = false
})
</script>

<template>
  <view class="psou-category-icon" :style="{ width: size, height: size }">
    <u-image
      v-if="icon && isImage && !failed"
      :src="icon"
      :width="size"
      :height="size"
      mode="aspectFit"
      bg-color="transparent"
      :show-loading="false"
      @error="failed = true"
    />
    <u-icon
      v-else
      :name="icon && !isImage ? icon : fallback"
      :size="size"
      :color="color"
    />
  </view>
</template>

<style lang="scss" scoped>
.psou-category-icon {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  line-height: 0;
}
</style>
