<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { rurl } from '@/library/global/url'
import { useAppStore } from '@/stores/app'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  compact?: boolean
  iconOnly?: boolean
}>(), {
  compact: false,
  iconOnly: false,
})

defineEmits<{
  click: []
}>()

const appStore = useAppStore()
const logoFailed = ref(false)

const logoUrl = computed(() => rurl(appStore.app.logo || ''))
const title = computed(() => appStore.app.showName || appStore.app.name || 'PSou')
const remark = computed(() => appStore.app.description || 'PSOU 资源站')
const fallbackMark = computed(() => Array.from(title.value)[0] || '盘')

watch(logoUrl, () => {
  logoFailed.value = false
})
</script>

<template>
  <view
    class="psou-brand"
    :class="{ 'psou-brand--compact': compact, 'psou-brand--icon-only': iconOnly }"
    @click="$emit('click')"
  >
    <view class="psou-brand__mark psou-brand__mark--clickable">
      <image
        v-if="logoUrl && !logoFailed"
        class="psou-brand__logo"
        :src="logoUrl"
        mode="aspectFit"
        @error="logoFailed = true"
      />
      <text v-else>
        {{ fallbackMark }}
      </text>
    </view>
    <view v-if="!iconOnly" class="psou-brand__copy">
      <text class="psou-brand__name">
        {{ title }}
      </text>
      <text v-if="!compact && remark" class="psou-brand__sub">
        {{ remark }}
      </text>
    </view>
  </view>
</template>

<style lang="scss" scoped>
.psou-brand {
  display: flex;
  align-items: center;
  gap: 9px;
  cursor: pointer;
}

.psou-brand__mark {
  display: grid;
  width: 48px;
  height: 48px;
  flex: 0 0 auto;
  place-items: center;
  border-radius: 14px;
  color: #fff;
  font-size: $font-lgxx;
  font-weight: 700;
  background: linear-gradient(155deg, #59d9e4, #00a9b8 52%, #006d78);
  box-shadow: 0 4px 14px rgba(0, 184, 201, 0.24), inset 0 1px 0 rgba(255, 255, 255, 0.3);
}

.psou-brand__logo {
  width: 100%;
  height: 100%;
  border-radius: inherit;
}

.psou-brand__mark--clickable {
  cursor: pointer;
}

.psou-brand__copy {
  display: flex;
  min-width: 0;
  flex-direction: column;
}

.psou-brand__name {
  margin-bottom: 6px;
  color: var(--psou-text);
  font-size: $font-normal;
  font-weight: 600;
  line-height: 1.15;
}

.psou-brand__sub {
  margin-top: 2px;
  color: var(--psou-text-2);
  font-size: $font-xs;
  line-height: 1.15;
}

.psou-brand--compact {
  gap: 8px;
}

.psou-brand--compact .psou-brand__mark {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  font-size: $font-lg;
}

.psou-brand--icon-only {
  cursor: pointer;
}

.psou-brand--icon-only .psou-brand__mark {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  font-size: $font-lg;
  box-shadow: 0 4px 14px rgba(0, 184, 201, 0.24);
}
</style>
