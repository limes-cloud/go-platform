# PSou Client

基于 [uView Pro Starter](https://starter.uviewpro.cn/zh/guide/intro.html) 的 uni-app 客户端，目标为 H5、微信小程序与 PC 浏览器。界面按 `server/psou/.prd/设计方案/界面设计-版本十.html`（VOL.10.1）实现。

## 技术栈

- uni-app + Vue 3 + TypeScript
- uView Pro（组件、黑色主题）
- Pinia + pinia-plugin-persistedstate
- UnoCSS
- 自研请求层（基于 uView Pro `http` 插件，保留原 `client-uniapp` 的 Token 刷新能力）

## 开发命令

```bash
pnpm install
pnpm dev:h5
pnpm dev:mp-weixin
pnpm build:h5
pnpm build:mp-weixin
pnpm type-check
pnpm lint
```

## 已迁移能力

- 请求层：统一响应解包、Bearer Token、401 刷新重试、错误提示、上传封装
- 鉴权：Token 存取、当前用户初始化、退出登录
- 状态：应用信息、用户信息、频道与搜索关键词
- 全局工具：`$g` 导航、复制、资源 URL、时间格式化、平台识别
- UI 基础：固定黑色主题、PC Shell、移动端 Header / BackNav / Tabbar、统一色调 Hero
- PSou 页面：首页、资源分类、二级分类、资源详情、搜索
- PSou 页面基础组件：`psou-page-heading`、`psou-section-heading`、`psou-filter-tabs`、`psou-tone-hero`、`psou-button`
- PSou 资源展示组件：`psou-channel-card`、`psou-resource-grid`、`psou-resource-card`、`psou-cover`、`psou-file-list`、`psou-info-list`、`psou-disclaimer`、`psou-search-results`、`psou-search-field`、`psou-search-result-item`
- PSou 反馈组件：`psou-loading`、`psou-empty`、`psou-notice`、`psou-data-note`、`psou-brand`
- PSou 应用壳组件：`psou-desktop-shell`、`psou-mobile-header`、`psou-mobile-back-nav`、`psou-mobile-tabbar`
- PSou Mock 数据：7 个一级频道、二级分类、资源文件清单与推荐 Banner，集中在 `mock/psou/fixtures.ts`
- PSou API：页面用例接口、领域模型、DTO 与 service 适配层已落到 `src/api/psou`；现有资源检索、链接预检、转存接口保持独立

## 架构分层

- `pages/`：页面编排、页面状态和用户交互，不复制通用展示结构。
- `components/`：展示组件，只通过 props / emits 通信，不读取页面 store，不直接决定业务跳转；Hero、筛选、文件、信息表、搜索区等公共结构全部复用。
- `composables/`：跨页面响应式能力和语义化主题入口。
- `library/navigation.ts`：唯一的页面路由表与跳转函数，页面不再散落 URL 字符串。
- `library/global/copy.ts`：剪贴板与跨端 Toast 的唯一入口。
- `api/psou/service.ts`：页面唯一数据入口；页面不直接引用 mock，也不自行拼装后端碎片字段。
- `mock/`：开发期 fixture 与 mock transport，只在启用 mock 时参与构建。
- `stores/`：只保留跨页面共享状态，不做 UI 透传包装。

更完整的分层规则、组件分类和新页面接入流程见 `ARCHITECTURE.md`。

> `src/App.root.vue` 是 uView Pro `UniRoot` 插件注入的根入口，负责全局 Toast / 网络状态，不能当作死代码删除。

## 目录说明

```text
src/
  api/          # 接口与类型，system 为原模板能力，psou 为 PSou 业务接口
  common/       # 请求拦截器、uView Pro 主题、全局样式
  components/   # 无页面状态的展示组件
  library/      # 路由、剪贴板、请求、鉴权、全局工具、升级
  composables/  # 响应式断点、主题
  pages/        # 首页 / 分类 / 详情 / 搜索
  stores/       # Pinia 状态
mock/
  psou/         # PSou fixture 与接口级 mock transport
```

## Mock 与接口切换

- 页面只调用 `src/api/psou/service.ts`，不读取 `mock/`。
- 开发与当前预览通过 `VITE_USE_MOCK=true` 将其余页面用例的 `@psou/transport` 指向 `mock/psou/transport.ts`。
- 一级分类、二级分类、分类聚合、资源详情、快速检索与在线提取接口已接入真实 BFF，不受 `VITE_USE_MOCK` 影响：`/psou/api/categories`、`/psou/api/categories/aggregate`、`/psou/api/resources`、`/psou/api/resource`、`/psou/api/search/quick`、`/psou/api/search/transfer`。
- 当前开发与生产预览环境都暂时启用 mock，保证没有客户端 BFF 时也能完整走通；正式联调前再关闭对应环境。
- 接入正式客户端 BFF 后，把对应环境的 `VITE_USE_MOCK` 改为 `false`，transport 自动切到 `src/api/psou/http-transport.ts`，页面代码无需调整。
- Mock 路由按页面用例聚合：`/psou/client/channels`、`/psou/client/categories`、`/psou/client/categories/{id}`、`/psou/client/resource?resourceId=`。

## 双端策略

当前采用单工程双布局，而不是拆成两个前端工程：

- 断点：H5 宽度 `>= 1024px` 使用 PC 布局，其余使用铺满窗口的移动 H5 / 小程序布局。
- 共享：API 契约、Mock 路由、请求层、Pinia、主题 Token、业务组件全部复用。
- 主题：全端固定黑色主题，不提供浅色模式；H5 启动页、页面底色、uView Token 与小程序系统主题均使用 `#05070f`。
- 分叉：PC 使用 `psou-desktop-shell`（固定 216px 侧栏 + 76px 顶栏），移动端使用 `psou-mobile-header`、`psou-mobile-back-nav` 与 `psou-mobile-tabbar`。
- 隔离：PC Shell 通过 `#ifdef H5` 条件编译，不进入微信小程序包；小程序构建产物中不存在 PC 组件引用。
- 导航：不注册原生 TabBar，首页与分类页使用自绘 uView Tabbar；所有业务 URL 集中在 `src/library/navigation.ts`。
- 组件边界：PC Shell 不再读取 catalog store，频道、分类、选中态和搜索词全部由页面传入，交互通过 emits 上抛。
- 降级：封面用 `padding-top: 56.25%` 维持 16:9，避免微信旧内核不支持 `aspect-ratio` 时塌陷。

已通过 CDP 设置真实 CSS viewport 验证 `390px`：`innerWidth=390`、`scrollWidth=390`，无横向溢出。另验证 `500 / 768 / 1024 / 1440 / 1920px`，首页、分类、详情、搜索链路可走通。`pnpm type-check`、`pnpm build:h5` 与 `pnpm build:mp-weixin` 均通过；`pnpm lint` 仍存在历史页面格式问题。

## 当前边界

- 页面数据统一来自客户端 API service；当前由 `mock/psou` 提供接口级 mock，尚未接入正式客户端 BFF。
- “提取 / 获取资源 / 一键转存”当前只复制演示链接或提示能力待接入，不会发起真实转存。
- 微信小程序已完成编译与 H5 组件隔离检查，仍需在微信开发者工具和目标真机上做一次安全区与字体渲染验收。
- 版本十明确不做社区与个人中心，因此未注册用户页/设置页；账号与鉴权 SDK 保留，供后续转存能力接入时复用。
