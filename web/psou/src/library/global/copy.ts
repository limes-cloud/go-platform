function copy(text: string, successText = '复制成功') {
  uni.setClipboardData({
    data: text,
    showToast: false,
    success() {
      // #ifndef MP-WEIXIN
      uni.$g?.utoast?.show({
        title: successText,
        type: 'success',
        duration: 2000,
      })
      // #endif
    },
    fail() {
      uni.$g?.utoast?.show({
        title: '复制失败',
        type: 'error',
        duration: 2000,
      })
    },
  })
}

export { copy }
