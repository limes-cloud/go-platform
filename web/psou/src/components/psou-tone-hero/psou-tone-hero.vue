<script setup lang="ts">
import type { CoverTone } from '@/api/psou/type'
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { getPlatform } from '@/library/utils/platform'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  cover?: string
  tone?: CoverTone
  glyph?: string
  variant?: 'page' | 'desktop' | 'slide' | 'slide-desktop'
  height?: string
  focusX?: number
  focusY?: number
}>(), {
  cover: '',
  tone: 'teal',
  glyph: '',
  variant: 'page',
  height: '',
  focusX: 0.5,
  focusY: 0.5,
})

const clampFocus = (value: number) => Math.min(1, Math.max(0, value))

const REFERENCE_FOCUS_ASPECT = 12 / 5
const isH5 = getPlatform().startsWith('web')
const heroRef = ref<HTMLElement | null>(null)
const containerAspect = ref(0)
const imageAspect = ref(0)
let imageLoadToken = 0
let resizeObserver: ResizeObserver | null = null

const visibleFractionX = (aspect: number, image: number) => Math.min(1, aspect / image)
const visibleFractionY = (aspect: number, image: number) => Math.min(1, image / aspect)
const focusToImagePoint = (position: number, visible: number) => position * (1 - visible) + 0.5 * visible

function imagePointToFocus(point: number, visible: number) {
  if (visible >= 1 - 1e-6) {
    return 0.5
  }
  return clampFocus((point - 0.5 * visible) / (1 - visible))
}

function heroElement() {
  const target = heroRef.value as unknown as {
    getBoundingClientRect?: () => DOMRect
    $el?: HTMLElement
  } | null
  if (!target) {
    return null
  }
  if (typeof target.getBoundingClientRect === 'function') {
    return target as unknown as HTMLElement
  }
  return target.$el || null
}

function measureContainerAspect() {
  const element = heroElement()
  if (!isH5 || !element) {
    return
  }
  const rect = element.getBoundingClientRect()
  if (rect.width > 0 && rect.height > 0) {
    containerAspect.value = rect.width / rect.height
  }
}

function loadImageAspect() {
  if (!isH5 || typeof window === 'undefined' || typeof Image === 'undefined' || !props.cover) {
    imageAspect.value = 0
    return
  }
  imageAspect.value = 0
  const token = ++imageLoadToken
  const image = new Image()
  image.onload = () => {
    if (token !== imageLoadToken) {
      return
    }
    imageAspect.value = image.naturalWidth > 0 && image.naturalHeight > 0
      ? image.naturalWidth / image.naturalHeight
      : 0
  }
  image.onerror = () => {
    if (token === imageLoadToken) {
      imageAspect.value = 0
    }
  }
  image.src = props.cover
}

watch(() => props.cover, loadImageAspect, { immediate: true })

onMounted(() => {
  if (!isH5) {
    return
  }
  measureContainerAspect()
  const element = heroElement()
  if (element && typeof ResizeObserver !== 'undefined') {
    resizeObserver = new ResizeObserver(measureContainerAspect)
    resizeObserver.observe(element)
  }
  else if (typeof window !== 'undefined') {
    window.addEventListener('resize', measureContainerAspect)
  }
})

onBeforeUnmount(() => {
  resizeObserver?.disconnect()
  resizeObserver = null
  if (typeof window !== 'undefined') {
    window.removeEventListener('resize', measureContainerAspect)
  }
  imageLoadToken += 1
})

const resolvedFocus = computed(() => {
  const focusX = clampFocus(props.focusX)
  const focusY = clampFocus(props.focusY)
  if (props.variant !== 'slide' || !imageAspect.value || !containerAspect.value) {
    return { x: focusX, y: focusY }
  }

  const referenceVisibleX = visibleFractionX(REFERENCE_FOCUS_ASPECT, imageAspect.value)
  const referenceVisibleY = visibleFractionY(REFERENCE_FOCUS_ASPECT, imageAspect.value)
  const currentVisibleX = visibleFractionX(containerAspect.value, imageAspect.value)
  const currentVisibleY = visibleFractionY(containerAspect.value, imageAspect.value)

  return {
    x: imagePointToFocus(focusToImagePoint(focusX, referenceVisibleX), currentVisibleX),
    y: imagePointToFocus(focusToImagePoint(focusY, referenceVisibleY), currentVisibleY),
  }
})

