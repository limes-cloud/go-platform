# Account Recover 双任务在线化规划

> 状态：已实现
> 日期：2026-11-07
> 范围：`server/psou` 网盘账号限流恢复与账号信息同步
> 前置：`pan-account.md`、旧版 `~/software/psou/cmd/account/recover.go`

## 1. 任务拆分

旧版 `account recover` 由 crontab 每 10 分钟执行一次，代码里实际做了两件事：

1. 扫描限流账号，探测登录态并真实建一次分享，确认平台风控是否恢复；
2. 同步正常账号的派生信息。

新版拆成两个独立在线任务，而不是一个任务里串两段：

| 任务 | 周期 | 职责 | 不做什么 |
| --- | --- | --- | --- |
| `account share recover` | 30 分钟 | 扫描限流账号，真实建分享，确认 share 链路恢复后清限流标记 | 不刷新容量/VIP，不处理普通正常账号 |
| `account info sync` | 10 分钟 | 同步正常账号的登录态、userId、UK、容量、VIP、最近检测时间 | 不清限流标记，不做限流恢复判定的主流程 |

两个任务都只处理 `pan_account`。旧版里的 `isUploadScope`、`isBanned`、`banDays`
属于分发渠道账号信息，已拆分到 `distribute_account`，不迁入这两个任务。

新版现有单账号 `RecoverAccount` 只探测登录态，登录有效就清 `ext.limitedAt`。
这条判定不够：线上实测百度 `31034` 只打在 `/share/set`，登录接口正常并不代表
分享链路已恢复。`share recover` 任务和手动恢复必须共用“真实建分享”判定。

## 2. 共同约束

### 2.1 数据边界

| 维度 | 旧版 | 新版 | 处理 |
| --- | --- | --- | --- |
| 租户 | 单租户 | `pan_account.app` | 后台任务无 `AppKey`，必须从 DB 枚举 app |
| 状态 | `0正常/1失效/2冻结/3停用/4限流` | `-1失效/0停用/1正常` | 限流只体现在 `ext.limitedAt`，不占用主状态 |
| 容量 | 旧版在 ext | 新版独立列 | 写 `storage_total/storage_used` |
| 用户身份 | `user_id` = 百度知道 userId | 当前实际仍是百度知道 userId | 保留语义；网盘 uk 单独放 `ext.uk` |
| 凭证 | `cookie` | `token` | 只在进程内使用，不落日志、不出响应 |
| 分发权限/封禁 | 旧版在 pan_account/ext | 已归 `distribute_account` | 两个任务都不处理 |

### 2.2 并发与写回

1. 每个任务有独立全局锁，多实例下同一任务只允许一个实例跑：
   - `psou:system:account:share:recover:lock`
   - `psou:system:account:info:sync:lock`
2. 每个任务内部直接使用 kratosx 协程池：
   `ctx.Pool().NewWaitRunner(pool.WithMaxWaitRunnerOption(4))`。账号之间并发执行，
   不串行；这个 4 是单任务总并发上限，不按 app 拆成 4×N。
3. 单账号继续使用 `psou:{app}:account:lock:{id}`，与手动检测、转存、分享、刷新容量串行；
   同一账号同一时刻只能有一个执行单元。任务内建议使用 `TryAcquire`，抢不到锁直接跳过本轮，
   不能阻塞其它账号。
4. 不新增第二个更新入口；把现有 `dbs.Account.UpdateAccount` 统一改成原子写入口：
   事务内 `SELECT ... FOR UPDATE` 锁行，读取最新账号和 `ext`，执行调用方的增量修改，
   再写回；不能拿批量查询时的快照直接覆盖。
5. 服务层分布式账号锁负责跨任务串行，DB 行锁负责仓储层读改写原子性，两层都要有。
6. 两个任务都只改自己拥有的字段；`ext` 以行锁内读到的最新值为基线。
7. 状态迁移还要带原状态条件，避免覆盖探测期间的人工停用/修改。

## 3. 任务一：Share 恢复探测

### 3.1 周期与范围

