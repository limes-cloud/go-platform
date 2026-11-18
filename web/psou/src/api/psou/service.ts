import type {
  Category,
  CategoryResourcesReply,
  GetResourceHomeReply,
  ResourceDetailReply,
  SearchResourcesReply,
  SiteAnnouncement,
  SiteCopyright,
  TransferResourceReply,
} from './type'
import {
  GetClientCategories,
  GetClientCategoryChildren,
  GetClientCategoryResources,
  GetClientPublicAnnouncement,
  GetClientPublicCopyright,
  GetClientResourceDetail,
  GetClientResourceHome,
  GetClientResourceURL,
  IncrementResourceClick,
  QuickSearchResources,
  TransferResource,
} from './api'

export async function fetchRootCategories(): Promise<Category[]> {
  const reply = await GetClientCategories()
  return Array.isArray(reply?.list) ? reply.list : []
}

export async function fetchCategoryChildren(parentId: number): Promise<Category[]> {
  const reply = await GetClientCategoryChildren(parentId)
  return Array.isArray(reply?.list) ? reply.list : []
}

export function fetchResourceHome(categoryId: number): Promise<GetResourceHomeReply> {
  return GetClientResourceHome(categoryId)
}

export function fetchCategoryResources(
  categoryId: number,
  page = 1,
  pageSize = 20,
  orderBy: 'updatedAt' | 'weight' = 'updatedAt',
): Promise<CategoryResourcesReply> {
  return GetClientCategoryResources(categoryId, page, pageSize, orderBy).then(reply => ({
    resources: Array.isArray(reply?.list) ? reply.list : [],
    pagination: { page, pageSize, total: Number(reply?.total) || 0 },
  }))
}

export async function fetchResourceDetail(resourceId: string | number): Promise<ResourceDetailReply> {
  const reply = await GetClientResourceDetail(resourceId)
  return reply.resource
}

export function fetchResourceURL(resourceId: number, netdiskId: number) {
  return GetClientResourceURL(resourceId, netdiskId)
}

export async function incrementResourceClick(resourceId: number): Promise<void> {
  await IncrementResourceClick(resourceId)
}

export function quickSearchResources(keyword: string): Promise<SearchResourcesReply> {
  return QuickSearchResources(keyword.trim())
}

export function transferSearchResource(token: string): Promise<TransferResourceReply> {
  return TransferResource({ token })
}

export function fetchSiteAnnouncement(): Promise<SiteAnnouncement> {
  return GetClientPublicAnnouncement()
}

export function fetchSiteCopyright(): Promise<SiteCopyright> {
  return GetClientPublicCopyright()
}
