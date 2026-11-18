# Resource 实施方案

> 状态：已实施
> 日期：2026-10-28
> 范围：`server/psou` 新在线服务，`resource` 资源主档及公共资源读模型
> 前置文档：`.prd/psou-online-rebuild/README.md`、`.prd/psou-online-rebuild/category.md`
> 关联文档：`.prd/psou-online-rebuild/netdisk.md`

## 1. 目标与边界

本期目标是完成资源主档的后台维护、上下架、频道 Banner、分类分页和公共端聚合读取，为 H5、微信小程序、PC 的资源浏览与详情页提供稳定的只读接口。

本期包含：

- `Resource` 实体、资源状态、来源常量和扩展结构；
- 管理端资源 CRUD、分页搜索、上下架、Banner 设置；
- 资源标题规范化与同分类幂等校验；
- 二级分类约束、Banner 频道约束和上架副本约束；
- 公共端分类资源分页、资源详情、首页/频道聚合和点击计数；
- 封面对象 key 到完整 URL 的公共端解析；
- 管理端通过独立的三方数据入口按影片名称补全封面、摘要、详情、标签和评分，并由用户选择封面；
- 按 `app` 隔离，以及与 `category`、`netdisk` 的跨模块一致性约束；
- admin-web、H5 的接口字段和调用方式调整。

本期不包含：

- 网盘副本的增删改、文件树和状态维护，见 `netdisk.md`；
- 搜索、搜索转存、临时分享和清理链路；
- 资源批量导入、旧数据迁移、远端网盘文件删除；
- AI 生成资源元数据；
- 内容分发和离线任务；
- 资源浏览/点击的风控、去重和反作弊；
- Redis 读缓存。

交付结果以管理端与公共接口人工联调为准，不新增自动单元测试。

## 2. API

### 2.1 管理端

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `POST` | `/psou/admin/resource` | 创建资源，`body: "*"` |
| `PUT` | `/psou/admin/resource` | 更新资源元数据，`body: "*"` |
| `DELETE` | `/psou/admin/resource` | 删除资源及其全部网盘副本，`id` 放 query |
| `GET` | `/psou/admin/resource` | 资源详情，`id` 放 query |
| `GET` | `/psou/admin/resource/metadata` | 按标题获取三方资源元数据及封面候选，`title`、`type` 放 query |
| `GET` | `/psou/admin/resources` | 分页列表 |
| `PUT` | `/psou/admin/resource/status` | 上架/下架，`body: "*"` |
| `PUT` | `/psou/admin/resource/banner` | 设置/取消 Banner，`body: "*"` |

#### 资源元数据补全

请求参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `title` | 是 | 影片、剧集或图书名称，最大 255 |
| `type` | 否 | `auto`、`movie`、`tv`、`book`，默认 `auto` |

外部数据源：

| 用途 | 接口 |
| --- | --- |
| 影视候选搜索 | `https://movie.douban.com/j/subject_suggest?q=<title>` |
| 图书候选搜索 | `https://book.douban.com/j/subject_suggest?q=<title>` |
| 详情、简介、评分、标签 | `https://m.douban.com/rexxar/api/v2/<kind>/<id>?for_mobile=1` |
| 封面图片 | 详情响应中的 `cover.image` / `pic`，由后端携带 `Referer` 上传到对象存储 |

返回字段包括 `title`、`summary`、`description`、`tags`、`score`、`year`、`kind`、`sourceUrl`、`covers` 和 `coverError`。封面不保存豆瓣 URL，也不向前端返回图片字节：`psou` 后端调用 resource 的 URL 上传能力落到 `psou/resource/cover`，`covers` 返回去重后的对象 key 列表。去重先按豆瓣图片主体 ID 合并尺寸变体，再按上传后对象 key 中的内容 MD5 合并重复图片。管理端以封面选择弹窗展示，用户选择候选图后进入 640×360 裁剪弹窗，裁剪结果重新上传对象存储并回填新 key，避免竖图直接作为横版封面使用；全部上传失败时 `coverError` 提示手动补充。

豆瓣图片 CDN 会对部分 Go 客户端返回 JS 风控页，resource 服务下载 `*.doubanio.com` 时自动补充 `Referer`；单个封面候选失败不会中断其他候选，但仍需按第三方非公开接口失败可降级处理。

创建和更新请求：

