export const PSOU_ROUTES = {
  home: '/pages/index/index',
  category: '/pages/category/index',
  categoryDetail: '/pages/category/detail',
  catalogChannel: '/pages/category/channel',
  resourceDetail: '/pages/resource/detail',
  search: '/pages/search/index',
} as const

function currentRoute() {
  const pages = getCurrentPages()
  return pages[pages.length - 1]?.route || ''
}

function withQuery(path: string, query: Record<string, string | undefined>) {
  const params = Object.entries(query)
    .filter((entry): entry is [string, string] => Boolean(entry[1]))
    .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
    .join('&')
  return params ? `${path}?${params}` : path
}

export function openHomePage(catalogId?: number | string) {
  if (catalogId === undefined && currentRoute().includes('pages/index/index')) {
    uni.pageScrollTo({ scrollTop: 0, duration: 200 })
    return
  }
  uni.reLaunch({
    url: withQuery(PSOU_ROUTES.home, {
      catalogId: catalogId === undefined ? undefined : String(catalogId),
    }),
  })
}

export function openCatalogChannelPage(catalogId: number | string) {
  uni.navigateTo({
    url: withQuery(PSOU_ROUTES.catalogChannel, {
      catalogId: String(catalogId),
    }),
  })
}

export function openSearchPage() {
  uni.reLaunch({ url: PSOU_ROUTES.search })
}

export function openCategoryDetailPage(
  categoryId: string | number,
  options: { replace?: boolean } = {},
) {
  const url = withQuery(PSOU_ROUTES.categoryDetail, {
    category: String(categoryId),
  })
  if (options.replace)
    uni.redirectTo({ url })
  else
    uni.navigateTo({ url })
}

export function openResourceDetailPage(
  resourceId: string | number,
  options: { catalogId?: number | string } = {},
) {
  uni.navigateTo({
    url: withQuery(PSOU_ROUTES.resourceDetail, {
      resourceId: String(resourceId),
      catalogId: options.catalogId === undefined ? undefined : String(options.catalogId),
    }),
  })
}

export function goBackOrRoute(fallback: string) {
  if (getCurrentPages().length > 1)
    uni.navigateBack()
  else
    uni.reLaunch({ url: fallback })
}

export function syncCatalogQuery(catalogId?: number | string) {
  // #ifdef H5
  if (typeof window === 'undefined')
    return

  const url = new URL(window.location.href)
  if (url.hash) {
    const [hashPath, hashQuery = ''] = url.hash.slice(1).split('?')
    const params = new URLSearchParams(hashQuery)
    if (catalogId === undefined)
      params.delete('catalogId')
    else
      params.set('catalogId', String(catalogId))
    const nextQuery = params.toString()
    url.hash = nextQuery ? `${hashPath}?${nextQuery}` : hashPath
  }
  else {
    if (catalogId === undefined)
      url.searchParams.delete('catalogId')
    else
      url.searchParams.set('catalogId', String(catalogId))
  }
  window.history.replaceState(window.history.state, '', url)
  // #endif
}
