import type {
  CategoryDetailReply,
  CategoryIndexReply,
  CategoryView,
  Channel,
  ChannelId,
  ChannelListReply,
  CoverTone,
  ResourceDetailReply,
  ResourceFile,
  ResourceItem,
  ResourcePlatform,
} from '@/api/psou/type'

export const channels: Channel[] = [
  { id: 'film', name: '影视', icon: 'play-right', glyph: '影', count: '128,406' },
  { id: 'music', name: '音乐', icon: 'volume-fill', glyph: '音', count: '36,820' },
  { id: 'game', name: '游戏', icon: 'grid', glyph: '游', count: '18,264' },
  { id: 'software', name: '软件', icon: 'setting', glyph: '软', count: '24,689' },
  { id: 'course', name: '课程', icon: 'file-text', glyph: '课', count: '12,408' },
  { id: 'doc', name: '文档', icon: 'list', glyph: '文', count: '8,932' },
  { id: 'material', name: '素材', icon: 'photo', glyph: '素', count: '21,574' },
]

interface MockCategoryDefinition {
  name: string
  icon: string
}

const categoryDefinitions: Record<ChannelId, MockCategoryDefinition[]> = {
  film: [
    { name: '电影', icon: 'https://psou-data.oss-cn-beijing.aliyuncs.com/764f94e0345d3d1a672af3a8ebb46fd7.png' },
    { name: '电视剧', icon: 'play-right-fill' },
    { name: '动漫', icon: 'photo' },
    { name: '纪录片', icon: 'photo' },
    { name: '综艺', icon: 'volume-fill' },
  ],
  music: [
    { name: '华语', icon: 'https://psou-data.oss-cn-beijing.aliyuncs.com/90a30e9bf3a3d1251d1fe0dd677b11ca.png' },
    { name: '欧美', icon: 'volume-fill' },
    { name: '日韩', icon: 'volume-fill' },
    { name: '纯音乐', icon: 'volume-fill' },
    { name: '现场', icon: 'play-right-fill' },
  ],
  game: [
    { name: '单机游戏', icon: 'https://psou-data.oss-cn-beijing.aliyuncs.com/df8788c83609041d5948a0501d2e0b05.png' },
    { name: '手机游戏', icon: 'grid' },
    { name: '主机游戏', icon: 'grid' },
    { name: '游戏素材', icon: 'photo' },
    { name: '模组', icon: 'setting' },
  ],
  software: [
    { name: '效率工具', icon: 'https://psou-data.oss-cn-beijing.aliyuncs.com/4b8bd4f3c7ae24ce7cba6982eb79b05e.png' },
    { name: '设计软件', icon: 'photo' },
    { name: '开发工具', icon: 'setting' },
    { name: '系统工具', icon: 'setting' },
    { name: '插件', icon: 'grid' },
  ],
  course: [
    { name: '编程开发', icon: 'file-text' },
    { name: '设计课程', icon: 'photo' },
    { name: '职场技能', icon: 'file-text' },
    { name: '语言学习', icon: 'file-text' },
    { name: '考试资料', icon: 'list' },
  ],
  doc: [
    { name: '电子书', icon: 'file-text' },
    { name: '行业报告', icon: 'file-text' },
    { name: '教程手册', icon: 'list' },
    { name: '文档模板', icon: 'file-text' },
    { name: '学术资料', icon: 'list' },
  ],
  material: [
    { name: '图片素材', icon: 'photo' },
    { name: '视频素材', icon: 'play-right-fill' },
    { name: '音效素材', icon: 'volume-fill' },
    { name: '字体素材', icon: 'file-text' },
    { name: '设计模板', icon: 'grid' },
  ],
}

const channelCountBase: Record<ChannelId, number> = {
  film: 468,
  music: 326,
  game: 214,
  software: 286,
  course: 194,
  doc: 128,
  material: 148,
}

