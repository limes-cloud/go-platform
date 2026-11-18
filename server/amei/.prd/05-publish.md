# 批量发布

> 状态：方案设计
> 日期：2026-11-12
> 范围：一键批量发布、平台自适应、素材上传、审核状态、幂等和人工接管
> 前置：目标平台已完成 OAuth 授权且对应内容类型能力为 `supported=true`

## 1. 产品定义

用户在 amei 选择：

- 1 个内容版本；
- 1 个或多个平台账号；
- 立即发布或定时发布；
- 可选的平台级覆盖项。

amei 创建一个发布批次，并按 `contentVersion × platformAccount` 拆成多个任务。每个任务独立执行、
独立重试、独立失败，不因一个平台未通过审核而阻塞其他平台。

“一键发布”不承诺：

- 所有平台都有开放发布 API；
- 所有任务一次成功；
- 发布后立即公开；
- 内容一定通过平台审核；
- 搜索引擎一定收录；
- 同一份文案适合所有平台。

## 2. 发布前检查

控制面在创建任务前检查：

1. 用户是否拥有该平台账号；
2. 账号状态是否 `active`；
3. 授权 scope 是否包含对应内容类型和能力；
4. 适配器 `capabilities` 是否支持 `article`、`image_text` 或 `video`；
5. 内容是否完整：文章有标题/正文，图文有图片，视频有主视频素材；
6. 媒体是否已在 `amei-media` 状态为 `ready`；
7. 是否重复提交同一 `contentVersion + account + scheduledAt`；
8. 是否超过内部软额度；平台硬额度由适配器返回。

任一检查失败时，平台选项在提交前禁用并展示明确原因。不能等调用平台后才报“未开通”。

## 3. 内容自适应

控制面只传统一字段，适配器负责平台映射：

| 统一字段 | 适配器处理 |
| --- | --- |
| `title` | 截断、清洗、补充书名/作者；空标题平台生成默认标题 |
| `summary` | 作为摘要；不支持摘要时并入正文开头 |
| `body` | Markdown/HTML/纯文本转换与清洗 |
| `canonicalUrl` | 平台允许时加入正文；不允许时由适配器移除 |
| `tags` | 映射为话题/标签；不支持则忽略 |
| `categoryHints` | 映射为平台分类；无法映射时使用平台默认或要求人工 |
| `media` | 下载签名 URL，校验哈希，上传平台素材库 |
| `cover` | 裁切、转码、上传封面素材 |
| `visibility` | 公开/私密/仅粉丝等平台枚举映射 |
| `copyright` | 原创/转载/禁止转载等平台字段 |
| `brandDisclosure` | 商业内容标识；平台不支持时提示合规风险 |
| `scheduledAt` | 平台支持原生定时则传递，否则控制面等待后触发 |

适配器不能自动改写书籍核心事实、作者、价格、购买链接或评价性结论；平台敏感词处理只能提示或做等价表达，不能伪造内容。

## 4. 素材上传与发布解耦

```text
内容版本 ready
    │
    ├─ asset 未上传平台：创建 media/upload-task
    │       └─ 适配器下载 -> 平台上传 -> platformMediaId
    │
    └─ asset 已缓存：复用 platformMediaId
            │
            ▼
      创建 publish-task
            │
            ├─ 平台创建/投稿成功 -> pending_review
            ├─ 平台直接发布 -> published
            ├─ 审核拒绝 -> failed
            └─ 需要授权/确认 -> needs_action
```

为什么分开：

- 大视频上传耗时长，失败后不应重新创建内容；
- 同一素材可复用于多个标题/文案版本；
- 平台素材有独立有效期和清理规则；
- 可以只重试素材上传，不触发内容发布。

## 5. 任务模型

### 5.1 `publishBatch`

一次用户操作产生的任务集合：

```json
{
  "id": "pb_1001",
  "userId": "u_1001",
  "contentVersionId": "cv_1001",
  "contentType": "video",
  "mode": "now",
  "scheduledAt": null,
  "status": "running",
  "total": 3,
  "published": 1,
  "pendingReview": 1,
  "needsAction": 1,
  "failed": 0
}
```

### 5.2 `publishTask`

一个内容版本在一个平台账号上的一次发布：

```json
{
  "id": "pt_1001",
  "batchId": "pb_1001",
  "userId": "u_1001",
  "contentVersionId": "cv_1001",
  "accountId": "pa_1001",
  "platformCode": "douyin",
  "contentType": "video",
  "status": "pending_review",
  "idempotencyKey": "cv_1001:pa_1001:now:20261112",
  "adapterTaskId": "adapter_pt_01",
  "platformPostId": null,
  "platformUrl": null,
  "lastError": null
}
```

唯一性约束：`user_id + account_id + content_version_id + publish_mode + scheduled_slot`。
重复点击“发布”返回已有批次，不新建重复任务。

## 6. 状态机

```text
queued
  │
  ▼
validating
  │
  ├─ invalid ─────────────────────────────► failed
  ▼
uploading_media
  │
  ├─ media failed ────────────────────────► failed
  ▼
publishing
  │
  ├─ needs user/platform action ──────────► needs_action ──完成──┐
  │                                                               │
  ├─ platform accepted, reviewing ─────────► pending_review        │
  │                                                               │
  ├─ platform confirmed published ─────────► published             │
  │                                                               │
  └─ explicit reject/error ───────────────► failed                │
                                                                  │
needs_action ──重新授权/补资料后重新执行──────────────────────────┘
```

允许状态：

`queued`、`validating`、`uploading_media`、`publishing`、`pending_review`、`needs_action`、`published`、`failed`、`canceled`。

