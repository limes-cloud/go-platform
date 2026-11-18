interface RgbColor {
  r: number
  g: number
  b: number
}

interface HslColor {
  h: number
  s: number
  l: number
}

export interface SoftTintedPalette {
  deep: string
  base: string
  lift: string
  accent: string
  ink: string
  inkSoft: string
}

function parseHexColor(value?: string): RgbColor | null {
  if (!value)
    return null

  let hex = value.trim().replace(/^#/, '')
  if (hex.length === 3)
    hex = hex.split('').map(char => `${char}${char}`).join('')
  if (!/^[\da-f]{6}$/i.test(hex))
    return null

  return {
    r: Number.parseInt(hex.slice(0, 2), 16),
    g: Number.parseInt(hex.slice(2, 4), 16),
    b: Number.parseInt(hex.slice(4, 6), 16),
  }
}

function toHex(value: number) {
  return Math.round(Math.min(255, Math.max(0, value))).toString(16).padStart(2, '0')
}

export function normalizeHexColor(value?: string) {
  const color = parseHexColor(value)
  if (!color)
    return ''
  return `#${toHex(color.r)}${toHex(color.g)}${toHex(color.b)}`
}

export function mixHexColor(base: string, target: string, targetWeight: number) {
  const baseColor = parseHexColor(base)
  const targetColor = parseHexColor(target)
  if (!baseColor || !targetColor)
    return base

  const weight = Math.min(1, Math.max(0, targetWeight))
  return `#${toHex(baseColor.r * (1 - weight) + targetColor.r * weight)}${
    toHex(baseColor.g * (1 - weight) + targetColor.g * weight)
  }${toHex(baseColor.b * (1 - weight) + targetColor.b * weight)}`
}

export function hexToRgba(value: string, alpha: number) {
  const color = parseHexColor(value)
  if (!color)
    return `rgba(0, 0, 0, ${alpha})`
  return `rgba(${color.r}, ${color.g}, ${color.b}, ${alpha})`
}

function rgbToHsl(color: RgbColor): HslColor {
  const r = color.r / 255
  const g = color.g / 255
  const b = color.b / 255
  const max = Math.max(r, g, b)
  const min = Math.min(r, g, b)
  const delta = max - min
  const l = (max + min) / 2

  if (delta === 0)
    return { h: 0, s: 0, l: l * 100 }

  const s = delta / (1 - Math.abs(2 * l - 1))
  let h = 0
  if (max === r)
    h = ((g - b) / delta) % 6
  else if (max === g)
    h = (b - r) / delta + 2
  else
    h = (r - g) / delta + 4

  return { h: (h * 60 + 360) % 360, s: s * 100, l: l * 100 }
}

function hueToChannel(p: number, q: number, t: number) {
  let value = t
  if (value < 0)
    value += 1
  if (value > 1)
    value -= 1
  if (value < 1 / 6)
    return p + (q - p) * 6 * value
  if (value < 1 / 2)
    return q
  if (value < 2 / 3)
    return p + (q - p) * (2 / 3 - value) * 6
  return p
}

function hslToHex(h: number, s: number, l: number) {
  const saturation = Math.min(100, Math.max(0, s)) / 100
  const lightness = Math.min(100, Math.max(0, l)) / 100
  if (saturation === 0)
    return `#${toHex(lightness * 255)}${toHex(lightness * 255)}${toHex(lightness * 255)}`

  const q = lightness < 0.5
    ? lightness * (1 + saturation)
    : lightness + saturation - lightness * saturation
  const p = 2 * lightness - q
  const hue = (((h % 360) + 360) % 360) / 360
  return `#${toHex(hueToChannel(p, q, hue + 1 / 3) * 255)}${
    toHex(hueToChannel(p, q, hue) * 255)
  }${toHex(hueToChannel(p, q, hue - 1 / 3) * 255)}`
}

export function deriveSoftTintedPalette(value: string): SoftTintedPalette | null {
  const color = parseHexColor(value)
  if (!color)
    return null

  const hsl = rgbToHsl(color)
  const neutral = hsl.s < 8
  const chroma = neutral ? 0 : Math.min(68, Math.max(28, hsl.s))
  const inkChroma = neutral ? 0 : chroma * 0.14

  return {
    deep: hslToHex(hsl.h, chroma * 0.34, 20),
    base: hslToHex(hsl.h, chroma * 0.42, 27),
    lift: hslToHex(hsl.h, chroma * 0.38, 35),
    accent: hslToHex(hsl.h, neutral ? 0 : Math.min(78, chroma * 0.95), 74),
    ink: hslToHex(hsl.h, inkChroma, 97),
    inkSoft: hslToHex(hsl.h, inkChroma, 82),
  }
}
