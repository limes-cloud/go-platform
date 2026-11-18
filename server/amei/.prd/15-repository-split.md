# 三仓库拆分与独立部署

> 状态：架构方案
> 日期：2026-11-12
> 目标：上传能力独立成仓，平台发布底层独立实现，控制面只做统一编排
> 依赖方向：`amei -> amei-media`、`amei -> amei-adapters`；媒体仓和适配器仓互不依赖控制面数据库

## 1. 仓库划分

| 仓库 | 职责 | 独立数据 | 独立部署 |
| --- | --- | --- | --- |
| `amei` | 手机号用户、内容与版本、平台账号索引、批次/任务、调度、数据汇总、Web 后台 | MySQL、Redis | `amei-api`、`amei-worker`、`amei-web` |
| `amei-media` | 上传票据、直传校验、MIME/ffprobe、转码、封面、字幕、对象存储、签名 URL、资产生命周期 | MySQL、对象存储、转码队列 | `media-api`、`media-worker` |
| `amei-adapters` | 平台 OAuth、凭据加密、平台素材上传、字段映射、发布、状态查询、指标拉取 | 加密凭据库、适配器 Redis（可选） | 每个平台独立服务或独立部署单元 |

不建立三个仓库共享的数据库，也不共享平台 token 表。跨仓只走 HTTPS JSON API 和短期签名 URL。

## 2. 为什么必须拆

### 2.1 上传不能塞进控制面

- 视频文件大，直传、分片、转码、重试的生命周期与内容编排不同；
- 对象存储密钥、转码 worker 和 CDN 签名不应进入控制面；
- 平台素材上传需要读取媒体，但媒体平台不应了解抖音/B 站字段；
- 媒体层可以独立扩容、限流和清理，不阻塞用户登录和后台查询。

### 2.2 平台实现不能塞进控制面

- 每个平台都有自己的 OAuth、签名、上传、审核和错误码；
- token 只应存在适配器，控制面数据库泄漏不能连带平台账号；
- 单平台接口变更时只回滚一个适配器；
- 社区 SDK 和官方 SDK 只能留在适配器内，不能污染领域模型。

## 3. `amei` 控制面

### 3.1 模块

```text
amei
  cmd/api
  cmd/worker
  internal/user
  internal/content
  internal/account
  internal/publish
  internal/metrics
  internal/adapterclient
  internal/mediaclient
  migrations
  web
```

### 3.2 拥有的数据

- `amei_user`、`amei_otp`；
- `amei_platform_account` 的账号索引和脱敏摘要；
- `amei_content`、`amei_content_version`、`amei_content_media`；
- `amei_publish_batch`、`amei_publish_task`、`amei_publish_attempt`；
- `amei_platform_post`；
- `amei_metric_pull_job`、`amei_metric_snapshot`；
- 适配器注册表、内部软额度、审计日志。

不拥有：媒体二进制、对象存储密钥、平台 access/refresh token、平台 Cookie、平台素材缓存。

### 3.3 对外 API

- `/amei/api/v1/auth/*`：手机号 OTP；
- `/amei/api/v1/contents/*`：内容与版本；
- `/amei/api/v1/accounts/*`：授权挑战、账号列表、重授权、解绑；
- `/amei/api/v1/publish-batches/*`：一键发布和任务状态；
- `/amei/api/v1/metrics/*`：数据看板和手工补录。

## 4. `amei-media` 媒体仓库

### 4.1 独立边界

`amei-media` 不知道抖音、B 站或视频号。它只识别通用媒体角色：

| 角色 | 示例 | 说明 |
| --- | --- | --- |
| `video` | 主视频 | 视频发布的主素材 |
| `cover` | 封面图 | 可由用户上传或抽帧生成 |
| `image` | 图文图片 | 图片正文素材 |
| `subtitle` | 字幕 | SRT/VTT |

平台规格由适配器通过 `variant` 请求或由媒体层提供的基础变体选择，不在媒体层写死平台规则。