`published` 必须由平台接口确认，或由用户在人工接管页确认并回填作品 ID/URL；仅点击“发布”按钮不算成功。

## 7. 批次聚合

| 批次状态 | 条件 |
| --- | --- |
| `queued` | 所有任务尚未开始 |
| `running` | 至少一个任务运行中 |
| `needs_action` | 无运行中任务，且至少一个需要人工处理 |
| `published` | 所有任务 `published` |
| `partial` | 至少一个 `published`，且至少一个 `failed/skipped/canceled` |
| `pending_review` | 至少一个审核中，其余也已提交或等待审核 |
| `failed` | 所有任务 failed/canceled |

批次状态是派生状态，可由任务状态重算，不单独维护互斥的业务真相。

## 8. 发布 API

### 8.1 创建批次

`POST /amei/api/v1/publish-batches`

```json
{
  "contentVersionId": "cv_1001",
  "accountIds": ["pa_1001", "pa_1002", "pa_1003"],
  "mode": "now",
  "scheduledAt": null,
  "platformOverrides": {
    "pa_1002": {
      "title": "更适合快手用户的标题",
      "tags": ["读书"]
    }
  },
  "idempotencyKey": "client-generated-uuid"
}
```

响应：

```json
{
  "batchId": "pb_1001",
  "status": "queued",
  "tasks": [
    {"taskId": "pt_1001", "accountId": "pa_1001", "status": "queued"},
    {"taskId": "pt_1002", "accountId": "pa_1002", "status": "skipped", "reason": "content_type_not_supported"},
    {"taskId": "pt_1003", "accountId": "pa_1003", "status": "queued"}
  ]
}
```

被跳过的平台不进入适配器调用，原因写入任务。

### 8.2 查询批次

`GET /amei/api/v1/publish-batches/{id}` 返回批次和任务列表。

### 8.3 查询任务

`GET /amei/api/v1/publish-tasks/{id}` 返回状态、平台 URL、审核原因和人工动作。

### 8.4 取消

`POST /amei/api/v1/publish-batches/{id}/cancel`

只能取消未提交平台的任务；已提交任务需看平台是否支持撤回。

### 8.5 人工确认

`POST /amei/api/v1/publish-tasks/{id}/confirm`

```json
{
  "platformPostId": "optional",
  "platformUrl": "https://...",
  "note": "用户已在平台后台确认发布"
}
```

只有 `needs_action` 或平台明确不支持状态回读的任务允许人工确认。

## 9. 幂等与重复发布

- 控制面 `idempotencyKey` 保证同一批次不重复创建；
- 适配器发布接口同样接收 `Idempotency-Key`，保存平台侧请求映射；
- 超时后先查询 `GET /v1/publish-tasks/{taskId}` 或平台作品列表；
- 平台不支持幂等键时，适配器在本地记录 `contentVersionId + accountRef + contentHash`，并在重试前查询最近作品；
- 平台已发布但 URL 暂时不可得，状态保持 `published`，URL 可为空；
- 审核拒绝的内容默认不自动二次发布，必须人工修改内容版本。

## 10. 审核与人工接管

平台审核是正常流程，不是系统故障：

- `pending_review`：继续定时查询；
- `needs_action`：展示平台要求，例如重新授权、实名、扫码、补充类目；
- `failed`：保存脱敏审核原因、平台错误码、可重试性；
- 无公开状态接口的平台：任务在 `published` 后仍标记 `statusSource=submit_accepted`，避免误称“已公开”。

人工接管页至少展示：平台、账号、内容标题、当前状态、平台原始提示、重新授权按钮、打开平台后台按钮、确认/标记失败按钮。

## 11. 定时发布

- 平台支持原生定时：把 `scheduledAt` 交给适配器；控制面记录 `scheduledBy=platform`；
- 平台不支持：控制面在计划时间触发任务；记录 `scheduledBy=amei`；
- 重启后从数据库扫描到期任务，不依赖内存 timer；
- 同一任务只允许一个 worker 持有租约；
- 时区统一存 UTC，界面按用户时区展示。

## 12. 失败分类

| 类型 | 示例 | 处理 |
| --- | --- | --- |
| 内容校验 | 标题超长、视频缺失 | 不调用平台，提示修改 |
| 媒体处理 | 转码失败、封面不合规 | 回到 `amei-media`，不重试发布 |
| 授权 | token 过期、scope 不足 | `needs_action`，重新授权 |
| 平台限流 | QPS/日额度 | 按 `retryAfterMs` 延后 |
| 审核拒绝 | 违规、重复、版权 | `failed`，人工修改 |
| 适配器暂时不可用 | 5xx、超时 | 指数退避重试 |
| 未知结果 | 请求超时但平台可能已创建 | 先查询，禁止直接重发 |

## 13. 发布审计

每次尝试保存：

- `task_id`、`attempt`、`request_id`、`adapter_request_id`；
- 变更前/后状态；
- HTTP 状态、平台错误码、脱敏错误信息；
- 媒体上传耗时、平台发布耗时；
- 是否人工确认、操作人、备注；
- 创建时间。

不记录完整正文、平台 token、cookie、OAuth code 或签名 URL 的完整查询串。

## 14. 验收标准

- 文章、图文、视频三种内容都可以创建批次；
- 每个平台账号生成独立任务；
- 不支持的内容类型在提交前被禁用或标记 skipped；
- 单平台失败不影响其他平台；
- 重复提交不会重复发布；
- 平台审核中、需重授权、明确拒绝三种情况可区分；
- 视频素材上传失败与内容发布失败可分别重试；
- 发布成功后保存平台作品 ID/URL 和状态来源；
- 定时任务重启后可恢复；
- 控制面没有平台专属发布分支。