| 字段 | 类型 | 创建必填 | 更新必填 | 说明 |
| --- | --- | --- | --- | --- |
| `title` | string | 是 | 是 | 标题，最大 255 |
| `summary` | string | 是 | 是 | 摘要，最大 512 |
| `description` | string | 是 | 是 | 详情，最大 65535 字节 |
| `categoryId` | uint32 | 是 | 是 | 必须为二级分类 |
| `tags` | repeated string | 是 | 是 | 至少 1 个，服务端去空、去重 |
| `score` | double | 是 | 是 | 0～10，最多 1 位小数 |
| `cover` | string | 是 | 是 | 对象 key 或完整 HTTP(S) URL |
| `weight` | int32 | 否 | 否 | 默认 0，越大越靠前 |

创建请求不接受 `status`、`isBanner`、`source`、`viewCount`、`clickCount`。新资源固定为下架状态，添加正常网盘副本后再调用状态接口上架。

更新请求只修改元数据，不修改状态、Banner、来源、浏览量和点击数。`ext` 本期由服务端保留，不由后台表单直接编辑。

列表参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `page` | 是 | 页码，从 1 开始 |
| `pageSize` | 是 | 每页数量，最大 200 |
| `categoryId` | 否 | 按分类过滤 |
| `status` | 否 | 0 下架，1 上架 |
| `isBanner` | 否 | 是否 Banner |
| `keyword` | 否 | 标题模糊搜索，最大 255 |
| `orderBy` | 否 | `weight`、`score`、`viewCount`、`clickCount`、`createdAt`、`updatedAt` |
| `order` | 否 | `asc`、`desc` |

管理端响应中的 `cover` 返回数据库原始值：对象 key 或完整 URL。管理端负责编辑回显和保存，不做 URL 解析。

Proto 实现约束：当前 `kratosx proto client` 会把跨 proto package 的 import 写成 `psou/api/...` 绝对导入，导致 Go module 编译失败。本模块不跨 package 引用 message，公共资源读模型在 `resource.proto` 内独立定义 `ResourceCategoryNode`、`ResourceNetdiskFile`、`ResourceNetdiskItem`。

### 2.2 公共端

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `GET` | `/psou/api/resources` | 指定二级分类下的上架资源分页 |
| `GET` | `/psou/api/resource` | 上架资源详情及正常网盘副本，`id` 放 query |
| `POST` | `/psou/api/resource/click` | 记录一次网盘链接点击 |
| `GET` | `/psou/api/categories/aggregate` | 指定一级分类的 Banner、二级分类区块和精选资源 |

分类资源分页参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `categoryId` | 是 | 二级分类 ID，分类及其父分类都必须展示中 |
| `page` | 否 | 默认 1 |
| `pageSize` | 否 | 默认 20，最大 100 |
| `sort` | 否 | `latest` 或 `weight`，默认 `latest` |

排序规则：

- `latest`：`updated_at DESC, id DESC`；
- `weight`：`weight DESC, updated_at DESC, id DESC`。

聚合接口的 `categoryId` 必须是一级分类。聚合规则：

- 一级分类必须展示中；
- 只返回展示中的二级分类；
- `banners` 返回该频道最多 5 个上架 Banner 资源；
- `sections` 每个二级分类最多返回 6 个上架资源；
- Banner 排序：`weight DESC, score DESC, updated_at DESC, id DESC`；
- 区块排序：`weight DESC, updated_at DESC, id DESC`；
- 没有子分类或没有资源时返回空数组，不返回 `null`。

### 2.3 公共响应

资源列表项：

```json
{
  "id": 1,
  "title": "示例资源",
  "summary": "一句话介绍",
  "cover": "https://oss.example.com/platform/cover.jpg",
  "tags": ["电影", "4K"],
  "score": 8.5,
  "updatedAt": 1793184000
}
```

资源详情：

```json
{
  "id": 1,
  "title": "示例资源",
  "summary": "一句话介绍",
  "description": "资源详情",
  "cover": "https://oss.example.com/platform/cover.jpg",
  "tags": ["电影", "4K"],
  "score": 8.5,
  "updatedAt": 1793184000,
  "netdisks": []
}
```

聚合响应：

```json
{
  "category": { "id": 1, "parentId": 0, "name": "影视", "icon": "https://oss.example.com/platform/icon.png", "isHome": true },
  "banners": [],
  "sections": [
    {
      "category": { "id": 2, "parentId": 1, "name": "电影", "icon": "https://oss.example.com/platform/icon.png", "isHome": false },
      "resources": []
    }
  ]
}
```

