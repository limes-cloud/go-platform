import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "GoPlatform",
  description: "Go-Platform是一个集成了管理中台、业务中台、客户端的微服务快速开发框架",
  themeConfig: {
    logo: '/my-logo.svg',
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: '首页', link: '/' },
      {
        text: '前端',
        items: [
          { text: 'Item A', link: '/item-1' },
          { text: 'Item B', link: '/' },
          { text: 'Item C', link: '/item-3' }
        ]
      },
      {
        text: '后端',
        items: [
          { text: '开始手册', link: '/backend/kratosx/start.md' },
          { text: 'Kratosx 脚手架', link: '/item-2' },
          { text: 'Configure 配置中心', link: '/item-3' }
        ]
      },
    ],

    sidebar: {
      '/backend/kratosx/': [
        {
          text: '开始手册',
          items: [
            { text: '认识微服务', link: '/backend/kratosx/start.md' },
            { text: 'protobuf安装', link: '/backend/kratosx/protobuf-install.md' },
            { text: 'kratosx 安装', link: '/backend/kratosx/kratosx-install.md' },
            { text: 'kratosx 组件', link: '/backend/kratosx/components.md' },
          ]
        }
      ],
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/limes-cloud/go-platform' }
    ]
  }
})
