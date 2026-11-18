# SearchTransfer 实施方案

> 状态：待确认
> 日期：2026-10-28
> 范围：`server/psou` 新在线服务的搜索、在线提取、临时分享与清理，以及资源管理录入来源所需的文件浏览/转存能力
> 前置文档：`.prd/psou-online-rebuild/README.md`、`.prd/psou-online-rebuild/pan-account.md`

## 1. 目标与边界

本期完成 `search_transfer` 对应的在线闭环：

- 通过 pansou 检索百度、夸克资源；
- 对检索结果签发不透明 token，H5、微信小程序、PC 不接触原始分享链接和提取码；
- 按 token 将源分享整包转存到 `search` 通路的账号；
- 创建临时分享，返回可直接打开或复制的分享链接；
- 记录临时容器引用，TTL 到期后由服务自身清理；
- 为 admin-web 的资源来源录入提供文件树、文件统计和指定账号转存能力。

本期不包含：

- `fixed`、`transfer` 离线通路的调度与执行；
- `distribute_channel`、`distribute_account`；
- 内容生成、SEO、页面行为流水和搜索流水；
- 旧 `/psou/client/*` 路由兼容；
- 旧库迁移、双写或跨库查询；
- `cmd`、外部 crontab 和任何业务 CLI。

两个流程必须分开：

- **公共端在线提取**自动选择 `search` 通路账号，写入 `search_transfer`，生成短 TTL 临时分享；
- **管理端资源录入**使用用户显式选中的账号和 `manual` 通路，不写入 `search_transfer`，生成供 `netdisk` 使用的持久目录和分享。

## 2. API

### 2.1 公共接口

H5、微信小程序、PC 统一使用 `/psou/api/search/*`，`app` 只从 `ctx.AppKey()` 获取。

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `POST` | `/psou/api/search/quick` | 快速检索，不预检链接，最多返回 `business.search.quickMaxResults` 条 |
| `POST` | `/psou/api/search/transfer` | 在线提取，返回临时分享链接和过期时间 |

快速检索请求：

```json
{ "keyword": "电影" }
```

快速检索响应：

```json
{
  "list": [
    {
      "platform": "baidu",
      "title": "资源标题",
      "token": "不透明加密串",
      "source": "tg:频道名"
    }
  ]
}
```

在线提取请求：

```json
{ "token": "检索 token" }
```

- 公共端固定整包转存，不接受文件子集、文件树 meta 或 `transferAll`；
- 公共接口不接受原始分享链接、提取码、账号 ID。

在线提取响应：

```json
{
  "shareUrl": "https://pan.baidu.com/s/xxx?pwd=abcd",
  "expiresAt": 1793200820
}
```

`shareUrl` 必须自带百度提取码；夸克本身无提取码。响应不再返回独立 `password`。

### 2.2 管理接口

管理端统一使用 `/psou/admin/search/*`，由网关完成 manager 鉴权，`app` 仍只从上下文获取。

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `POST` | `/psou/admin/search/quick` | 资源来源检索，返回与公共端相同的结果结构 |
| `POST` | `/psou/admin/search/files` | 查看源分享文件树，用于资源录入 |
| `POST` | `/psou/admin/search/scan` | 统计勾选文件的大小、数量和格式 |
| `POST` | `/psou/admin/search/transfer` | 使用用户指定账号转存到 `manual` 通路 |

管理端文件树/扫描请求允许二选一：

- `token`：来自管理端检索结果；
- `platform + shareUrl + password`：管理员直接粘贴来源链接。

管理端转存响应：

```json
{
  "accountId": 2,
  "platform": "baidu",
  "fsId": "转存目录的平台标识",
  "shareUrl": "https://pan.baidu.com/s/xxx?pwd=abcd",
  "size": 1024,
  "fileCount": 10,
  "folderCount": 2
}
```

- 不返回 `sourceShareUrl`、`sourcePassword`、`targetPath`、`sharePassword`；
- 不接收 `resourceTitle`、`resourceSummary`、`resourceDescription`，资源说明由 `resource` 实体承载，不写入网盘目录；
- `shareUrl` 已包含提取码；
- `fsId` 是 `netdisk` 保存副本所需的目标目录标识；
- 管理端转存不写 `search_transfer`，不占用 `search` 额度，必须占用 `manual` 额度。