公共端不返回 `source`、`weight`、`status`、`titleMd5`、`viewCount`、`clickCount`、`ext` 和分类管理字段。公共端 `cover` 必须解析为完整可访问 URL。

## 3. 实体设计

```go
// 资源状态。
const (
	ResourceStatusOffline uint8 = 0
	ResourceStatusOnline  uint8 = 1
)

// 资源来源。
const (
	ResourceSourceSystem = "system"
	ResourceSourceImport = "import"
	ResourceSourceAPI    = "api"
	ResourceSourceDemo   = "demo"
)

const ResourceBannerLimit = 5

// Resource 资源主档。
type Resource struct {
	App         string       `json:"app"         gorm:"column:app"`                       // 应用
	Title       string       `json:"title"       gorm:"column:title"`                     // 标题
	TitleMd5    string       `json:"-"           gorm:"column:title_md5"`                 // 规范化标题MD5
	Summary     string       `json:"summary"     gorm:"column:summary"`                   // 摘要
	Description string       `json:"description" gorm:"column:description"`               // 详情
	CategoryId  uint32       `json:"categoryId"  gorm:"column:category_id"`               // 分类ID
	Tags        []string     `json:"tags"        gorm:"column:tags;serializer:json"`       // 标签
	Score       float64      `json:"score"       gorm:"column:score"`                     // 评分
	Cover       string       `json:"cover"       gorm:"column:cover"`                     // 封面
	ViewCount   uint64       `json:"viewCount"   gorm:"column:view_count"`                // 浏览量
	ClickCount  uint64       `json:"clickCount"  gorm:"column:click_count"`               // 点击数
	Weight      *int32       `json:"weight"      gorm:"column:weight"`                    // 权重
	IsBanner    *bool        `json:"isBanner"    gorm:"column:is_banner"`                 // 轮播
	Status      *uint8       `json:"status"      gorm:"column:status"`                    // 状态
	Source      string       `json:"source"      gorm:"column:source"`                    // 来源
	Ext         *ResourceExt `json:"ext"         gorm:"column:ext;serializer:json"`       // 扩展
	model.BaseModel
}

func (Resource) TableName() string { return "resource" }

// ResourceExt 资源扩展，本期预留。
type ResourceExt struct{}

```

`TitleMd5` 只用于幂等和唯一键，不返回给任何端。`Tags` 在 Go 中为 `[]string`，通过 GORM `serializer:json` 写入 TEXT；禁止让 app 层手工拼 JSON。

## 4. 校验与状态规则

### 4.1 基础字段

- `title` 去首尾空白并清理控制字符，结果不能为空且不超过 255 字符；
- `titleMd5` 使用规范化标题的 MD5，同一 `app + categoryId + titleMd5` 只能存在一条资源；
- `summary` 必填，去首尾空白后不超过 512 字符；
- `description` 必填，不超过 65535 字节；
- `tags` 必填，逐项 `TrimSpace`、去空、去重，序列化后不超过 4096 字节；
- `score` 必填，必须是有限数值，范围 `0～10`，最多 1 位小数；
- `cover` 必填，规则与分类图标一致：完整 HTTP(S) URL，或 32 位十六进制文件名对象 key；
- `weight` 允许为负数和 0，默认 0；
- `source` 后台创建固定为 `system`，不接受客户端覆盖。

### 4.2 分类约束

- `category_id` 必须存在且属于当前 `app`；
- 分类必须是二级分类，其父分类必须是一级分类；
- 创建或更换分类时，与 category 模块共用 `psou:{app}:category:lock`，避免分类删除与资源写入并发产生孤儿引用；
- 分类隐藏后资源仍可保持上架，但公共端必须同时校验二级分类和父分类都在展示中；
- Banner 资源不能直接更换分类，必须先取消 Banner。

### 4.3 创建与更新

- 新资源固定 `status=0`、`is_banner=0`、`view_count=0`、`click_count=0`；
- 创建前校验同分类标题唯一，数据库唯一键 `uk_app_title_category` 作为最终保护；
- 更新不允许修改 `source`、`view_count`、`click_count`、`ext`、`status` 和 `is_banner`；
- 更新分类时必须重新校验分类约束和标题唯一性；
- 数据更新使用显式字段列表，确保 `weight=0` 可以正常落库；
- 唯一键冲突统一转换为资源重名错误。

### 4.4 上下架

