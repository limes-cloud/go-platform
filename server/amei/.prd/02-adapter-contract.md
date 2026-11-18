# 适配器协议

> 状态：方案设计
> 日期：2026-11-12
> 范围：`amei` 控制面与 `amei-adapters` 之间的 HTTP JSON 协议
> 默认传输：HTTPS（内网可 mTLS）；不使用网页 DOM 作为协议字段

## 1. 设计原则

1. 只使用开放平台 API。适配器在能力声明中标记 `official` 或 `community`，不得提供网页自动化模式。
2. 内容平台无关。控制面只传文章、图文、视频和通用发布选项。
3. 凭据适配器自治。OAuth token、refresh token、平台素材 ID 和平台签名均由适配器管理。
4. 媒体与控制面解耦。内容只携带 `assetId` 和短期签名 URL，不在 JSON 中塞大文件或 base64。
5. 异步任务化。素材上传、发布、审核查询和指标拉取均返回任务 ID。
6. 幂等。发布、媒体上传和指标拉取均支持幂等键，超时不得盲目重复创建。
7. 显式能力。平台没有的能力必须返回 `supported=false`，不能只靠失败提示。

## 2. 传输、认证和版本

- `Content-Type: application/json; charset=utf-8`。
- 服务认证：`Authorization: Bearer <adapter-service-token>`；生产建议 mTLS。
- 请求头：
  - `X-Request-Id`：控制面生成；
  - `X-Amei-Timestamp`：毫秒时间戳；
  - `Idempotency-Key`：所有副作用写接口必带。
- 所有响应包含 `requestId`、`schemaVersion`；错误包含稳定 `code` 和脱敏 `message`。
- `schemaVersion` 当前为 `1.0`。新增字段向后兼容；破坏性变更升主版本。
- 适配器不得在响应里返回 access token、refresh token、cookie、平台密码或 OAuth authorization code 明文。

## 3. 接口总览

| 方法 | 路径 | 用途 | 模式 |
| --- | --- | --- | --- |
| `GET` | `/healthz` | 进程健康 | 同步 |
| `GET` | `/v1/capabilities` | 平台能力、发布类型、媒体限制、额度来源 | 同步 |
| `POST` | `/v1/oauth/authorize` | 创建平台 OAuth 授权地址或授权挑战 | 同步 |
| `POST` | `/v1/oauth/exchange` | 用授权码换取平台 token（回调后调用） | 同步 |
| `GET` | `/v1/accounts/{accountRef}/session` | 查询授权/账号状态 | 同步 |
| `POST` | `/v1/accounts/{accountRef}/refresh` | 刷新 token | 同步 |
| `POST` | `/v1/accounts/{accountRef}/revoke` | 撤销授权/解绑 | 同步 |
| `POST` | `/v1/media/upload-tasks` | 预上传媒体到平台，取得平台素材 ID | 异步 |
| `GET` | `/v1/media/upload-tasks/{taskId}` | 查询平台素材上传 | 同步 |
| `POST` | `/v1/publish-tasks` | 创建平台发布任务 | 异步 |
| `GET` | `/v1/publish-tasks/{taskId}` | 查询发布/审核状态 | 同步 |
| `POST` | `/v1/publish-tasks/{taskId}/cancel` | 取消未提交任务 | 同步 |
| `POST` | `/v1/metrics/tasks` | 创建作品/账号指标拉取任务 | 异步 |
| `GET` | `/v1/metrics/tasks/{taskId}` | 查询指标任务 | 同步 |

平台回调（如 OAuth redirect、授权码回调）由适配器自身承接。控制面不接触平台 authorization code。

## 4. 能力发现

### 4.1 `GET /v1/capabilities`

```json
{
  "requestId": "req_cap_01",
  "schemaVersion": "1.0",
  "platformCode": "douyin",
  "platformName": "抖音",
  "adapterVersion": "1.0.0",
  "apiMode": "official",
  "contentTypes": {
    "video": {
      "supported": true,
      "maxDurationMs": null,
      "maxBytes": null,
      "coverRequired": false,
      "titleMax": null,
      "descriptionMax": null
    },
    "imageText": {
      "supported": true,
      "maxImages": null,
      "titleMax": null,
      "descriptionMax": null
    },
    "article": {
      "supported": false
    }
  },
  "authTypes": ["oauth"],
  "publishModes": ["now", "schedule"],
  "metricsTypes": ["post", "account"],
  "quotaSources": {
    "platformDailyLimit": null,
    "platformLimitStatus": "未核实/待补充",
    "rateLimitHeaders": ["X-RateLimit-Limit", "X-RateLimit-Remaining"]
  },
  "manualActionTypes": ["oauth_reauth", "platform_review", "account_verification"],
  "evidence": [
    {
      "url": "https://github.com/bytedance/douyin-openapi-sdk-go",
      "verifiedAt": "2026-11-12",
      "commit": "a50593c5ccdc31ab5b7cb2153947dfad612bbed9"
    }
  ]
}
```

