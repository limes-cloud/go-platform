# Category 实施方案

> 状态：已实施
> 日期：2026-10-28
> 范围：`server/psou` 新在线服务，`category` 分类树
> 前置文档：`.prd/psou-online-rebuild/README.md`
> 验收：管理端与公共端接口、图标 key/URL 双端语义、两级树约束、
> 首页唯一与删除引用保护均已在本地通过；`go test ./...` 与 H5 `pnpm type-check` 通过。

## 1. 目标与边界

本期目标是完成固定两级分类树、管理端维护能力、公共端分类读取能力，以及分类被引用时的删除保护。

本期包含：

- `Category` 实体、状态常量、树形转换和更新入参；
- 一级分类、二级分类的新增、编辑、删除和树形列表；
- 展示/隐藏、排序、首页分类设置；
- 分类名称、图标、父级和两级树约束；
- 公共端展示中的一级分类及指定一级分类下的二级分类查询；
- 分类删除时对子分类和 `resource` 引用的保护；
- 按 `app` 隔离、分类写操作并发控制和首页唯一性；
- 管理端、H5 接口路径及图标字段的接入方案。

本期不包含：

- 首页聚合数据 `aggregate`，包括轮播、二级分类区块和资源列表；
- 分类下资源的分页、排序和统计；
- `resource` 的 CRUD、上架/下架、浏览量和点击数更新；
- 除分类图标以外的资源 URL 解析和图片处理能力；
- 三级及更多层级分类；
- 旧服务 `/psou/client/*` 路由兼容；
- 数据库迁移和旧数据导入。

`aggregate`、`resources` 依赖 `resource` 表和资源查询，由后续 resource 模块实现。本期只交付分类树本身，避免 category 模块直接依赖尚未实现的资源领域。

交付结果以管理端和公共接口的手动验收为准，不新增自动单元测试。

## 2. API

### 2.1 管理端

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `POST` | `/psou/admin/category` | 创建分类，`body: "*"` |
| `PUT` | `/psou/admin/category` | 更新分类，`body: "*"`，ID 放在请求体 |
| `DELETE` | `/psou/admin/category` | 删除分类，`id` 放在 query |
| `GET` | `/psou/admin/category` | 分类详情，`id` 放在 query |
| `GET` | `/psou/admin/categories` | 分类树列表，不分页 |

管理端列表参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `parentId` | 否 | 按父分类筛选；`0` 表示一级分类 |
| `status` | 否 | `0` 隐藏，`1` 展示 |
| `name` | 否 | 分类名称模糊搜索 |

列表规则：

- 始终返回树形结构，一级分类的 `children` 包含命中的二级分类；
- 不传 `parentId` 时返回完整分类树；`parentId=0` 时只返回一级分类节点，`parentId>0` 时只返回该一级分类下的直接子分类；
- `parentId>0` 时必须指向已存在的一级分类，否则返回分类不存在；
- 搜索条件命中二级分类时保留其一级分类作为树节点；
- `total` 表示实际命中的分类数量，不包含仅为保持树结构而补入的祖先节点；
- 分类总量小，不分页。

### 2.2 公共端

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `GET` | `/psou/api/categories` | 展示中的一级分类 |
| `GET` | `/psou/api/categories?parentId=` | 指定展示中一级分类下的展示中二级分类 |

规则：

- `parentId` 省略时返回一级分类；
- `parentId` 存在时必须大于 `0`；
- 父分类必须是展示中的一级分类，否则返回分类不存在；
- 只返回 `status=1` 的分类；
- 排序统一为 `sort ASC, id ASC`；
- 公共端不返回 `status`、`sort`、创建时间和更新时间。

### 2.3 公共端响应结构

```json
{
  "list": [
    {
      "id": 1,
      "parentId": 0,
      "name": "影视",
      "icon": "https://oss.example.com/platform/d41d8cd98f00b204e9800998ecf8427e.png",
      "isHome": true
    }
  ]
}
```

图标字段按端拆分，两个接口不共用同一语义：