### 4.2 最小 API

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `POST` | `/v1/media/upload-tickets` | 申请直传票据 |
| `POST` | `/v1/media/assets/{assetId}/complete` | 完成上传并触发校验 |
| `GET` | `/v1/media/assets/{assetId}` | 查询状态、元数据、派生版本 |
| `POST` | `/v1/media/assets/{assetId}/download-url` | 生成短 TTL 下载 URL |
| `POST` | `/v1/media/assets/{assetId}/archive` | 归档 |
| `DELETE` | `/v1/media/assets/{assetId}` | 软删除和延迟清理 |

详细字段见 `11-content-and-media.md`。

### 4.3 上传流程

```text
Web/客户端 -> amei 请求 assetId
           -> amei-media 返回签名 PUT URL
           -> 客户端直传对象存储
           -> 客户端 complete
           -> media-worker 校验/探测/转码
           -> asset ready + variants
           -> amei 记录 assetId（不记录二进制）
           -> 适配器申请短期下载 URL
```

### 4.4 数据与密钥

- 对象存储私有桶，前端永远拿不到长期密钥；
- 媒体元数据独立 MySQL；
- 转码队列与 worker 独立扩容；
- 删除采用延迟清理，避免发布重试引用失效；
- 签名 URL 单资产、短 TTL、不可写、不写完整查询串日志。

## 5. `amei-adapters` 平台适配仓库

### 5.1 结构建议

```text
amei-adapters
  cmd/adapter-server
  internal/contract
  internal/credential
  internal/platform/douyin
  internal/platform/kuaishou
  internal/platform/bilibili
  internal/platform/weibo
  internal/platform/xiaohongshu
  internal/platform/wechat_channels
  internal/platform/placeholder
  migrations
```

每个平台实现同一组内部接口：

```go
type Adapter interface {
    Capabilities(ctx context.Context) (Capabilities, error)
    Authorize(ctx context.Context, req AuthorizeRequest) (AuthorizeChallenge, error)
    Exchange(ctx context.Context, req ExchangeRequest) (AccountSession, error)
    Refresh(ctx context.Context, accountRef string) (AccountSession, error)
    UploadMedia(ctx context.Context, req MediaUploadRequest) (PlatformMediaRef, error)
    Publish(ctx context.Context, req PublishRequest) (PublishResult, error)
    QueryPublish(ctx context.Context, taskID string) (PublishStatus, error)
    PullMetrics(ctx context.Context, req MetricsRequest) (MetricsResult, error)
}
```

这是适配器仓内部契约，不是控制面协议。控制面只认 HTTP JSON。

### 5.2 平台模块要求

- 官方 SDK 只出现在该平台模块的 infrastructure 层；
- 平台字段映射、截断、话题处理和素材规格全部在模块内；
- 每个平台维护独立的错误码映射；
- `capabilities` 中声明支持的内容类型、限制、授权方式、数据能力和额度状态；
- 不支持的平台返回 `supported=false`，不能假装成功；
- 适配器不读取控制面数据库，只通过请求中的 `accountRef`、`assetId` 和签名 URL 工作。

### 5.3 凭据边界

- access token、refresh token、client secret 只存在适配器；
- 凭据使用 KMS/信封加密，密钥与数据库分离；
- 控制面只收到 `accountRef`、脱敏昵称、头像、scope 摘要和过期时间；
- 日志、错误响应和链路追踪不得带 token；
- 解绑和吊销可审计，token 删除可验证。

## 6. 跨仓调用契约

### 6.1 控制面 -> 媒体层

```json
{
  "requestId": "req_media_001",
  "ownerType": "content",
  "ownerId": "content_1001",
  "role": "video",
  "fileName": "book-review.mp4",
  "declaredMime": "video/mp4",
  "declaredBytes": 48230000,
  "sha256": "hex..."
}
```

控制面只保存返回的 `assetId` 和摘要。适配器需要素材时由控制面向媒体层申请短期 URL，不把对象存储长期密钥传给适配器。

### 6.2 控制面 -> 适配器

发布请求只传通用内容，不传平台字段：