## 3. 检索与 token

### 3.1 pansou

新增 `repository.PansouClient`，infra 使用 `GET /api/search?kw=<keyword>&res=merge`，只接收 `baidu`、`quark`：

1. 关键词去首尾空格，长度 1～128；
2. 拒绝以 `http://`、`https://` 开头的关键词；
3. 丢弃不在百度/夸克平台的结果；
4. 丢弃标题中带协议链接、裸域名、中文域名或 Telegram 入口的推广结果；
5. 同一平台按规范化 URL 去重；
6. 百度、夸克交替轮转，避免单一平台占满首屏；
7. quick 最多返回 `business.search.quickMaxResults` 条，检索阶段不预检链接。

`PansouClient` 只保留 `Search`，不迁移 `CheckLinks`。pansou 超时读取 `business.search.pansouTimeout`，检索失败不回退到旧服务或 mock。

公共接口不在业务层新增限流中间件；上线时由网关或 Nginx 统一处理。

检索本身不落库。项目已取消 `search_log`，本期不新增搜索流水。

### 3.2 检索 token

使用 AES-256-GCM 加密，密钥材料来自 `SEARCH_TOKEN_KEY`，经 SHA-256 派生 32 字节 key。密文格式为 `base64url(nonce || ciphertext)`。

```go
type searchTokenPayload struct {
	App      string `json:"app"`
	Platform string `json:"platform"`
	ShareURL string `json:"shareUrl"`
	Password string `json:"password,omitempty"`
	Keyword  string `json:"keyword"`
	Exp      int64  `json:"exp"`
}
```

规则：

- `app` 必须存在，并在解密后与 `ctx.AppKey()` 严格相等；
- 平台只允许 `baidu`、`quark`；
- `shareUrl` 必填；
- `keyword` 必填，用于临时容器命名和提取记录；
- `Exp` 为 Unix 秒，有效期读取 `business.search.tokenTTL`；
- 跨租户 token、过期 token、被篡改 token 统一返回 `SearchLinkInvalidError`；
- `SEARCH_TOKEN_KEY` 为空时检索接口直接失败，不能降级成明文或空密钥；
- token 不写日志，不进入错误信息。

### 3.3 文件树 meta

`meta` 只用于管理端文件树、扫描和管理端转存，公共端不返回也不接收。

`ListTransferFiles` 返回的 `meta` 同样是 AES-GCM 加密串，明文不能直接暴露 `shareid/uk/bdclnd`：

```go
type shareMetaPayload struct {
	App     string `json:"app"`
	FromURL string `json:"fromUrl"`
	Meta    struct {
		ShareId string `json:"shareId"`
		Uk      string `json:"uk"`
		Bdclnd  string `json:"bdclnd"`
	} `json:"meta"`
	Exp int64 `json:"exp"`
}
```

解密后必须同时校验 `app` 与来源链接，防止把一个分享的凭据用于另一个分享。校验失败不进入平台请求，按“未提供 meta”处理并重新拉取文件树；不得改用其他分享的凭据。

## 4. 公共在线提取

### 4.1 主流程

1. 校验 app、token、token 所属租户和过期时间；
2. 规范化源链接：去空白、去 fragment、去尾随 `?`，作为同源复用键；
3. 获取 `psou:{app}:search:transfer:lock:{sha256(fromURL)}` 分布式锁，串行化同源提取与清理；
4. 按 `app + from_url` 查询最新记录，仅在分享未过期时复用，不清理历史记录；
5. 使用只读验链账号读取源分享文件树，计算总大小并取得 `meta`，不设置固定包大小上限；
6. 按 `search` 通路选号，剩余容量至少取 `max(business.search.minFreeBytes, 已知资源大小)`；
7. 账号必须配置 `search` 转存目录，目录不存在时不作为候选；
8. 在 `<searchDir>/tmp` 下创建唯一临时容器 `<清洗关键词>_<base36(nano)>`；
9. 写入 `search_transfer`，状态 `0=转存中`，`fs_id` 保存 `EnsureDir` 返回的容器引用；若写库失败，立即 best-effort 删除刚创建的容器；
10. 调用 `TransferToDir` 将源分享整包转存到容器，`Files` 固定为空并传入步骤 5 取得的 `meta`；
11. 通过 `ResolveShareFsId` 取容器分享 ID，再调用 `CreateShare`；
12. 将提取码合并进分享链接，写入 `share_url`；
13. 更新状态为 `1=已分享`，写入新的 `expires_at`；
14. 成功后分别累加账号 `search` 通路的每日转存、每日分享计数；
15. best-effort 刷新账号容量。

