<script setup lang="ts">
import type { Category } from '@/api/psou/type'
import { computed, ref, watch } from 'vue'
import { deriveSoftTintedPalette, hexToRgba, normalizeHexColor } from '@/library/color'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  node: Category
  layout?: 'desktop' | 'mobile'
  tone?: number
  iconTint?: boolean
}>(), {
  layout: 'desktop',
  tone: 0,
  iconTint: false,
})

defineEmits<{
  select: [node: Category]
}>()

const iconFailed = ref(false)
const DEFAULT_ICON_COLOR = '#2463eb'
const initial = computed(() => props.node.name.trim().slice(0, 1) || '分')
const toneClass = computed(() => `psou-catalog-card--tone-${Math.abs(props.tone) % 7}`)
const hasIconTint = computed(() => props.iconTint)
const iconColor = computed(() => normalizeHexColor(props.node.iconColor) || DEFAULT_ICON_COLOR)
const tintStyle = computed<Record<string, string>>(() => {
  const style: Record<string, string> = {}
  if (!hasIconTint.value)
    return style

  const primary = iconColor.value
  const palette = deriveSoftTintedPalette(primary)
  if (!palette)
    return style

  style['--psou-catalog-pastel'] = `linear-gradient(128deg, ${palette.deep} 0%, ${palette.base} 52%, ${palette.lift} 100%)`
  style['--psou-catalog-accent'] = palette.accent
  style['--psou-catalog-outline'] = hexToRgba(primary, 0.2)
  style['--psou-catalog-tint'] = hexToRgba(primary, 0.1)
  style['--psou-catalog-shadow'] = 'rgba(0, 0, 0, 0.14)'
  style['--psou-catalog-glow'] = hexToRgba(primary, 0.1)
  style['--psou-catalog-wash'] = hexToRgba(primary, 0.05)
  style['--psou-catalog-glow-strong'] = hexToRgba(primary, 0.58)
  style['--psou-catalog-glow-soft'] = hexToRgba(primary, 0.34)
  style['--psou-catalog-ink'] = palette.ink
  style['--psou-catalog-ink-soft'] = palette.inkSoft
  return style
})

watch(() => props.node.icon, () => {
  iconFailed.value = false
})
</script>

<template>
  <view
    class="psou-catalog-card"
    :class="[`psou-catalog-card--${layout}`, toneClass, { 'psou-catalog-card--icon-tint': hasIconTint }]"
    :style="tintStyle"
    @click="$emit('select', node)"
  >
    <view v-if="hasIconTint" class="psou-catalog-card__glow">
      <view class="psou-catalog-card__glow-orb psou-catalog-card__glow-orb--primary" />
      <view class="psou-catalog-card__glow-orb psou-catalog-card__glow-orb--secondary" />
    </view>
    <view v-if="hasIconTint" class="psou-catalog-card__veil" />
    <view class="psou-catalog-card__pattern" />
    <view v-if="hasIconTint" class="psou-catalog-card__wash">
      <view class="psou-catalog-card__wash-orb psou-catalog-card__wash-orb--top" />
      <view class="psou-catalog-card__wash-orb psou-catalog-card__wash-orb--band" />
    </view>
    <view class="psou-catalog-card__icon">
      <u-image
        v-if="node.icon && !iconFailed"
        :src="node.icon"
        width="100%"
        height="100%"
        mode="aspectFit"
        bg-color="transparent"
        :show-loading="false"
        @error="iconFailed = true"
      />
      <text v-else class="psou-catalog-card__initial">
        {{ initial }}
      </text>
    </view>
    <view class="psou-catalog-card__copy">
      <text class="psou-catalog-card__name">
        {{ node.name }}
      </text>
      <text v-if="layout === 'desktop'" class="psou-catalog-card__meta">
        一级分类
      </text>
    </view>
    <view class="psou-catalog-card__arrow">
      <u-icon
        name="arrow-right"
        size="16px"
        :color="hasIconTint ? 'var(--psou-catalog-ink)' : layout === 'desktop' ? 'rgba(255,255,255,.8)' : 'rgba(255,255,255,.86)'"
      />
    </view>
  </view>
</template>

<style lang="scss" scoped>
.psou-catalog-card {
  position: relative;
  display: flex;
  align-items: center;
  overflow: hidden;
  color: #fff;
  background: var(--psou-catalog-tone);
  cursor: pointer;
  isolation: isolate;
}

.psou-catalog-card--desktop {
  height: 64px;
  gap: 12px;
  padding: 0 16px;
  border-radius: 12px;
}

.psou-catalog-card--mobile {
  height: 64px;
  gap: 12px;
  padding: 0 16px;
  border-radius: 12px;
}

