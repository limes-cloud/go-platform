import { readFile } from 'node:fs/promises'
import process from 'node:process'
import { fileURLToPath, URL } from 'node:url'

import Uni from '@uni-helper/plugin-uni'
import Components from '@uni-helper/vite-plugin-uni-components'
import { uViewProResolver } from '@uni-helper/vite-plugin-uni-components/resolvers'
import UniPages from '@uni-helper/vite-plugin-uni-pages'
import UnoCSS from 'unocss/vite'
import { UniRoot } from 'uview-pro/plugins'
import { defineConfig, loadEnv } from 'vite'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const transport = env.VITE_USE_MOCK === 'true'
    ? './mock/psou/transport.ts'
    : './src/api/psou/http-transport.ts'
  const assetOrigin = (env.VITE_ASSET_ORIGIN || '').replace(/\/+$/, '')

  return {
    // 生产构建由 deploy/platform/build-web.sh 传入 rustfs(47) 地址，让动态 chunk 直接走 47。
    // 运行时 router.base 由 src/manifest.json 的 h5.router.base 固定为 "/"，
    // 这样 /static/... 本地图片仍然走页面同源，不会被带到 47。
    base: env.VITE_ASSET_BASE || '/',
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
        '@psou/transport': fileURLToPath(new URL(transport, import.meta.url)),
      },
    },
    plugins: [
      UniPages({
        homePage: 'pages/index/index',
        configSource: 'src/pages.config.ts',
        dts: 'src/types/uni-pages.d.ts',
        exclude: ['**/components/**/**.*'],
        subPackages: [],
      }),
      // https://github.com/anyup/uview-pro
      UniRoot(),
      // https://uni-helper.js.org/vite-plugin-uni-components
      Components({
        dts: true,
        resolvers: [uViewProResolver()],
      }),
      // https://uni-helper.js.org/plugin-uni
      Uni(),
      {
        name: 'fix-vite-plugin-vue',
        configResolved(config) {
          const plugin = config.plugins.find(plugin => plugin.name === 'vite:vue')
          if (plugin && plugin.api && plugin.api.options) {
            plugin.api.options.devToolsEnabled = false
          }
        },
      },
      UnoCSS(),
      // 资源托管在 rustfs（跨域）时，Vite preload helper 会把动态 chunk 依赖拼成
      // 站点相对地址（/assets/xxx），页面域上并不存在这些文件。这里在构建阶段
      // 把前缀改成资源域，修改发生在 hash 计算前，产物文件名会随内容一起变化。
      assetOrigin && {
        name: 'psou-remote-asset-origin',
        enforce: 'post' as const,
        apply: 'build' as const,
        renderChunk(code: string) {
          if (!code.includes('Unable to preload CSS')) {
            return null
          }
          return {
            code: code.replace(/return"\/"\+([\w$]+)/g, `return"${assetOrigin}/"+$1`),
            map: null,
          }
        },
      },
    ],
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: '@import "uview-pro/theme.scss";',
        },
      },
    },
    optimizeDeps: {
      // 已知动态 import 的依赖直接预构建，避免页面加载时触发全量 reload（看日志出现过 qrcode）
      include: ['qrcode'],
      exclude: process.env.UNI_PLATFORM === 'h5' && process.env.NODE_ENV === 'development' ? ['uview-pro'] : [],
      esbuildOptions: {
        plugins: [
          {
            // @web-tracing/core 内联了 pako，源码里的 //#ifdef 会被 uni 条件编译误处理。
            name: 'strip-web-tracing-conditionals',
            setup(build) {
              build.onLoad({ filter: /@web-tracing[\\/]core[\\/]index\.mjs$/ }, async ({ path }) => ({
                contents: (await readFile(path, 'utf8')).replace(/^\s*\/\/#(?:ifdef|ifndef|endif).*$/gm, ''),
                loader: 'js',
              }))
            },
          },
        ],
      },
    },
    server: {
      host: '0.0.0.0',
      port: 5173,
      watch: {
        // 生成文件不进 watcher，避免自身写入触发重编译的自激循环
        ignored: [
          '**/components.d.ts',
          '**/uni-pages.d.ts',
          '**/pages.json',
        ],
      },
    },
  }
})