不再向临时分享容器上传站点说明文件。多租户下没有 app 级站点配置表，固定 `psou.us` 文案会把其他租户带到错误站点。

### 4.2 临时目录与 fs_id

`search_transfer.fs_id` 保存的是**临时容器的平台引用**，不是目标文件本身的 ID：

- 百度 `EnsureDir` 返回目录路径，`fs_id` 存该路径；
- 夸克 `EnsureDir` 返回目录 `fid`，`fs_id` 存该 `fid`。

这符合当前 `PanClient.Delete(platform, token, dirRef)` 的契约，不需要为清理再新增目录字段。`fs_id` 必须非空，并在记录创建后保持不变。

目录规则：

- 只允许 `<searchDir>/tmp/<name>`，不得写到账号根目录；
- 关键词清洗路径保留字符、控制字符和换行，截断到 40 个 rune；
- `searchDir` 未配置时，该账号不可用于在线提取，不回退到根目录；
- 同源不同次提取必须使用不同容器名。

### 4.3 分享链接

- 百度 `CreateShare` 已返回 `...?pwd=xxxx` 时直接使用；
- 适配器返回独立密码但链接未携带时，服务端使用 URL query 合并 `pwd`；
- 夸克分享链接无提取码，不追加空参数；
- 数据库只保存 `share_url`，不再保存独立分享密码；
- 前端复制和二维码只使用 `shareUrl`。

### 4.4 复用与并发

`search_transfer` 不限制同一租户同一源链接只能有一行。新请求只读取该来源最新记录，并在源链接锁内探测记录的 `fs_id` 是否仍存在。容器仍存在时优先续用，容器不存在时再创建新记录；请求路径不得同步清理历史容器。

| 已有状态 | 新请求处理 |
| --- | --- |
| `1=已分享`，`expires_at > now` 且 `fs_id` 仍存在 | 复用原链接并延长 TTL；`share_url` 为空时基于旧容器重新生成分享 |
| `1=已分享`，`expires_at <= now` 且 `fs_id` 仍存在 | 复用旧容器，延长 TTL；`share_url` 为空时基于旧容器重新生成分享，不重复转存 |
| `1=已分享`，但 `fs_id` 已不存在 | 创建新转存记录；旧记录由清理 worker 按 ID 收尾 |
| `0=转存中` 且 `expires_at > now` | 返回 `SearchTransferBusyError`，提示稍后重试 |
| `0=转存中` 且已超过处理期限 | 视为残留记录，直接创建新转存记录；旧记录由清理 worker 处理 |
| `4=失败` | 直接创建新转存记录；旧记录由清理 worker 处理 |
| `3=已清理`，`share_url` 非空且 `fs_id` 仍存在 | 恢复为 `1=已分享` 并延长 TTL，不重复转存 |
| `3=已清理`，`fs_id` 已不存在 | 直接创建新转存记录 |
| `2=清理放弃`，`share_url` 非空且 `fs_id` 仍存在 | 恢复为 `1=已分享` 并延长 TTL；保留记录供后续清理 |
| `2=清理放弃`，`fs_id` 不存在或无分享链接 | 直接创建新转存记录，不永久阻塞同源提取 |

锁只保护同源提取与清理，不与账号锁嵌套反序：

1. 先拿源链接锁；
2. 再调用 Account 服务，Account 内部按需拿账号锁；
3. 禁止先拿账号锁再尝试源链接锁。

锁租期读取 `business.search.transferLockTTL`，并开启自动续期。锁 key 使用 URL 的 SHA-256，不直接拼原始链接。

### 4.5 失败与重试

最多尝试 `business.search.maxAccountAttempts` 个账号。百度、夸克的平台错误先归类：

- `Limited`：账号写入 `limitedAt`、`limitOp=search`，换下一个账号；
- `Invalid`：账号置为失效并写平台错误码，换下一个账号；
- `SpaceFull`：刷新账号容量，排除当前账号后换下一个；
- `Normal`：不自动换号，按错误语义返回。