```json
{
  "schemaVersion": "1.0",
  "accountRef": "acc_douyin_001",
  "content": {
    "contentType": "video",
    "title": "书籍简介",
    "summary": "编辑后的摘要",
    "body": "正文或视频描述",
    "tags": ["读书", "书评"],
    "canonicalUrl": "https://psou.example.com/book/123",
    "primaryVideoAssetId": "asset_video_01",
    "coverAssetId": "asset_cover_01",
    "visibility": "public",
    "copyright": "original"
  },
  "publishMode": "now",
  "scheduledAt": null
}
```

适配器负责把 `tags`、`categoryHints`、`body`、`canonicalUrl` 和素材映射为平台字段；映射失败返回 `UNSUPPORTED_CONTENT` 或 `NEEDS_ACTION`。

### 6.3 幂等与超时

- 所有写请求带 `Idempotency-Key`；
- 适配器保存 `accountRef + idempotencyKey -> platform task/post` 映射；
- 控制面超时后先查询，不直接重新创建；
- 媒体上传和内容发布分别有幂等键；
- 适配器返回 `requestId`，控制面把它写入发布尝试记录。

## 7. 部署与网络

| 服务 | 公网 | 入站 | 出站 | 密钥 |
| --- | --- | --- | --- | --- |
| `amei-api` | 是，HTTPS | 用户、后台 | media/adapters 内网 | 用户 JWT、短信 |
| `amei-worker` | 否 | 无 | MySQL/Redis/media/adapters | 任务签名 |
| `media-api` | 可选签名上传/下载 | 控制面、客户端签名 URL | 对象存储 | 对象存储、签名 |
| `media-worker` | 否 | 队列 | 对象存储 | 转码、对象存储 |
| `adapter-*` | 仅回调需要 | 控制面、平台回调 | 平台 API、media 签名 URL | 平台 client secret、KMS |

OAuth 回调可由适配器统一入口承接，回调后只把 `accountRef` 和脱敏账号信息交给控制面。

## 8. 本地联调

建议使用独立 `docker-compose`：

```text
amei-api + amei-worker + mysql + redis
media-api + media-worker + media-mysql + minio
adapter-server + adapter-mysql + fake-platform
```

`fake-platform` 必须覆盖：

- OAuth code 换 token、过期和刷新；
- 素材上传成功/超时/重复上传；
- 发布成功、审核中、审核拒绝、限流和权限不足；
- 指标分页、缺失字段和 0 值；
- 错误响应脱敏。

真实平台联调只使用测试应用和小流量测试账号，不能把测试 token 写入仓库或 PRD 示例。

## 9. 发布与版本

| 仓库 | 版本方式 | 回滚单位 |
| --- | --- | --- |
| `amei` | 语义化版本 + 数据库迁移 | 控制面镜像、迁移回滚 |
| `amei-media` | 独立镜像版本 | 媒体 API/worker、转码配置 |
| `amei-adapters` | 每平台独立版本 | 单平台适配器镜像 |

适配器协议变更必须保持向后兼容；破坏性变更提升 `schemaVersion` 主版本，并让旧适配器继续服务已有任务。

## 10. 交付顺序

1. 创建三个独立仓库和 CI，先冻结 HTTP 契约；
2. 先实现 `amei-media` 的本地对象存储和直传链路；
3. 实现 `amei` 的手机号 OTP、内容版本和任务模型；
4. 实现抖音官方 SDK 适配器闭环；
5. 接入批量发布和数据拉取；
6. 用测试应用验证快手、B 站、微博文本/图片；
7. 小红书、视频号只做能力占位，确认权限后再开发。

## 11. 验收

- 三个仓库可以独立构建、部署和回滚；
- 媒体层不出现平台名称和平台字段；
- 适配器不读取控制面数据库；
- 控制面响应和数据库中无平台 token/cookie；
- 一次发布可拆成多个平台任务，单平台失败不阻塞其他平台；
- 适配器超时不会导致重复发布；
- 平台能力未确认时按钮禁用并展示原因。
