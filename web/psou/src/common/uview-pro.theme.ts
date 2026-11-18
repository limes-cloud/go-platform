export interface UViewTheme {
  name: string
  label: string
  color: Record<string, string>
  darkColor: Record<string, string>
}

const darkPalette = {
  primary: '#38d6e4',
  error: '#f87171',
  warning: '#fbbf24',
  success: '#4ade80',
  info: '#94a3b8',
  primaryLight: '#0b3035',
  errorLight: '#450a0a',
  warningLight: '#451a03',
  successLight: '#052e16',
  infoLight: '#1e293b',
  primaryDark: '#7ce7ee',
  errorDark: '#fca5a5',
  warningDark: '#fcd34d',
  successDark: '#86efac',
  infoDark: '#cbd5e1',
  primaryDisabled: '#164b51',
  errorDisabled: '#7f1d1d',
  warningDisabled: '#78350f',
  successDisabled: '#14532d',
  infoDisabled: '#334155',
  bgColor: '#05070f',
  bgWhite: '#11141d',
  bgGrayLight: '#080b18',
  bgGrayDark: '#1a1e2a',
  bgBlack: '#05070f',
  borderColor: 'rgba(255, 255, 255, 0.08)',
  lightColor: '#1a1e2a',
  mainColor: '#f5f5f7',
  contentColor: '#9b9ba4',
  tipsColor: '#686871',
  whiteColor: '#ffffff',
  blackColor: '#05070f',
  dividerColor: 'rgba(255, 255, 255, 0.08)',
  maskColor: 'rgba(0, 0, 0, 0.58)',
  shadowColor: 'rgba(0, 0, 0, 0.34)',
}

const themes: UViewTheme[] = [
  {
    name: 'psou',
    label: '盘搜黑',
    color: darkPalette,
    darkColor: darkPalette,
  },
]

export default themes