export const categories: CategoryView[] = channels.flatMap((channel) => {
  return categoryDefinitions[channel.id].map((item, index) => ({
    id: `${channel.id}-${index + 1}`,
    channelId: channel.id,
    name: item.name,
    icon: item.icon,
    count: String(channelCountBase[channel.id] - index * 37),
  }))
})

const filmSeeds: Record<string, Array<[string, string]>> = {
  'film-1': [
    ['流浪地球 2 4K', '近未来太阳危机下的行星发动机救援，4K HDR 双版本，含幕后特辑。'],
    ['宇宙探索编辑部', '荒诞又浪漫的民间外星人寻找之旅，国语中字，附删减片段。'],
    ['封神第一部', '商王殷寿与姬发的父子抉择，4K 国语中字，附幕后纪录片。'],
    ['沙丘 2', '厄拉科斯沙海上的复仇与预言，4K HDR，中英特效字幕。'],
    ['星际穿越', '穿越虫洞寻找人类新家园，4K 修复 IMAX 画幅。'],
    ['奥本海默', '原子弹之父的荣耀与审判，4K 杜比视界，中英双字。'],
    ['盗梦空间', '潜入梦境深处的最后一项任务，4K 修复，国语配音。'],
    ['银翼杀手 2049', '复制人与人性的边界追问，4K HDR，含三部前传短片。'],
  ],
  'film-2': [
    ['三体 4K 修复版', '纳米科学家与外星文明的第一次接触，4K HDR 全 30 集，中英字幕。'],
    ['漫长的季节', '东北小城跨越二十年的悬案与人生，4K 全集，国语中字。'],
    ['狂飙 完整版', '京海市二十年扫黑风云，1080P 全 39 集，未删减版。'],
    ['繁花', '九十年代上海商海沉浮，4K 沪语/国语，全 30 集。'],
    ['我的阿勒泰', '草原上的少女与牧民的四季生活，1080P 全 8 集，国语。'],
    ['琅琊榜', '麒麟才子复仇昭雪之路，4K 修复，全 54 集。'],
    ['潜伏', '谍战经典修复版，1080P 全 30 集，国语中字。'],
    ['觉醒年代', '百年前青年求索与觉醒，4K 修复，全 43 集。'],
  ],
  'film-3': [
    ['中国奇谭 短片合集', '八个植根传统文化的奇幻短片，1080P 全 8 集，国语。'],
    ['灵笼 第二季', '末世灯塔下的人类生存与抉择，4K 全 12 集，中字。'],
    ['时光代理人', '两位青年通过照片回到过去，1080P 全 12 集，国语。'],
    ['雾山五行', '水墨武侠风的五行之战，4K 全 3 集，国语。'],
    ['凡人修仙传', '凡人韩立步步修仙的漫长旅途，1080P 年番合集，中字。'],
    ['刺客伍六七', '失忆刺客在小岛上的日常与冒险，1080P 全 40 集，国语。'],
    ['罗小黑战记', '治愈系国漫代表作，1080P 全 28 集，国语。'],
    ['大理寺日志', '唐朝洛阳的奇案追踪，1080P 全 12 集，国语。'],
  ],
  'film-4': [
    ['地球脉动 III', '跨越岛屿与深海的自然奇观，4K HDR 全 8 集，国语。'],
    ['舌尖上的中国 全四季', '中国人餐桌上的四季与乡愁，4K 全四季合集，国语中字。'],
    ['但是还有书籍', '与书有关的六段温柔故事，1080P 全 6 集，国语。'],
    ['蔚蓝之境', '中国近海的海洋生态全景，4K 全 6 集，国语。'],
    ['河西走廊', '丝绸之路上的千年历史回响，4K 修复 全 10 集。'],
    ['人生第一次', '十二个普通人的人生第一次，1080P 全 12 集，国语。'],
    ['我在故宫修文物', '文物修复师的日常与坚守，1080P 全 3 集，国语。'],
    ['航拍中国', '俯瞰山河的地理影像志，4K 全四季合集，国语。'],
  ],
  'film-5': [
    ['声生不息 · 宝岛季', '两岸歌手重唱华语经典，1080P 全 12 期，国语。'],
    ['种地吧 第二季', '十位少年在田间完成耕种季，1080P 全 20 期，国语。'],
    ['脱口秀和 Ta 的朋友们', '脱口秀演员的舞台段子与幕后，1080P 全 12 期，国语。'],
    ['歌手 2026', '顶级歌手同台竞演现场，4K 全 13 期，国语。'],
    ['向往的生活 · 蘑菇屋', '蘑菇屋里的慢生活与老友相聚，1080P 全 14 期，国语。'],
    ['奔跑吧', '户外竞技与城市探索，1080P 全 12 期，国语。'],
    ['中国好声音', '华语音乐人选秀现场，1080P 全 15 期，国语。'],
    ['极限挑战', '兄弟团城市任务挑战，1080P 全 12 期，国语。'],
  ],
}

