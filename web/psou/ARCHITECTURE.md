# PSou Client Architecture

## 1. 目标

一套 uni-app 工程同时服务：

- H5 移动浏览器：宽度 `< 1024px`
- 微信小程序
- PC 浏览器：宽度 `>= 1024px`

平台差异只落在“页面壳”和“布局组织”上，数据、请求、路由、主题和业务展示组件共享。

## 2. 分层

```text
pages/       页面编排：读取路由参数、组织页面状态、连接 store 与跳转
components/  展示组件：只接收 props，通过 emits 上抛交互
composables/ 跨页面响应式能力：断点等
library/     无 UI 的公共能力：请求、鉴权、路由、复制、平台、时间
api/         领域模型、页面用例接口、service 适配层
mock/        开发期 fixture 与 mock transport，仅通过 transport 注入
stores/      仅跨页面共享状态
common/      全局请求配置、主题 Token、uView Pro 配置
```

依赖方向固定为：

```text
pages -> components
pages -> composables / library / stores / api(service + types)
components -> api(types/展示映射) / library(纯函数)
components -X-> stores
components -X-> pages
pages/components -X-> mock
mock -> api(types) + mock fixtures
library -X-> components / pages
```

页面不得复制组件内部的展示结构；展示组件不得决定业务跳转，也不得直接读写页面 store。

## 3. 页面与组件职责

页面负责：

- 路由参数解析与页面级状态
- 选择 PC 或移动布局
- 调用 `library/navigation.ts` 完成跳转
- 组装页面数据和组件事件

组件负责：

- 稳定的 DOM 结构、样式、空态、选中态和多端兼容
- 通过 props 接收数据，通过 emits 描述用户意图
- 通过 `v-model` 或 `modelValue` 接收受控状态

### 数据与 Mock

- 页面只调用 `src/api/psou/service.ts`，不直接读取 fixture，也不拼装后端碎片字段。
- `src/api/psou/api.ts` 定义客户端页面用例 API；`service.ts` 是页面依赖的稳定边界，后续可在这里完成正式 DTO 到 ViewModel 的适配。
- `src/api/psou/transport.ts` 定义统一 transport 契约。
- `VITE_USE_MOCK=true` 时，Vite 将 `@psou/transport` 指向 `mock/psou/transport.ts`；否则指向 `src/api/psou/http-transport.ts`。
- H5 与微信小程序共用同一套 mock 路由；页面切换真实接口时不改模板和状态流。
- 当前页面用例路由：

```text
GET /psou/client/channels
GET /psou/client/category
GET /psou/client/category/children?parentId=6
GET /psou/client/category/aggregate?categoryId=1
GET /psou/client/categories?channelId=film
GET /psou/client/categories/{categoryId}?channelId=film
GET /psou/client/resource?resourceId=2
POST /psou/api/search/quick
POST /psou/api/search/transfer
```

一级分类、二级分类、分类聚合、资源详情和搜索接口已接入真实 BFF，不经过 mock transport。

### 应用壳

- `psou-desktop-shell`：PC 侧栏、顶栏、搜索框和内容容器
- `psou-mobile-header`：移动端品牌、搜索框
- `psou-mobile-back-nav`：详情页透明返回导航
- `psou-mobile-tabbar`：移动端首页与分类页切换

### 页面基础组件

- `psou-page-heading`：PC/移动页面标题、眉题、描述、数量
- `psou-section-heading`：内容区小标题、数量、说明、查看全部
- `psou-filter-tabs`：line / pills / button 三种筛选形态
- `psou-tone-hero`：所有资源色调 Hero 的背景、纹理、大字与水印
- `psou-button`：项目级主按钮、幽灵按钮和图标按钮

### 资源展示组件

- `psou-channel-card`：PC/移动一级频道卡
- `psou-resource-grid`：资源网格容器
- `psou-resource-card`：资源卡
- `psou-cover`：16:9 渐变封面与信息遮罩
- `psou-file-list`：文件清单
- `psou-info-list`：rows / grid / facts 三种信息表
- `psou-disclaimer`：免责声明
- `psou-search-results`：搜索摘要、说明、筛选、结果和空态
- `psou-search-field`：PC 顶部搜索输入
- `psou-search-result-item`：单条搜索结果

### 反馈组件

- `psou-loading`
- `psou-empty`
- `psou-notice`
- `psou-data-note`
- `psou-brand`

## 4. 主题与色调

- 全端固定黑色主题，不提供浅色分支。
- 基础颜色与间距 Token 只在 `common/style.scss` 定义。
- 资源色调通过 `.psou-tone--{tone}` 提供横向和纵向两种渐变变量，由 `psou-tone-hero` 使用。
- 频道卡颜色属于频道身份，封装在 `psou-channel-card` 内部。
- 页面只传 `CoverTone` 或业务状态，不重复声明主题变量和渐变。

## 5. 状态边界

- `stores/app`：应用元信息和平台信息
- `stores/user`：用户与 Token
- `stores/catalog`：跨页面共享的当前频道、搜索词
- 页面局部选中态：留在页面内
- 组件选中态：由父级受控，不在组件里复制 store

## 6. 响应式规则

- 唯一断点：`1024px`。
- 不使用固定移动画布，也不在 H5 上锁宽；移动布局始终铺满窗口。
- PC Shell 只在 `#ifdef H5` 中引入，不进入微信小程序包。
- 移动端尺寸使用 `px`，避免 `rpx` 在平板和宽屏 H5 上放大过度。

## 7. 路由规则

- 所有页面路径集中在 `library/navigation.ts`。
- 页面之间不直接拼接 URL。
- 首页、搜索、分类主页使用 `reLaunch`，详情页使用 `navigateTo`。
- 返回时优先 `navigateBack`，无历史栈时回退到明确的业务入口。

## 8. 新页面接入流程

1. 在 `pages.json` 注册页面。
2. 在 `library/navigation.ts` 增加路径和跳转函数。
3. 页面按 `isDesktop` 分成 PC 与移动两种布局。
4. 先查现有组件能否复用，再新增页面级展示组件。
5. 新组件只接受 props/emits，不读取 store。
6. 页面数据必须先在 `api/psou` 增加 service 与 client API，再在 `mock/psou/transport.ts` 增加对应 mock 路由。
7. 同时执行 `pnpm lint`、`pnpm type-check`、`pnpm build:h5`、`pnpm build:mp-weixin`。

## 9. 不可删除的框架入口

`src/App.root.vue` 由 uView Pro 的 `UniRoot` 插件注入，负责全局配置、Toast 和网络状态。它不是业务死代码，不能按普通页面组件删除。

## 10. 当前非目标

- 不做浅色主题
- 不做多语言
- 不做社区和个人中心
- 不在展示组件里预埋真实转存流程