| 端 | 字段 | 返回值 | 用途 |
| --- | --- | --- | --- |
| 管理端 | `CategoryItem.icon` | 数据库原始 key 或原始 HTTP(S) URL | 编辑回显、保存、删除 |
| 公共端 | `CategoryNode.icon` | 完整可访问 URL | H5、小程序、PC 直接展示 |

公共端数据库中保存对象 key 时，psou 通过 resource gRPC 的 `GetFileURLByKey` 解析；已保存完整 HTTP(S) URL 时原样返回。管理端不解析、不改写图标值。

## 3. 实体设计

```go
// CategoryStatus 分类状态。
const (
	CategoryStatusHidden  uint8 = 0
	CategoryStatusVisible uint8 = 1
)

// Category 分类树：一级分类 + 二级分类。
type Category struct {
	App      string      `json:"app"      gorm:"column:app"`
	ParentId uint32      `json:"parentId" gorm:"column:parent_id"`
	Name     string      `json:"name"     gorm:"column:name"`
	Icon     string      `json:"icon"     gorm:"column:icon"`
	Sort     *int32      `json:"sort"     gorm:"column:sort"`
	Status   *uint8      `json:"status"   gorm:"column:status"`
	IsHome   *bool       `json:"isHome"   gorm:"column:is_home"`
	Children []*Category `json:"children" gorm:"-"`
	model.BaseModel
}

func (Category) TableName() string { return "category" }

func (c *Category) StatusValue() uint8 {
	if c.Status == nil {
		return CategoryStatusHidden
	}
	return *c.Status
}

func (c *Category) IsHomeValue() bool {
	return c.IsHome != nil && *c.IsHome
}

```

字段规则：

- `ParentId`、`Name`、`Icon` 是必填字段，实体使用值类型；
- `Sort`、`Status`、`IsHome` 的合法值包含 Go 零值，实体使用指针；
- 更新直接复用 `Category`：service 将请求值合并进当前实体，repository 清空 `App` 后按 `app + id` 更新；
- `app` 不进入 Proto 请求和响应，只能从 `ctx.AppKey()` 获取；
- `category` 表没有 `ext` 字段；
- 时间字段沿用 `model.BaseModel` 的 Unix 秒；
- 分类树最多两级，不提供任意深度树接口。

## 4. 分类树规则

1. `parentId=0` 表示一级分类。
2. `parentId>0` 表示二级分类，父分类必须存在且本身是一级分类。
3. 二级分类不能再有子分类，禁止三级分类。
4. 一级分类创建后不允许修改 `parentId`。
5. 二级分类可以移动到另一个一级分类下，但移动后仍必须是二级分类。
6. 二级分类可以升级为一级分类，但该分类下存在 `resource` 时禁止升级。
7. 分类名称按 `(app, parent_id, name)` 唯一；同一父级下不允许重名，不同父级允许同名。
8. 名称入库前 `TrimSpace`，长度按 rune 计算，范围为 1～64。
9. 父级被隐藏后，其二级分类仍可被管理端查看，但公共端不可访问。

## 5. 服务行为

### 5.1 创建

- 校验 `app` 非空；
- 校验名称、图标和父分类；
- `status` 未传时默认 `1`；
- `sort` 未传时默认 `0`；
- `isHome` 未传时默认 `false`；
- `isHome=true` 时只允许一级分类，且状态必须为展示；
- 先检查同级重名，再由数据库唯一键做最终兜底；
- 设置首页分类时，在同一事务中清除当前 app 的其他首页标记；
- 创建失败返回 `CreateError`，重名返回 `CategoryDuplicateError`。

创建请求示例：

```json
{
  "parentId": 0,
  "name": "影视",
  "icon": "d41d8cd98f00b204e9800998ecf8427e.png",
  "sort": 0,
  "status": 1,
  "isHome": true
}
```

### 5.2 更新

