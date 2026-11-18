# Netdisk 实施方案

> 状态：已实施
> 日期：2026-10-28
> 范围：`server/psou` 新在线服务，`netdisk` 资源网盘副本
> 前置文档：`.prd/psou-online-rebuild/README.md`、`.prd/psou-online-rebuild/resource.md`

## 1. 目标与边界

本期目标是完成资源在各网盘平台的可用副本管理，维护分享链接、文件统计、目录树和有效性状态，并为资源详情提供只读副本数据。

本期包含：

- `Netdisk` 实体、`NetdiskExt`、副本状态和文件树结构；
- 管理端副本 CRUD、分页列表、详情和状态切换；
- 同资源同平台唯一约束；
- 转存账号存在性和平台一致性校验；
- 上架资源至少保留一个正常副本；
- 资源删除时级联清理副本；
- 公共资源详情只读取正常副本；
- admin-web 字段和状态语义调整。

本期不包含：

- 网盘平台登录、转存、分享和清理执行；
- 搜索转存链路，见后续 `search_transfer`；
- 定时链接检测任务和自动失效；
- 网盘真实文件的删除；
- 旧数据迁移；
- 公共端单独开放 netdisk CRUD 接口。

## 2. API

`netdisk` 仅开放管理端接口。公共端通过资源详情读取嵌套的正常副本。

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `POST` | `/psou/admin/netdisk` | 创建副本，`body: "*"` |
| `PUT` | `/psou/admin/netdisk` | 更新副本，`body: "*"` |
| `DELETE` | `/psou/admin/netdisk` | 删除副本，`id` 放 query |
| `GET` | `/psou/admin/netdisk` | 副本详情，`id` 放 query，包含文件树 |
| `GET` | `/psou/admin/netdisks` | 分页列表，不返回文件树 |
| `PUT` | `/psou/admin/netdisk/status` | 更新副本状态，`body: "*"` |

创建请求：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `resourceId` | uint32 | 是 | 所属资源 |
| `userId` | int64 | 是 | 上传用户 ID，0 表示系统 |
| `accountId` | uint32 | 是 | 转存账号 ID |
| `fsId` | string | 是 | 平台文件 ID，最大 128 |
| `platform` | string | 是 | `baidu` 或 `quark` |
| `shareUrl` | string | 是 | 分享链接，最大 512 |
| `fromUrl` | string | 是 | 来源链接，最大 512 |
| `size` | int64 | 是 | 字节数，不能小于 0 |
| `formatSummary` | string | 否 | 格式摘要，最大 64 |
| `fileCount` | uint32 | 否 | 文件数量 |
| `files` | repeated NetdiskFile | 否 | 根节点文件树 |

更新请求额外包含 `id`，不允许修改 `resourceId` 和 `platform`。修改平台时删除旧副本后重新创建。

更新请求必须提交完整文件树：未传或空数组表示清空文件树；管理端编辑前先调用详情接口，避免列表接口漏传文件树。

Proto 实现约束：当前 `kratosx proto client` 不支持跨 proto package 引用的可靠生成，本模块 proto 保持独立，不引用 `resource.proto`；资源公共读模型中的副本结构由 `resource.proto` 自行定义并转换。

列表参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `page` | 是 | 页码，从 1 开始 |
| `pageSize` | 是 | 每页数量，最大 200 |
| `resourceId` | 否 | 按资源过滤 |
| `platform` | 否 | 按平台过滤 |
| `status` | 否 | 0 失效，1 正常 |
| `orderBy` | 否 | `createdAt`、`updatedAt`、`lastCheckedAt` |
| `order` | 否 | `asc`、`desc` |

### 2.1 管理端响应

```json
{
  "id": 1,
  "resourceId": 10,
  "userId": 0,
  "accountId": 2,
  "fsId": "file-123",
  "platform": "quark",
  "shareUrl": "https://pan.quark.cn/s/example",
  "fromUrl": "https://pan.quark.cn/s/source",
  "size": 1073741824,
  "formatSummary": "4K / MKV",
  "fileCount": 2,
  "status": 1,
  "lastCheckedAt": 0,
  "files": [
    { "name": "电影", "path": "/电影", "isDir": true, "size": 0, "children": [] }
  ],
  "createdAt": 1793184000,
  "updatedAt": 1793184000
}
```

管理端列表不返回 `files`；详情返回。`lastCheckedAt` 只读，由未来的检测能力维护。

### 2.2 公共端响应

公共端不提供独立 netdisk 接口，资源详情中的副本字段固定为：

```json
{
  "id": 1,
  "platform": "quark",
  "shareUrl": "https://pan.quark.cn/s/example",
  "size": 1073741824,
  "formatSummary": "4K / MKV",
  "fileCount": 2,
  "files": [],
  "updatedAt": 1793184000
}
```

公共端禁止返回 `userId`、`accountId`、`fsId`、`fromUrl`、`status`、`lastCheckedAt` 和原始 `ext`。