约束：

- `apiMode` 只能是 `official`、`community`。不存在 `web_fallback`；没有开放 API 的平台返回 `supported=false`。
- `maxDurationMs`、`maxBytes`、`maxImages` 等必须来自官方文档或实测；未知填 `null`，不能猜。
- `platformDailyLimit` 与 `platformLimitStatus` 是平台事实；内部软额度存控制面，不混用。
- 不支持的内容类型必须返回 `supported=false`，控制面提交前禁用该平台。

## 5. 平台授权

### 5.1 发起授权

`POST /v1/oauth/authorize`

```json
{
  "schemaVersion": "1.0",
  "userId": "u_1001",
  "returnUrl": "https://amei.example.com/accounts/callback",
  "scopes": ["video.publish", "video.data"]
}
```

响应：

```json
{
  "requestId": "req_auth_01",
  "challengeId": "chl_01",
  "type": "oauth_url",
  "authorizeUrl": "https://open.example.com/oauth/authorize?...",
  "expiresAt": 1760000000000
}
```

`type` 允许 `oauth_url`、`qr`、`manual_confirm`。平台只提供扫码授权时返回 `qr`；平台只允许后台人工授权时返回 `manual_confirm`。

### 5.2 用授权码换取 token

平台回调适配器后，适配器调用：

`POST /v1/oauth/exchange`

```json
{
  "challengeId": "chl_01",
  "authorizationCode": "from-platform-callback"
}
```

成功返回脱敏账号信息：

```json
{
  "requestId": "req_exchange_01",
  "accountRef": "acc_douyin_001",
  "displayName": "书评号",
  "avatarUrl": "https://...",
  "status": "active",
  "authType": "oauth",
  "scopes": ["video.publish", "video.data"],
  "tokenExpiresAt": 1762592000000,
  "profile": {
    "platformUserId": "open-id-or-uid",
    "homeUrl": "https://..."
  }
}
```

控制面只保存 `accountRef`、脱敏展示字段、scope 摘要和过期提示，不保存 token。

### 5.3 会话状态

`GET /v1/accounts/{accountRef}/session`

```json
{
  "requestId": "req_sess_01",
  "accountRef": "acc_douyin_001",
  "status": "active",
  "authType": "oauth",
  "scopes": ["video.publish", "video.data"],
  "expiresAt": 1762592000000,
  "lastCheckedAt": 1760000000000,
  "action": null
}
```

状态：

| 状态 | 含义 |
| --- | --- |
| `active` | 授权有效，可调用已授权能力 |
| `expired` | token 过期/被撤销，需要重新授权 |
| `needs_action` | 需要用户扫码、确认或补齐平台资质 |
| `disabled` | 平台账号被停用或用户主动解绑 |
| `error` | 适配器无法判断，需排查 |

## 6. 统一内容载荷

控制面传给适配器的内容版本是不可变快照：

```json
{
  "contentVersionId": "cv_1001",
  "contentType": "video",
  "title": "三分钟读懂这本书",
  "summary": "一本书的核心观点与适合人群。",
  "body": {
    "format": "markdown",
    "value": "## 这本书讲了什么\n..."
  },
  "canonicalUrl": "https://psou.example.com/book/123",
  "tags": ["书评", "阅读", "效率"],
  "categoryHints": ["读书"],
  "media": [
    {
      "assetId": "asset_video_01",
      "role": "primary_video",
      "mime": "video/mp4",
      "bytes": 48230000,
      "durationMs": 96000,
      "width": 1080,
      "height": 1920,
      "sha256": "hex...",
      "downloadUrl": "https://media.example.com/signed/...",
      "expiresAt": 1760003600000
    },
    {
      "assetId": "asset_cover_01",
      "role": "cover",
      "mime": "image/jpeg",
      "bytes": 320000,
      "width": 1080,
      "height": 1440,
      "sha256": "hex...",
      "downloadUrl": "https://media.example.com/signed/...",
      "expiresAt": 1760003600000
    }
  ],
  "options": {
    "visibility": "public",
    "copyright": "original",
    "allowReprint": false,
    "brandDisclosure": true
  }
}
```