分享已取消/失效：

- 返回 `SearchShareExpiredError`；
- 若已创建临时容器，立即 best-effort 删除。

提取码错误或缺失：

- 返回 `SearchPasswordError`；
- 若已创建临时容器，立即 best-effort 删除。

超过 `business.search.maxAccountAttempts` 个账号仍不可用：

- 返回 `SearchNoShareAccountError`；
- 不写成功分享记录；若已有容器，标记 `4=失败` 交给清理 worker。

对外响应不能包含平台 errno、token、账号 ID、容器引用或完整底层错误。

### 4.6 大小与额度

- 文件树、扫描使用只读账号，不检查每日转存/分享额度；
- 真正提取使用 `search` 转存通路，同时检查每日转存和分享额度；
- 不设置固定包大小上限；
- 账号最小剩余容量读取 `business.search.minFreeBytes`；
- 已知资源大小时，账号剩余容量还必须不小于资源大小；
- 复用已有分享不累加每日次数；
- 转存成功累加 `dailyTransfers["search"]`；
- 分享成功累加 `dailyShares["search"]`；
- 计数写回统一调用 `Account.UpdateAccount`，不使用 JSON SQL。

## 5. 管理端资源来源转存

管理端流程与公共在线提取共用文件树解析、平台适配和 token/meta 校验，但业务规则不同：

1. 文件树和勾选统计使用只读验链账号，只读取源分享，不转存；
2. 转存必须指定 `accountId`，账号必须正常、未限流、平台匹配；
3. 目标目录从账号 `manual` 通路读取，未配置时明确报错；
4. 目录名使用管理员输入或 `<清洗标题>_<base36(nano)>`；
5. 使用指定账号把源分享整包/子集转到 `manual` 目录；
6. 创建该目录的分享，返回自带提取码的 `shareUrl`；
7. 通过 `ResolveShareFsId` 返回目录 `fsId`、文件数和总大小；
8. 成功后累加该账号 `manual` 通路的转存/分享次数；
9. 不写 `search_transfer`，不自动选号，不创建短 TTL 清理任务，不向目录上传说明文件。

管理员直接粘贴链接时，平台由 URL 识别；显式传入平台时必须与识别结果一致。

## 6. 数据模型与状态机

### 6.1 表结构

沿用当前 `server/psou/deploy/schema.sql` 中的 `search_transfer`。本期将同源唯一键改为普通索引，以允许保留历史记录：

| 字段 | 语义 |
| --- | --- |
| `app` | 租户 |
| `account_id` | 执行提取的 `search` 通路账号 |
| `keyword` | 来源搜索词 |
| `client_ip` | 来源 IP |
| `from_url` | 规范化后的源分享链接，同一来源可保留多条历史记录 |
| `fs_id` | 临时容器引用：百度目录路径 / 夸克 fid，必填且非空 |
| `share_url` | 临时分享链接，百度链接自带 `pwd` |
| `expires_at` | 0 状态为处理截止时间；1 状态为分享 TTL；4 状态为清理触发时间 |
| `status` | 记录状态 |
| `cleanup_fail_count` | 清理失败累计次数 |
| `fail_reason` | 最近失败原因，最多 512 rune |
| `created_at` | 创建时间 |
| `updated_at` | 更新时间 |

索引：

- `idx_app_from_url(app, from_url, id)`：同租户同源链接按 ID 倒序读取最新记录；
- `idx_app_status_expires`：按租户和状态扫描到期记录；
- `idx_app_account`：账号引用统计与按账号清理。

### 6.2 状态

```go
const (
	SearchTransferStatusTransferring uint8 = 0 // 转存中
	SearchTransferStatusShared       uint8 = 1 // 已分享
	SearchTransferStatusAbandoned    uint8 = 2 // 清理失败放弃重试
	SearchTransferStatusCleaned      uint8 = 3 // 已清理
	SearchTransferStatusFailed       uint8 = 4 // 提取失败，待清理
)
```

状态转换：