## 3. 实体设计

```go
// 网盘副本状态。
const (
	NetdiskStatusInvalid uint8 = 0
	NetdiskStatusNormal  uint8 = 1
)

// Netdisk 资源网盘副本。
type Netdisk struct {
	App           string      `json:"app"           gorm:"column:app"`                       // 应用
	UserId        int64       `json:"userId"        gorm:"column:user_id"`                   // 上传用户ID
	AccountId     uint32      `json:"accountId"     gorm:"column:account_id"`                // 账号ID
	FsId          string      `json:"fsId"          gorm:"column:fs_id"`                     // 文件ID
	ResourceId    uint32      `json:"resourceId"    gorm:"column:resource_id"`               // 资源ID
	Platform      string      `json:"platform"      gorm:"column:platform"`                  // 平台
	ShareUrl      string      `json:"shareUrl"      gorm:"column:share_url"`                 // 分享链接
	FromUrl       string      `json:"fromUrl"       gorm:"column:from_url"`                  // 来源链接
	Size          int64       `json:"size"          gorm:"column:size"`                      // 文件大小
	FormatSummary *string     `json:"formatSummary" gorm:"column:format_summary"`            // 格式摘要
	FileCount     *uint32     `json:"fileCount"     gorm:"column:file_count"`                // 文件数
	Status        *uint8      `json:"status"        gorm:"column:status"`                    // 状态
	LastCheckedAt *int64      `json:"lastCheckedAt" gorm:"column:last_checked_at"`           // 最近检测时间
	Ext           *NetdiskExt `json:"ext"           gorm:"column:ext;serializer:json"`       // 扩展
	model.BaseModel
}

func (Netdisk) TableName() string { return "netdisk" }

// NetdiskExt 网盘副本扩展。
type NetdiskExt struct {
	Files []*NetdiskFile `json:"files,omitempty"` // 根节点文件树
}

// NetdiskFile 网盘文件树节点。
type NetdiskFile struct {
	Name     string         `json:"name"`               // 文件名
	Path     string         `json:"path"`               // 平台路径
	IsDir    bool           `json:"isDir"`              // 是否目录
	Size     int64          `json:"size"`               // 文件大小
	Children []*NetdiskFile `json:"children,omitempty"` // 子节点
}

```

规则：

- `files` 是根节点数组，目录通过 `children` 递归，文件节点不再包含子节点；
- 文件树只存在于 `ext`，数据库不拆表；
- `ext` 序列化后不超过 65535 字节；
- `formatSummary` 对空值返回空字符串；
- `status` 未设置时业务层按失效处理，但新数据明确写入状态；
- `lastCheckedAt=0` 表示从未检测。

## 4. 校验规则

- `resourceId` 必须属于当前 `app` 且资源存在；
- `userId >= 0`，0 表示系统上传；
- `accountId > 0`，账号必须存在且属于当前 `app`；
- 账号平台必须等于副本平台；
- `platform` 仅允许 `baidu`、`quark`，统一转小写；
- `fsId` 去空白后必填，最大 128；
- `shareUrl`、`fromUrl` 必须是合法 HTTP(S) URL，最大 512；
- `size >= 0`；
- `formatSummary` 去空白，最大 64；
- 同一 `app + resourceId + platform` 只能有一个副本，数据库唯一键 `uk_app_resource_platform` 兜底；
- 创建时状态固定为正常，`lastCheckedAt` 为 0；
- 创建和更新都不能直接写检测时间；
- 更新不能更换资源，也不能更换平台；
- 更新使用显式字段列表，允许清空 `formatSummary`、`fileCount` 和 `files`；
- 文件树校验节点总数、深度和序列化大小，非法结构返回参数错误。

文件树建议限制：

- 最大深度 32；
- 最大节点数 2000；
- 路径和名称不能包含控制字符；
- 文件节点 `children` 必须为空；
- 序列化后的 `ext` 不超过 65535 字节。

## 5. 状态与一致性

状态定义：

- `0`：失效，公共端不展示；
- `1`：正常，公共端可展示。

规则：

- 创建副本后直接为正常状态，因为管理端创建前已经完成链接提取/转存确认；
- 手动标记正常时不修改 `lastCheckedAt`；
- 将正常副本标记为失效前，如果所属资源已上架，必须保证仍有其他正常副本，否则拒绝；
- 删除正常副本前执行同样的最后副本检查；
- 删除失效副本不检查副本数量；
- 上架资源且只剩一个正常副本时，不允许将该副本失效或删除；
- 资源下架后可自由删除或失效最后副本；
- 资源删除时，在同一事务内删除该资源全部副本；
- 删除副本只删除新在线库记录，不删除网盘真实文件，也不撤销远端分享。

资源状态变化与副本状态变化必须使用同一把资源锁串行化，避免同时通过“至少一个正常副本”的检查后产生零副本资源。

## 6. 转存账号与平台

