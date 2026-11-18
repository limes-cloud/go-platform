<script setup lang="ts">
defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  items: Array<{ label: string, value?: string | number }>
  layout?: 'rows' | 'grid' | 'facts'
}>(), {
  layout: 'rows',
})
</script>

<template>
  <view class="psou-info-list" :class="`psou-info-list--${layout}`">
    <view v-for="item in items" :key="item.label" class="psou-info-list__item">
      <text>{{ item.label }}</text>
      <b>{{ item.value }}</b>
    </view>
  </view>
</template>

<style lang="scss" scoped>
.psou-info-list {
  display: flex;
}

.psou-info-list--rows {
  flex-direction: column;
}

.psou-info-list--rows .psou-info-list__item {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 8px;
  padding: 5px 0;
  font-size: $font-normal;
}

.psou-info-list--rows text {
  color: var(--psou-text-3);
}

.psou-info-list--rows b {
  overflow: hidden;
  color: var(--psou-text-2);
  font-weight: 500;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.psou-info-list--grid {
  display: grid;
  overflow: hidden;
  border: 1px solid var(--psou-border);
  border-radius: 10px;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  background: var(--psou-surface);
}

.psou-info-list--grid .psou-info-list__item {
  display: flex;
  min-width: 0;
  flex-direction: column;
  gap: 3px;
  padding: 10px 12px;
  border-right: 1px solid var(--psou-border);
  border-bottom: 1px solid var(--psou-border);
}

.psou-info-list--grid .psou-info-list__item:nth-child(2n) {
  border-right: 0;
}

.psou-info-list--grid .psou-info-list__item:nth-last-child(-n + 2) {
  border-bottom: 0;
}

.psou-info-list--grid text {
  color: var(--psou-text-3);
  font-size: $font-xs;
}

.psou-info-list--grid b {
  overflow: hidden;
  color: var(--psou-text-2);
  font-size: $font-xs;
  font-weight: 500;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.psou-info-list--facts {
  display: grid;
  padding: 10px 0;
  grid-template-columns: repeat(3, 1fr);
  border-top: 1px solid var(--psou-border);
  border-bottom: 1px solid var(--psou-border);
}

.psou-info-list--facts .psou-info-list__item {
  display: flex;
  align-items: center;
  flex-direction: column;
  gap: 3px;
  border-right: 1px solid var(--psou-border);
}

.psou-info-list--facts .psou-info-list__item:last-child {
  border-right: 0;
}

.psou-info-list--facts b {
  color: var(--psou-text);
  font-size: $font-md;
  font-weight: 600;
}

.psou-info-list--facts text {
  color: var(--psou-text-3);
  font-size: $font-xs;
}
</style>