const tones: CoverTone[] = ['blue', 'teal', 'gold', 'rose', 'violet', 'indigo']
const platforms: ResourcePlatform[] = ['quark', 'baidu', 'xunlei']
const sizes = ['48.6 GB', '32.4 GB', '8.6 GB', '24.6 GB', '26.8 GB', '18.2 GB', '28.6 GB', '16.8 GB']
const formats = ['MKV / MP4', '4K HDR', 'MP4', 'MKV']
const dates = ['2026-10-18', '2026-10-16', '2026-10-12', '2026-10-08', '2026-10-02', '2026-09-28']

function glyphOf(title: string) {
  return title.replace(/[《》\s·-]/g, '').charAt(0) || '资'
}

function filesFor(title: string, size: string): ResourceFile[] {
  return [
    { name: `${title} · 主文件`, type: '视频', size },
    { name: `${title} · 字幕包`, type: '字幕', size: '126 MB' },
    { name: `${title} · 花絮`, type: '文件夹', size: '1.2 GB' },
    { name: `${title} · 说明文档`, type: '文档', size: '2.4 MB' },
  ]
}

function makeResource(
  channelId: ChannelId,
  category: CategoryView,
  title: string,
  description: string,
  index: number,
): ResourceItem {
  const size = sizes[index % sizes.length]
  const sciFiKeywords = /三体|流浪地球|沙丘|星际穿越|银翼杀手|降临|火星救援|灵笼|宇宙探索/.test(title)
  return {
    id: `${category.id}-${index + 1}`,
    channelId,
    categoryId: category.id,
    categoryName: category.name,
    title,
    cover: '',
    description,
    score: (9.7 - (index % 8) * 0.1).toFixed(1),
    size,
    format: formats[index % formats.length],
    updatedAt: dates[index % dates.length],
    platform: platforms[index % platforms.length],
    coverTone: tones[index % tones.length],
    glyph: glyphOf(title),
    keywords: sciFiKeywords ? ['科幻', '太空'] : [getChannel(channelId).name, category.name],
    files: filesFor(title, size),
    shareUrl: `https://pan.example.com/s/${category.id}-${index + 1}`,
    viewCount: 120 + index * 13,
    clickCount: 8 + index * 2,
    bannerFocusX: 0.5,
    bannerFocusY: 0.5,
  }
}

const filmResources: ResourceItem[] = categories
  .filter(category => category.channelId === 'film')
  .flatMap((category) => {
    return (filmSeeds[category.id] || []).map(([title, description], index) => {
      return makeResource('film', category, title, description, index)
    })
  })

const genericDescriptions = [
  '站内演示资源，包含完整文件清单与更新信息。',
  '整理归档版本，适合收藏与多端查看。',
  '近期热门资源，含多格式文件与说明。',
  '分类精选合集，内容完整、结构清晰。',
  '更新维护版本，支持预览与来源切换。',
  '基础版本资源，正在持续补充更多内容。',
]

