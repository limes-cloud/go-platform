<script setup lang="ts">
defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  variant?: 'accent' | 'ghost' | 'icon'
  size?: 'default' | 'small'
  block?: boolean
  disabled?: boolean
}>(), {
  variant: 'accent',
  size: 'default',
  block: false,
  disabled: false,
})

defineEmits<{
  click: []
}>()
</script>

<template>
  <view
    class="psou-button"
    :class="[
      `psou-button--${variant}`,
      `psou-button--size-${size}`,
      { 'psou-button--block': block, 'psou-button--disabled': disabled },
    ]"
    @click="!disabled && $emit('click')"
  >
    <slot />
  </view>
</template>

<style lang="scss" scoped>
.psou-button {
  display: inline-flex;
  height: 36px;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 0 17px;
  border-radius: 8px;
  font-size: $font-normal;
  font-weight: 500;
  cursor: pointer;
}

.psou-button--accent {
  color: #041416;
  background: var(--psou-accent);
}

.psou-button--size-small {
  height: 30px;
  padding: 0 13px;
  border-radius: 7px;
  font-size: $font-xs;
}

.psou-button--ghost {
  border: 1px solid rgba(255, 255, 255, 0.17);
  color: #fff;
  background: rgba(255, 255, 255, 0.12);
}

.psou-button--icon {
  width: 36px;
  padding: 0;
  border: 1px solid rgba(255, 255, 255, 0.16);
  border-radius: 9px;
  background: rgba(255, 255, 255, 0.12);
}

.psou-button--block {
  width: 100%;
}

.psou-button--disabled {
  opacity: 0.45;
  cursor: not-allowed;
  pointer-events: none;
}
</style>
