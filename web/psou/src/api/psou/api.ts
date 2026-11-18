import type {
  CategoryListReply,
  GetPublicResourceReply,
  GetResourceHomeReply,
  ListPublicResourcesReply,
  ResourceDownloadReply,
  SearchResourcesReply,
  SiteAnnouncement,
  SiteCopyright,
  TransferResourceReply,
  TransferResourceRequest,
} from './type'
import { request } from '@/library/request'

export function GetClientCategories() {
  return request.get<CategoryListReply>('/psou/api/categories')
}

export function GetClientCategoryChildren(parentId: number) {
  return request.get<CategoryListReply>('/psou/api/categories', {
    params: { parentId },
  })
}

export function GetClientResourceHome(categoryId: number) {
  return request.get<GetResourceHomeReply>('/psou/api/resource/home', {
    params: { categoryId },
  })
}

export function GetClientCategoryResources(
  categoryId: number,
  page = 1,
  pageSize = 20,
  orderBy: 'updatedAt' | 'weight' = 'updatedAt',
) {
  return request.get<ListPublicResourcesReply>('/psou/api/resources', {
    params: { categoryId, page, pageSize, orderBy, order: 'desc' },
  })
}

export function GetClientResourceDetail(resourceId: string | number) {
  return request.get<GetPublicResourceReply>('/psou/api/resource', {
    params: { id: resourceId },
  })
}

export function GetClientResourceDownload(resourceId: number, netdiskId: number) {
  return request.post<ResourceDownloadReply>('/psou/api/resource/download', {
    resourceId,
    netdiskId,
  })
}

export function GetClientPublicAnnouncement() {
  return request.get<SiteAnnouncement>('/psou/api/setting/announcement', {
    meta: { toast: false },
  })
}

export function GetClientPublicCopyright() {
  return request.get<SiteCopyright>('/psou/api/setting/copyright', {
    meta: { toast: false },
  })
}

export function IncrementResourceClick(id: number) {
  return request.post('/psou/api/resource/click', { id }, { meta: { toast: false } })
}

export function QuickSearchResources(keyword: string) {
  return request.post<SearchResourcesReply>('/psou/api/search/quick', { keyword }, { timeout: 35000 })
}

export function TransferResource(data: TransferResourceRequest) {
  return request.post<TransferResourceReply>('/psou/api/search/transfer', data, {
    timeout: 120000,
    meta: { toast: false },
  })
}
