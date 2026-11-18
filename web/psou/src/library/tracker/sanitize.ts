import type { TrackerProps } from './types'

const sensitiveKeys = [
  'password',
  'passwd',
  'token',
  'authorization',
  'cookie',
  'secret',
  'phone',
  'mobile',
  'idcard',
  'id_card',
  'credential',
  'shareurl',
  'share_url',
  'netdiskurl',
  'netdisk_url',
  'session',
]

const sensitiveExactKeys = ['q', 'wd', 'code', 'keyword', 'searchkeyword', 'search_keyword']

export function sanitizeTrackerProps(input?: Record<string, unknown>): TrackerProps {
  const result = sanitizeMap(input || {}, 0)
  try {
    if (JSON.stringify(result).length > 12_000)
      return { _truncated: true }
  }
  catch {
    return { _truncated: true }
  }
  return result
}

function sanitizeMap(input: Record<string, unknown>, depth: number): TrackerProps {
  if (depth > 4)
    return { _truncated: true }

  const result: TrackerProps = {}
  Object.keys(input).slice(0, 50).forEach((key) => {
    if (isSensitiveKey(key))
      return
    result[truncateString(key, 128)] = sanitizeValue(input[key], depth + 1)
  })
  return result
}

function sanitizeValue(value: unknown, depth: number): unknown {
  if (typeof value === 'string')
    return truncateString(value, 512)
  if (typeof value === 'number' || typeof value === 'boolean' || value === null || value === undefined)
    return value
  if (Array.isArray(value))
    return value.slice(0, 50).map(item => sanitizeValue(item, depth + 1))
  if (typeof value === 'object')
    return sanitizeMap(value as Record<string, unknown>, depth)
  return truncateString(String(value), 512)
}

function isSensitiveKey(key: string) {
  const normalized = key.trim().toLowerCase()
  if (sensitiveExactKeys.includes(normalized))
    return true
  return sensitiveKeys.some(item => normalized.includes(item))
}

function truncateString(value: string, limit: number) {
  return value.length > limit ? value.slice(0, limit) : value
}
