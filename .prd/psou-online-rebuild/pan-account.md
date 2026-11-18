# PanAccount 实施方案

> 状态：实施中
> 日期：2026-10-28
> 范围：`server/psou` 新在线服务，仅 `pan_account` 表对应的账号池底座
> 前置文档：`.prd/psou-online-rebuild/README.md`

## 1. 目标与边界

本期目标是完成 `pan_account` 的账号池底座，以及账号侧依赖的平台能力，为 fixed、transfer、search、manual 四条转存通路提供可管理、可探测、可计数的网盘账号。

本期包含：

- `PanAccount` 实体、`AccountExt`、状态与转存通路常量；
- `fixed`、`transfer`、`search`、`manual` 四套转存目录与每日额度配置的完整 CRUD 和持久化；
- Admin 账号 CRUD、分页列表、状态管理；
- fixed、transfer、search、manual 四通路账号候选筛选与选号；
- fixed、transfer、search、manual 四通路的每日转存、每日分享计数；
- 百度、夸克等平台登录态探测；
- 网盘容量刷新；
- 账号扫码登录会话与一次性 ticket；
- 平台账号昵称自动解析；
- fixed/transfer 执行所需的平台基础客户端能力；
- 分发渠道账号引用检查与删除保护；
- Token 响应脱敏、按 `app` 隔离、删除引用保护；
- 交付结果以 `fixed`、`transfer`、`search`、`manual` 四条通路的可运行能力验收；技术分层代码只作为实现方式，不作为独立交付项；不编写自动单元测试，由人工验收。

四条通路的交付内容：

- `fixed`：账号配置、选号、额度计数、平台目录/转存/分享能力，以及 fixed 模块的调度与执行；
- `transfer`：账号配置、选号、额度计数、平台目录/转存/分享能力，以及 transfer 模块的调度与执行；
- `search`：账号配置、选号、额度计数和平台能力；真实搜索转存、临时分享与清理由 `search_transfer` 模块实现。
- `manual`：账号配置、选号、额度计数和平台能力；用于分类资源的人工触发转存，不进入自动调度。

模块归属：

- `PanAccount` 负责账号 CRUD、配置、状态、探测、容量、扫码、昵称和选号；
- `PanClient` / `AccountQRClient` 负责百度、夸克的登录态、昵称、容量、目录、转存、分享和清理等平台能力；
- fixed/transfer 必须实现各自的选号、任务编排、调度与执行；选号和平台客户端由本方案提供，业务编排在对应模块实现；
- `distribute_account` 必须实现分发渠道账号 CRUD、绑定和同步；`PanAccount` 提供账号引用检查与删除保护；
- 真正的搜索转存、临时分享与清理流程放到 `search_transfer` 方案实现，不在本文件展开；
- 旧库数据迁移与兼容仍不作为本次内容。

本次不再将这些能力标记为“不实现”。其中搜索转存链路归 `search_transfer`，其余账号侧能力在本方案内落地。

## 2. API

账号管理只开放到管理端，不暴露在 `/psou/api/*` 公共接口。

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `POST` | `/psou/admin/account` | 创建账号，`body: "*"` |
| `PUT` | `/psou/admin/account` | 更新账号，`body: "*"`，ID 放在请求体 |
| `DELETE` | `/psou/admin/account` | 删除账号，ID 放在 query |
| `GET` | `/psou/admin/account` | 账号详情，ID 放在 query |
| `GET` | `/psou/admin/accounts` | 分页列表 |
| `POST` | `/psou/admin/account/check` | 探测指定账号登录态，`body: "*"` |
| `POST` | `/psou/admin/account/recover` | 触发限流账号恢复探测，`body: "*"` |
| `POST` | `/psou/admin/account/storage/refresh` | 刷新指定账号容量，`body: "*"` |
| `POST` | `/psou/admin/account/qr/session` | 创建扫码登录会话，`body: "*"` |
| `GET` | `/psou/admin/account/qr/session` | 查询扫码状态，`sessionId` 放 query |

路由遵循 manager 现有 Proto 约定：单对象接口使用单数路径且不把 ID 放进 URL，列表接口使用复数路径。示例见 `server/manager/api/app/proto/app_service.proto`。