- 默认周期：30 分钟；
- 启动后立即抢一次调度锁，抢到后执行；锁 TTL 固定为业务周期，下一轮等待锁过期后再执行；
- 候选条件：`status=1` 且 `ext.limitedAt != null`；
- `status=0/-1` 即使残留 `limitedAt` 也不处理；
- 按 app 逐个执行，账号按 `id` 分页遍历。

### 3.2 需要拉取的信息

#### 数据库

| 字段 | 用途 |
| --- | --- |
| `app`、`id` | 租户隔离、账号锁、日志 |
| `platform` | 选择百度/夸克建分享实现 |
| `token` | 调平台接口，禁止写日志 |
| `status` | 只处理正常账号 |
| `ext.limitedAt` | 判断是否仍处于限流状态 |
| `ext.limitOp` | 记录限流来源 `transfer/share` |
| `ext.recoverRefs` | 建分享所需稳定文件/目录引用 |

#### 平台侧

| 平台 | 信息 | 接口 | 用途 |
| --- | --- | --- | --- |
| 百度 | 建分享结果与 errno | `CreateShare`（`/share/set`） | 判断 share 风控是否解除 |
| 夸克 | 建分享结果与 errno | `CreateShare` | 判断 share 风控是否解除 |

这个任务不需要拉容量、VIP、userId、UK。容量和会员统一由 10 分钟的信息同步任务负责，
避免每 30 分钟重复拉一堆非恢复必需的数据。

### 3.3 分享探针引用

必须用一个稳定、可控、不含业务内容的引用建分享：

1. `ext.recoverRefs` 已存在时直接复用；
2. 不存在时在 `/psou/.recover-probe` 创建专用目录，并上传固定小文件
   `psou-recover-probe.txt`，把文件 fs_id 写入 `ext.recoverRefs`；
3. 恢复时用该引用建一次永久分享，成功即认为 share 链路恢复；
4. 建出的分享不取消，与旧版行为一致。

不读取或分享 `TransferDirs` 中的业务文件，避免恢复探针暴露刚转存的内容。

### 3.4 状态迁移

| 场景 | 状态 | 字段处理 |
| --- | --- | --- |
| 账号已停用/失效/无限流 | 跳过 | 不动 |
| 建分享成功 | 保持 `1` | 清 `limitedAt/limitOp/limitErrno`，写 `lastShareCheckAt` |
| 建分享仍限流 | 保持 `1` | 保留限流字段，更新 `lastShareCheckAt/limitErrno` |
| 建分享返回登录失效 | 改为 `-1` | 保留限流字段，写 `errorCode/lastShareCheckAt` |
| 建分享返回空间不足 | 保持 `1` | 保留限流字段，记录 `limitErrno`；容量交给信息同步任务刷新 |
| 网络失败/出口被拒/未知错误 | 保持 | 更新 `lastShareCheckAt`，下一轮重试 |
| 探测期间被人工停用 | 不改 | 条件写回未命中，放弃本次状态迁移 |

旧版统一用“建分享”作为风控探针，本期沿用。若后续发现只影响转存、不影响分享的限流码，
再为 `limitOp=transfer` 设计独立探针。

## 4. 任务二：账号信息同步

### 4.1 周期与范围

- 默认周期：10 分钟；
- 启动后立即抢一次调度锁，抢到后执行；锁 TTL 固定为业务周期，下一轮等待锁过期后再执行；
- 候选条件：`status=1`；
- 包含处于限流状态的正常账号，保证限流账号的容量/VIP 也持续更新；
- 按 app 逐个执行，账号按 `id` 分页遍历。

### 4.2 需要拉取的信息

#### 数据库

| 字段 | 用途 |
| --- | --- |
| `app`、`id` | 租户隔离、账号锁、日志 |
| `platform` | 选择平台探针 |
| `token` | 调平台接口，禁止写日志 |
| `status` | 只同步正常账号 |
| `user_id` | 已绑定身份校验 |
| `ext.uk` | 百度网盘身份校验 |

#### 平台侧

##### 百度

