import type { ResourcePlatform } from './type'

export const platformMap = {
  quark: { label: '夸克', glyph: '夸', color: '#0e6bff', icon: '/static/platforms/quark.png' },
  baidu: { label: '百度', glyph: '百', color: '#2932e1', icon: '/static/platforms/baidu.png' },
  xunlei: { label: '迅雷', glyph: '迅', color: '#1f6fd6', icon: '/static/platforms/xunlei.png' },
} as const

export const platformOptions: ResourcePlatform[] = ['quark', 'baidu', 'xunlei']