| 当前 | 触发 | 目标 |
| --- | --- | --- |
| - | 创建容器并开始转存 | `0` |
| `0` | 转存、分享、写记录成功 | `1` |
| `0` | 转存失败或分享失败 | `4` |
| `0` | 超过处理期限被 worker 清理成功 | `3` |
| `0` | 超过处理期限但清理失败 | `4`，`cleanup_fail_count+1` |
| `1` | 容器仍存在且收到同源请求 | `1`，延长 `expires_at`；缺少 `share_url` 时重新生成分享 |
| `1` | 容器已不存在且收到同源请求 | 新建一行 `0`；旧行由 worker 转为 `3` |
| `2`/`3` | 容器仍存在且保存有分享链接 | 恢复为 `1`，延长 `expires_at` |
| `1` | 到期清理成功 | `3` |
| `1`/`4` | 清理失败且未达上限 | 保持原状态，`cleanup_fail_count+1` |
| `1`/`4` | 清理失败达到 `business.search.cleanupMaxFailCount` 次 | `2` |
| `2` | 无自动转换 | 终态，需人工处理 |

`fs_id` 在记录创建时写入，后续状态转换不清空，保留审计和人工排查依据。

### 6.3 实体与仓储

```go
type SearchTransfer struct {
	App              string  `json:"app"              gorm:"column:app"`
	AccountId        uint32  `json:"accountId"        gorm:"column:account_id"`
	Keyword          string  `json:"keyword"          gorm:"column:keyword"`
	ClientIP         string  `json:"clientIp"         gorm:"column:client_ip"`
	FromUrl          string  `json:"fromUrl"          gorm:"column:from_url"`
	FsId             string  `json:"fsId"             gorm:"column:fs_id"`
	ShareUrl         *string `json:"shareUrl"         gorm:"column:share_url"`
	ExpiresAt        *int64  `json:"expiresAt"        gorm:"column:expires_at"`
	Status           *uint8  `json:"status"           gorm:"column:status"`
	CleanupFailCount *uint32 `json:"cleanupFailCount" gorm:"column:cleanup_fail_count"`
	FailReason       *string `json:"failReason"       gorm:"column:fail_reason"`
	model.BaseModel
}

func (SearchTransfer) TableName() string { return "search_transfer" }
```

仓储只定义接口，具体方法控制在：

- `GetLatestByFromURL(ctx, app, fromURL)`：按 ID 倒序返回同源最新记录；
- `GetByID(ctx, app, id)`：清理 worker 按记录 ID 重新读取，避免误清理同源新记录；
- `Create(ctx, app, record)`；
- `Update(ctx, app, record)`；
- `ListExpired(ctx, app, before, limit)`；
- `CleanupApps(ctx)`：返回存在待清理记录的 `DISTINCT app`；
- `DeleteHistory(ctx, app, before, limit)`。

所有查询、更新、删除都必须带 `app` 条件。管理端来源转存不经过该仓储。

## 7. 清理 worker

清理不依赖旧 `cmd` 或外部 crontab，由在线服务自身在启动后拉起。

### 7.1 调度

- 使用 kratosx tasker 的 `AfterStart` 注册；
- 每 `business.search.cleanupInterval` 执行一轮；
- 全局 worker 使用 `psou:system:search:cleanup:lock` 的 `TryAcquire()`，同一时间只有一个实例执行；
- 每轮先查询 `search_transfer` 中待清理记录的 `DISTINCT app`，再按 app 查询待清理记录；
- 单批读取 `business.search.cleanupBatch` 条，下一轮继续；
- 每条记录先获取 `psou:{app}:search:transfer:lock:{sha256(fromURL)}`，避免与用户复用/重新提取竞争；
- 获取锁后必须按 `record.id` 重新读取记录，不能按 `from_url` 重新读取最新记录。

待清理条件：

- `status IN (0, 1, 4)`；
- `expires_at <= now`；
- `fs_id != ''`；
- `status=0` 只清理超过处理期限的残留记录。

### 7.2 单条清理

