<script setup lang="ts">
import { onLaunch } from '@dcloudio/uni-app'
import { useCatalogStore } from '@/stores/catalog'

defineOptions({ name: 'App' })

const catalog = useCatalogStore()

onLaunch(() => {
  void catalog.ensureRootCategories().catch(() => {})
})
</script>

<style lang="scss">
@import "uview-pro/index.scss";
@import "common/style.scss";
</style>
