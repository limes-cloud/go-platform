<script setup lang="ts">
import PsouCategoryIcon from '@/components/psou-category-icon/psou-category-icon.vue'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  title?: string
  eyebrow?: string
  description?: string
  count?: string | number
  layout?: 'desktop' | 'mobile'
  icon?: string
}>(), {
  title: '',
  eyebrow: '',
  description: '',
  count: '',
  layout: 'desktop',
  icon: '',
})
</script>

<template>
  <view class="psou-page-heading" :class="`psou-page-heading--${layout}`">
    <view class="psou-page-heading__copy">
      <text v-if="eyebrow" class="psou-page-heading__eyebrow">
        {{ eyebrow }}
      </text>
      <view v-if="title || icon" class="psou-page-heading__title-row">
        <PsouCategoryIcon
          v-if="icon"
          :icon="icon"
          size="24px"
          fallback="grid"
          color="var(--psou-accent)"
        />
        <text v-if="title" class="psou-page-heading__title">
          {{ title }}
        </text>
      </view>
      <text v-if="description" class="psou-page-heading__desc">
        {{ description }}
      </text>
    </view>
    <text v-if="count" class="psou-page-heading__count">
      {{ count }}
    </text>
  </view>
</template>

<style lang="scss" scoped>
.psou-page-heading {
  display: flex;
  min-width: 0;
}

.psou-page-heading--desktop {
  align-items: end;
  justify-content: space-between;
  gap: 24px;
}

.psou-page-heading--mobile {
  flex-direction: column;
  padding: 24px 0 16px;
}

.psou-page-heading__copy {
  min-width: 0;
}

.psou-page-heading__eyebrow {
  display: block;
  margin-bottom: 5px;
  color: var(--psou-accent);
  font-family: 'SFMono-Regular', Consolas, monospace;
  font-size: $font-xs;
  letter-spacing: 0.1em;
}

.psou-page-heading__title {
  display: block;
  color: var(--psou-text);
  font-size: $font-lgxx;
  font-weight: 700;
  letter-spacing: -0.03em;
  line-height: 1.2;
}

.psou-page-heading__title-row {
  display: flex;
  min-width: 0;
  align-items: center;
  gap: 9px;
}

.psou-page-heading--mobile .psou-page-heading__title {
  font-size: $font-lgxx;
}

.psou-page-heading__desc {
  display: block;
  max-width: 390px;
  margin-top: 4px;
  color: var(--psou-text-2);
  font-size: $font-normal;
  line-height: 1.75;
}

.psou-page-heading__count {
  flex: 0 0 auto;
  color: var(--psou-text-3);
  font-size: $font-xs;
}
</style>
