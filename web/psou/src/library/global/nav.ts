import { openHomePage } from '@/library/navigation'
import { useUserStore } from '@/stores/user'

export default {
  home() {
    openHomePage()
  },
  to(path: string) {
    uni.navigateTo({ url: path })
  },
  back() {
    if (getCurrentPages().length > 1) {
      uni.navigateBack()
      return
    }
    this.home()
  },
  async logout() {
    const userStore = useUserStore()
    await userStore.logout()
    this.home()
  },
}