创建、更新请求通过 `AccountConfig` 携带四条通路的配置；详情和列表返回类型化的 `AccountExt`，其中包含配置与运行计数。创建和更新支持用一次性 `qrTicket` 代替手工 Token。

列表参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `page` | 是 | 页码，从 1 开始 |
| `pageSize` | 是 | 每页数量，最大 200 |
| `platform` | 否 | 平台过滤 |
| `status` | 否 | 状态过滤：-1、0、1 |
| `keyword` | 否 | 按名称、平台用户 ID 搜索 |
| `orderBy` | 否 | `priority`、`storageUsed`、`createdAt` |
| `order` | 否 | `asc`、`desc` |

规则：

- `app` 只从 `ctx.AppKey()` 获取，不接受客户端传参，不设置默认 `psou`；
- 所有按 ID 的查询、更新、删除都必须同时带 `app` 条件；
- Token 永远不出现在详情、列表、创建、更新响应中；
- 管理端身份与应用范围由网关的 manager 鉴权结果提供。

## 3. 实体设计

```go
type PanAccount struct {
	App          string      `json:"app"          gorm:"column:app"`
	Platform     string      `json:"platform"     gorm:"column:platform"`
	Name         string      `json:"name"         gorm:"column:name"`
	UserId       *uint64     `json:"userId"       gorm:"column:user_id"`
	Token        string      `json:"-"            gorm:"column:token"`
	Status       *int8       `json:"status"       gorm:"column:status"`
	Priority     *int32      `json:"priority"     gorm:"column:priority"`
	ErrorCode    *string     `json:"errorCode"    gorm:"column:error_code"`
	StorageTotal *uint64     `json:"storageTotal" gorm:"column:storage_total"`
	StorageUsed  *uint64     `json:"storageUsed"  gorm:"column:storage_used"`
	Remark       *string     `json:"remark"       gorm:"column:remark"`
	Ext          *AccountExt `json:"ext"          gorm:"column:ext;serializer:json"`
	model.BaseModel
}

func (PanAccount) TableName() string { return "pan_account" }
```

字段规则：

- `Name` 必填，最大 128 字符；
- `Platform` 必填，最大 32 字符；
- `Token` 创建时必填，更新时为空表示不修改；
- `Status` 只允许 `-1` 失效、`0` 停用、`1` 正常，创建默认 `1`；
- `Priority` 创建默认 `0`，数值越大越优先；
- `StorageTotal`、`StorageUsed` 为只读探测字段，不允许通过管理接口直接修改；
- `Ext` 使用 GORM `serializer:json`，不再使用 `GetExt`、`SetExt` 手工转换。

`UserId`、`StorageTotal`、`StorageUsed` 建议使用 `uint64`，与 DDL 的 `bigint unsigned` 保持一致。

`Status`、`Priority` 等字段即使数据库有默认值，仍保留指针，用于区分“未传”和“显式写零值”。

## 4. AccountExt

```go
type TransferRoute string

const (
	TransferRouteFixed    TransferRoute = "fixed"
	TransferRouteTransfer TransferRoute = "transfer"
	TransferRouteSearch   TransferRoute = "search"
	TransferRouteManual   TransferRoute = "manual"
)

type AccountExt struct {
	LastCheckAt    *int64                       `json:"lastCheckAt,omitempty"`
	LimitedAt      *int64                       `json:"limitedAt,omitempty"`
	LimitOp        *string                      `json:"limitOp,omitempty"`        // 限流触发来源，由触发方写入
	TransferDirs   map[TransferRoute]*TransferDirRef `json:"transferDirs,omitempty"`
	DailyTransfers map[TransferRoute]*DailyStat `json:"dailyTransfers,omitempty"`
	DailyShares    map[TransferRoute]*DailyStat `json:"dailyShares,omitempty"`
}

type TransferDirRef struct {
	Path string `json:"path"`           // 转存目录路径
	FsID string `json:"fsId,omitempty"` // 百度 fs_id / 夸克 fid
}

type DailyStat struct {
	Date  string `json:"date"`
	Count int32  `json:"count"`
	Limit int32  `json:"limit"`
}
```

管理接口使用显式的四通路配置，不使用任意字符串 key：