1. 按 `app + account_id` 读取账号；
2. 持源链接锁按 `app + id` 重新读取记录；记录已删除或状态不再待清理时跳过；
3. 账号不存在时标记 `2=清理放弃`，保留记录；
4. 命中账号清理冷却 key 时跳过本轮；
5. 先调用 `Exists` 探测容器；明确不存在时直接标记 `3=已清理`；
6. 否则调用 `DeletePaced` 删除临时容器；
7. 成功后将状态改为 `3=已清理`；
8. 失败时 `cleanup_fail_count+1`，写 `fail_reason`；
9. 失败达到 `business.search.cleanupMaxFailCount` 次时改为 `2=清理放弃`；
10. 失败后给账号设置 `business.search.cleanupBlockedTTL` 清理冷却，避免连续对同一账号发起删除；
11. 每个账号每轮最多刷新一次容量。

账号清理冷却 key：

```text
psou:{app}:search:account:cleanup-blocked:{accountId}
```

### 7.3 历史记录

历史记录保留 `business.search.recordRetention`：

- 只硬删 `status=3` 的记录；
- 可硬删 `status=4` 且没有残留容器的记录；本期所有 `4` 都保留容器引用，因此默认不硬删；
- 永不自动硬删 `status=2`，避免丢失可能残留在网盘中的容器线索。

## 8. 配置、超时与账号协作

### 8.1 配置

```yaml
business:
  search:
    pansouURL: "http://..."
    pansouTimeout: 30s
    tokenKey: "${SEARCH_TOKEN_KEY}"
    tokenTTL: 30m
    shareTTL: 3m
    quickMaxResults: 80
    processingTTL: 3m
    minFreeBytes: 5368709120 # 5 GiB
    maxAccountAttempts: 3
    transferTimeout: 110s
    transferLockTTL: 3m
    cleanupInterval: 30s
    cleanupBatch: 100
    cleanupMaxFailCount: 5
    cleanupBlockedTTL: 2h
    recordRetention: 24h
```

规则：

- `pansouURL` 是部署地址，必须显式配置；
- `pansouTimeout` 是单次 pansou 请求超时；
- `tokenKey` 必须由环境变量注入；
- `tokenTTL` 同时用于检索 token 和文件树 meta，不再单独配置 `metaTTL`；
- `shareTTL` 是临时分享有效时间，不是网盘平台分享的最终寿命；
- `processingTTL` 是 `status=0` 的最长处理时间；
- `minFreeBytes` 是选号最小剩余容量，单位为字节；
- `maxAccountAttempts` 是限流、失效或容量不足时最多尝试的账号数；
- `transferTimeout` 是单次提取内部超时，必须小于 `server.http.timeout`；
- `transferLockTTL` 是同源提取锁的租期，必须覆盖 `transferTimeout` 并开启自动续期；
- 清理参数、失败冷却和历史保留时间统一从 `business.search` 读取；
- 业务代码通过 `ctx.Config().Search` 读取，不在 service 中重复定义这些默认值或常量。

配置项：

| 配置 | 默认值 | 说明 |
| --- | --- | --- |
| `pansouTimeout` | 30s | pansou 请求超时 |
| `quickMaxResults` | 80 | quick 最大返回数 |
| `processingTTL` | 3m | `status=0` 的最长处理时间 |
| `minFreeBytes` | 5368709120（5 GiB） | 选号最小剩余容量 |
| `maxAccountAttempts` | 3 | 限流/失效时最多尝试账号数 |
| `transferTimeout` | 110s | 单次提取内部超时 |
| `transferLockTTL` | 3m | 同源提取锁租期 |
| `cleanupInterval` | 30s | 清理轮询间隔 |
| `cleanupBatch` | 100 | 单轮每 app 处理条数 |
| `cleanupMaxFailCount` | 5 | 清理失败上限 |
| `cleanupBlockedTTL` | 2h | 删除失败账号冷却时间 |
| `recordRetention` | 24h | 已清理记录保留时间 |

### 8.2 HTTP 超时

当前全局 `server.http.timeout=10s` 不足以覆盖仍是同步模型的在线提取。本期采用：

- `server.http.timeout` 调整为 `120s`；
- 网关 `proxy_read_timeout` 同步调整为 `120s`；
- 前端提取请求超时设置为 `120s`；
- pansou HTTP client 读取 `business.search.pansouTimeout`；
- 单次提取内部上限读取 `business.search.transferTimeout`；
- 管理端转存与公共提取共用 120 秒上限。

超时后用户可以用同源 token 重试：

- 已成功写库时直接复用分享；
- 仍在处理中时返回 `SearchTransferBusyError`；
- 失败残留由清理 worker 处理。

