function getPlatform() {
  const sys = uni.getSystemInfoSync()
  let platform = sys.uniPlatform

  // 易班APP
  if (sys.ua && sys.ua.includes('yiban')) {
    platform = 'web-yiban'
  }

  // 微信web
  if (sys.ua && sys.ua.includes('MicroMessenger')) {
    platform = 'web-weixin'
  }

  // 支付宝web
  if (sys.ua && sys.ua.includes('Alipay')) {
    platform = 'web-alipay'
  }

  // 抖音web
  if (sys.ua && sys.ua.includes('DiDi')) {
    platform = 'web-douyin'
  }

  return platform
}

export { getPlatform }