- 按 `app + id` 读取当前分类；不存在返回 `CategoryNotFoundError`；
- `parentId`、`name`、`icon` 必须传入，`sort`、`status`、`isHome` 未传时保留原值；
- 使用最终值校验父子关系、首页状态和同级重名；
- 一级分类修改父级直接拒绝；
- 二级分类升级为一级分类前检查 `resource` 引用；
- 状态由展示改为隐藏时，如果该分类仍是首页分类则拒绝；
- 设置首页分类时，在同一事务中清除当前 app 的其他首页标记；
- 更新直接传入合并后的 `Category`，条件必须包含 `app` 和 `id`，不能更新 `App`；
- 重名返回 `CategoryDuplicateError`，状态冲突返回 `CategoryStateError`。

### 5.3 删除

- 按 `app + id` 读取当前分类；不存在返回 `CategoryNotFoundError`；
- 首页分类不能删除；
- 一级分类存在子分类时不能删除；
- 分类存在 `resource` 引用时不能删除；
- 引用检查与删除在同一事务内执行；
- 无引用时硬删除，不做软删除；
- 有引用时返回 `CategoryReferencedError`，具体提示子分类或资源引用。

### 5.4 公共查询

- 一级分类：`app + parent_id=0 + status=1`，按 `sort ASC, id ASC`；
- 二级分类：先校验父分类为展示中的一级分类，再查询其展示中的子分类；
- 隐藏分类、隐藏父分类下的子分类不返回；
- 未设置首页分类时不报错，由前端使用第一个展示中的一级分类兜底。

### 5.5 图标

图标只接受以下两种值：

- 完整 HTTP(S) 图片地址；
- 上传服务返回的 32 位十六进制文件名对象 key，例如 `d41d8cd98f00b204e9800998ecf8427e.png`。

校验规则沿用旧在线实现：

- 入库前 `TrimSpace`；
- 最大长度 512；
- key 后缀只允许 `png`、`jpg`、`jpeg`、`webp`、`gif`、`svg`、`bmp`、`ico`；
- 空值、相对路径、`data:` URL 和其他格式返回参数错误。

服务端原样存储图标值：对象 key 或完整 HTTP(S) URL。管理端详情和列表返回原始值，展示时调用 `rurl()`；公共分类接口组装响应时统一将对象 key 解析为完整 URL。

resource 解析规则：

- 通过 `ctx.GrpcConn("Resource")` 调用 `resource.api.file.FileService/GetFileURLByKey`；
- 已是 HTTP(S) URL 时直接返回，不发起 gRPC 请求；
- 同一次响应内按对象 key 去重，避免多个分类共用图标时重复请求 resource；
- resource 返回空值或非 HTTP(S) URL 时视为解析失败；
- 单个图标解析失败记录 `Warnw` 并将该分类的 `icon` 置为空字符串，不阻断整个分类列表；
- 不缓存 resource 返回的 URL，避免签名 URL 过期后继续下发；
- 不修改数据库中的原始图标值。

依赖接口放在 `domain/repository`：

```go
type ResourceFileURL interface {
	GetFileURLByKey(ctx core.Context, value string) (string, error)
}
```

`infra/rpcs.Resource` 实现该接口；`app/category.go` 只负责在组装公共响应时调用并映射结果。

## 6. 首页分类规则

- 每个 app 最多一个一级分类设置 `is_home=1`；
- 只有展示中的一级分类可以设为首页；
- 首页分类不能直接隐藏，需先取消首页标记；
- 首页分类不能删除；
- 设置新首页时，旧首页在同一个事务中取消；
- 允许取消首页且暂时没有首页分类；
- 没有首页分类时，H5 使用排序最靠前的展示中一级分类；
- `is_home` 不能用数据库唯一键表达，唯一性由 app 级分类写锁和事务共同保证。

## 7. 并发与一致性

分类写操作统一使用 app 级分布式锁：

```text
psou:{app}:category:lock
```

规则：

- 创建、更新、删除、设置首页全部在 service 层获取该锁；
- 锁租期 30 秒并开启自动续期；获取失败返回“分类正在处理中，请稍后重试”；
- 标准链路为：获取锁 → 重新读取当前分类 → 校验 → 事务写入 → 释放锁；
- 设置首页和清除旧首页必须在同一事务内完成；
- 删除时子分类和资源引用检查必须在删除事务内完成；
- 数据库唯一键 `uk_app_parent_name` 作为跨实例并发重名的最终保护；
- 不使用 Redis 缓存分类树，避免后台修改后的失效问题。

