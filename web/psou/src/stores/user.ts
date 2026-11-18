import type { User } from '@/api/system/type'
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { GetCurrentUser, Logout } from '@/api/system/api'
import { auth } from '@/library/auth'
import { setTrackerUser } from '@/library/tracker'

export const useUserStore = defineStore('userStore', () => {
  const info = ref<User>({} as User)
  const isLogin = ref(false)
  const initialized = ref(false)

  const hasToken = computed(() => auth.hasToken())

  function setUserInfo(value: User) {
    info.value = value
    setTrackerUser(value.id)
  }

  function setLoginStatus(value: boolean) {
    isLogin.value = value
  }

  function setToken(token: string) {
    auth.setToken(token)
  }

  async function refreshInfo() {
    if (!auth.hasToken()) {
      setLoginStatus(false)
      return undefined
    }
    const data = await GetCurrentUser()
    setUserInfo(data)
    setLoginStatus(true)
    return data
  }

  async function login(token: string) {
    setToken(token)
    return refreshInfo()
  }

  async function initUser() {
    if (initialized.value)
      return
    initialized.value = true
    if (!auth.hasToken())
      return

    try {
      await refreshInfo()
    }
    catch {
      auth.clearToken()
      setLoginStatus(false)
    }
  }

  function clearUser() {
    info.value = {} as User
    isLogin.value = false
    setTrackerUser('')
  }

  async function logout() {
    try {
      if (auth.hasToken())
        await Logout()
    }
    catch {
      // Local logout must still succeed when the remote session is unavailable.
    }
    finally {
      auth.clearToken()
      clearUser()
    }
  }

  return {
    info,
    isLogin,
    initialized,
    hasToken,
    refreshInfo,
    setUserInfo,
    setLoginStatus,
    setToken,
    login,
    initUser,
    clearUser,
    logout,
  }
})