.psou-catalog-card--icon-tint {
  border: 1px solid var(--psou-catalog-outline);
  background: var(--psou-catalog-pastel);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    0 12px 28px var(--psou-catalog-shadow);
  transition: transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
}

.psou-catalog-card--icon-tint:hover {
  border-color: var(--psou-catalog-accent);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.12),
    0 16px 34px var(--psou-catalog-shadow),
    0 0 24px var(--psou-catalog-glow);
  transform: translateY(-2px);
}

.psou-catalog-card--icon-tint:active {
  transform: scale(0.985);
}

.psou-catalog-card__pattern {
  position: absolute;
  inset: 0;
  z-index: 1;
  overflow: hidden;
  pointer-events: none;
}

.psou-catalog-card--desktop .psou-catalog-card__pattern {
  background: radial-gradient(220px 130px at 88% 20%, rgba(255, 255, 255, 0.22), transparent 70%);
}

.psou-catalog-card--mobile .psou-catalog-card__pattern {
  background: radial-gradient(180px 110px at 88% 20%, rgba(255, 255, 255, 0.2), transparent 70%);
}

.psou-catalog-card--icon-tint .psou-catalog-card__pattern {
  background:
    radial-gradient(220px 130px at 92% 8%, rgba(255, 255, 255, 0.09), transparent 68%),
    radial-gradient(160px 96px at 48% 108%, var(--psou-catalog-wash), transparent 72%);
}

.psou-catalog-card__glow {
  position: absolute;
  inset: -36%;
  z-index: 0;
  overflow: hidden;
  opacity: 0.42;
  pointer-events: none;
  filter: blur(28px) saturate(1.18);
  transform: scale(1.08);
}

.psou-catalog-card--desktop .psou-catalog-card__glow {
  filter: blur(34px) saturate(1.12);
}

.psou-catalog-card__glow-orb {
  position: absolute;
  border-radius: 34%;
}

.psou-catalog-card__glow-orb--primary {
  top: -32%;
  right: 2%;
  width: 66%;
  height: 176%;
  background: var(--psou-catalog-glow-strong);
  transform: rotate(18deg);
}

.psou-catalog-card__glow-orb--secondary {
  bottom: -54%;
  left: -8%;
  width: 58%;
  height: 132%;
  background: var(--psou-catalog-glow-soft);
  transform: rotate(-12deg);
}

.psou-catalog-card__veil {
  position: absolute;
  inset: 0;
  z-index: 1;
  background:
    linear-gradient(92deg, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0.02) 46%, transparent 78%),
    linear-gradient(0deg, var(--psou-catalog-wash, rgba(64, 43, 137, 0.08)), transparent 46%);
  pointer-events: none;
}

.psou-catalog-card__wash {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  z-index: 1;
  overflow: hidden;
  pointer-events: none;
}

.psou-catalog-card__wash-orb {
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.055);
  pointer-events: none;
}

.psou-catalog-card__wash-orb--top {
  top: -76%;
  right: -24%;
  width: 78%;
  height: 142%;
  background: rgba(255, 255, 255, 0.075);
  transform: rotate(21deg);
}

.psou-catalog-card__wash-orb--band {
  top: 18%;
  left: -14%;
  width: 128%;
  height: 66%;
  border-radius: 48%;
  background: rgba(255, 255, 255, 0.03);
  transform: rotate(-11deg);
}

.psou-catalog-card__icon {
  position: relative;
  z-index: 2;
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(255, 255, 255, 0.12);
}

.psou-catalog-card--desktop .psou-catalog-card__icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
}

.psou-catalog-card--mobile .psou-catalog-card__icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
}

.psou-catalog-card--icon-tint .psou-catalog-card__icon {
  border-color: var(--psou-catalog-outline);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.12),
    0 8px 20px var(--psou-catalog-shadow);
  background: var(--psou-catalog-tint);
  backdrop-filter: blur(8px);
}

.psou-catalog-card__initial {
  color: rgba(255, 255, 255, 0.9);
  font-family: 'Noto Serif SC', serif;
  font-size: $font-lgx;
  font-weight: 700;
  line-height: 1;
}

.psou-catalog-card--icon-tint .psou-catalog-card__initial {
  color: var(--psou-catalog-ink);
}

.psou-catalog-card__copy {
  position: relative;
  z-index: 2;
  display: flex;
  min-width: 0;
  flex: 1;
  flex-direction: column;
  gap: 3px;
}

.psou-catalog-card--desktop .psou-catalog-card__copy {
  gap: 4px;
}

.psou-catalog-card__name {
  font-size: $font-lg;
  font-weight: 600;
}

.psou-catalog-card--mobile .psou-catalog-card__name {
  font-size: $font-lg;
}

