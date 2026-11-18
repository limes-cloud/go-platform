import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
    title: "GoPlatform 统一应用管理平台",
    description:
        "Go-Platform是一个集成了管理中台、业务中台、客户端的微服务快速开发框架",
    themeConfig: {
        logo: "/my-logo.svg",
        // https://vitepress.dev/reference/default-theme-config
        nav: [
            // { text: "开发指南", link: "/guide" },
            {
                text: "开发指南",
                items: [
                    { text: "项目介绍", link: "/guide/guide/intro.md" },
                    { text: "Item B", link: "/" },
                    { text: "Item C", link: "/item-3" },
                ],
            },
            {
                text: "后端",
                items: [
                    { text: "系统介绍", link: "/backend/design/code.md" },
                    { text: "下载安装", link: "/backend/start/start.md" },
                    {
                        text: "快速开始",
                        link: "/backend/kratosx/components.md",
                    },
                    { text: "Configure 配置中心", link: "/item-3" },
                ],
            },
        ],
        sidebar: {
            "/guide": [
                {
                    text: "开发指南",
                    items: [
                        { text: "系统介绍", link: "/guide/guide/intro.md" },
                        { text: "系统安装", link: "/guide/guide/deploy.md" },
                    ],
                },
                {
                    text: "开发指南",
                    items: [{ text: "系统介绍", link: "/guide/intro2.md" }],
                },
            ],
            "/backend/design": [
                {
                    text: "阅读目录",
                    items: [
                        { text: "系统介绍", link: "/backend/design/code.md" },
                        {
                            text: "装机助手方案",
                            link: "/backend/design/installer-assistant.md",
                        },
                    ],
                },
            ],
            "/backend/start": [
                {
                    text: "开始手册",
                    items: [
                        { text: "认识微服务", link: "/backend/start/start.md" },
                        {
                            text: "protobuf安装",
                            link: "/backend/start/protobuf-install.md",
                        },
                        {
                            text: "cli工具安装",
                            link: "/backend/start/kratosx-install.md",
                        },
                        {
                            text: "项目安装",
                            link: "/backend/start/project-install.md",
                        },
                    ],
                },
            ],
            "/backend/kratosx/": [
                {
                    text: "kratosx组件",
                    items: [
                        { text: "启动服务", link: "/backend/kratosx/start.md" },
                        {
                            text: "context 上下文",
                            link: "/backend/kratosx/context.md",
                        },
                        {
                            text: "config 配置组件",
                            link: "/backend/kratosx/config.md",
                        },
                        {
                            text: "server 系统配置",
                            link: "/backend/kratosx/server.md",
                        },

                        // { text: 'kratosx 组件', link: '/backend/kratosx/components.md' },
                    ],
                },
            ],
        },

        socialLinks: [
            {
                icon: "github",
                link: "https://github.com/limes-cloud/go-platform",
            },
        ],
    },
});
