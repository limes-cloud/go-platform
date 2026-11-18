<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { fetchSiteCopyright } from '@/api/psou/service'

withDefaults(defineProps<{
  layout?: 'desktop' | 'mobile'
}>(), {
  layout: 'mobile',
})

const content = ref('')

onMounted(async () => {
  try {
    const copyright = await fetchSiteCopyright()
    content.value = String(copyright?.content || '').trim()
  }
  catch {
    content.value = ''
  }
})
</script>

<template>
  <view v-if="content" class="psou-site-footer" :class="`psou-site-footer--${layout}`">
    <text class="psou-site-footer__text">
      {{ content }}
    </text>
  </view>
</template>

<style lang="scss" scoped>
.psou-site-footer {
  margin: 15px 0;
  text-align: center;
}

.psou-site-footer--mobile {
  padding: 0 24px;
}

.psou-site-footer--desktop {
  margin: 30px 0;
  padding: 0;
}

.psou-site-footer__text {
  color: var(--psou-text-3);
  font-size: 12px;
  line-height: 1.7;
  white-space: pre-wrap;
  word-break: break-word;
}
</style>
