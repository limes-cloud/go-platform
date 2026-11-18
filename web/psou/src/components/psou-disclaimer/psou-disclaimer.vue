<script setup lang="ts">
defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

withDefaults(defineProps<{
  text?: string
}>(), {
  text: '本站不存储、不上传、不转存任何文件，仅提供公开网络资源信息的索引与检索服务。资源链接由用户分享，请于下载后 24 小时内删除，勿用于商业用途。',
})
</script>

<template>
  <view class="psou-disclaimer">
    <text class="psou-disclaimer__title">
      免责声明
    </text>
    <text class="psou-disclaimer__text">
      {{ text }}
    </text>
  </view>
</template>

<style lang="scss" scoped>
.psou-disclaimer {
  display: flex;
  flex-direction: column;
  gap: 5px;
  padding: 12px;
  border: 1px solid var(--psou-border);
  border-radius: 9px;
  background: var(--psou-surface);
}

.psou-disclaimer__title {
  color: var(--psou-text-2);
  font-size: $font-md;
  font-weight: 600;
}

.psou-disclaimer__text {
  color: var(--psou-text-3);
  font-size: $font-normal;
  line-height: 1.75;
}
</style>