- 状态只允许 `0`、`1`；
- 上架前必须至少存在 1 个 `netdisk.status=1` 的正常副本；
- 上架后再下线副本时，必须保证资源仍有正常副本，否则拒绝副本操作；
- 下架不删除网盘副本；
- 资源下架后公共列表、详情、聚合和点击计数都不可见；
- 资源已有 Banner 且重新上架时，必须重新校验频道 Banner 名额；名额不足时返回状态错误，要求先取消 Banner。

### 4.5 Banner

- Banner 上限按一级分类（频道）计算，每个频道最多 5 个；
- 资源必须上架、至少有一个正常副本、二级分类和父分类均展示中；
- Banner 计数只统计同频道内上架且 `is_banner=1` 的资源；
- 设置 Banner 时使用 app 级分类锁串行化，避免并发突破上限；
- 取消 Banner 不要求其他条件；
- 分类隐藏不会清除资源 Banner，但公共聚合和详情不展示；
- 分类删除由 `resource` 引用保护，不允许删除仍有资源的分类。

## 5. 公共读取

### 5.1 列表

- 只查询 `resource.status=1`；
- 二级分类和父分类都必须 `status=1`；
- 不返回已删除或不存在的分类下资源；
- 总数和列表使用同一组过滤条件；
- `pageSize` 最大 100，超出返回参数错误。

### 5.2 聚合

- 先校验一级分类存在、`parent_id=0` 且展示中；
- 查询该一级分类下全部展示中的二级分类；
- Banner 只从这些二级分类中查询，过滤上架和 `is_banner=1`；
- 每个区块查询 6 条上架资源；分类数量有限，允许按分类逐条查询，必须使用 `(app, category_id, status, ...)` 索引；
- 封面在 app 层批量解析，同一对象 key 只调用一次 resource gRPC；
- 聚合结果不缓存；后续出现性能问题再引入带主动失效的 Redis 缓存，不在本期引入。

### 5.3 详情与计数

- 详情只允许读取上架资源；
- 资源所属二级分类和父分类都必须展示中，否则按资源不存在处理；
- 只返回 `netdisk.status=1` 的副本，副本字段规则见 `netdisk.md`；
- 详情查询成功后异步/尽力增加 `view_count`，失败只记日志，不影响响应；
- 前端在打开网盘分享链接前调用 `/psou/api/resource/click`，服务端校验资源公共可见后原子执行 `click_count = click_count + 1`；
- 计数直接写 MySQL，不使用 Redis 计数，避免丢更新和额外对账。

### 5.4 封面 URL

- 数据库保留对象 key 或原始 URL；
- 管理端原样返回，公共端统一解析；
- 使用 `repository.ResourceFileURL.GetFileURLByKey`；
- 已为 HTTP(S) URL 时不调用 resource 服务；
- 同一响应按 key 去重；
- 解析失败记录 Warn 并将该条封面置空，不阻断列表或详情感；
- 不缓存签名 URL，避免过期后继续下发。

## 6. 并发与一致性

锁顺序固定为：分类锁 → 资源锁 → 账号锁。

- 创建资源、修改资源所属分类、删除资源、设置 Banner：获取 `psou:{app}:category:lock`；
- 更新状态、Banner 名额校验、删除资源：再获取 `psou:{app}:resource:{id}:lock`；
- 只修改标题、摘要、详情等非分类元数据时，只获取资源锁；
- 获取锁后必须重新读取资源、分类和副本状态，再执行最终校验与写入；
- 删除资源必须在同一事务内先删除 `netdisk`，再删除 `resource`；
- 上架、设置 Banner、删除/失效最后一个正常副本之间存在竞争时，由资源锁串行化；
- 数据库唯一键作为跨实例并发兜底；
- 不使用外键，由应用层和锁保证引用关系。

资源删除只删除新在线库中的资源与副本记录，不删除网盘平台中的真实文件或已有分享，也不调用远端平台。

## 7. Repository 与 Service

```go
type ListResourceRequest struct {
	page.Search
	CategoryId  *uint32  // 指定二级分类
	CategoryIds []uint32 // 指定一组二级分类，用于频道 Banner
	Status      *uint8   // 资源状态
	IsBanner    *bool    // 是否 Banner
	Keyword     *string  // 标题模糊搜索
}

type ResourceStatInput struct {
	Id         uint32 // 资源ID
	ViewDelta  uint64 // 浏览量增量
	ClickDelta uint64 // 点击量增量
}

type Resource interface {
	GetResource(ctx core.Context, app string, id uint32) (*entity.Resource, error)
	ListResource(ctx core.Context, app string, req *types.ListResourceRequest) ([]*entity.Resource, uint32, error)
	CreateResource(ctx core.Context, app string, resource *entity.Resource) (uint32, error)
	UpdateResource(ctx core.Context, app string, resource *entity.Resource) error
	IncrementResourceStat(ctx core.Context, app string, in *types.ResourceStatInput) error
	DeleteResource(ctx core.Context, app string, id uint32) error
}
```