由于 `resource` 没有数据库外键，后续 resource 模块创建、移动或删除资源时，必须使用同一把 app 级分类锁，避免分类删除与资源写入之间产生孤儿引用。该约束写入 resource 模块的接入要求。

## 8. Repository 接口

```go
// Category 分类仓储接口。
type Category interface {
	GetCategory(ctx core.Context, app string, id uint32) (*entity.Category, error)
	ListCategory(ctx core.Context, app string) ([]*entity.Category, error)
	ExistsCategoryName(ctx core.Context, app string, category *entity.Category) (bool, error)
	CreateCategory(ctx core.Context, app string, req *entity.Category) (uint32, error)
	UpdateCategory(ctx core.Context, app string, category *entity.Category) error
	ClearOtherHome(ctx core.Context, app string, id uint32) error
	CountReferences(ctx core.Context, app string, id uint32) (*types.CategoryReferenceCount, error)
	DeleteCategory(ctx core.Context, app string, id uint32) (*types.CategoryReferenceCount, error)
}
```

`types.CategoryReferenceCount`：

```go
type CategoryReferenceCount struct {
	Children  int64
	Resources int64
}

func (c *CategoryReferenceCount) Total() int64 {
	return c.Children + c.Resources
}
```

仓储约定：

- `GetCategory`、`UpdateCategory`、`DeleteCategory` 的条件必须同时包含 `app` 和 `id`；
- `ClearOtherHome` 只能清除同一 app 下的其他首页标记；
- `ListCategory` 按 `parent_id ASC, sort ASC, id ASC` 返回该 app 的全部分类，树构建和筛选在 service 完成；
- 分类配置表数据量小，一次读取全部可以避免筛选后丢失祖先节点；
- `CountReferences` 用于二级分类升级为一级分类前检查资源引用；
- `DeleteCategory` 在事务内统计子分类和 `resource` 引用，无引用时删除，有引用时返回引用计数；
- repository 文件只定义接口，不定义 struct；
- infra 层返回原生 error，由 service 统一映射业务错误。

## 9. 错误码

在 `api/errors/proto/errors.proto` 末尾追加：

```proto
CategoryNotFoundError = 40 [(errors.code) = 404, (errors.message) = "分类不存在"];
CategoryDuplicateError = 41 [(errors.code) = 409, (errors.message) = "同级分类名称已存在"];
CategoryReferencedError = 42 [(errors.code) = 409, (errors.message) = "分类已被引用"];
CategoryStateError = 43 [(errors.code) = 409, (errors.message) = "分类状态不允许该操作"];
```

使用规则：

- 参数格式、非法父子层级、名称、图标、首页基础校验使用 `ParamsError`；
- 分类不存在使用 `CategoryNotFoundError`；
- 同级重名使用 `CategoryDuplicateError`；
- 删除受引用使用 `CategoryReferencedError`；
- 隐藏首页、删除首页、非法首页设置，以及已存在分类的禁止性父级变更使用 `CategoryStateError`；
- 数据库失败使用 `CreateError`、`UpdateError`、`DeleteError` 或 `ListError`。

## 10. Proto 与路由

### 10.1 消息