本期不引入异步任务表、轮询接口或 Redis 任务状态。

### 8.3 Account 与 PanClient 的配合

为避免搜索模块复制账号状态写回逻辑，在 `Account` 服务增加统一入口：

```go
func (s *Account) HandlePlatformError(ctx core.Context, app string, in *types.AccountPlatformErrorInput) error
```

由 Account 在账号锁内重新读取账号并统一处理限流、登录态失效和空间不足。Search 只负责判断是否换号。

`SelectAccountRequest` 增加两个可选字段：

- `ExcludeIds []uint32`：排除本轮已失败账号；
- `RequireTransferDir bool`：要求对应通路的转存目录与 `fsId` 已配置。

同时增加只读验链选号：

```go
func (s *Account) SelectReadAccount(ctx core.Context, app, platform string) (*entity.PanAccount, error)
```

只检查正常状态和未限流，不检查每日额度、不写计数，用于文件树浏览和勾选统计。

`PanClient` 现有 `EnsureDir`、`TransferToDir`、`ResolveShareFsId`、`CreateShare`、`DeletePaced`、`Exists` 已满足本期能力，不新增平台专用分支。

## 9. 错误码

在 `api/errors/proto/errors.proto` 末尾追加，编号从 80 开始，避免与现有 60～67 冲突：

| 枚举 | HTTP | 默认文案 |
| --- | --- | --- |
| `SearchError` | 500 | 资源检索失败 |
| `SearchTransferError` | 500 | 转存失败 |
| `SearchLinkInvalidError` | 400 | 转存凭证无效或已过期，请重新搜索 |
| `SearchNoShareAccountError` | 503 | 无可用分享账号 |
| `SearchShareExpiredError` | 400 | 该分享已被取消或失效，请切换其他资源尝试一下～ |
| `SearchPasswordError` | 400 | 提取码错误或缺失，请切换其他资源尝试一下～ |
| `SearchTransferBusyError` | 409 | 资源正在提取中，请稍后重试 |

客户端不接收平台 errno，底层错误只写服务端日志和 `fail_reason`。

## 10. 实现落点

```text
server/psou/
├── api/search/
│   ├── proto/search.proto
│   ├── proto/search_service.proto
│   └── 生成文件
├── internal/
│   ├── app/
│   │   ├── search.go                 # HTTP/gRPC handler 与依赖注入
│   │   └── search_cleanup.go         # AfterStart 注册清理 worker
│   ├── types/
│   │   └── search.go                 # 请求、响应、内部结果 DTO
│   ├── domain/
│   │   ├── entity/search_transfer.go
│   │   ├── repository/search_transfer.go
│   │   ├── repository/pansou.go
│   │   └── service/
│   │       ├── search.go             # 检索、文件树、扫描、管理端转存
│   │       ├── search_token.go       # token/meta 加解密
│   │       ├── search_transfer.go    # 在线提取、复用、选号
│   │       └── search_cleanup.go     # 到期清单与状态迁移
│   └── infra/
│       ├── apis/pansou.go            # pansou HTTP client
│       └── dbs/search_transfer.go    # GORM 仓储
```

约束：

- proto 生成文件不手改；
- repository 只放 interface；
- `types` 不依赖 `entity`；
- 不使用 `AutoMigrate`；
- 不新增 `cmd/`；
- 不写单元测试，按用户要求由人工联调验收；
- 除本次直接依赖的账号能力外，不顺带改造其他模块。

## 11. 前端改造

### 11.1 H5 / 微信小程序 / PC

| 旧路径 | 新路径 |
| --- | --- |
| `/psou/client/search/quick` | `/psou/api/search/quick` |
| `/psou/client/search/transfer` | `/psou/api/search/transfer` |

同时：

- 删除未使用的 `/psou/client/search` 全量检索封装，不再保留 `/client/*` 兜底；
- 删除未使用的 `CheckResources` API、请求/响应类型和 `ResourceCheckState`；
- `TransferResourceRequest` 只保留 `token`，删除 `files`、`transferAll`、`meta`；
- `TransferResourceReply` 删除 `password`，模板只使用 `shareUrl`；
- 复制分享时直接复制完整 `shareUrl`，百度链接已经带取码；
- 公共请求统一携带 `X-App-Key`；
- 提取请求超时设置为 120 秒，loading 文案和进度展示保持不变。