```proto
message AccountRouteConfig {
  optional string transferDir = 1;
  optional int32 dailyTransferLimit = 2;
  optional int32 dailyShareLimit = 3;
}

message AccountConfig {
  AccountRouteConfig fixed = 1;
  AccountRouteConfig transfer = 2;
  AccountRouteConfig search = 3;
  AccountRouteConfig manual = 4;
}

message CreateAccountRequest {
  string platform = 1;
  string name = 2;
  optional uint64 userId = 3;
  string token = 4;
  string qrTicket = 5;
  int32 priority = 6;
  optional string remark = 7;
  AccountConfig config = 8;
}

message UpdateAccountRequest {
  uint32 accountId = 1;
  optional string name = 2;
  optional uint64 userId = 3;
  optional string token = 4;
  optional string qrTicket = 5;
  optional int32 status = 6;
  optional int32 priority = 7;
  optional string remark = 8;
  AccountConfig config = 9;
}
```

创建请求示例：

```json
{
  "platform": "baidu",
  "name": "",
  "token": "登录凭证",
  "priority": 0,
  "config": {
    "fixed": {
      "transferDir": "/psou/fixed",
      "dailyTransferLimit": 20,
      "dailyShareLimit": 10
    },
    "transfer": {
      "transferDir": "/psou/transfer",
      "dailyTransferLimit": 20,
      "dailyShareLimit": 10
    },
    "search": {
      "transferDir": "/psou/search",
      "dailyTransferLimit": 50,
      "dailyShareLimit": 50
    },
    "manual": {
      "transferDir": "/psou/manual",
      "dailyTransferLimit": 20,
      "dailyShareLimit": 10
    }
  }
}
```

配置落库映射：

| 请求字段 | `AccountExt` 落点 |
| --- | --- |
| `config.fixed.transferDir` | `transferDirs["fixed"].path` |
| `config.transfer.transferDir` | `transferDirs["transfer"].path` |
| `config.search.transferDir` | `transferDirs["search"].path` |
| `config.manual.transferDir` | `transferDirs["manual"].path` |
| `config.fixed.dailyTransferLimit` | `dailyTransfers["fixed"].limit` |
| `config.fixed.dailyShareLimit` | `dailyShares["fixed"].limit` |
| `config.transfer.dailyTransferLimit` | `dailyTransfers["transfer"].limit` |
| `config.transfer.dailyShareLimit` | `dailyShares["transfer"].limit` |
| `config.search.dailyTransferLimit` | `dailyTransfers["search"].limit` |
| `config.search.dailyShareLimit` | `dailyShares["search"].limit` |
| `config.manual.dailyTransferLimit` | `dailyTransfers["manual"].limit` |
| `config.manual.dailyShareLimit` | `dailyShares["manual"].limit` |

`dailyTransferLimit`、`dailyShareLimit` 只是请求字段，不单独落库；创建时统一写入对应 `DailyStat.Limit`。创建时只有显式传入的非空目录和额度才写入，未传的通路不生成空配置；对显式传入额度的通路，以 `date=""`、`count=0`、对应 `limit` 初始化每日统计。

规则：

- `LimitOp` 记录触发限流的业务标识，由触发方写入自身标识，例如 `fixed`、`transfer`、`search`、`manual`；不维护固定枚举；
- `DailyStat.Limit <= 0` 表示不限；
- `DailyStat.Date` 为 `YYYY-MM-DD`；
- 跨日时重置 `Count`，保留 `Limit`；
- 创建和更新接口完整支持 `fixed`、`transfer`、`search`、`manual` 四套配置；
- 配置值为 `transferDir`、`dailyTransferLimit`、`dailyShareLimit`，只有 `Limit` 可配置，`Date/Count` 是只读运行数据；
- 转存目录为空字符串时删除对应目录配置，执行时回退到平台默认根目录；
- 创建账号、修改目录或更新登录态时，先解析并创建全部已配置目录，再把 `path` 与平台 `fs_id`/`fid` 一并写入 `transferDirs`；任一路径失败则整个操作失败；
- 运行时优先使用 `fsId` 直接调用网盘接口；标识失效时按 `path` 重新解析并回写，避免每次操作都列父目录；
- 旧版 `transferDirs` 的纯字符串值必须兼容读取，读取后视为只有 `path`、没有 `fsId`；
- 四条通路都支持配置读取、选号和额度计数；
- fixed/transfer 的调度与任务执行由对应模块调用本方案的选号和平台客户端；
- search 的在线提取、临时分享与清理由 `search_transfer` 模块调用本方案的选号和平台客户端。
- manual 只由分类资源的人工转存入口调用，不注册自动调度任务。