```proto
message CategoryNode {
  uint32 id = 1;
  uint32 parentId = 2;
  string name = 3;
  string icon = 4; // 完整可访问 URL
  bool isHome = 5;
}

message CategoryItem {
  uint32 id = 1;
  uint32 parentId = 2;
  string name = 3;
  string icon = 4; // 数据库原始 key/URL，供编辑保存
  int32 sort = 5;
  uint32 status = 6;
  bool isHome = 7;
  int64 createdAt = 8;
  int64 updatedAt = 9;
  repeated CategoryItem children = 10;
}

message GetCategoryRequest {
  uint32 id = 1 [(validate.rules).uint32 = {gte: 1}];
}

message GetCategoryReply {
  CategoryItem category = 1;
}

message ListCategoriesRequest {
  optional uint32 parentId = 1;
  optional uint32 status = 2 [(validate.rules).uint32 = {in: [0, 1]}];
  optional string name = 3 [(validate.rules).string = {max_len: 64}];
}

message ListCategoriesReply {
  uint32 total = 1;
  repeated CategoryItem list = 2;
}

message CreateCategoryRequest {
  uint32 parentId = 1;
  string name = 2 [(validate.rules).string = {min_len: 1, max_len: 64}];
  string icon = 3 [(validate.rules).string = {min_len: 1, max_len: 512}];
  optional int32 sort = 4;
  optional uint32 status = 5 [(validate.rules).uint32 = {in: [0, 1]}];
  optional bool isHome = 6;
}

message CreateCategoryReply {
  uint32 id = 1;
}

message UpdateCategoryRequest {
  uint32 id = 1 [(validate.rules).uint32 = {gte: 1}];
  uint32 parentId = 2;
  string name = 3 [(validate.rules).string = {min_len: 1, max_len: 64}];
  string icon = 4 [(validate.rules).string = {min_len: 1, max_len: 512}];
  optional int32 sort = 5;
  optional uint32 status = 6 [(validate.rules).uint32 = {in: [0, 1]}];
  optional bool isHome = 7;
}

message UpdateCategoryReply {}

message DeleteCategoryRequest {
  uint32 id = 1 [(validate.rules).uint32 = {gte: 1}];
}

message DeleteCategoryReply {}

message ListPublicCategoriesRequest {
  optional uint32 parentId = 1 [(validate.rules).uint32 = {gte: 1}];
}

message ListPublicCategoriesReply {
  repeated CategoryNode list = 1;
}
```

### 10.2 服务

```proto
service Category {
  rpc GetCategory(GetCategoryRequest) returns (GetCategoryReply) {
    option (google.api.http) = {get: "/psou/admin/category"};
  }

  rpc ListCategories(ListCategoriesRequest) returns (ListCategoriesReply) {
    option (google.api.http) = {get: "/psou/admin/categories"};
  }

  rpc CreateCategory(CreateCategoryRequest) returns (CreateCategoryReply) {
    option (google.api.http) = {post: "/psou/admin/category" body: "*"};
  }

  rpc UpdateCategory(UpdateCategoryRequest) returns (UpdateCategoryReply) {
    option (google.api.http) = {put: "/psou/admin/category" body: "*"};
  }

  rpc DeleteCategory(DeleteCategoryRequest) returns (DeleteCategoryReply) {
    option (google.api.http) = {delete: "/psou/admin/category"};
  }

  rpc ListPublicCategories(ListPublicCategoriesRequest) returns (ListPublicCategoriesReply) {
    option (google.api.http) = {get: "/psou/api/categories"};
  }
}
```

详情接口不组装 `children`；管理端树形数据统一从 `/psou/admin/categories` 获取。

## 11. 文件清单

新增：

- `server/psou/api/category/proto/category.proto`
- `server/psou/api/category/proto/category_service.proto`
- `server/psou/api/category/*.pb.go`
- `server/psou/internal/domain/entity/category.go`
- `server/psou/internal/types/category.go`
- `server/psou/internal/domain/repository/category.go`
- `server/psou/internal/domain/repository/resource_url.go`
- `server/psou/internal/domain/service/category.go`
- `server/psou/internal/infra/dbs/category.go`
- `server/psou/internal/infra/rpcs/resource.go`
- `server/psou/internal/app/category.go`

修改：

- `server/psou/api/errors/proto/errors.proto`，追加分类错误码并重新生成；
- `web/admin-web/src/api/psou/category/api.ts`，全部改为 `/psou/admin/*`；
- `web/admin-web/src/api/psou/category/type.ts`，按新列表响应补齐类型；
- `web/psou/src/api/psou/api.ts`，一级/二级分类改为 `/psou/api/categories`；
- `web/psou/src/api/psou/service.ts`，适配 `{ list }` 响应，直接使用服务端返回的完整图标 URL；
- `server/psou/go.mod`、`server/psou/go.sum`，增加 `github.com/limes-cloud/resource/api` 依赖；
- `server/psou/deploy/schema.sql` 不需要变更，现有 `category` 表已满足本期设计。

