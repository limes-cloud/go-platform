export interface SearchResourcesRequest {
  keyword: string
}

export interface SearchResultItem {
  platform: string
  title: string
  token: string
  source: string
}

export interface SearchResourcesReply {
  list: SearchResultItem[]
}

export interface TransferResourceRequest {
  token: string
}

export interface TransferResourceReply {
  shareUrl: string
  expiresAt: number
}

export type ChannelId = 'film' | 'music' | 'game' | 'software' | 'course' | 'doc' | 'material'

export type CoverTone = 'blue' | 'teal' | 'gold' | 'rose' | 'violet' | 'indigo'

export type ResourcePlatform = 'quark' | 'baidu' | 'xunlei'

export interface Category {
  id: number
  parentId: number
  name: string
  icon: string
  iconColor?: string
  isHome: boolean
}

export interface CategoryListReply {
  list: Category[]
}

export interface Resource {
  id: number
  title: string
  summary: string
  description?: string
  cover: string
  tags: string[]
  score: number | null
  updatedAt: number
  viewCount: number
  clickCount: number
  bannerFocusX?: number
  bannerFocusY?: number
}

export interface NetdiskFile {
  name: string
  path: string
  isDir: boolean
  size: string
  children?: NetdiskFile[]
}

export interface Netdisk {
  id: number
  platform: string
  size: string
  formatSummary: string
  fileCount: number
  files: NetdiskFile[]
  updatedAt: number
}

export interface ResourceSection {
  category: Category
  resources: Resource[]
}

export interface GetResourceHomeReply {
  category: Category
  banners: Resource[]
  sections: ResourceSection[]
}

export interface ClientPagination {
  page: number
  pageSize: number
  total: number
}

export interface CategoryResourcesReply {
  resources: Resource[]
  pagination: ClientPagination
}

export interface ListPublicResourcesReply {
  total: number
  list: Resource[]
}

export interface Channel {
  id: ChannelId
  name: string
  icon: string
  glyph: string
  count: string
}

export interface CategoryView {
  id: string
  parentId?: number
  channelId: ChannelId
  name: string
  icon?: string
  iconColor?: string
  count?: string
}

export interface ResourceFile {
  name: string
  type: string
  size: string
}

export interface ResourceItem {
  id: string
  channelId: ChannelId
  categoryId: string
  categoryName: string
  title: string
  cover: string
  description: string
  score: string
  size: string
  format: string
  updatedAt: string
  platform: ResourcePlatform
  coverTone: CoverTone
  glyph: string
  keywords: string[]
  files: ResourceFile[]
  shareUrl: string
  viewCount: number
  clickCount: number
  bannerFocusX: number
  bannerFocusY: number
}

export interface BannerItem {
  resource: ResourceItem
  tags: string[]
}

export interface HomeSection {
  category: Category
  resources: ResourceItem[]
}

export interface ChannelListReply {
  channels: Channel[]
}

export interface CategoryIndexReply {
  channels: Channel[]
  channel: Channel
  categories: CategoryView[]
}

export interface CategoryDetailReply {
  channels: Channel[]
  channel: Channel
  category: CategoryView
  categories: CategoryView[]
  resources: ResourceItem[]
}

export interface ResourceDetailReply extends Resource {
  description: string
  netdisks: Netdisk[]
}

export interface GetPublicResourceReply {
  resource: ResourceDetailReply
}

export interface ResourceDownloadReply {
  downloadUrl: string
  platform: string
}

export interface SiteAnnouncement {
  enabled: boolean
  content: string
}

export interface SiteCopyright {
  content: string
}
