<script setup lang="ts">
import type { ResourceItem } from '@/api/psou/type'
import PsouCover from '@/components/psou-cover/psou-cover.vue'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  resource: ResourceItem
  showDescription?: boolean
}>(), {
  showDescription: true,
})

defineEmits<{
  select: [resource: ResourceItem]
}>()
</script>

<template>
  <view class="psou-resource-card" @click="$emit('select', resource)">
    <PsouCover
      :cover="resource.cover"
      :tone="resource.coverTone"
      :glyph="resource.glyph"
      :score="resource.score"
      :description="resource.description"
      :mask="showDescription"
    />
    <text class="psou-resource-card__title">
      {{ resource.title }}
    </text>
    <text v-if="resource.keywords.length" class="psou-resource-card__tags">
      {{ resource.keywords.join('、') }}
    </text>
  </view>
</template>

<style lang="scss" scoped>
.psou-resource-card {
  min-width: 0;
  cursor: pointer;
  transition: transform 0.2s ease;

  &:hover {
    transform: translateY(-2px);
  }
}

.psou-resource-card__title {
  display: block;
  overflow: hidden;
  margin: 9px 0 3px;
  color: var(--psou-text);
  font-size: $font-normal;
  font-weight: 500;
  line-height: 1.4;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.psou-resource-card__tags {
  display: block;
  color: var(--psou-text-3);
  font-size: $font-xs;
  line-height: 1.4;
  overflow-wrap: anywhere;
  white-space: normal;
}
</style>
