export function setWebIcon(path: string): void {
  // #ifdef H5
  if (typeof document === 'undefined') {
    return
  }
  const link
    = (document.querySelector('link[rel*=\'icon\']') as HTMLLinkElement)
      || document.createElement('link')
  link.rel = 'icon'
  link.href = path
  document.head.appendChild(link)
  // #endif
}