| 信息 | 当前接口 | 用途 | 落库 |
| --- | --- | --- | --- |
| 网盘会话是否有效 | `CheckPanSession`（`/api/quota`，`-6` 视为失效） | 判断登录态 | `status/errorCode` |
| 百度知道 userId | `GetUserId`（`loginInfo`） | 身份校验、防止换号 | `user_id`（仅空绑定时） |
| 网盘 uk | `getUK`（bdstoken） | 身份校验、识别自己的分享 | `ext.uk`（仅空绑定时） |
| 总容量/已用容量 | `GetStorageQuota` | 选号容量门控 | `storage_total/used` |
| 会员类型 | `GetVipType`（`uinfo`） | VIP 解压能力 | `ext.isVip` |
| 最近同步时间 | 本任务写入 | 排障/展示 | `ext.lastCheckAt` |

当前 `CheckPanSession` 和 `GetStorageQuota` 都请求 quota 接口，单账号会重复拉一次容量。
实现时可合并成一次“quota 探测”，返回 `errno + total + used`，信息同步只发一次请求。

##### 夸克

| 信息 | 当前接口 | 用途 | 落库 |
| --- | --- | --- | --- |
| 登录态 | `listDir(root)`，`31001` 视为失效 | 判断会话是否有效 | `status/errorCode` |
| 总容量/已用容量 | `getMemberInfo`（`/clouddrive/member`） | 容量门控 | `storage_total/used` |
| 会员 | `member_type + exp_at` | VIP 能力 | `ext.isVip` |
| 最近同步时间 | 本任务写入 | 排障/展示 | `ext.lastCheckAt` |

夸克当前不返回稳定的 `user_id/uk`，只能同步登录态、容量和会员。

### 4.3 写回规则

| 写入项 | 条件 | 说明 |
| --- | --- | --- |
| `storage_total/used` | 成功拿到容量 | 失败保留旧值 |
| `ext.isVip` | 平台返回会员信息 | 非 VIP 时同时清 `isUnzipAccount` |
| `ext.uk` | 账号尚未绑定且百度返回 | 已绑定且不一致时拒绝写并告警 |
| `user_id` | 账号尚未绑定且百度返回 | 只补空绑定，不覆盖已有值 |
| `ext.lastCheckAt` | 每次真实探测后 | 平台请求失败时是否更新按产品口径决定，建议不更新 |
| `status/errorCode` | 平台明确判定登录失效 | 只允许 `1 -> -1`；不改 `0`，不恢复失效账号 |

信息同步任务不修改 `limitedAt/limitOp/limitErrno`，因此不会和 share 恢复任务
争抢限流状态机。它只负责“账号当前长什么样”，不负责“限流是否解除”。

## 5. 两个任务的关系

```text
每 10 分钟：account info sync
  status=1 全量
  -> Probe
  -> 更新容量/VIP/身份/最近检查时间
  -> 登录明确失效时 1 -> -1

每 30 分钟：account share recover
  status=1 AND limitedAt != null
  -> CreateShare(recoverRef)
  -> 成功：清限流
  -> 失效：1 -> -1
  -> 仍限流/未知：保留限流，更新下次检查时间
```

两个任务会同时覆盖限流账号，但写集不冲突：

- 信息同步只写容量、VIP、身份、`lastCheckAt`；
- share 恢复只写 `status/errorCode` 和限流相关 ext 字段；
- 两者共用账号锁，后拿到锁的任务会基于最新记录做增量写回。

## 6. 在线任务实现

### 6.1 触发方式

- 复用 `ctx.AfterStart` + goroutine，任务体使用 `for {}`；
- 每轮先 `Acquire` 任务级 Redis 锁，拿到锁后再扫描账号；不主动释放，锁 TTL 直接使用业务周期；
- `WithLockAcquireWaitTime(5s)` 控制等待期间的自旋频率，避免长时间高频 Redis 轮询；
- 不新增 `cmd/`，不依赖 crontab；
- 两个任务分别注册、分别配置周期、分别拿任务锁；
- 启动即抢锁执行一次，之后按锁 TTL 周而复始。

### 6.2 app 枚举与分页

后台 context 没有 `AppKey`，不能调用 `ctx.AppKey()`。仓储需要提供：

