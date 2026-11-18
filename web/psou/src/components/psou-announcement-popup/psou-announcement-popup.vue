<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { fetchSiteAnnouncement } from '@/api/psou/service'
import PsouButton from '@/components/psou-button/psou-button.vue'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const ANNOUNCEMENT_SHOWN_AT_KEY = 'psou_announcement_shown_at'
const ANNOUNCEMENT_INTERVAL = 30 * 60 * 1000

const visible = ref(false)
const content = ref('')
let announcementHandled = false

function isWithinSuppressionWindow() {
  const shownAt = Number(uni.getStorageSync(ANNOUNCEMENT_SHOWN_AT_KEY) || 0)
  if (!Number.isFinite(shownAt) || shownAt <= 0)
    return false

  const elapsed = Date.now() - shownAt
  return elapsed >= 0 && elapsed < ANNOUNCEMENT_INTERVAL
}

onMounted(async () => {
  if (announcementHandled)
    return
  announcementHandled = true
  if (isWithinSuppressionWindow())
    return

  try {
    const announcement = await fetchSiteAnnouncement()
    const text = String(announcement?.content || '').trim()
    if (!announcement?.enabled || !text)
      return
    content.value = text
    visible.value = true
    uni.setStorageSync(ANNOUNCEMENT_SHOWN_AT_KEY, String(Date.now()))
  }
  catch {
    // 公告属于非关键内容，加载失败时静默跳过，不影响站点使用。
  }
})
</script>

<template>
  <u-popup
    v-model="visible"
    mode="center"
    :border-radius="16"
    :z-index="10000"
    :mask-close-able="false"
  >
    <view class="psou-announcement">
      <view class="psou-announcement__head">
        <text class="psou-announcement__title">
          站点公告
        </text>
        <view class="psou-announcement__close" @click="visible = false">
          <u-icon name="close" size="14px" color="#9b9ba4" />
        </view>
      </view>
      <scroll-view scroll-y class="psou-announcement__scroll">
        <rich-text :nodes="content" class="psou-announcement__content" />
      </scroll-view>
      <view class="psou-announcement__footer">
        <PsouButton block @click="visible = false">
          我知道了
        </PsouButton>
      </view>
    </view>
  </u-popup>
</template>

<style lang="scss" scoped>
.psou-announcement {
  width: 86vw;
  max-width: 340px;
  padding: 22px;
  background: var(--psou-bg-soft);
}

.psou-announcement__head {
  display: flex;
  gap: 12px;
  align-items: center;
  justify-content: space-between;
}

.psou-announcement__title {
  color: var(--psou-text);
  font-size: $font-lg;
  font-weight: 600;
}

.psou-announcement__close {
  display: flex;
  width: 26px;
  height: 26px;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.06);
}

.psou-announcement__scroll {
  max-height: 46vh;
  margin-top: 14px;
}

.psou-announcement__content {
  display: block;
  color: var(--psou-text-2);
  font-size: $font-normal;
  line-height: 1.7;
  word-break: break-word;
}

.psou-announcement__content :deep(p) {
  margin: 0 0 8px;
}

.psou-announcement__content :deep(p:last-child) {
  margin-bottom: 0;
}

.psou-announcement__content :deep(a) {
  color: var(--psou-accent);
}

.psou-announcement__content :deep(img) {
  max-width: 100%;
  height: auto;
}

.psou-announcement__content :deep(ul),
.psou-announcement__content :deep(ol) {
  padding-left: 20px;
  margin: 8px 0;
}

.psou-announcement__footer {
  margin-top: 18px;
}

.psou-announcement__footer :deep(.psou-button) {
  color: #fff;
}

.psou-announcement__footer :deep(.psou-button:active) {
  opacity: 0.86;
}
</style>
