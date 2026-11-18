# 内容模型与独立媒体层

> 状态：方案设计
> 日期：2026-11-12
> 范围：文章、图文、视频内容模型，`amei-media` 独立仓库边界和接口
> 关联：`02-adapter-contract.md`、`05-publish.md`、`07-data-model.md`

## 1. 为什么单独做 `amei-media`

视频上传、转码、封面、字幕和对象存储与发布平台无关，也不应该塞进控制面：

- 控制面不应接收和转发几十 MB 到数 GB 的视频；
- 平台适配器需要统一、可信的下载 URL；
- 转码任务耗时长，需要独立扩容和失败恢复；
- 文章配图、图文图集、视频封面、字幕都需要版本和生命周期；
- 同一素材可能复用于多个标题、平台和内容版本。

因此建议单独创建 `amei-media` 仓库。`amei` 只保存 `assetId` 和元数据引用，平台适配器按需向 `amei-media` 获取短 TTL 签名 URL。

## 2. 内容类型

### 2.1 文章 `article`

```json
{
  "contentType": "article",
  "title": "这本书为什么值得重读",
  "summary": "从三个角度拆解书中的核心观点。",
  "body": {
    "format": "markdown",
    "value": "## 核心观点\n..."
  },
  "coverAssetId": "asset_cover_01",
  "inlineAssetIds": ["asset_img_01", "asset_img_02"],
  "tags": ["书评", "阅读"],
  "canonicalUrl": "https://psou.example.com/book/123"
}
```

适配器按平台能力选择：

- 支持 Markdown/HTML：转换后提交；
- 只支持富文本：适配器做受控 HTML 清洗；
- 不支持长文：返回 `UNSUPPORTED_CAPABILITY`，不强行截断核心内容。

### 2.2 图文 `image_text`

```json
{
  "contentType": "image_text",
  "title": "5 本书建立阅读体系",
  "summary": "先读哪本、为什么读、适合谁。",
  "imageAssetIds": ["asset_img_01", "asset_img_02", "asset_img_03"],
  "coverAssetId": "asset_img_01",
  "tags": ["书单", "阅读"]
}
```

平台图片数量、比例、大小、文字占比和水印规则不同，由适配器校验和映射。上层只表达图片集合和排序，不写死“最多 9 张”之类的平台限制。

### 2.3 视频 `video`

```json
{
  "contentType": "video",
  "title": "三分钟读懂这本书",
  "description": "核心观点、适合人群和阅读建议。",
  "primaryVideoAssetId": "asset_video_01",
  "coverAssetId": "asset_cover_01",
  "subtitleAssetId": "asset_srt_01",
  "tags": ["书评", "阅读"]
}
```

视频模型必须包含：

- 主视频素材；
- 可选封面；
- 可选字幕；
- 标题/描述/话题；
- 时长、分辨率、帧率、码率、音轨等派生元数据；
- 平台需要的原创/转载/商业标识。

## 3. 内容版本

发布必须以版本快照为准：

- 用户编辑内容条目，产生新版本；
- 版本包含标题、正文、标签、素材引用和发布选项；
- 发布任务创建后版本不可变；
- 修改文案必须新建版本；
- 同一版本可在多个平台账号上发布；
- 每个平台可以提供标题/标签覆盖项，但不改原始版本。

租约与状态：

```text
draft -> ready -> archived
             └─ 被发布任务引用
```

`ready` 要求：

- 文章有标题和正文；
- 图文至少有 1 张 `ready` 图片；
- 视频有 `ready` 的主视频；
- 所有素材哈希、MIME、大小已确认；
- 素材授权信息已填写（产品要求的范围内）。

## 4. `amei-media` 职责

### 4.1 包含

- 上传票据和客户端直传；
- 媒体元数据探测；
- 图片压缩、尺寸裁剪、EXIF 清理；
- 视频转码、封装、码率/分辨率派生；
- 封面抽帧和裁切；
- 字幕解析/转码（SRT/VTT）；
- 私有对象存储、生命周期和签名 URL；
- 素材状态、哈希去重、引用计数；
- 版权授权附件和删除请求。

### 4.2 不包含

- 平台 OAuth；
- 平台素材上传；
- 平台标题/标签/审核字段；
- 发布任务编排；
- 平台数据拉取。

平台素材上传属于 `amei-adapters`，因为它需要平台 token 和平台专属协议。

## 5. 媒体状态机

```text
created
  │ 上传票据签发
  ▼
uploading
  │ 客户端上传完成
  ▼
uploaded ──扫描/探测失败──► failed
  │
  ▼
probing
  │
  ├─ 图片正常 ─────────────► processing ──► ready
  │
  └─ 视频正常 ─────────────► transcoding ─► ready
                                             │
                                             └─ archived/deleted
```

`ready` 是最小发布条件。`failed` 必须保存可展示的脱敏原因，例如“视频无音轨”“分辨率低于平台要求”“文件损坏”。

## 6. 上传流程

### 6.1 申请上传票据

`POST /v1/media/upload-tickets`

