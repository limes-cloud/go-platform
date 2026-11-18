<script setup lang="ts">
defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  modelValue?: string
  placeholder?: string
  readonly?: boolean
  showKbd?: boolean
  size?: 'compact' | 'default'
}>(), {
  modelValue: '',
  placeholder: '搜索影视、音乐、游戏、软件…',
  readonly: false,
  showKbd: false,
  size: 'default',
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  'search': [value: string]
  'tap': []
}>()

function handleInput(event: { detail: { value: string } }) {
  emit('update:modelValue', event.detail.value)
}

function handleConfirm() {
  emit('search', props.modelValue)
}

function handleTap() {
  if (props.readonly)
    emit('tap')
}
</script>

<template>
  <view class="psou-search" :class="`psou-search--${size}`" @click="handleTap">
    <u-icon name="search" color="var(--psou-accent)" size="16px" />
    <input
      v-if="!readonly"
      class="psou-search__input"
      :value="modelValue"
      :placeholder="placeholder"
      placeholder-class="psou-search__placeholder"
      confirm-type="search"
      @input="handleInput"
      @confirm="handleConfirm"
    >
    <text v-else class="psou-search__display">
      {{ modelValue || placeholder }}
    </text>
    <text v-if="showKbd" class="psou-search__kbd">
      ⌘K
    </text>
  </view>
</template>

<style lang="scss" scoped>
.psou-search {
  display: flex;
  height: 42px;
  align-items: center;
  gap: 8px;
  padding: 0 12px;
  border: 1px solid var(--psou-search-border);
  border-radius: 8px;
  color: #fff;
  font-size: $font-xs;
  background: var(--psou-search-bg);
  cursor: pointer;
  transition: background-color 0.1s linear, border-color 0.1s linear;
}

.psou-search--compact {
  height: 36px;
  padding: 0 12px;
  border-radius: 6px;
}

.psou-search__input {
  min-width: 0;
  flex: 1;
  color: #fff;
  font-size: $font-normal;
}

.psou-search__placeholder {
  color: rgba(255, 255, 255, 0.8);
}

.psou-search__display {
  overflow: hidden;
  flex: 1;
  color: rgba(255, 255, 255, 0.58);
  font-size: $font-normal;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.psou-search__kbd {
  flex: 0 0 auto;
  padding: 2px 5px;
  border-radius: 6px;
  color: var(--psou-text-2);
  font-size: $font-xs;
  background: var(--psou-search-kbd-bg);
}
</style>