const coverStyle = computed(() => {
  if (!props.cover) {
    return undefined
  }
  const x = resolvedFocus.value.x * 100
  const y = resolvedFocus.value.y * 100
  return {
    backgroundImage: `url("${props.cover}")`,
    backgroundPosition: `${x}% ${y}%`,
  }
})
</script>

<template>
  <view
    ref="heroRef"
    class="psou-tone-hero"
    :class="[`psou-tone--${tone}`, `psou-tone-hero--${variant}`]"
    :style="height ? { height } : undefined"
  >
    <!-- #ifdef H5 -->
    <view v-if="cover" class="psou-tone-hero__cover psou-tone-hero__cover--background" :style="coverStyle" />
    <!-- #endif -->
    <!-- #ifndef H5 -->
    <image v-if="cover" class="psou-tone-hero__cover" :src="cover" mode="aspectFill" />
    <!-- #endif -->
    <view v-if="!cover" class="psou-tone-hero__pattern" />
    <text v-if="!cover && glyph" class="psou-tone-hero__glyph">
      {{ glyph }}
    </text>
    <slot />
  </view>
</template>

<style lang="scss" scoped>
.psou-tone-hero {
  position: relative;
  width: 100%;
  height: 100%;
  overflow: hidden;
  isolation: isolate;
  background: #07121a;
  color: #fff;
}