规则：

- `contentType`：`article`、`image_text`、`video`；
- `body.format`：`markdown`、`html` 或 `plain_text`；
- `media[].downloadUrl` 是短 TTL 签名 URL，适配器下载后上传平台，不缓存到日志；
- 图片按 `role` 区分 `cover`、`inline`、`gallery`；
- 视频 `role=primary_video` 必填，若平台需要封面而内容无封面，返回 `VALIDATION_FAILED`；
- 平台特有字段通过 `platformOptions` 传递，只能作为已知扩展，不允许控制面直接拼平台请求。

## 7. 平台素材上传

`POST /v1/media/upload-tasks`

```json
{
  "schemaVersion": "1.0",
  "accountRef": "acc_douyin_001",
  "contentVersionId": "cv_1001",
  "assets": [
    {
      "assetId": "asset_video_01",
      "role": "primary_video",
      "sha256": "hex...",
      "downloadUrl": "https://media.example.com/signed/...",
      "expiresAt": 1760003600000
    }
  ]
}
```

响应：

```json
{
  "requestId": "req_media_01",
  "taskId": "mut_01",
  "status": "queued"
}
```

查询成功：

```json
{
  "taskId": "mut_01",
  "status": "succeeded",
  "results": [
    {
      "assetId": "asset_video_01",
      "platformMediaId": "v0200fg10000...",
      "platformCoverId": null,
      "expiresAt": 1762592000000
    }
  ]
}
```

平台素材 ID 在适配器本地按 `accountRef + sha256 + platform` 缓存。缓存过期后重新上传，不能长期假设平台素材永久存在。

## 8. 创建发布任务

`POST /v1/publish-tasks`

```json
{
  "schemaVersion": "1.0",
  "accountRef": "acc_douyin_001",
  "contentVersionId": "cv_1001",
  "content": {
    "contentType": "video",
    "title": "三分钟读懂这本书",
    "summary": "一本书的核心观点与适合人群。",
    "body": {
      "format": "plain_text",
      "value": "这本书适合想建立阅读体系的人。"
    },
    "canonicalUrl": "https://psou.example.com/book/123",
    "tags": ["书评", "阅读"],
    "media": [
      {
        "assetId": "asset_video_01",
        "role": "primary_video",
        "downloadUrl": "https://media.example.com/signed/...",
        "expiresAt": 1760003600000
      }
    ]
  },
  "publish": {
    "mode": "now",
    "scheduledAt": null,
    "visibility": "public"
  },
  "platformOptions": {
    "privateStatus": 0,
    "poiId": null
  }
}
```

响应：

```json
{
  "requestId": "req_pub_01",
  "taskId": "pt_01",
  "status": "queued"
}
```

适配器负责：

1. 校验内容类型是否支持；
2. 下载并校验媒体哈希；
3. 上传平台素材，取得平台素材 ID；
4. 按平台规则截断标题/文案、映射话题、分类、封面和原创字段；
5. 调用官方创建/发布接口；
6. 返回平台作品 ID、URL、审核状态和原始错误码。

## 9. 发布状态

`GET /v1/publish-tasks/{taskId}`

```json
{
  "requestId": "req_pub_query_01",
  "taskId": "pt_01",
  "status": "published",
  "platformPostId": "7123456789",
  "platformUrl": "https://www.douyin.com/video/7123456789",
  "reviewStatus": "approved",
  "platformStatusCode": "0",
  "platformStatusMessage": "ok",
  "publishedAt": 1760000000000,
  "media": [
    {
      "assetId": "asset_video_01",
      "platformMediaId": "v0200fg10000...",
      "status": "uploaded"
    }
  ],
  "action": null,
  "retryAfterMs": null
}
```

状态机：

| 状态 | 说明 |
| --- | --- |
| `queued` | 已创建，等待执行 |
| `validating` | 校验字段和媒体 |
| `uploading_media` | 上传平台素材 |
| `publishing` | 调用平台发布接口 |
| `pending_review` | 平台审核中 |
| `needs_action` | 需要重新授权、扫码、补资料或人工确认 |
| `published` | 平台确认发布 |
| `failed` | 明确失败，不再自动重试 |
| `canceled` | 用户取消或平台允许撤回 |