```json
{
  "ownerType": "content",
  "ownerId": "content_1001",
  "fileName": "book-review.mp4",
  "declaredMime": "video/mp4",
  "declaredBytes": 48230000,
  "sha256": "hex...",
  "purpose": "video"
}
```

响应：

```json
{
  "assetId": "asset_video_01",
  "uploadUrl": "https://storage.example.com/...signed...",
  "method": "PUT",
  "headers": {
    "Content-Type": "video/mp4"
  },
  "expiresAt": 1760003600000,
  "maxBytes": 536870912
}
```

接入约束：

- 上传 URL 只允许写指定对象 key；
- 过期后不可续用；
- 前端不得拿到对象存储长期密钥；
- 服务端在完成回调后重新校验 MIME、大小和哈希。

### 6.2 完成上传

`POST /v1/media/assets/{assetId}/complete`

```json
{
  "sha256": "hex...",
  "bytes": 48230000,
  "etag": "storage-etag"
}
```

响应 `202 Accepted`，进入 `probing`。前端轮询或订阅事件，不等待转码完成。

### 6.3 查询资产

`GET /v1/media/assets/{assetId}`

```json
{
  "assetId": "asset_video_01",
  "status": "ready",
  "mime": "video/mp4",
  "bytes": 48230000,
  "durationMs": 96000,
  "width": 1080,
  "height": 1920,
  "sha256": "hex...",
  "variants": [
    {"name": "source", "downloadUrl": "https://...", "expiresAt": 1760003600000},
    {"name": "platform_1080x1920", "downloadUrl": "https://...", "expiresAt": 1760003600000}
  ]
}
```

### 6.4 获取签名下载 URL

`POST /v1/media/assets/{assetId}/download-url`

```json
{
  "variant": "platform_1080x1920",
  "ttlSeconds": 900
}
```

只有控制面或已认证适配器可以申请。URL 不写日志，不长期缓存。

## 7. 校验与转码

### 7.1 通用校验

| 项目 | 校验 |
| --- | --- |
| MIME | 文件头/ffprobe，不信任扩展名 |
| 大小 | 按用途和平台上限分层 |
| 哈希 | 防止重复上传和篡改 |
| 图片 | 尺寸、比例、格式、EXIF、损坏 |
| 视频 | 容器、编码、时长、分辨率、帧率、音轨、码率 |
| 字幕 | 编码、时间轴、最大行宽 |

平台真实上限未核实时，不能硬编码成产品承诺；使用保守内部上限并展示“以后台为准”。

### 7.2 视频派生

建议产出：

- `source`：原始合规文件；
- `platform_master`：H.264/AAC、MP4、统一分辨率；
- `vertical_1080x1920`：竖屏平台候选；
- `horizontal_1920x1080`：横屏平台候选；
- `cover`：抽帧/用户上传；
- `subtitle`：SRT/VTT。

最终向平台上传哪个版本由适配器根据 `capabilities` 选择，不在媒体层写死抖音/B 站规则。

### 7.3 重复素材

按 `sha256 + purpose` 去重：

- 同一用户重复上传相同素材，复用资产；
- 不同用户是否复用需按隔离策略决定，默认不跨用户暴露资产；
- 资产被多个内容版本引用时维护引用计数；
- 删除使用延迟清理，避免发布任务重试时引用失效。

## 8. 版权与内容安全

- 每个资产可关联授权说明、来源 URL 和授权文件；
- 书籍封面、作者照片、出版社图片需要运营确认授权；
- 上传图片/视频不包含未授权的第三方水印或版权素材；
- 支持内容删除请求，删除后清理派生版本和平台素材缓存（平台支持时）；
- 媒体层不判断平台审核规则，只做通用安全与规格校验。

## 9. API 汇总

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `POST` | `/v1/media/upload-tickets` | 申请直传票据 |
| `POST` | `/v1/media/assets/{assetId}/complete` | 上传完成 |
| `GET` | `/v1/media/assets/{assetId}` | 资产和派生版本 |
| `POST` | `/v1/media/assets/{assetId}/download-url` | 签名下载 URL |
| `POST` | `/v1/media/assets/{assetId}/archive` | 归档 |
| `DELETE` | `/v1/media/assets/{assetId}` | 软删除/延迟清理 |
| `POST` | `/v1/media/assets/{assetId}/authorization` | 绑定授权说明 |

## 10. 与控制面的契约

控制面只保存：

- `assetId`；
- `role`、`mime`、`bytes`、`width`、`height`、`durationMs`；
- `sha256`；
- 排序和状态摘要。

控制面不保存：

- 文件二进制；
- 对象存储长期密钥；
- 转码临时文件；
- 平台素材 ID（由适配器保存）。

## 11. 验收标准

- `amei-media` 可独立部署、独立扩容；
- 前端通过签名 URL 直传，控制面不代理大文件；
- 图片、视频、字幕均有完整状态机；
- 视频转码后可查询派生版本；
- 非法文件、超限文件、损坏文件被拒绝；
- 同一素材重复上传可去重；
- 签名 URL 短 TTL，过期不可访问；
- 平台适配器只拿短期 URL，不拿对象存储长期密钥；
- 控制面数据库无媒体二进制和平台 token。