- `ListShareRecoverApps(ctx)`：存在 `status=1 + limitedAt` 的 app；
- `ListShareRecoverAccounts(ctx, app, afterID, limit)`：按 `id ASC` 分页；
- `ListInfoSyncApps(ctx)`：存在 `status=1` 账号的 app；
- `ListInfoSyncAccounts(ctx, app, afterID, limit)`：按 `id ASC` 分页。

限流筛选沿用旧版备份的 JSON 条件：

```sql
status = 1
AND JSON_EXTRACT(ext, '$.limitedAt') IS NOT NULL
AND JSON_TYPE(JSON_EXTRACT(ext, '$.limitedAt')) <> 'NULL'
```

`ext` 没有 JSON 索引，账号量大时需要关注扫描成本；至少补 `(app, status)` 索引，
后续再评估生成列或独立 `limited_at` 列。

### 6.3 建议配置

```yaml
business:
  account:
    shareRecoverInterval: 30m
    shareRecoverBatch: 50
    shareRecoverConcurrency: 4
    infoSyncInterval: 10m
    infoSyncBatch: 100
    infoSyncConcurrency: 4
```

- `shareRecoverBatch` 是每次分页大小，不是整轮上限；
- `infoSyncBatch` 同样只控制分页，worker 会继续按 `afterID` 遍历完当前 app；
- 两个任务各自创建独立 `WaitRunner`，最大并发都固定为 4，配置值建议限制在 `1..4`；
- 并发单位是账号：不同账号可以同时探测，同一账号由账号锁保证串行；
- 单个账号失败只记录该账号结果，不影响同批其它账号；
- 不允许因为一个慢账号阻塞整个 app 的扫描，worker 应持续消费后续账号。

实现直接使用 kratosx 协程池，不自定义 worker、job channel 或 errgroup：

```go
runner := ctx.Pool().NewWaitRunner(
    pool.WithMaxWaitRunnerOption(4), // 单任务账号级最大并发
    pool.WithErrorBreakOption(false),
)

for _, account := range accounts {
    account := account
    runner.AddTask(func() error {
        // TryAcquire 账号锁；抢不到直接返回 nil，跳过本轮
        // 重新读取账号，执行 share 恢复或信息同步
        return nil
    })
}

if err := runner.Wait(); err != nil {
    ctx.Logger().Warnw("msg", "account worker finished with errors", "err", err.Error())
}
for _, taskErr := range runner.ErrorList() {
    ctx.Logger().Warnw("msg", "account task error", "err", taskErr.Error())
}
```

- `WithMaxWaitRunnerOption(4)` 控制同时在途账号数；
- `WithErrorBreakOption(false)` 保证单个账号失败不阻断其它账号；
- `WaitRunner.AddTask` 在达到并发上限时会形成背压，不需要额外手写信号量；
- 分页结果按批提交，不要把全部账号一次性压进内存；
- 每个任务仍然先 `TryAcquire` 账号锁，再重读账号并执行探测；
- 预期业务结果（仍限流、跳过）不计入任务错误，用原子计数器汇总。

### 6.4 观测字段

建议补充以下 `AccountExt`：

| 字段 | 用途 |
| --- | --- |
| `recoverRefs` | share 恢复探针引用 |
| `lastShareCheckAt` | 最近一次 share 恢复探测时间 |
| `limitErrno` | 最近一次限流原始 errno |

`lastCheckAt` 保留给信息同步；`lastShareCheckAt` 单独记录 share 恢复，避免两个周期混在一起。

## 7. 代码落点与缺口

| 层 | 需要补的内容 |
| --- | --- |
| `entity` | `AccountExt` 增加 `recoverRefs/lastShareCheckAt/limitErrno` |
| `repository` | 两组 app 枚举和分页方法；统一改造 `UpdateAccount` 为原子 patch 写入口 |
| `dbs` | `UpdateAccount` 事务内 `FOR UPDATE` 锁行、读最新行、执行 patch、按列写回；JSON 限流筛选与 `(app,status)` 查询 |
| `service` | `RecoverShare` 核心（手动/任务共用）、`SyncInfo` 核心；所有调用方改为通过统一 `UpdateAccount` 增量更新，`HandlePlatformError` 写限流 errno |
| `app` | `account_share_recover.go`、`account_info_sync.go` 两个任务注册；`main.go` 分别挂载 |
| `core/conf.go` | `AccountConf`：两个周期、两个 batch、两个并发上限（默认 4，最大 4） |
| `conf/conf.yaml` | 补 `business.account` 配置 |
| `api/account/proto` | 若补 `limitErrno`，同步管理端展示字段 |

