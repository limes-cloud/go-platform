import { ref } from 'vue'

const TOKEN_KEY = `psou-client-token`
const token = ref('')
let loaded = false

function hydrate() {
  if (loaded)
    return
  loaded = true
  token.value = String(uni.getStorageSync(TOKEN_KEY) || '')
}

export const auth = {
  token,
  hasToken() {
    hydrate()
    return !!token.value
  },
  getToken() {
    hydrate()
    return token.value
  },
  setToken(value: string) {
    loaded = true
    token.value = value
    return uni.setStorageSync(TOKEN_KEY, value)
  },
  clearToken() {
    loaded = true
    token.value = ''
    return uni.removeStorageSync(TOKEN_KEY)
  },
}
