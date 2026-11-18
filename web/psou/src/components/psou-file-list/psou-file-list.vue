<script setup lang="ts">
import type { NetdiskFile } from '@/api/psou/type'
import { computed } from 'vue'
import PsouFileTypeIcon from '@/components/psou-file-type-icon/psou-file-type-icon.vue'
import { formatFileType } from '@/library/format'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  files: NetdiskFile[]
  showType?: boolean
  iconSize?: string
  maxHeight?: string
}>(), {
  showType: false,
  iconSize: '14px',
  maxHeight: '80px',
})

interface FlatFile extends NetdiskFile {
  depth: number
}

const flatFiles = computed<FlatFile[]>(() => {
  const result: FlatFile[] = []
  const walk = (files: NetdiskFile[], depth: number) => {
    for (const file of files) {
      result.push({ ...file, depth })
      if (file.children?.length)
        walk(file.children, depth + 1)
    }
  }
  walk(props.files, 0)
  return result
})
</script>

<template>
  <view class="psou-file-list" :style="{ maxHeight }">
    <view
      v-for="(file, index) in flatFiles"
      :key="`${file.path}-${file.name}-${index}`"
      class="psou-file-list__item"
      :style="{ paddingLeft: `${file.depth * 14}px` }"
    >
      <PsouFileTypeIcon :name="file.name" :dir="file.isDir" :size="iconSize" />
      <text class="psou-file-list__name">
        {{ file.name }}
      </text>
      <text v-if="showType" class="psou-file-list__type">
        {{ file.isDir ? '目录' : formatFileType(file.name) }}
      </text>
      <text class="psou-file-list__size">
        {{ file.size || '--' }}
      </text>
    </view>
  </view>
</template>

<style lang="scss" scoped>
.psou-file-list {
  overflow-y: auto;
  border-top: 1px solid var(--psou-border);
}

.psou-file-list__item {
  display: flex;
  min-width: 0;
  align-items: center;
  gap: 8px;
  padding: 9px 0;
  border-bottom: 1px solid var(--psou-border);
  color: var(--psou-text-2);
  font-size: $font-normal;
}

.psou-file-list__name {
  overflow: hidden;
  flex: 1;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.psou-file-list__type {
  padding: 1px 4px;
  border: 1px solid var(--psou-border);
  border-radius: 4px;
  color: var(--psou-text-3);
  font-size: $font-xs;
}

.psou-file-list__size {
  color: var(--psou-text-3);
  font-size: $font-xs;
  font-variant-numeric: tabular-nums;
}
</style>