.psou-tone-hero.psou-tone--blue {
  background: linear-gradient(0deg, #03101e, #07365c 52%, #0a6583);
}

.psou-tone-hero.psou-tone--teal {
  background: linear-gradient(0deg, #031013, #07383d 52%, #0a5b63);
}

.psou-tone-hero.psou-tone--gold {
  background: linear-gradient(0deg, #171005, #4d320e 52%, #85581a);
}

.psou-tone-hero.psou-tone--rose {
  background: linear-gradient(0deg, #1e0710, #59152d 52%, #8a2548);
}

.psou-tone-hero.psou-tone--violet {
  background: linear-gradient(0deg, #120820, #352050 52%, #55357c);
}

.psou-tone-hero.psou-tone--indigo {
  background: linear-gradient(0deg, #070c1c, #192e5c 52%, #294b8b);
}

.psou-tone-hero--desktop.psou-tone--blue,
.psou-tone-hero--slide-desktop.psou-tone--blue {
  background: linear-gradient(112deg, #03101e, #07365c 48%, #0a6583);
}

.psou-tone-hero--desktop.psou-tone--teal,
.psou-tone-hero--slide-desktop.psou-tone--teal {
  background: linear-gradient(112deg, #031013, #07383d 48%, #0a5b63);
}

.psou-tone-hero--desktop.psou-tone--gold,
.psou-tone-hero--slide-desktop.psou-tone--gold {
  background: linear-gradient(112deg, #171005, #4d320e 48%, #85581a);
}

.psou-tone-hero--desktop.psou-tone--rose,
.psou-tone-hero--slide-desktop.psou-tone--rose {
  background: linear-gradient(112deg, #1e0710, #59152d 48%, #8a2548);
}

.psou-tone-hero--desktop.psou-tone--violet,
.psou-tone-hero--slide-desktop.psou-tone--violet {
  background: linear-gradient(112deg, #120820, #352050 48%, #55357c);
}

.psou-tone-hero--desktop.psou-tone--indigo,
.psou-tone-hero--slide-desktop.psou-tone--indigo {
  background: linear-gradient(112deg, #070c1c, #192e5c 48%, #294b8b);
}

.psou-tone-hero.psou-tone-hero--slide-desktop {
  background: #05070f;
}

.psou-tone-hero__cover {
  position: absolute;
  inset: 0;
  z-index: 0;
  width: 100%;
  height: 100%;
}

.psou-tone-hero__cover--background {
  background-repeat: no-repeat;
  background-size: cover;
}

.psou-tone-hero--slide-desktop .psou-tone-hero__cover {
  left: 120px;
  width: calc(100% - 120px);
  -webkit-mask-image: linear-gradient(90deg, transparent 0%, #000 120px);
  mask-image: linear-gradient(90deg, transparent 0%, #000 120px);
}

.psou-tone-hero::after {
  position: absolute;
  inset: 0;
  z-index: 1;
  content: '';
}

.psou-tone-hero--page::after,
.psou-tone-hero--slide::after {
  background: linear-gradient(180deg, rgba(3, 7, 15, 0.05), rgba(3, 7, 15, 1));
}

.psou-tone-hero--desktop::after {
  background:
    linear-gradient(90deg, rgba(2, 6, 10, 0.42), rgba(2, 6, 10, 0.06) 58%, rgba(2, 6, 10, 0.36)),
    linear-gradient(
      0deg,
      #05070f 0%,
      rgba(5, 7, 15, 0.9) 14%,
      rgba(5, 7, 15, 0.35) 42%,
      transparent 62%
    );
}

.psou-tone-hero--slide-desktop::after {
  background: linear-gradient(180deg, rgba(2, 6, 8, 0.08), rgba(2, 6, 8, 0.18) 40%, rgba(2, 6, 8, 1));
}

.psou-tone-hero__pattern {
  position: absolute;
  inset: 0;
  z-index: 0;
  background:
    radial-gradient(230px 160px at 82% 22%, rgba(56, 214, 228, 0.26), transparent 70%),
    repeating-radial-gradient(circle at 82% 28%, transparent 0 28px, rgba(255, 255, 255, 0.045) 28px 29px);
}

.psou-tone-hero--desktop .psou-tone-hero__pattern {
  background:
    radial-gradient(520px 300px at 80% 18%, rgba(56, 214, 228, 0.24), transparent 70%),
    repeating-radial-gradient(circle at 82% 26%, transparent 0 28px, rgba(255, 255, 255, 0.045) 28px 29px);
}

.psou-tone-hero--slide .psou-tone-hero__pattern {
  background:
    radial-gradient(220px 160px at 82% 22%, rgba(56, 214, 228, 0.3), transparent 70%),
    repeating-radial-gradient(circle at 82% 28%, transparent 0 30px, rgba(255, 255, 255, 0.045) 30px 31px);
}

.psou-tone-hero--slide-desktop .psou-tone-hero__pattern {
  background:
    radial-gradient(520px 300px at 82% 16%, rgba(56, 214, 228, 0.28), transparent 70%),
    repeating-radial-gradient(circle at 82% 22%, transparent 0 26px, rgba(255, 255, 255, 0.045) 26px 27px);
}

.psou-tone-hero__glyph {
  position: absolute;
  z-index: 0;
  color: rgba(255, 255, 255, 0.1);
  font-family: 'Noto Serif SC', serif;
  font-weight: 900;
  line-height: 1;
  transform: rotate(-7deg);
}

.psou-tone-hero--page .psou-tone-hero__glyph {
  top: 42%;
  right: 18px;
  font-size: 128px;
  transform: translateY(-50%) rotate(-7deg);
}

.psou-tone-hero--desktop .psou-tone-hero__glyph {
  top: 12%;
  right: 8%;
  color: rgba(255, 255, 255, 0.07);
  font-size: 310px;
}

.psou-tone-hero--slide .psou-tone-hero__glyph {
  top: 50%;
  right: 18px;
  font-size: 132px;
  transform: translateY(-50%) rotate(-7deg);
}

.psou-tone-hero--slide-desktop .psou-tone-hero__glyph {
  top: -50px;
  right: 250px;
  color: rgba(255, 255, 255, 0.055);
  font-size: 340px;
}
</style>