## 5. 账号唯一性

将 `pan_account.user_id` 改为可空，并增加唯一键：

```sql
`user_id` bigint unsigned DEFAULT NULL COMMENT '平台用户ID',
UNIQUE KEY `uk_app_platform_user` (`app`, `platform`, `user_id`),
KEY `idx_app_platform_user` (`app`, `platform`, `user_id`)
```

规则：

- 平台返回了 `user_id` 时按 `(app, platform, user_id)` 去重；
- 平台没有 `user_id` 时写 `NULL`，MySQL 唯一索引允许多个 `NULL`，不会阻止账号创建；
- 创建和更新时先做应用层重复校验，以返回明确错误；数据库唯一键负责并发兜底。

## 6. Service 行为

### 6.1 创建

- 校验 `platform`、`name`，并要求 `token` 与 `qrTicket` 二选一；
- 使用 `qrTicket` 时先从 Redis 一次性消费并换取 Token，逾期或重复使用直接拒绝；
- 入库前按平台调用 `Probe` 探测登录态；探测请求失败或平台明确判定失效时拒绝创建；
- `name` 为空时调用 `ResolveDisplayName` 自动解析平台昵称，仍为空则拒绝创建；
- 创建过程中查询一次容量，失败不阻断创建，保留 `storageTotal/storageUsed` 为空；
- 补齐 `status=1`、`priority=0`；
- 初始化 `Ext`，按请求写入 `fixed`、`transfer`、`search`、`manual` 四套目录和每日额度配置；
- 每日额度按 `int32` 接收，`<=0` 统一按不限保存；
- 当 `user_id` 非空时检查 `(app, platform, user_id)` 是否重复；
- 写入 `lastCheckAt` 和本次探测得到的 `user_id`、错误码；
- 保存原始 Token，不裁剪内容，不输出到日志和响应。

### 6.2 更新

- 先按 `app + id` 读取账号；
- 仅更新请求中明确传入的字段；
- `token` 为空时保持原值；
- `status`、`priority`、`remark` 支持显式更新为零值或空字符串；
- `lastCheckAt`、`limitedAt`、`errorCode`、容量字段不允许通过普通编辑接口覆盖；
- `fixed`、`transfer`、`search`、`manual` 四套配置均允许修改；
- 未传的通路配置保持不变，传入的通路只更新其中明确传入的字段；
- 目录字段显式传空字符串表示清除该通路自定义目录；
- 修改每日上限时必须保留该通路已有的 `Date` 和 `Count`；
- 修改任一通路配置都不得覆盖其它通路配置及当前计数。

### 6.3 列表与详情

- 列表和详情均不返回 Token；
- 返回类型化的 `AccountExt`；
- 列表排序默认 `priority DESC, id ASC`；
- 支持按 `storageUsed` 排序；
- 关键字只搜索 `name` 和 `user_id`，不允许动态 SQL 字段名。

### 6.4 删除

- 删除前检查账号是否被以下表引用：
  - `netdisk.account_id`；
  - `search_transfer.account_id`；
  - `distribute_account.pan_account_id`。
- 有引用时拒绝删除，提示改为停用；
- 无引用时硬删除。

### 6.5 状态

- `-1`：凭证失效；
- `0`：人工停用；
- `1`：正常；
- 创建默认 `1`；
- 人工停用后，登录态探测不得自动改回正常；
- `-1` 账号探测成功后恢复为 `1`；
- 探测请求本身失败时保持原状态；
- 平台明确返回登录态失效时将 `1` 改为 `-1`；
- 限流由 `limitedAt`、`limitOp` 表示，不占用主状态。

### 6.6 登录态探测

- `CheckAccount` 调用 `PanClient.Probe`；
- 探测成功写入 `lastCheckAt`；
- 探测判定失效时写入 `status=-1`、`errorCode`；
- 探测恢复后写入 `status=1`、清空 `errorCode`；
- `RecoverAccount` 只选择带 `limitedAt` 的正常账号，探测成功后清空 `limitedAt/limitOp/errorCode`；
- 状态与 Ext 必须使用同一事务和原状态条件更新，避免覆盖人工停用或其它流程写入的字段。