写回统一走改造后的 `dbs.Account.UpdateAccount`，不再保留“service 先查、再把整条
`PanAccount` 交给仓储覆盖”的旧模式。建议把仓储接口改成：

```go
// UpdateAccount 是账号字段和 ext 的唯一写入口。
// 在事务内锁行、读取最新账号、执行增量修改并写回。
// patch 只允许改当前任务拥有的字段；ext 必须在 row lock 内基于最新值修改。
func (r *Account) UpdateAccount(
    ctx core.Context,
    app string,
    id uint32,
    patch func(current *entity.PanAccount) error,
) (*entity.PanAccount, error)
```

实现约束：

1. `ctx.Transaction` 内用 `SELECT ... FOR UPDATE` 查询
   `WHERE app = ? AND id = ?`，同时锁定租户和账号；
2. 查询结果作为最新基线，`patch` 只在这个对象上做增量修改；
3. `patch` 返回错误时整体回滚；
4. 写回只选择本流程拥有的列，避免误覆盖无关字段；
5. `ext` 必须整体序列化写回，但不能在锁外构造；
6. 返回写回后的账号快照，供调用方记日志或继续判断。

改造后所有账号写路径都要收敛到这一个方法，包括：

- 手动更新账号；
- `CheckAccount`、`RecoverShare`、`SyncInfo`；
- 容量刷新、`HandlePlatformError`；
- 每日转存/分享计数。

改造后不再保留第二个 `ext` 写路径：不允许调用方直接 `UpdateColumn("ext", ...)`，
也不允许把锁外读取的旧 `PanAccount` 整行写回。所有 `ext` 变更都在统一
`UpdateAccount` 的行锁内完成。

示意实现：

```go
var current entity.PanAccount
if err := ctx.Transaction(func(txCtx core.Context) error {
    if err := txCtx.DB().
        Clauses(clause.Locking{Strength: "UPDATE"}).
        Where("app = ? AND id = ?", app, id).
        First(&current).Error; err != nil {
        return err
    }
    if err := patch(&current); err != nil {
        return err
    }
    return txCtx.DB().Model(&entity.PanAccount{}).
        Where("app = ? AND id = ?", app, id).
        Select("status", "error_code", "user_id", "storage_total", "storage_used", "ext").
        Updates(&current).Error
}); err != nil {
    return nil, err
}
return &current, nil
```

如果后续需要写 `name/priority/remark` 等其他列，再显式扩展 `Select` 列表，不能默认整行覆盖。

两类业务写回都复用该原子方法：

```sql
-- share 恢复：只改状态、错误码和限流 ext
UPDATE pan_account
SET status = ?, error_code = ?, ext = ?
WHERE app = ? AND id = ? AND status = 1

-- 信息同步：只改身份、容量、VIP 和 lastCheckAt
UPDATE pan_account
SET status = ?, error_code = ?, user_id = ?, storage_total = ?, storage_used = ?, ext = ?
WHERE app = ? AND id = ? AND status = 1
```

SQL 只是目标写集示意；实际必须由统一后的 `UpdateAccount` 在 `FOR UPDATE` 行锁内完成读改写。

## 8. 调用方关系

| 调用方 | 使用哪套逻辑 |
| --- | --- |
| 后台 share 恢复任务 | `RecoverShare`，按 30 分钟周期 |
| 手动 `POST /psou/admin/account/recover` | `RecoverShare`，立即执行 |
| `AccountAvailability` | 账号处于限流时调用 `RecoverShare`；账号锁保证与后台任务互斥 |
| 后台信息同步任务 | `SyncInfo`，按 10 分钟周期 |
| 手动 `POST /psou/admin/account/check` | 保留现有全量探测，可复用 `SyncInfo` 的探测逻辑和状态迁移 |