HTTP 200 不代表发布成功；控制面必须以 `status` 为准。

## 10. 人工接管

```json
{
  "status": "needs_action",
  "action": {
    "type": "oauth_reauth",
    "actionUrl": "https://adapter.example.com/oauth/start?...",
    "message": "平台授权已过期，请重新授权",
    "expiresAt": 1760007200000
  }
}
```

允许的 `action.type`：

- `oauth_reauth`：重新授权；
- `manual_confirm`：平台后台人工确认；
- `platform_review`：只能等待审核；
- `account_verification`：平台实名/资质补全；
- `unsupported`：当前平台能力未开通。

人工接管不是自动发布成功。控制面必须保留原始任务状态，不得把“用户点过确认”直接当成 `published`。

## 11. 指标拉取

`POST /v1/metrics/tasks`

```json
{
  "schemaVersion": "1.0",
  "accountRef": "acc_douyin_001",
  "contentVersionId": "cv_1001",
  "platformPostIds": ["7123456789"],
  "from": "2026-11-01",
  "to": "2026-11-12",
  "granularity": "daily"
}
```

适配器只从官方接口读取，不可用浏览器后台数据冒充 API。返回：

```json
{
  "taskId": "mt_01",
  "status": "succeeded",
  "metrics": [
    {
      "platformPostId": "7123456789",
      "statDate": "2026-11-11",
      "impressions": null,
      "plays": 12000,
      "reads": null,
      "likes": 231,
      "comments": 18,
      "shares": 9,
      "favorites": 45,
      "followersDelta": null,
      "completionRate": null,
      "avgWatchTimeMs": null,
      "availableFields": ["plays", "likes", "comments", "shares", "favorites"],
      "source": "official_api",
      "pulledAt": 1760000000000
    }
  ]
}
```

平台不提供的字段返回 `null` 并放入 `availableFields`，不能用 0 冒充未知。

## 12. 错误模型

```json
{
  "requestId": "req_err_01",
  "code": "PLATFORM_RATE_LIMITED",
  "message": "平台限流，请稍后重试",
  "retryable": true,
  "retryAfterMs": 60000,
  "platformErrorCode": "45009",
  "platformErrorMessage": "api limit reached",
  "detail": null
}
```

稳定错误码：

| 错误码 | 是否重试 | 处理 |
| --- | --- | --- |
| `INVALID_REQUEST` | 否 | 修正协议字段 |
| `VALIDATION_FAILED` | 否 | 提示用户修改内容 |
| `AUTH_EXPIRED` | 否 | 重新授权 |
| `PERMISSION_DENIED` | 否 | 展示未获平台权限 |
| `PLATFORM_RATE_LIMITED` | 是 | 按 `retryAfterMs` 延后 |
| `MEDIA_UPLOAD_FAILED` | 视情况 | 校验媒体或重试上传 |
| `MEDIA_PROCESSING` | 是 | 稍后查询 |
| `PLATFORM_REVIEWING` | 是 | 查询状态 |
| `PLATFORM_REJECTED` | 否 | 记录审核原因 |
| `UNSUPPORTED_CAPABILITY` | 否 | 禁用平台该内容类型 |
| `ADAPTER_UNAVAILABLE` | 是 | 指数退避 |
| `UNKNOWN_PLATFORM_RESULT` | 否 | 先查询幂等键，禁止重发 |

## 13. 安全要求

- 平台凭据只在适配器加密存储；控制面数据库不得出现 token/cookie 字段；
- 签名下载 URL 短 TTL、单用途、只能读取指定资产；
- 日志脱敏手机号、OAuth code、token、签名 URL 查询参数；
- 不记录完整视频/图片二进制，不记录平台原始响应中的敏感字段；
- 适配器按平台和应用维度限流，不使用多账号规避平台额度；
- 所有发布任务保留 `adapterRequestId`、`platformErrorCode` 和审计记录。

## 14. 验收标准

- 新增平台只需新增适配器，不改控制面发布协议；
- 平台能力未知时能返回 `supported=false` 或 `null`，不以失败代替能力声明；
- 文章、图文、视频三种内容均可建模；
- 平台 OAuth token 不出适配器；
- 媒体上传和发布任务可分别查询、重试和审计；
- 超时任务先用幂等键查询，不重复发文；
- 指标缺失字段为 `null` 且有 `availableFields`；
- 所有平台事实带来源和验证状态。
