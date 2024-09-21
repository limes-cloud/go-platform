import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "GoPlatform 企业级快速开发脚手架",
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
          // { text: '设计原则', link: '/backend/design/design.md' },
          { text: '安装手册', link: '/backend/start/start.md' },
          { text: 'Kratosx组件', link: '/backend/kratosx/components.md' },
          { text: 'Configure 配置中心', link: '/item-3' }
        ]
      },
    ],
    sidebar: {
      '/backend/design': [
        {
          text: '设计原则',
          items: [
            { text: '认识微服务', link: '/backend/start/start.md' },
            { text: 'protobuf安装', link: '/backend/start/protobuf-install.md' },
            { text: 'kratosx-cli安装', link: '/backend/start/kratosx-install.md' },
          ]
        }
      ],
      '/backend/start': [
        {
          text: '安装手册',
          items: [
            // { text: '认识微服务', link: '/backend/start/start.md' },
            { text: 'protobuf安装', link: '/backend/start/protobuf-install.md' },
            { text: 'kratosx-cli安装', link: '/backend/start/kratosx-install.md' },
            { text: '配置中心', link: '/backend/start/kratosx-install.md' },

          ]
        }
      ],
      '/backend/kratosx/': [
        {
          text: 'kratosx组件',
          items: [
            { text: '启动服务', link: '/backend/kratosx/start.md' },
            { text: 'context 上下文', link: '/backend/kratosx/context.md' },
            { text: 'config 配置组件', link: '/backend/kratosx/config.md' },
            { text: 'server 系统配置', link: '/backend/kratosx/server.md' },

            // { text: 'kratosx 组件', link: '/backend/kratosx/components.md' },
          ]
        }
      ],
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/limes-cloud/go-platform' }
    ]
  }
})
