<script setup lang="ts">
import type { ResourceItem } from '@/api/psou/type'
import { computed } from 'vue'
import PsouResourceCard from '@/components/psou-resource-card/psou-resource-card.vue'
import { useResponsive } from '@/composables/useResponsive'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  resources: ResourceItem[]
  layout: 'mobile' | 'desktop'
  density?: 'default' | 'compact'
  /** 最多展示的行数；不传 = 全部展示。超出部分按当前列数自动裁剪。 */
  maxRows?: number
}>(), {
  density: 'default',
  maxRows: 0,
})

defineEmits<{
  select: [resource: ResourceItem]
}>()

const { windowWidth } = useResponsive()
const columns = computed(() => {
  if (props.layout === 'desktop') {
    if (windowWidth.value >= 1800)
      return 8
    if (windowWidth.value >= 1600)
      return 7
    if (windowWidth.value >= 1400)
      return 6
    if (windowWidth.value >= 1200)
      return 5
    return 4
  }
  if (windowWidth.value >= 900)
    return 6
  if (windowWidth.value >= 768)
    return 5
  if (windowWidth.value >= 600)
    return 4
  if (windowWidth.value >= 360)
    return 3
  return 2
})
const visibleResources = computed(() => {
  const limit = props.maxRows > 0 ? props.maxRows * columns.value : props.resources.length
  return limit >= props.resources.length ? props.resources : props.resources.slice(0, limit)
})
</script>

<template>
  <view
    class="psou-resource-grid"
    :class="[`psou-resource-grid--${layout}`, `psou-resource-grid--${density}`]"
    :style="{ gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))` }"
  >
    <PsouResourceCard
      v-for="resource in visibleResources"
      :key="resource.id"
      :resource="resource"
      @select="$emit('select', resource)"
    />
  </view>
</template>

<style lang="scss" scoped>
.psou-resource-grid {
  display: grid;
  min-width: 0;
}

.psou-resource-grid--mobile {
  gap: 16px 9px;
}

.psou-resource-grid--mobile.psou-resource-grid--compact {
  gap: 14px 8px;
}

.psou-resource-grid--desktop {
  gap: 18px 14px;
}

.psou-resource-grid--desktop.psou-resource-grid--compact {
  gap: 16px 14px;
}
</style>
