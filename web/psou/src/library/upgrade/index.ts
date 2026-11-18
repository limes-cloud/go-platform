export function autoUpgradeVersion() {
  // #ifdef MP

  const updateManager = uni.getUpdateManager()
  updateManager.onCheckForUpdate(() => {})

  updateManager.onUpdateReady(() => {
    uni.showModal({
      title: '更新提示',
      content: '新版本已经准备好，是否重启应用？',
      success(res) {
        if (res.confirm) {
          // 新的版本已经下载好，调用 applyUpdate 应用新版本并重启
          updateManager.applyUpdate()
        }
      },
    })
  })

  updateManager.onUpdateFailed(() => {
    uni.showToast({
      title: '新版本下载失败，请手动重启尝试',
      duration: 2000,
      icon: 'none',
      mask: true,
    })
  })
  // #endif
}