### 6.7 容量刷新

- `RefreshStorage` 调用 `PanClient.GetStorageQuota`；
- 成功时写回 `storageTotal/storageUsed`；
- 失败只记录日志，不清空原容量；
- 容量刷新不改状态和错误码；
- 转存成功后可异步/同步触发一次容量刷新，由调用方决定。

### 6.8 昵称自动解析

- 创建时 `name` 为空才调用平台昵称接口；
- 百度取登录信息昵称，夸克取账号资料昵称；
- 解析结果先 `TrimSpace`，超过 128 字符截断；
- 解析失败或结果为空时创建失败，不落库空名称。

### 6.9 扫码登录

- 只支持 `baidu`、`quark`；
- 会话保存在 Redis，TTL 3 分钟；
- 状态固定为 `pending | scanned | confirmed | expired | failed`；
- `confirmed` 时生成一次性 `qrTicket`，TTL 5 分钟；
- ticket 使用 `GETDEL` 原子消费，只允许使用一次；
- 创建或更新账号时可用 ticket 换取 Token，手工 Token 与 ticket 互斥；
- 二维码会话 key 必须带 `psou:{app}:` 前缀；
- 二维码图片只在创建响应中返回，Token 和 seed cookie 不进入日志。

### 6.10 平台能力与执行支持

- `PanClient` 至少实现登录态探测、昵称解析、容量查询、目录确保、目录解析、转存、建分享、删除和文件树读取；
- `AccountQRClient` 实现二维码创建、扫码轮询和登录态兑换；
- fixed/transfer/search/manual 四条通路共用 `PanClient`，平台差异由 dispatcher 承担；
- fixed/transfer 的调度与任务执行在各自模块实现，不在 domain service 内写平台分支；
- 转存成功后调用对应通路的 `BumpDailyTransfer`，分享成功后调用 `BumpDailyShare`；
- `search_transfer` 复用同一套账号配置、选号和平台客户端，但搜索提取、临时分享与清理逻辑在 `search_transfer` 方案中实现。

## 7. Token 安全

- 实体 JSON 标签使用 `json:"-"`；
- Proto 不定义 Token 响应字段；
- 日志禁止记录 Token、请求体和扫码凭证；
- 更新时空字符串表示不修改；
- 当前 Token 在数据库明文存储；如需加密，应作为独立安全改造，不在本期临时实现。

## 8. 四通路账号选号

所有 `status=1` 的账号都视为可参与 fixed、transfer、search、manual 四条通路，不新增通路开关。停用或失效账号通过状态排除，各通路再按自己的每日额度过滤。

候选条件：

- `app` 与当前请求一致；
- `platform` 匹配；
- `status=1`；
- `limitedAt == nil`；
- `DailyTransfers[route]` 未达到上限；
- `DailyShares[route]` 未达到上限；
- 若 `storageTotal`、`storageUsed` 均已探测，剩余容量必须大于或等于调用方传入的最小剩余容量。

额度判断：

```text
available = stat == nil || stat.Limit <= 0 || stat.Date != today || stat.Count < stat.Limit
```

排序：

1. `priority DESC`；
2. 剩余容量 `DESC`；
3. `id ASC`。

选号：

- 同一 `app + platform + route` 使用独立 round-robin 游标；
- 游标 key 为 `<route>:<app>:<platform>`；
- 账号列表为空时返回账号池耗尽错误；
- 每次选号直查数据库，不增加进程内账号缓存。

调用方式统一为 `SelectAccount(ctx, app, in *types.SelectAccountRequest)`。`search_transfer`、fixed、transfer 和 manual 转存入口只传各自 route，不复制选号逻辑。

## 9. 每日额度计数

fixed、transfer、search、manual 四条通路分别使用自己的两个额度：

- `DailyTransfers[route]`：门控该通路的转存步骤；
- `DailyShares[route]`：门控该通路的分享步骤。

执行规则：