- 副本的 `accountId` 是事实来源，不复制账号名称或平台 Token；
- 创建/更新副本时校验账号存在且平台一致；
- 账号停用或失效不回写副本状态，已有分享链接仍可展示，由管理员手动标记副本失效；
- 删除转存账号时，现有账号删除保护会统计 `netdisk.account_id` 引用并拒绝删除；
- 账号平台当前以在线服务 `pan_account` 支持的 `baidu`、`quark` 为准；
- 不支持平台在参数校验阶段直接拒绝，不依赖数据库枚举。

## 7. 并发与锁

锁顺序固定为：分类锁 → 资源锁 → 账号锁。

- 创建、更新、删除、状态切换副本：获取 `psou:{app}:resource:{resourceId}:lock`；
- 绑定或更新 `accountId` 时，再获取 `psou:{app}:account:{accountId}:lock`，与账号删除串行化；
- 资源删除先获取分类锁和资源锁，再清理副本；
- 获取资源锁和账号锁后，必须重新读取资源与账号，再校验存在性、平台和副本数量；
- 数据唯一键是跨实例并发的最终保护；
- 事务内先完成引用和最后副本检查，再执行写入；
- 不允许在 repository 内获取业务锁，统一在 service 层处理。

## 8. Repository 与 Service

```go
type ListNetdiskRequest struct {
	page.Search
	ResourceId *uint32 // 所属资源
	Platform   *string // 网盘平台
	Status     *uint8  // 副本状态
}

type Netdisk interface {
	GetNetdisk(ctx core.Context, app string, id uint32) (*entity.Netdisk, error)
	ListNetdisk(ctx core.Context, app string, req *types.ListNetdiskRequest) ([]*entity.Netdisk, uint32, error)
	CreateNetdisk(ctx core.Context, app string, netdisk *entity.Netdisk) (uint32, error)
	UpdateNetdisk(ctx core.Context, app string, netdisk *entity.Netdisk) error
	DeleteNetdisk(ctx core.Context, app string, id uint32) error
}
```

服务依赖：

- `Netdisk` service 注入 `repository.Netdisk`、`repository.Resource`、`repository.Account`；
- 资源服务通过 `repository.Netdisk.ListNetdisk` 读取正常副本和总数；
- 不通过另一个 domain service 做跨表引用查询，避免服务循环依赖；
- app 层负责把 `NetdiskExt.Files` 转为 proto 文件树，公共端负责裁剪敏感字段。
- 唯一列表方法就是 `ListNetdisk`：管理端、资源详情、正常副本、最后副本检查都通过 `types.ListNetdiskRequest` 的 `resourceId/platform/status/page` 组合过滤；repo 不为某一种场景新增专用 List 方法。
- 正常副本数量复用 `ListNetdisk` 返回的 `total`，不再增加 `CountNormalNetdisk`。
- 同资源同平台查重不再增加 `ExistsNetdiskPlatform`，直接依赖唯一键 `uk_app_resource_platform`，创建/更新捕获唯一键冲突并转换为 `NetdiskDuplicateError`。
- 状态切换和元数据更新统一通过 `UpdateNetdisk` 写入，直接复用 `entity.Netdisk`：service 在锁内读取当前副本、合并修改后传入，repo 按 `app + id` 更新可编辑字段并保证合法零值可落库。
- `DeleteNetdisk` 只接收副本 ID，与分类删除保持同一形态；资源级联删除由 service 在同一事务内先用 `ListNetdisk` 读取该资源的副本 ID，再逐条调用 `DeleteNetdisk`。
- 所有 service/repository 方法除 `ctx` 外最多 3 个参数。

## 9. 前端与接口变更

admin-web：

- netdisk API 改为 `/psou/admin/netdisk*`；
- `formatText` → `formatSummary`；
- 删除 `folderCount`、`sort`；
- `ext` 字符串 → 结构化 `files`；
- 状态语义改为 `0=失效、1=正常`，开关展示同步翻转；
- 编辑副本前调用详情接口获取完整文件树；
- 资源页的来源编辑保存链路保留“提取/选择/转存/保存”流程，转存成功后创建正常副本。

H5 / 微信小程序 / PC：

- 不直接请求 netdisk 接口；
- 从资源详情读取 `netdisks`；
- 只依赖公共端裁剪后的字段；
- 文件树按 `children` 递归渲染，空数组不能渲染成占位节点。

## 10. 验收项

- 创建副本时所有必填字段和平台、URL、账号校验生效；
- 同资源同平台重复副本被拒绝；
- 账号不存在或平台不匹配被拒绝；
- 上架资源不能失效或删除最后一个正常副本；
- 资源下架后可以清理最后副本；
- 删除资源时副本全部清理，且不会出现孤儿记录；
- 公共详情只返回正常副本，不泄露 `accountId`、`fsId`、`fromUrl`；
- 文件树可以完整保存、读取和递归展示；
- 文件树超限或非法结构被拒绝；
- 不同 app 的副本完全隔离。