const generatedResources: ResourceItem[] = categories
  .filter(category => category.channelId !== 'film')
  .flatMap((category, categoryIndex) => {
    const channel = channels.find(item => item.id === category.channelId)
    return Array.from({ length: 6 }, (_, index) => {
      const title = `${channel?.name || '资源'} · ${category.name}精选 ${index + 1}`
      return makeResource(
        category.channelId,
        category,
        title,
        genericDescriptions[(categoryIndex + index) % genericDescriptions.length],
        index,
      )
    })
  })

export const resources: ResourceItem[] = [...filmResources, ...generatedResources]

export function getChannel(channelId: string | undefined): Channel {
  return channels.find(item => item.id === channelId) || channels[0]
}

export function getCategories(channelId: ChannelId): CategoryView[] {
  return categories.filter(item => item.channelId === channelId)
}

export function getCategory(categoryId: string | undefined): CategoryView | undefined {
  return categories.find(item => item.id === categoryId)
}

export function getResourcesByChannel(channelId: ChannelId): ResourceItem[] {
  return resources.filter(item => item.channelId === channelId)
}

export function getResourcesByCategory(categoryId: string): ResourceItem[] {
  return resources.filter(item => item.categoryId === categoryId)
}

export function getResource(resourceId: string | undefined): ResourceItem | undefined {
  return resources.find(item => item.id === resourceId)
}

export function getChannelList(): ChannelListReply {
  return { channels }
}

export function getCategoryIndex(channelId: string | undefined): CategoryIndexReply {
  const channel = getChannel(channelId)
  return {
    channels,
    channel,
    categories: getCategories(channel.id),
  }
}

export function getCategoryDetail(
  channelId: string | undefined,
  categoryId: string | undefined,
): CategoryDetailReply {
  const fallbackChannel = getChannel(channelId)
  const requestedCategory = getCategory(categoryId)
  const category = requestedCategory?.channelId === fallbackChannel.id
    ? requestedCategory
    : getCategories(fallbackChannel.id)[0]

  return {
    channels,
    channel: getChannel(category.channelId),
    category,
    categories: getCategories(category.channelId),
    resources: getResourcesByCategory(category.id),
  }
}

export function getResourceDetail(resourceId: string | undefined): ResourceDetailReply | undefined {
  const index = resources.findIndex(item => item.id === resourceId)
  if (index < 0)
    return undefined
  const resource = resources[index]
  const updatedAt = Math.floor(new Date(resource.updatedAt).getTime() / 1000)
  const score = Number(resource.score)

  return {
    id: index + 1,
    title: resource.title,
    summary: resource.description,
    description: resource.description,
    cover: resource.cover,
    tags: resource.keywords,
    score: Number.isFinite(score) ? score : null,
    updatedAt,
    viewCount: resource.viewCount,
    clickCount: resource.clickCount,
    netdisks: [{
      id: index + 1,
      platform: resource.platform,
      size: resource.size,
      formatSummary: resource.format,
      fileCount: resource.files.length,
      files: resource.files.map(file => ({
        name: file.name,
        path: `/${file.name}`,
        isDir: false,
        size: file.size,
      })),
      updatedAt,
    }],
  }
}

export function searchResources(keyword: string, platform: ResourcePlatform | 'all' = 'all') {
  const normalized = keyword.trim().toLowerCase()
  return resources.filter((item) => {
    const matchKeyword = !normalized
      || item.title.toLowerCase().includes(normalized)
      || item.description.toLowerCase().includes(normalized)
      || item.categoryName.includes(normalized)
      || item.keywords.some(keyword => keyword.toLowerCase().includes(normalized))
    const matchPlatform = platform === 'all' || item.platform === platform
    return matchKeyword && matchPlatform
  })
}