### 11.2 admin-web

| 旧路径 | 新路径 |
| --- | --- |
| `/psou/client/search/quick` | `/psou/admin/search/quick` |
| `/psou/client/search/transfer/files` | `/psou/admin/search/files` |
| `/psou/client/search/transfer/scan` | `/psou/admin/search/scan` |
| `/psou/client/search/transfer-to-account` | `/psou/admin/search/transfer` |

同时：

- 删除 `sourcePassword`、`sharePassword`、`targetPath` 字段；
- 删除 `resourceTitle`、`resourceSummary`、`resourceDescription` 字段；
- 资源来源弹窗的复制逻辑只使用 `shareUrl`；
- 选择账号后仍回填 `accountId`、`fsId`、`size`、`fileCount`、`folderCount`；
- 资源保存仍由现有 `netdisk` 接口完成，不在 search 模块直接写 `resource` 或 `netdisk`。

## 12. 验收清单

### 公共搜索

- quick 只返回百度/夸克，标题推广链接被剔除；
- 两个平台交替出现，结果不超过 `business.search.quickMaxResults` 条；
- 同一结果重复 URL 被去重；
- token 跨 app 使用失败；
- token 超过 `business.search.tokenTTL` 失败；
- 公共端不存在 `check` 接口，公共提取不接受 `files`、`transferAll`、`meta`。

### 公共提取

- 百度提取成功，`shareUrl` 自带 `pwd`；
- 夸克提取成功，`shareUrl` 无空 `pwd` 参数；
- 同一源链接在分享 TTL 内重复提取时，先探测 `fs_id`，容器存在则复用同一分享并延长 TTL；
- 分享 TTL 已过期但容器仍存在时，复用旧容器、延长 TTL，不重复转存；
- 已有记录未保存 `share_url` 但容器仍存在时，基于旧容器重新生成分享；
- 容器已不存在时才新建提取记录；请求路径不清理旧容器；
- 旧记录及其容器由清理 worker 按记录 ID 异步处理；
- 并发请求只有一个执行转存，其余返回忙碌或复用；
- 公共提取固定整包转存；
- 不因固定大小上限拒绝；目标账号容量不足时换号；
- 搜索已失效/提取码错误分别返回对应 400 错误；
- 命中平台限流时最多换 `business.search.maxAccountAttempts` 个账号，失败账号状态被正确写回；
- 成功后 `search` 转存/分享计数各增加 1；
- 复用不增加计数；
- `search_transfer` 的 `fs_id` 非空，`share_url` 可访问。

### 清理

- TTL 到期后容器被删除，状态变为 `3=已清理`；
- 删除失败计数递增，达到 `business.search.cleanupMaxFailCount` 后变为 `2=清理放弃`；
- 删除失败账号进入 `business.search.cleanupBlockedTTL` 冷却；
- 容器已不存在时直接标记已清理；
- 处理中超时的 `0` 状态残留能被清理；
- 多租户记录按 app 隔离，worker 不越权清理其他 app 的记录；
- 记录硬删只处理允许硬删的状态。

### 管理端

- 粘贴百度/夸克链接可以读取文件树；
- 文件树/扫描不占每日转存/分享额度；
- 指定账号转存只写 `manual` 目录并累加 `manual` 计数；
- 指定账号平台不匹配时拒绝；
- 管理端转存响应不包含旧密码、来源链接和目标路径字段；
- 管理端转存不会新增 `search_transfer` 记录；
- 资源保存能用返回的 `fsId` 创建/更新 `netdisk`。

### 构建

- `make proto` 可重新生成 search 代码；
- `go test ./...`、`go build ./...` 通过；
- admin-web、H5 类型检查通过；
- 全仓库不存在 `/psou/client/search` 调用。

## 13. 本轮不做

- 异步提取任务与轮询协议；
- 搜索历史、搜索耗时、热门词和页面行为统计；
- 临时分享二维码服务端生成，仍由前端生成；
- 网盘平台分享有效期与本地 TTL 的精确同步；
- 多实例清理 worker 的指标面板；
- 旧在线服务数据迁移；
- `fixed`、`transfer`、`distribute_*` 的在线调度。
