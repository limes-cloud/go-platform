<script setup lang="ts">
import { useTheme } from 'uview-pro'
import PsouAnnouncementPopup from '@/components/psou-announcement-popup/psou-announcement-popup.vue'

const { setDarkMode, setTheme } = useTheme()

setTheme('psou')
setDarkMode('dark')
</script>

<template>
  <u-config-provider>
    <slot />
    <PsouAnnouncementPopup />
    <u-toast global />
    <u-no-network />
  </u-config-provider>
</template>