- 选号前两个额度都必须可用；
- 转存成功后 `DailyTransfers[route].Count + 1`；
- 分享成功后 `DailyShares[route].Count + 1`；
- 任一步失败不增加对应计数；
- 跨日时 `Count` 重置为 1，`Limit` 保持不变；
- `Limit <= 0` 不限制；
- 在账号级锁内重新读取账号，按强类型 `AccountExt` 修改计数后，通过 `UpdateAccount` 整体写回；
- 通路只能来自 `fixed/transfer/search/manual` 白名单。

并发说明：

- 本期额度按成功次数计数，检查和计数之间不预占额度；
- 高并发下同一账号可能短时超过上限；
- 若需要严格不超额，需要增加预占字段或账号级分布式锁，本期不引入。

## 10. Repository 接口

所有方法显式接收 `app`：

```go
type Account interface {
	GetAccount(ctx core.Context, app string, id uint32) (*entity.PanAccount, error)
	GetAccountByUserId(ctx core.Context, app, platform string, userId uint64) (*entity.PanAccount, error)
	ListAccount(ctx core.Context, app string, req *types.ListAccountRequest) ([]*entity.PanAccount, uint32, error)
	CreateAccount(ctx core.Context, app string, account *entity.PanAccount) (uint32, error)
	UpdateAccount(ctx core.Context, app string, in *types.UpdateAccountInput) error
	DeleteAccount(ctx core.Context, app string, id uint32) (*types.AccountReferenceCount, error)
	CountReferences(ctx core.Context, app string, id uint32) (*types.AccountReferenceCount, error)
	ListCandidates(ctx core.Context, app, platform string) ([]*entity.PanAccount, error)
}
```

实现约束：

- 所有查询带 `app`；
- 状态、容量、`ext` 和日计数统一通过 `UpdateAccount` 写回；
- 更新入参使用 `types.UpdateAccountInput`，需要写零值时使用指针字段；删除直接传账号 ID，不定义删除入参；
- 不提供隐式默认租户；
- 不使用 `AutoMigrate`；
- 不缓存账号候选列表；
- `ext` 按强类型结构读取、修改后整体赋值，不使用数据库 JSON 函数；
- 删除引用检查与删除操作放在同一事务内。

平台客户端接口统一定义在 `domain/repository`：

```go
type PanClient interface {
	Probe(ctx core.Context, platform string, acc *entity.PanAccount) (*types.ProbeResult, error)
	ResolveDisplayName(ctx core.Context, platform, token string) (string, error)
	GetStorageQuota(ctx core.Context, platform, token string) (uint64, uint64, error)
	InitAccount(ctx core.Context, acc *entity.PanAccount) (map[entity.TransferRoute]*entity.TransferDirRef, error)
	EnsureDir(ctx core.Context, platform, token, dir string) (string, error)
	ResolveDir(ctx core.Context, platform, token, dir string) (*entity.TransferDirRef, error)
	UploadFile(ctx core.Context, in *types.UploadFileInput) (string, error)
	ListShareTree(ctx core.Context, in *types.ListShareTreeInput) ([]*types.ShareTreeItem, *types.ShareMeta, error)
	TransferToDir(ctx core.Context, in *types.TransferToDirInput) ([]*types.LandedFile, error)
	DirStat(ctx core.Context, platform, token, dirRef string) (int, int64, error)
	ResolveShareFsId(ctx core.Context, platform, token, dirRef string) (string, error)
	CreateShare(ctx core.Context, in *types.PanCreateShareInput) (string, string, error)
	Delete(ctx core.Context, platform, token, dirRef string) error
	DeletePaced(ctx core.Context, platform, token, dirRef string) error
	Exists(ctx core.Context, platform, token, dirRef string) (bool, error)
	RenameFile(ctx core.Context, in *types.RenameFileInput) error
}

type AccountQRClient interface {
	CreateQRSession(ctx core.Context, platform string) (*types.QRCode, error)
	PollQRSession(ctx core.Context, platform, sign, seedToken string) (*types.QRLoginStatus, error)
	CompleteQRSession(ctx core.Context, platform, seedToken, credential string) (string, error)
}
```

平台差异由 `infra/apis` 的 dispatcher 处理，domain/service 不出现 `if platform == ...` 分支。

## 11. 文件清单