.psou-catalog-card__meta {
  color: rgba(255, 255, 255, 0.62);
  font-size: $font-xs;
}

.psou-catalog-card--icon-tint .psou-catalog-card__name,
.psou-catalog-card--icon-tint .psou-catalog-card__meta {
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.28);
}

.psou-catalog-card--icon-tint .psou-catalog-card__name {
  color: var(--psou-catalog-ink);
}

.psou-catalog-card--icon-tint .psou-catalog-card__meta {
  color: var(--psou-catalog-ink-soft);
}

.psou-catalog-card__arrow {
  position: relative;
  z-index: 3;
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.psou-catalog-card--icon-tint .psou-catalog-card__arrow {
  opacity: 0.68;
}

.psou-catalog-card--icon-tint:hover .psou-catalog-card__arrow {
  opacity: 1;
  transform: translateX(2px);
}

.psou-catalog-card--tone-0 {
  --psou-catalog-tone: linear-gradient(112deg, #061b22, #0a5b63);
  --psou-catalog-pastel: linear-gradient(128deg, #74cfc4 0%, #77b6e4 48%, #a89bea 100%);
  --psou-catalog-accent: #2f7888;
  --psou-catalog-outline: rgba(47, 120, 136, 0.46);
  --psou-catalog-tint: rgba(47, 120, 136, 0.18);
  --psou-catalog-shadow: rgba(47, 120, 136, 0.2);
}

.psou-catalog-card--tone-1 {
  --psou-catalog-tone: linear-gradient(112deg, #1a0b21, #64265d);
  --psou-catalog-pastel: linear-gradient(128deg, #d68eea 0%, #b98fea 48%, #8d89e1 100%);
  --psou-catalog-accent: #7b4daf;
  --psou-catalog-outline: rgba(123, 77, 175, 0.46);
  --psou-catalog-tint: rgba(123, 77, 175, 0.18);
  --psou-catalog-shadow: rgba(123, 77, 175, 0.2);
}

.psou-catalog-card--tone-2 {
  --psou-catalog-tone: linear-gradient(112deg, #1b0b0f, #742832);
  --psou-catalog-pastel: linear-gradient(128deg, #f99bbe 0%, #e594db 48%, #ad8fea 100%);
  --psou-catalog-accent: #b64f81;
  --psou-catalog-outline: rgba(182, 79, 129, 0.46);
  --psou-catalog-tint: rgba(182, 79, 129, 0.18);
  --psou-catalog-shadow: rgba(182, 79, 129, 0.2);
}

.psou-catalog-card--tone-3 {
  --psou-catalog-tone: linear-gradient(112deg, #111529, #3c4380);
  --psou-catalog-pastel: linear-gradient(128deg, #7cb1eb 0%, #8f98ea 48%, #b88fe8 100%);
  --psou-catalog-accent: #4e66b9;
  --psou-catalog-outline: rgba(78, 102, 185, 0.46);
  --psou-catalog-tint: rgba(78, 102, 185, 0.18);
  --psou-catalog-shadow: rgba(78, 102, 185, 0.2);
}

.psou-catalog-card--tone-4 {
  --psou-catalog-tone: linear-gradient(112deg, #211507, #78521c);
  --psou-catalog-pastel: linear-gradient(128deg, #efbd7f 0%, #f0a9b4 48%, #c193e7 100%);
  --psou-catalog-accent: #a36b32;
  --psou-catalog-outline: rgba(163, 107, 50, 0.46);
  --psou-catalog-tint: rgba(163, 107, 50, 0.18);
  --psou-catalog-shadow: rgba(163, 107, 50, 0.2);
}

.psou-catalog-card--tone-5 {
  --psou-catalog-tone: linear-gradient(112deg, #111827, #314a63);
  --psou-catalog-pastel: linear-gradient(128deg, #80d8c3 0%, #83c1e5 48%, #98a6e8 100%);
  --psou-catalog-accent: #2d857f;
  --psou-catalog-outline: rgba(45, 133, 127, 0.46);
  --psou-catalog-tint: rgba(45, 133, 127, 0.18);
  --psou-catalog-shadow: rgba(45, 133, 127, 0.2);
}

.psou-catalog-card--tone-6 {
  --psou-catalog-tone: linear-gradient(112deg, #180d1e, #5c2e64);
  --psou-catalog-pastel: linear-gradient(128deg, #dc94e8 0%, #b891e8 48%, #8fa7e7 100%);
  --psou-catalog-accent: #7c4cae;
  --psou-catalog-outline: rgba(124, 76, 174, 0.46);
  --psou-catalog-tint: rgba(124, 76, 174, 0.18);
  --psou-catalog-shadow: rgba(124, 76, 174, 0.2);
}
</style>
