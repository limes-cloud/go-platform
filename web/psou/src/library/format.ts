const sizeUnits = ['B', 'KB', 'MB', 'GB', 'TB']

export function formatBytes(size?: number | null) {
  if (size === undefined || size === null || !Number.isFinite(size) || size < 0)
    return '--'
  if (size === 0)
    return '0 B'

  let value = size
  let unitIndex = 0
  while (value >= 1024 && unitIndex < sizeUnits.length - 1) {
    value /= 1024
    unitIndex += 1
  }

  const digits = unitIndex === 0 || value >= 100 ? 0 : value >= 10 ? 1 : 2
  return `${Number(value.toFixed(digits))} ${sizeUnits[unitIndex]}`
}

export function formatFileType(name: string) {
  const extension = name.split('.').pop()
  return extension && extension !== name ? extension.toUpperCase() : '文件'
}

export function formatUnixDate(timestamp?: number | null, withTime = false) {
  if (!timestamp)
    return ''
  const date = new Date(timestamp * 1000)
  if (Number.isNaN(date.getTime()))
    return ''

  const pad = (value: number) => String(value).padStart(2, '0')
  const dateText = `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
  return withTime ? `${dateText} ${pad(date.getHours())}:${pad(date.getMinutes())}` : dateText
}
