import type { Category, ChannelId, CoverTone, Resource, ResourceItem } from '@/api/psou/type'
import { formatTime } from '@/library/global/time'

const coverTones: CoverTone[] = ['blue', 'teal', 'gold', 'rose', 'violet', 'indigo']

interface ResourceViewOptions {
  category?: Category
  channelId?: ChannelId
}

export function toResourceItem(
  resource: Resource,
  index: number,
  options: ResourceViewOptions = {},
): ResourceItem {
  return {
    id: String(resource.id),
    channelId: options.channelId || 'film',
    categoryId: options.category ? String(options.category.id) : '',
    categoryName: options.category?.name || '',
    title: resource.title,
    cover: resource.cover,
    description: resource.summary,
    score: resource.score === null ? '' : resource.score.toFixed(1),
    size: '',
    format: resource.tags[0] || '资源',
    updatedAt: formatTime(resource.updatedAt, '{m}-{d}'),
    platform: 'quark',
    coverTone: coverTones[(resource.id + index) % coverTones.length],
    glyph: Array.from(resource.title)[0] || '资',
    keywords: resource.tags,
    files: [],
    shareUrl: '',
    viewCount: Number(resource.viewCount) || 0,
    clickCount: Number(resource.clickCount) || 0,
    bannerFocusX: resource.bannerFocusX ?? 0.5,
    bannerFocusY: resource.bannerFocusY ?? 0.5,
  }
}
