<script setup lang="ts">
import type { SearchResultItem, TransferResourceReply } from '@/api/psou/type'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { platformMap } from '@/api/psou/platform'
import { copy } from '@/library/global/copy'

defineOptions({
  options: {
    addGlobalClass: true,
    styleIsolation: 'shared',
  },
})

const props = withDefaults(defineProps<{
  visible: boolean
  resource: SearchResultItem | null
  state: 'loading' | 'success' | 'error'
  result: TransferResourceReply | null
  errorMessage?: string
  isDesktop?: boolean
}>(), {
  errorMessage: '',
  isDesktop: false,
})

const emit = defineEmits<{
  close: []
  retry: []
}>()

const loadingTips = [
  '正在准备资源，请稍候...',
  '正在校验分享链接有效性...',
  '正在验证提取码...',
  '正在获取文件信息...',
  '正在分配转存账号...',
  '正在创建临时容器...',
  '正在转存文件（大文件可能需要一点时间）...',
  '正在整理文件...',
  '正在生成分享链接...',
  '马上就好，请稍候...',
]

const tipIndex = ref(0)
const remainingSeconds = ref(0)
const totalSeconds = ref(1)
const qrCodeUrl = ref('')
const qrLoading = ref(false)
const qrFailed = ref(false)
let tipTimer: ReturnType<typeof setInterval> | null = null
let countdownTimer: ReturnType<typeof setInterval> | null = null
let qrRequestId = 0