不修改：

- `server/psou_bak_20261028_030143/**`；
- `package.json`、`pnpm-lock.yaml` 和构建配置；
- resource 服务的 Proto、实现和表结构。

## 12. 手动验收计划

### 12.1 管理端

1. 不传 `sort/status/isHome` 创建一级分类，落库为 `0/1/0`。
2. 同一父级创建同名分类失败；不同父级创建同名分类成功。
3. 一级分类下创建二级分类成功；二级分类下再创建子分类失败。
4. 修改一级分类的 `parentId` 失败。
5. 无资源的二级分类可移动或升级为一级分类。
6. 有资源的二级分类升级为一级分类失败。
7. `status=0`、`sort=0`、`is_home=false` 能正确写入，不被 GORM 零值忽略。
8. 设置新首页后旧首页自动取消，同一 app 最多一个首页。
9. 隐藏首页分类失败；删除首页分类失败。
10. 删除有子分类的一级分类失败。
11. 删除有资源的分类失败。
12. 删除无子分类、无资源的二级分类成功。
13. 非法图标格式失败；对象 key 和完整 HTTP(S) URL 成功。
14. 管理端列表返回树形结构；按名称或状态搜索时保留命中节点的祖先。

### 12.2 公共端

1. 无 `parentId` 时只返回展示中的一级分类，按 `sort ASC, id ASC` 排序。
2. 指定展示中一级分类时只返回展示中的二级分类。
3. 指定隐藏或不存在的父分类时返回分类不存在。
4. 隐藏分类及其子分类不出现在公共响应中。
5. 未设置首页分类时接口正常返回，前端自动使用第一个展示中一级分类。
6. 公共响应不包含 `status`、`sort`、`createdAt`、`updatedAt`。
7. 数据库保存对象 key 时，公共图标返回 resource 解析后的完整 URL。
8. 数据库保存完整 HTTP(S) URL 时，公共图标原样返回且不调用 resource。
9. 两个分类使用同一个图标 key 时，同一次请求只调用一次 resource。
10. resource 不可用或单个图标解析失败时，分类列表仍正常返回，失败项图标为空。

### 12.3 多租户

1. 使用两个 `X-App-Key` 分别创建同名一级分类，互不冲突。
2. A app 的公共接口不能读取 B app 的分类。
3. A app 设置首页不会清除 B app 的首页标记。
4. 所有按 ID 的详情、更新、删除请求都同时带 `app` 条件。

## 13. 关联模块交付

- gateway 增加 `/psou/admin/category*` 管理路由和 `/psou/api/categories` 公共路由；
- admin-web 将分类 API 从 `/psou/api/*` 切换到 `/psou/admin/*`；
- H5/小程序/PC 将 `/psou/client/category*` 切换到 `/psou/api/categories`；
- psou 增加 resource gRPC 客户端，用于公共分类图标 URL 解析；
- H5 首页的 `aggregate` 和分类详情的 `resources` 继续等待 resource 模块实现，不在 category 模块内 mock 或临时实现；
- resource 模块实现资源写入时，必须与 category 模块共用 `psou:{app}:category:lock`，避免删除分类与创建资源并发产生孤儿数据；
- README 的交付状态在 category 实施完成后再更新，本文件确认前不修改业务代码。

## 14. 待确认

1. 公共分类接口返回完整图标 URL，psou 通过 resource gRPC 解析；管理端继续返回原始 key/URL。建议采用。
2. 本期 category 不包含首页 `aggregate` 和分类 `resources`，这两部分放到 resource 模块。建议采用。
3. 不新增独立首页分类接口；公共一级分类列表返回 `isHome`，没有首页时前端回退到第一个展示中一级分类。建议采用。
4. 管理端列表继续支持 `parentId/status/name` 筛选并返回树形结构，数据量小不分页。建议采用。

