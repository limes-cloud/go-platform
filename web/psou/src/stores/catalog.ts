import type { Category, ChannelId } from '@/api/psou/type'
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { fetchCategoryChildren, fetchRootCategories } from '@/api/psou/service'

export const useCatalogStore = defineStore('catalog', () => {
  const channelId = ref<ChannelId>('film')
  const searchKeyword = ref('')
  const rootCategories = ref<Category[]>([])
  const childrenByParentId = ref<Record<string, Category[]>>({})
  const parentIdByCategoryId = ref<Record<string, number>>({})

  let rootCategoriesPromise: Promise<Category[]> | null = null
  const childrenPromises = new Map<number, Promise<Category[]>>()

  const homeCategory = computed(() => {
    return rootCategories.value.find(category => category.isHome) || rootCategories.value[0]
  })

  function setChannel(value: ChannelId) {
    channelId.value = value
  }

  function setSearchKeyword(value: string) {
    searchKeyword.value = value.trim()
  }

  async function ensureRootCategories(force = false): Promise<Category[]> {
    if (!force && rootCategories.value.length > 0)
      return rootCategories.value
    if (!force && rootCategoriesPromise)
      return rootCategoriesPromise

    rootCategoriesPromise = fetchRootCategories()
      .then((categories) => {
        rootCategories.value = categories
        return categories
      })
      .finally(() => {
        rootCategoriesPromise = null
      })
    return rootCategoriesPromise
  }

  async function ensureCategoryChildren(parentId: number, force = false): Promise<Category[]> {
    const key = String(parentId)
    if (!force && childrenByParentId.value[key])
      return childrenByParentId.value[key]
    if (!force && childrenPromises.has(parentId))
      return childrenPromises.get(parentId)!

    const promise = fetchCategoryChildren(parentId)
      .then((categories) => {
        childrenByParentId.value = {
          ...childrenByParentId.value,
          [key]: categories,
        }
        const parentMap = { ...parentIdByCategoryId.value }
        for (const category of categories)
          parentMap[String(category.id)] = parentId
        parentIdByCategoryId.value = parentMap
        return categories
      })
      .finally(() => {
        childrenPromises.delete(parentId)
      })

    childrenPromises.set(parentId, promise)
    return promise
  }

  function setCategoryParent(categoryId: number | string, parentId: number) {
    parentIdByCategoryId.value = {
      ...parentIdByCategoryId.value,
      [String(categoryId)]: parentId,
    }
  }

  async function resolveRootCategoryId(categoryId: number | string): Promise<number | undefined> {
    const numericId = Number(categoryId)
    if (!Number.isInteger(numericId) || numericId <= 0)
      return undefined

    await ensureRootCategories()
    if (rootCategories.value.some(category => category.id === numericId))
      return numericId

    const cachedParentId = parentIdByCategoryId.value[String(numericId)]
    if (cachedParentId)
      return cachedParentId

    const matches = await Promise.all(rootCategories.value.map(async (root) => {
      try {
        const children = await ensureCategoryChildren(root.id)
        return children.some(category => category.id === numericId) ? root.id : undefined
      }
      catch {
        return undefined
      }
    }))
    return matches.find((id): id is number => Boolean(id))
  }

  return {
    channelId,
    searchKeyword,
    rootCategories,
    homeCategory,
    setChannel,
    setSearchKeyword,
    ensureRootCategories,
    ensureCategoryChildren,
    setCategoryParent,
    resolveRootCategoryId,
  }
})