const shareUrl = computed(() => props.result?.shareUrl?.trim() || '')
// 百度分享链接会把提取码拼在 ?pwd= 上，夸克公开分享没有该参数
const extractCode = computed(() => {
  const matched = shareUrl.value.match(/[?&]pwd=([^&#]+)/)
  if (!matched)
    return ''
  try {
    return decodeURIComponent(matched[1]).trim()
  }
  catch {
    return matched[1].trim()
  }
})
const platformName = computed(() => {
  const platform = props.resource?.platform || ''
  if (platform === 'xunlei')
    return '迅雷'
  const label = platformMap[platform as keyof typeof platformMap]?.label
  return label ? `${label}网盘` : '网盘'
})
const currentTip = computed(() => loadingTips[tipIndex.value] || loadingTips[0])
const expiresAt = computed(() => Number(props.result?.expiresAt || 0))
const hasExpiry = computed(() => props.state === 'success' && expiresAt.value > 0)
const expired = computed(() => hasExpiry.value && remainingSeconds.value <= 0)
const progress = computed(() => {
  if (!hasExpiry.value)
    return 0
  return Math.max(0, Math.min(100, (remainingSeconds.value / totalSeconds.value) * 100))
})
const progressTone = computed(() => {
  if (progress.value <= 20)
    return 'danger'
  if (progress.value <= 50)
    return 'warn'
  return 'safe'
})
const progressStyle = computed(() => ({ width: `${progress.value}%` }))
const countdownText = computed(() => {
  if (expired.value)
    return '链接已过期，请重新提取'
  const minutes = Math.floor(remainingSeconds.value / 60)
  const seconds = remainingSeconds.value % 60
  return `${minutes}:${String(seconds).padStart(2, '0')} 后失效`
})
const copyContent = computed(() => shareUrl.value)

function stopTipTimer() {
  if (tipTimer) {
    clearInterval(tipTimer)
    tipTimer = null
  }
}

function startTipTimer() {
  stopTipTimer()
  tipIndex.value = 0
  tipTimer = setInterval(() => {
    tipIndex.value = (tipIndex.value + 1) % loadingTips.length
  }, 2000)
}

function stopCountdown() {
  if (countdownTimer) {
    clearInterval(countdownTimer)
    countdownTimer = null
  }
}

function tickCountdown() {
  const remain = expiresAt.value - Math.floor(Date.now() / 1000)
  remainingSeconds.value = Math.max(0, remain)
  if (remain <= 0)
    stopCountdown()
}

function startCountdown() {
  stopCountdown()
  if (!props.visible || props.state !== 'success' || !hasExpiry.value) {
    remainingSeconds.value = 0
    totalSeconds.value = 1
    return
  }
  totalSeconds.value = Math.max(1, expiresAt.value - Math.floor(Date.now() / 1000))
  tickCountdown()
  if (remainingSeconds.value > 0)
    countdownTimer = setInterval(tickCountdown, 1000)
}

async function generateQrCode() {
  const requestId = ++qrRequestId
  qrCodeUrl.value = ''
  qrLoading.value = false
  qrFailed.value = false

  if (!props.visible || props.state !== 'success' || !props.isDesktop || !shareUrl.value)
    return

  // #ifdef H5
  qrLoading.value = true
  try {
    const { toDataURL } = await import('qrcode')
    const url = await toDataURL(shareUrl.value, {
      width: 220,
      margin: 1,
      errorCorrectionLevel: 'M',
      color: { dark: '#05070f', light: '#ffffff' },
    })
    if (requestId === qrRequestId)
      qrCodeUrl.value = url
  }
  catch {
    if (requestId === qrRequestId)
      qrFailed.value = true
  }
  finally {
    if (requestId === qrRequestId)
      qrLoading.value = false
  }
  // #endif
}

watch(
  () => [props.visible, props.state] as const,
  ([visible, state]) => {
    if (visible && state === 'loading')
      startTipTimer()
    else
      stopTipTimer()
  },
  { immediate: true },
)

watch(
  () => [props.visible, props.state, props.result?.expiresAt] as const,
  () => startCountdown(),
  { immediate: true },
)

watch(
  () => [props.visible, props.state, props.isDesktop, shareUrl.value] as const,
  () => {
    void generateQrCode()
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  stopTipTimer()
  stopCountdown()
})

function closeDialog() {
  emit('close')
}

function retryTransfer() {
  if (!expired.value)
    return
  emit('retry')
}

function copyLink() {
  if (!copyContent.value || expired.value)
    return
  copy(copyContent.value, '链接已复制')
}
</script>

<template>
  <view v-if="visible" class="psou-transfer">
    <view class="psou-transfer__backdrop" @click="closeDialog" />
    <view class="psou-transfer__panel" @click.stop>
      <view class="psou-transfer__header">
        <text class="psou-transfer__title">
          资源提取
        </text>
        <view class="psou-transfer__close" @click="closeDialog">
          <u-icon name="close" size="16px" color="var(--psou-text-2)" />
        </view>
      </view>

      <view class="psou-transfer__body">
        <text class="psou-transfer__resource">
          {{ resource?.title || '未命名资源' }}
        </text>

        <view v-if="state === 'loading'" class="psou-transfer__loading">
          <text :key="currentTip" class="psou-transfer__tip">
            {{ currentTip }}
          </text>
        </view>

        <view v-else-if="state === 'error'" class="psou-transfer__error">
          <view class="psou-transfer__error-mark">
            !
          </view>
          <text class="psou-transfer__error-text">
            {{ errorMessage || '提取失败，请稍后重试' }}
          </text>
        </view>

        <view v-else-if="state === 'success' && result" class="psou-transfer__result" :class="{ 'is-expired': expired }">
          <!-- #ifdef H5 -->
          <view v-if="isDesktop" class="psou-transfer__qr">
            <view v-if="qrCodeUrl" class="psou-transfer__qr-frame">
              <image class="psou-transfer__qr-image" :src="qrCodeUrl" mode="aspectFit" />
            </view>
            <view v-else-if="qrLoading" class="psou-transfer__qr-loading">
              <view class="psou-transfer__spinner" />
              <text>生成二维码...</text>
            </view>
            <a
              v-else-if="qrFailed && shareUrl"
              class="psou-transfer__qr-failed psou-transfer__qr-link"
              :href="shareUrl"
              target="_blank"
              rel="noopener noreferrer"
              referrerpolicy="no-referrer"
            >
              无法生成二维码，点此打开链接
            </a>
            <text v-else class="psou-transfer__qr-failed">
              未生成分享链接
            </text>
            <text class="psou-transfer__scan-tip">
              使用「{{ platformName }}」App 扫码，保存到你的网盘
            </text>
            <view v-if="extractCode" class="psou-transfer__extract-code">
              <text>
                提取码
              </text>
              <text class="psou-transfer__extract-value">
                {{ extractCode }}
              </text>
            </view>
          </view>
          <!-- #endif -->

          <view class="psou-transfer__actions">
            <!-- #ifdef H5 -->
            <a
              v-if="!isDesktop"
              class="psou-transfer__action psou-transfer__action--primary"
              :class="{ 'is-disabled': expired }"
              :href="expired ? undefined : shareUrl"
              target="_blank"
              rel="noopener noreferrer"
              referrerpolicy="no-referrer"
            >
              打开分享链接
            </a>
            <!-- #endif -->

            <!-- #ifndef H5 -->
            <view
              class="psou-transfer__action psou-transfer__action--primary"
              :class="{ 'is-disabled': expired }"
              @click="copyLink"
            >
              复制分享链接
            </view>
            <!-- #endif -->
          </view>

          <view v-if="hasExpiry" class="psou-transfer__timer">
            <view class="psou-transfer__progress">
              <view class="psou-transfer__progress-bar" :class="`is-${progressTone}`" :style="progressStyle" />
            </view>
            <text class="psou-transfer__countdown" :class="{ 'is-expired': expired }">
              {{ countdownText }}
            </text>
          </view>

          <text v-if="hasExpiry && !expired" class="psou-transfer__hint">
            链接有效期有限，请尽快保存到你的网盘
          </text>
        </view>
      </view>

      <view class="psou-transfer__footer">
        <view class="psou-transfer__footer-btn" @click="closeDialog">
          关闭
        </view>
        <view
          v-if="expired"
          class="psou-transfer__footer-btn psou-transfer__footer-btn--primary"
          @click="retryTransfer"
        >
          重新提取
        </view>
      </view>
    </view>
  </view>
</template>

<style lang="scss" scoped>
.psou-transfer {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  z-index: 10000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.psou-transfer__backdrop {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  background: rgba(3, 5, 12, 0.72);
  backdrop-filter: blur(6px);
  animation: psou-transfer-fade-in 0.2s ease;
}

.psou-transfer__panel {
  position: relative;
  z-index: 1;
  display: flex;
  width: 460px;
  max-width: 100%;
  max-height: calc(100vh - 40px);
  flex-direction: column;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.14);
  border-radius: 18px;
  background: rgba(20, 24, 42, 0.98);
  box-shadow: 0 24px 64px rgba(0, 0, 0, 0.6), inset 0 1px 0 rgba(255, 255, 255, 0.08);
  animation: psou-transfer-in 0.2s ease;
}

.psou-transfer__header {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.psou-transfer__title {
  color: var(--psou-text);
  font-size: $font-lg;
  font-weight: 600;
}

.psou-transfer__close {
  display: flex;
  width: 32px;
  height: 32px;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.06);
  cursor: pointer;
}

.psou-transfer__body {
  min-height: 0;
  flex: 1;
  overflow-y: auto;
  padding: 20px;
}

.psou-transfer__resource {
  display: block;
  color: var(--psou-text-2);
  font-size: $font-normal;
  line-height: 1.5;
  overflow-wrap: anywhere;
  word-break: break-word;
}

.psou-transfer__loading {
  display: flex;
  min-height: 210px;
  align-items: center;
  flex-direction: column;
  justify-content: center;
  gap: 18px;
  padding: 20px 0;
}

.psou-transfer__spinner {
  width: 30px;
  height: 30px;
  border: 2px solid rgba(255, 255, 255, 0.12);
  border-top-color: var(--psou-accent);
  border-radius: 50%;
  animation: psou-transfer-spin 0.8s linear infinite;
}

.psou-transfer__tip {
  color: var(--psou-text-2);
  font-size: $font-normal;
  line-height: 1.6;
  text-align: center;
  animation: psou-transfer-tip-in 0.4s ease;
}

.psou-transfer__error {
  display: flex;
  min-height: 180px;
  align-items: center;
  flex-direction: column;
  justify-content: center;
  gap: 14px;
  padding: 20px 8px;
}

.psou-transfer__error-mark {
  display: flex;
  width: 36px;
  height: 36px;
  align-items: center;
  justify-content: center;
  border: 1px solid rgba(248, 113, 113, 0.4);
  border-radius: 50%;
  color: #fca5a5;
  font-size: $font-lgxx;
  font-weight: 700;
  background: rgba(248, 113, 113, 0.1);
}

.psou-transfer__error-text {
  color: #fca5a5;
  font-size: $font-normal;
  line-height: 1.6;
  text-align: center;
}

.psou-transfer__result {
  display: flex;
  align-items: center;
  flex-direction: column;
  padding-top: 16px;
}

.psou-transfer__result.is-expired {
  opacity: 0.55;
}

.psou-transfer__qr {
  display: flex;
  align-items: center;
  flex-direction: column;
}

.psou-transfer__qr-frame {
  display: flex;
  width: 220px;
  height: 220px;
  align-items: center;
  justify-content: center;
  padding: 6px;
  border-radius: 14px;
  background: #fff;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.35);
}

.psou-transfer__qr-image {
  width: 208px;
  height: 208px;
}

.psou-transfer__qr-loading {
  display: flex;
  width: 220px;
  height: 220px;
  align-items: center;
  flex-direction: column;
  justify-content: center;
  gap: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 14px;
  color: var(--psou-text-3);
  font-size: $font-xs;
  background: rgba(255, 255, 255, 0.04);
}

.psou-transfer__qr-failed {
  display: block;
  width: 220px;
  padding: 28px 16px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 14px;
  color: var(--psou-text-2);
  font-size: $font-xs;
  line-height: 1.6;
  text-align: center;
  background: rgba(255, 255, 255, 0.04);
}

.psou-transfer__qr-link {
  text-decoration: none;
}

.psou-transfer__scan-tip {
  margin-top: 12px;
  color: var(--psou-text-2);
  font-size: $font-normal;
  text-align: center;
}

.psou-transfer__extract-code {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  margin-top: 10px;
  color: var(--psou-text-2);
  font-size: $font-normal;
}

.psou-transfer__extract-value {
  color: var(--psou-text);
  font-weight: 600;
  letter-spacing: 2px;
}

.psou-transfer__actions {
  display: flex;
  width: 100%;
  justify-content: center;
  gap: 10px;
  margin-top: 16px;
}

.psou-transfer__action {
  display: inline-flex;
  height: 38px;
  align-items: center;
  justify-content: center;
  padding: 0 20px;
  border-radius: 10px;
  font-size: $font-normal;
  font-weight: 500;
  text-decoration: none;
  cursor: pointer;
}

.psou-transfer__action--primary {
  color: #fff;
  background: linear-gradient(135deg, #22c7d8, #246bfd);
  box-shadow: 0 4px 14px rgba(36, 107, 253, 0.3);
}

.psou-transfer__action.is-disabled,
.psou-transfer__password.is-disabled {
  opacity: 0.45;
  pointer-events: none;
}

.psou-transfer__password {
  display: flex;
  align-items: center;
  gap: 7px;
  margin-top: 16px;
  padding: 8px 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 9px;
  color: var(--psou-text-2);
  font-size: $font-normal;
  background: rgba(255, 255, 255, 0.04);
}

.psou-transfer__password-label {
  color: var(--psou-text-3);
}

.psou-transfer__password-code {
  color: #a5b4fc;
  font-weight: 600;
  letter-spacing: 0.08em;
}

.psou-transfer__timer {
  width: 100%;
  max-width: 260px;
  margin-top: 18px;
}

.psou-transfer__progress {
  height: 6px;
  overflow: hidden;
  border-radius: 3px;
  background: rgba(255, 255, 255, 0.1);
}

.psou-transfer__progress-bar {
  height: 100%;
  border-radius: 3px;
  transition: width 1s linear;
}

.psou-transfer__progress-bar.is-safe {
  background: #34d399;
}

.psou-transfer__progress-bar.is-warn {
  background: #fbbf24;
}

.psou-transfer__progress-bar.is-danger {
  background: #f87171;
}

.psou-transfer__countdown {
  display: block;
  margin-top: 7px;
  color: var(--psou-text-2);
  font-size: $font-normal;
  text-align: center;
}

.psou-transfer__countdown.is-expired {
  color: #fca5a5;
  font-weight: 600;
}

.psou-transfer__hint {
  margin-top: 10px;
  color: #fcd34d;
  font-size: $font-xs;
  text-align: center;
}

.psou-transfer__footer {
  display: flex;
  flex: 0 0 auto;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 20px 18px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.psou-transfer__footer-btn {
  display: inline-flex;
  height: 36px;
  align-items: center;
  justify-content: center;
  padding: 0 16px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 9px;
  color: var(--psou-text-2);
  font-size: $font-normal;
  background: rgba(255, 255, 255, 0.06);
  cursor: pointer;
}

.psou-transfer__footer-btn--primary {
  border-color: transparent;
  color: #fff;
  background: linear-gradient(135deg, #22c7d8, #246bfd);
}

@keyframes psou-transfer-fade-in {
  from {
    opacity: 0;
  }

  to {
    opacity: 1;
  }
}

@keyframes psou-transfer-in {
  from {
    opacity: 0;
    transform: translateY(12px) scale(0.97);
  }

  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@keyframes psou-transfer-spin {
  to {
    transform: rotate(360deg);
  }
}

@keyframes psou-transfer-tip-in {
  from {
    opacity: 0.2;
    transform: translateY(4px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (max-width: 767px) {
  .psou-transfer {
    padding: 16px;
  }

  .psou-transfer__panel {
    max-height: calc(100vh - 32px);
  }

  .psou-transfer__header {
    padding: 14px 16px;
  }

  .psou-transfer__body {
    padding: 16px;
  }

  .psou-transfer__footer {
    padding: 12px 16px;
  }
}
</style>