服务拆分：

- `domain/service/resource.go`：管理端写入、状态、Banner、公共读取和计数；
- `app/resource.go`：proto 映射、封面解析、公共响应组装；
- 资源服务通过 `repository.Netdisk.ListNetdisk` 读取副本列表和总数，通过 `repository.Category` 校验分类，不构造 DB 客户端；
- 资源服务与 category service 不形成循环依赖。
- 唯一列表方法就是 `ListResource`：管理端、公共列表、频道 Banner、分类区块都通过 `types.ListResourceRequest` 的 `categoryId/categoryIds/status/isBanner/keyword/order/page` 组合过滤；repo 不为某一种页面新增专用 List 方法。
- Banner 查询传入 service 已读取的展示中二级分类 `categoryIds`；集合为空时 service 直接返回空结果，不查库。resource 表只存二级 `categoryId`，repo 不 JOIN `category`，也不冗余 `channel_id`。
- Banner 名额校验复用 `ListResource` 返回的 `total`，不再增加 `CountBannersByChannel`。
- 标题查重不再增加 `ExistsResourceTitle`，直接依赖唯一键 `uk_app_title_category`，创建/更新捕获唯一键冲突并转换为 `ResourceDuplicateError`。
- 元数据、状态和 Banner 统一通过 `UpdateResource` 写入，直接复用 `entity.Resource`：service 在锁内读取当前资源、合并修改后传入，repo 只按 `app + id` 写可编辑字段并保证合法零值可落库。
- 浏览量和点击量统一通过 `IncrementResourceStat` 原子增加，只更新计数列，不修改 `updated_at`，避免详情访问影响“最新”排序。
- 所有 service/repository 方法除 `ctx` 外最多 3 个参数。

## 8. 错误与前端调整

建议新增错误码：

| 错误 | HTTP | 场景 |
| --- | --- | --- |
| `ResourceNotFoundError` | 404 | 资源不存在或公共端不可见 |
| `ResourceDuplicateError` | 409 | 同分类标题重复 |
| `ResourceStateError` | 409 | 上架、下架或 Banner 状态冲突 |
| `NetdiskNotFoundError` | 404 | 网盘副本不存在 |
| `NetdiskDuplicateError` | 409 | 同资源同平台已有副本 |
| `NetdiskStateError` | 409 | 最后一个正常副本、状态冲突 |
| `NetdiskAccountError` | 409 | 转存账号不存在或平台不匹配 |

admin-web 调整：

- 资源接口从 `/psou/api/*` 改为 `/psou/admin/*`；
- `tags` 从 JSON 字符串改为字符串数组；
- 封面编辑保存对象 key，展示继续通过 `$rurl()` 解析；
- 状态和 Banner 使用独立接口；
- 资源来源表改为调用 netdisk 管理接口，并适配 `formatSummary`、`files`、状态语义变化，详见 `netdisk.md`。

H5 / 微信小程序 / PC 调整：

- 分类资源分页改为 `/psou/api/resources`；
- 资源详情改为 `/psou/api/resource`；
- 聚合改为 `/psou/api/categories/aggregate`；
- 点击网盘链接前调用 `/psou/api/resource/click`；
- 公共端标签直接读取数组，不解析字符串。

以上公共接口接入已由 `web/psou` 统一完成，H5、PC 和微信小程序共用同一套数据层；文件树按 `children` 递归展开。

## 9. 验收项

- 管理端可创建、编辑、查询、删除资源，所有必填校验生效；
- 同分类同名资源被拒绝，不同分类可以同名；
- 资源只能挂在二级分类下；
- 封面在管理端返回原始 key，在公共端返回完整 URL；
- 没有正常副本的资源不能上架；
- 每个频道 Banner 不超过 5 个，隐藏分类下资源不出现在聚合；
- 下架资源、隐藏分类资源不出现在公共列表和详情；
- 公共详情只返回正常副本，且不泄露账号和文件 ID；
- 浏览量在详情访问后增加，点击数在 click 接口后增加；
- 删除资源同时清理全部网盘副本；
- 不同 app 的资源、分类和 Banner 计数完全隔离。
