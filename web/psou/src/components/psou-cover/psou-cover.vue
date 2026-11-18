<script setup lang="ts">
import type { CoverTone } from '@/api/psou/type'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  cover?: string
  tone?: CoverTone
  glyph?: string
  score?: string
  description?: string
  mask?: boolean
}>(), {
  cover: '',
  tone: 'blue',
  glyph: '资',
  score: '',
  description: '',
  mask: false,
})
</script>

<template>
  <view class="psou-cover" :class="`psou-cover--${tone}`">
    <image v-if="cover" class="psou-cover__image" :src="cover" mode="aspectFill" />
    <view class="psou-cover__shade" />
    <text v-if="!cover" class="psou-cover__glyph">
      {{ glyph }}
    </text>
    <text v-if="score" class="psou-cover__score">
      {{ score }}
    </text>
    <view v-if="mask && description" class="psou-cover__mask">
      <text class="psou-cover__description">
        {{ description }}
      </text>
    </view>
  </view>
</template>

<style lang="scss" scoped>
.psou-cover {
  position: relative;
  width: 100%;
  height: 0;
  padding-top: 133.333%;
  overflow: hidden;
  isolation: isolate;
  border-radius: 6px;
  color: #fff;
  background: linear-gradient(135deg, #0b2745, #1f6feb 55%, #113a5e);
}

.psou-cover--teal {
  background: linear-gradient(135deg, #0b3b3f, #1a8f8a 55%, #123a63);
}

.psou-cover--gold {
  background: linear-gradient(135deg, #3f2f14, #a67c34 55%, #2b2338);
}

.psou-cover--rose {
  background: linear-gradient(135deg, #4a1d33, #b5545f 55%, #3c2054);
}

.psou-cover--violet {
  background: linear-gradient(135deg, #2b1830, #7a3f8c 55%, #24345f);
}

.psou-cover--indigo {
  background: linear-gradient(135deg, #17264f, #3f63c9 55%, #1a1f4a);
}

.psou-cover__image {
  position: absolute;
  inset: 0;
  z-index: 0;
  width: 100%;
  height: 100%;
}

.psou-cover__shade {
  position: absolute;
  inset: 0;
  z-index: 1;
  pointer-events: none;
  background: linear-gradient(180deg, transparent 42%, rgba(0, 0, 0, 0.62));
}

.psou-cover__glyph {
  position: absolute;
  left: 50%;
  top: 50%;
  z-index: 2;
  color: rgba(255, 255, 255, 0.92);
  font-family: 'Noto Serif SC', serif;
  font-size: $font-lgxx;
  font-weight: 700;
  line-height: 1;
  text-shadow: 0 5px 20px rgba(0, 0, 0, 0.35);
  transform: translate(-50%, -50%);
}

.psou-cover__score {
  position: absolute;
  top: 3px;
  right: 4px;
  z-index: 3;
  color: #ffd66b;
  font-size: $font-xs;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.8);
}

.psou-cover__mask {
  position: absolute;
  right: 0;
  bottom: 0;
  left: 0;
  z-index: 2;
  padding: 4px 0px 4px;
  background: rgba(0, 0, 0, 0.3);
}

.psou-cover__description {
  box-sizing: border-box;
  display: block;
  overflow: hidden;
  padding: 0 4px;
  color: rgba(255, 255, 255, 0.96);
  font-size: $font-xs;
  line-height: 1.5;
  text-overflow: ellipsis;
  text-shadow: 0 1px 6px rgba(0, 0, 0, 0.8), 0 0 2px rgba(0, 0, 0, 0.6);
  white-space: nowrap;
}
</style>
