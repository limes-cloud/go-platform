export default {
  parseTime,
  formatTime,
}

function parseTime(time: any, cFormat?: any) {
  if (arguments.length === 0 || !time) {
    return null
  }
  const format = cFormat || '{y}-{m}-{d} {h}:{i}:{s}'
  let date
  if (typeof time === 'object') {
    date = time
  }
  else {
    if (typeof time === 'string') {
      if (/^\d+$/.test(time)) {
        time = Number.parseInt(time as string, 10)
      }
      else {
        time = time.replace(/-/g, '/')
      }
    }

    if (typeof time === 'number' && time.toString().length === 10) {
      time *= 1000
    }
    date = new Date(time)
  }
  const formatObj: any = {
    y: date.getFullYear(),
    m: date.getMonth() + 1,
    d: date.getDate(),
    h: date.getHours(),
    i: date.getMinutes(),
    s: date.getSeconds(),
    a: date.getDay(),
  }
  return format.replace(/\{([ymdhisa])+\}/g, (result: any, key: string) => {
    const value = formatObj[key]
    if (key === 'a') {
      return ['日', '一', '二', '三', '四', '五', '六'][value]
    }
    return value.toString().padStart(2, '0')
  })
}

export function formatTime(time: any, option?: any) {
  if (!time) {
    return ''
  }

  if (`${time}`.length === 10) {
    time = Number.parseInt(time, 10) * 1000
  }
  else {
    time = +time
  }
  const d = new Date(time)
  const now = Date.now()

  const diff = (now - Number(d)) / 1000

  if (diff < 30) {
    return '刚刚'
  }
  if (diff < 3600) {
    // less 1 hour
    return `${Math.ceil(diff / 60)} 分钟前`
  }
  if (diff < 3600 * 24) {
    return `${Math.ceil(diff / 3600)} 小时前`
  }
  if (diff < 3600 * 24 * 2) {
    return `1天前`
  }

  return parseTime(time, option)
}