## 9. 分阶段实施

### 阶段 0：数据与字段确认

- 确认历史数据中 `status=4` 是否已迁移为 `status=1 + ext.limitedAt`；
- 确认旧 `ext.storageTotal/Used` 是否已迁到新列；
- 确认旧 `attachRefs/fixedRefs` 是否可迁成 `recoverRefs`；
- 用真实百度、夸克账号验证空目录/探针文件建分享可用；
- 确认是否补 `lastShareCheckAt/limitErrno`。

### 阶段 1：两个服务核心

- 实现 `RecoverShare`：只建分享，不做容量/VIP；
- 实现 `SyncInfo`：只同步信息，不清限流；
- 手动恢复改走 `RecoverShare`；
- 统一改造 `dbs.Account.UpdateAccount`，所有 ext 读改写从旧快照覆盖切换到行锁内增量更新；
- 保持 `AccountAvailability` 的即时恢复语义，与后台任务共用账号锁互斥。

### 阶段 2：两个在线任务

- 增加两套 app 枚举和账号分页；
- 增加两个全局锁和对应配置；
- 新增 `account_share_recover.go`、`account_info_sync.go`；
- 在 `main.go` 分别注册；
- 输出每轮汇总日志：`apps/scanned/recovered/invalidated/stillLimited/skipped/failed`。

### 阶段 3：观测与调优

- 根据线上恢复成功率调整 30 分钟周期和批量；
- 根据信息同步耗时调整 10 分钟周期；
- 观察并发 4 下的平台错误率和锁等待，必要时调低；不要超过 4；
- 评估 `(app,status)` 索引和 JSON 扫描成本；
- 分发权限同步另起 `distribute_account` worker，不并入这两个任务。

## 10. 验收口径

1. 两个 app 同时存在账号，两个任务都只处理各自 app，不串租户；
2. share 恢复只处理 `status=1 + limitedAt`，`status=0/-1` 残留限流也不处理；
3. 信息同步处理全部 `status=1` 账号，包括限流账号；
4. 信息同步只刷新容量/VIP/身份，不改变 `limitedAt/limitOp`；
5. 建分享成功后才清限流；建分享仍限流时保持原状态；
6. 登录明确失效时，两个任务都只允许把 `1` 改成 `-1`；
7. 平台网络失败时账号状态不变；
8. 探测期间人工停用账号，条件写回不生效；
9. 多实例运行时，每个任务各自只有一个实例执行；
10. 手动恢复与 share 恢复任务结果一致；
11. `AccountAvailability` 与后台 share 任务通过账号锁互斥，同一账号不会并发建分享；
12. Token 不出现在日志、错误信息和响应中。
13. 两个任务并发更新同一账号的不同字段时，`ext` 中的目录、每日计数、限流字段都不会丢更新；
14. 搜索确认没有第二处 `UpdateColumn("ext", ...)`，也没有旧快照整行覆盖。
15. 每个任务同时在途的账号数不超过 4；
16. 4 个不同账号可以并行探测，同一账号不会被执行两次；
17. 某账号锁被手动操作占用时，worker 跳过该账号并继续处理其它账号；
18. 一个慢账号或平台超时不会阻塞同批其它账号完成。

## 11. 待确认决策

1. share 探针使用旧固定文件、专用空目录，还是空目录 + 小文件？建议优先空目录，
   真实平台验证不通过时再放小文件。
2. `lastShareCheckAt/limitErrno` 已纳入实现，用于排障；恢复节奏完全由周期任务和 Redis
   账号锁控制，不再维护 `nextCheckAt`。
3. 历史 `status=4` 数据是否由独立迁移脚本处理？建议迁移成 `status=1 + limitedAt`，
   不让新任务长期兼容状态 4。
4. 信息同步遇到登录失效是否允许 `1 -> -1`？本规划建议允许；否则失效账号会继续参与选号。
5. 分发上传权限同步是否另起 `distribute_account` worker？本规划建议另起，不塞进这两个任务。
