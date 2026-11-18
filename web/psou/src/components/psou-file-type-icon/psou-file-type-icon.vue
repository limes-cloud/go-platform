<script setup lang="ts">
import { computed } from 'vue'
import audioIcon from '@/static/icons/file-type/audio.png'
import confIcon from '@/static/icons/file-type/conf.png'
import dirIcon from '@/static/icons/file-type/dir.png'
import docIcon from '@/static/icons/file-type/doc.png'
import imageIcon from '@/static/icons/file-type/image.png'
import otherIcon from '@/static/icons/file-type/other.png'
import pdfIcon from '@/static/icons/file-type/pdf.png'
import pptIcon from '@/static/icons/file-type/ppt.png'
import txtIcon from '@/static/icons/file-type/txt.png'
import videoIcon from '@/static/icons/file-type/video.png'
import webIcon from '@/static/icons/file-type/web.png'
import xlsIcon from '@/static/icons/file-type/xls.png'
import zipIcon from '@/static/icons/file-type/zip.png'

const props = withDefaults(defineProps<{
  name: string
  dir?: boolean
  size?: string
}>(), {
  dir: false,
  size: '16px',
})

const iconMap: Record<string, string> = {
  audio: audioIcon,
  conf: confIcon,
  dir: dirIcon,
  doc: docIcon,
  image: imageIcon,
  other: otherIcon,
  pdf: pdfIcon,
  ppt: pptIcon,
  txt: txtIcon,
  video: videoIcon,
  web: webIcon,
  xls: xlsIcon,
  zip: zipIcon,
}

const iconSrc = computed(() => iconMap[resolveFileType(props.dir ? 'dir' : props.name)] || otherIcon)

function resolveFileType(name: string) {
  const fileName = name.trim().toLowerCase()
  const dotIndex = fileName.lastIndexOf('.')
  if (dotIndex < 0 || dotIndex === fileName.length - 1)
    return 'other'

  switch (fileName.slice(dotIndex + 1)) {
    case 'pdf':
    case 'pdfx':
      return 'pdf'

    case 'xls':
    case 'xlsx':
    case 'xlsm':
    case 'csv':
    case 'tsv':
      return 'xls'

    case 'ppt':
    case 'pptx':
    case 'pps':
    case 'ppsx':
      return 'ppt'

    case 'doc':
    case 'docx':
    case 'rtf':
    case 'odt':
      return 'doc'

    case 'wav':
    case 'mp3':
    case 'aac':
    case 'flac':
    case 'm4a':
    case 'ogg':
    case 'opus':
    case 'wma':
      return 'audio'

    case 'yaml':
    case 'yml':
    case 'conf':
    case 'toml':
    case 'ini':
    case 'env':
    case 'xml':
    case 'json':
      return 'conf'

    case 'mov':
    case 'avi':
    case 'mp4':
    case 'mkv':
    case 'webm':
    case 'm4v':
    case 'ogv':
    case 'flv':
    case 'wmv':
      return 'video'

    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'ico':
    case 'gif':
    case 'webp':
    case 'bmp':
    case 'svg':
    case 'avif':
    case 'tif':
    case 'tiff':
    case 'heic':
      return 'image'

    case 'txt':
    case 'md':
    case 'markdown':
    case 'log':
    case 'srt':
    case 'ass':
    case 'vtt':
      return 'txt'

    case 'html':
    case 'htm':
    case 'js':
    case 'jsx':
    case 'ts':
    case 'tsx':
    case 'vue':
    case 'css':
    case 'scss':
    case 'less':
    case 'sql':
    case 'php':
    case 'java':
    case 'go':
    case 'py':
    case 'rb':
    case 'rs':
    case 'c':
    case 'h':
    case 'cpp':
    case 'cs':
    case 'sh':
    case 'bash':
    case 'zsh':
      return 'web'

    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
    case 'tgz':
    case 'bz2':
    case 'tbz2':
    case 'xz':
    case 'txz':
    case 'zipx':
      return 'zip'

    default:
      return 'other'
  }
}
</script>

<template>
  <image
    v-if="iconSrc"
    class="psou-file-type-icon"
    :src="iconSrc"
    mode="aspectFit"
    :style="{ width: size, height: size }"
  />
</template>

<style lang="scss" scoped>
.psou-file-type-icon {
  flex: 0 0 auto;
  display: block;
}
</style>