| 文件 | 说明 |
| --- | --- |
| `server/psou/api/account/proto/account.proto` | 消息定义 |
| `server/psou/api/account/proto/account_service.proto` | 管理接口定义 |
| `server/psou/api/account/*.pb.go` | Proto 生成代码 |
| `server/psou/internal/domain/entity/pan_account.go` | 实体、Ext、常量、状态判断 |
| `server/psou/internal/domain/repository/account.go` | Repository 接口 |
| `server/psou/internal/domain/repository/pan.go` | 平台能力接口 |
| `server/psou/internal/domain/repository/account_qr.go` | 扫码登录接口 |
| `server/psou/internal/domain/service/account.go` | 账号领域服务与选号 |
| `server/psou/internal/domain/service/account_qr.go` | 扫码会话与 ticket 服务 |
| `server/psou/internal/types/account.go` | 请求、响应、排序和引用统计 DTO |
| `server/psou/internal/types/account_qr.go` | 扫码会话 DTO |
| `server/psou/internal/infra/dbs/account.go` | GORM Repository 实现 |
| `server/psou/internal/infra/apis/pan.go` | 平台 dispatcher |
| `server/psou/internal/infra/apis/baidu*.go` | 百度平台能力 |
| `server/psou/internal/infra/apis/quark*.go` | 夸克平台能力 |
| `server/psou/internal/app/account.go` | Proto Handler 与依赖注入 |
| `server/psou/deploy/schema.sql` | 同步 `user_id` 可空与唯一键 |
| `.prd/psou-online-rebuild/README.md` | 同步账号实体说明 |

## 12. 手动验收计划

- 由用户通过实际接口手工验收，不编写自动单元测试；
- 创建、更新、详情、列表、删除接口逐一手工验证；
- 验证 `fixed`、`transfer`、`search`、`manual` 四套目录和每日额度可以完整创建、更新、读取，且互不覆盖；
- 验证 fixed、transfer、search、manual 使用各自额度与 round-robin 游标，互不干扰；
- 验证登录态探测的成功、失效、请求失败和人工停用四种状态迁移；
- 验证容量刷新成功写回、失败保留原值；
- 验证昵称为空时自动解析，解析失败时拒绝创建；
- 验证扫码会话状态流转、ticket 一次性消费与过期；
- 验证不同 `app` 不能读取、更新、删除对方账号；
- 验证 Token 不出现在响应和日志字段中；
- 验证 `status=0`、`priority=0`、空备注能够正确更新为零值；
- 验证 `DailyStat` 原子递增与跨日重置；
- 交付前只执行编译检查：`go vet ./...`、`go build ./...`。

## 13. 关联模块交付

以下能力都属于本次整体建设范围，不能遗漏；本文件只细化 `PanAccount`，其它模块需要各自补充实施方案。

| 能力 | 交付模块 | 说明 |
| --- | --- | --- |
| 账号 CRUD、四通路配置、探测、容量、扫码、昵称、选号 | `PanAccount` | 本文件实现 |
| 百度/夸克平台接口 | `PanClient` / `AccountQRClient` | 本文件定义接口并实现 infra 客户端 |
| fixed 选号、调度与执行 | fixed 模块 | 复用 PanAccount 选号、额度和 PanClient |
| transfer 选号、调度与执行 | transfer 模块 | 复用 PanAccount 选号、额度和 PanClient |
| 搜索转存、临时分享与清理 | `search_transfer` | 在 `search_transfer` 方案中实现 |
| 分类资源手动转存 | manual 转存模块 | 人工触发，复用 PanAccount 的 `manual` 配置、选号和额度 |
| 分发渠道账号 CRUD、绑定与同步 | `distribute_account` | 独立模块实现；PanAccount 只做引用保护 |

## 14. 待确认项

1. fixed、transfer、search、manual 是否都按“所有 `status=1` 账号自动参与”实现，不增加通路开关。
2. 每条通路的 `DailyTransfers` 与 `DailyShares` 是否都作为选号前置条件，并分别按转存成功、分享成功计数。
3. 是否同意 `UserId`、`StorageTotal`、`StorageUsed` 改为 `uint64`。
4. 管理接口是否按 manager 现有约定使用 `/psou/admin/account`（单个）和 `/psou/admin/accounts`（列表）。
5. fixed/transfer 选号与平台客户端是否在本批实现，任务编排与调度在各自模块实现。

以上确认后再进入业务代码实现。
