# 视频平台发布链

> 状态：方案设计
> 日期：2026-11-12
> 范围：抖音、快手、B 站、微博、小红书、视频号的短视频/图文视频发布
> 前提：官方开放平台能力已核实并取得权限；未核实平台默认禁用

## 1. 统一视频流水线

```text
原始视频
  │
  ▼
amei-media 探测/转码/封面/字幕
  │  assetId + 签名 URL
  ▼
amei 发布任务
  │
  ├─► 抖音适配器：平台上传 -> create_video / create_image_text
  ├─► 快手适配器：start_upload -> upload -> complete -> publish
  ├─► B 站适配器：init -> 8 MiB 分片 -> complete -> cover -> add-by-utoken（鉴权待实测）
  ├─► 微博适配器：视频仅机构可申请；文本/图片可用
  ├─► 小红书适配器：能力未核实，禁用
  └─► 视频号适配器：能力未核实，禁用
          │
          ▼
平台作品 ID / URL / 审核状态
          │
          ▼
指标任务（官方 API）
```

视频平台差异不能泄漏到控制面。控制面只传 `contentType=video`、`primaryVideoAssetId`、`coverAssetId`、标题、描述、标签和发布选项。

## 2. 视频统一字段

| 字段 | 说明 | 平台差异 |
| --- | --- | --- |
| `primaryVideoAssetId` | 主视频 | 必须 `ready` |
| `coverAssetId` | 封面 | 平台尺寸/是否必填不同 |
| `title` | 标题 | 长度、能否重复不同 |
| `description` | 描述/文案 | 长度、外链、话题不同 |
| `tags` | 标签/话题 | 数量和格式不同 |
| `category` | 分类/分区 | 仅部分平台有，如 B 站 `tid` |
| `copyright` | 原创/转载 | 平台枚举不同 |
| `visibility` | 公开/私密/粉丝可见 | 平台支持程度不同 |
| `scheduledAt` | 定时 | 支持原生定时的平台直接传递 |
| `brandDisclosure` | 商业内容标识 | 以平台规则为准 |

## 3. 平台能力与缺口

### 3.1 抖音

已核实能力：

- 视频创建：`/api/douyin/v1/video/create_video/`；
- 视频上传：`/api/douyin/v1/video/upload_video/`；
- 分片上传：init/upload part/complete；
- 图文上传/创建：`upload_image`、`create_image_text`；
- 作品列表、基础信息、作品数据；
- 粉丝数据。

推荐实现：

- 直接复用 `bytedance/douyin-openapi-sdk-go`；
- 适配器封装 SDK，不把 SDK 类型暴露给控制面；
- 视频先上传平台素材，再创建视频；
- 图文逐张上传，取得平台图片引用后创建图文；
- `access-token` 由适配器注入，不出适配器。

未知项：

- 开发者手机号注册细节；
- 应用审核和发布权限；
- 官方每日额度；
- 完整 OAuth 参数和 scope 名称（需后台确认）。

### 3.2 快手

社区 SDK 观察到的链路：

1. `POST /openapi/photo/start_upload` 获取 `upload_token`；
2. `POST /api/upload` 或 `multipart`/`fragment` 上传；
3. `POST /api/upload/complete`；
4. `POST /openapi/photo/publish`，字段 `upload_token`、`cover`、`caption`、`stero_type`；
5. `POST /openapi/photo/list` 获取作品和基础互动数据。

OAuth2 端点：

- `https://open.kuaishou.com/oauth2/authorize`
- `https://open.kuaishou.com/oauth2/access_token`
- `https://open.kuaishou.com/oauth2/refresh_token`
- 社区 SDK 还出现 `connect`、`qr_code`，需官方复核。

风险：

- 社区 SDK 最后提交 2021-04-14；
- 不能把旧字段直接当作当前官方契约；
- 上传大小、分片、封面、视频规格和每日额度需重新确认。

### 3.3 B 站

已核实：

- OAuth token 换发 `POST https://api.bilibili.com/x/account-oauth2/v1/token`；
- 视频初始化 `POST /arcopen/fn/archive/video/init`，返回 `upload_token`；
- 分片上传 `POST https://openupos.bilivideo.com/video/v2/part/upload`，demo 使用 8 MiB；
- 视频合并 `POST /arcopen/fn/archive/video/complete`；
- 封面上传 `POST /arcopen/fn/archive/cover/upload`，返回 `data.url`；
- 分区查询 `GET /arcopen/fn/archive/type/list`；
- 服务端稿件提交 `POST https://member.bilibili.com/arcopen/fn/archive/add-by-utoken`；
- 必填 `title`、`tid`、`tag`、`copyright`；
- 封面必须来自封面上传接口；
- 返回 `data.resource_id`；
- 非正式会员单日最多投递 5 个稿件。

鉴权冲突：

- 官方 demo 使用 query 参数；
- 另一份 OpenAPI 快照要求 `Access-Token`、`Authorization`、`X-Bili-*` HMAC-SHA256 签名头；
- 必须用真实应用实测，不能同时写死两套猜测。

未闭环：

- 授权 URL、scope 和 refresh 端点；
- 作品数据接口；
- 应用权限、审核周期和真实上传规格。

官方 demo 已归档且无 License，只作参考。不能把 `biliup` 的 Web/Studio 接口当作官方开放平台 API；该仓库 README 禁止商业使用，不作为生产依赖。

### 3.4 微博

已核实文本/图片：

- `statuses/share`；
- `statuses/upload_url_text`。

视频：

- 官方 `https://open.weibo.com/wiki/Video/api` 已核实：接入方必须是政务、媒体、机构等实体，个人暂时无法接入；
- 需联系蓝 V 客服或政务运营开通并获取接口文档；
- 端点、字段、格式、大小、时长和审核状态仍标记 `未核实/待补充`；
- 第一版只做文本/图片，不做视频自动发布；
- 若业务必须视频，先确认机构资质和商务开通，再设计适配器。

### 3.5 小红书

当前开放平台导航没有内容发布 API。不能因为存在商家/订单 API 就推断有笔记发布能力。

首版：

- 展示平台和账号绑定入口（如果官方允许）；
- `video.publish=false`、`imageText.publish=false`；
- 记录“未核实/待补充”；
- 继续通过官方渠道确认。

### 3.6 视频号

官方文档只确认小店/交易相关能力，未确认公开视频发布 API。

首版：

- 不接自动发布；
- 不调用 Web 后台或抓包接口；
- 不用下载/逆向项目；
- 只做人工运营流程说明。

## 4. 视频素材上传

平台素材上传由适配器实现，但复用 `amei-media` 的下载 URL：

```text
amei-media 资产 ready
  -> amei 将 assetId + signed URL 传给适配器
  -> 适配器下载并校验 sha256
  -> 适配器调用平台上传接口
  -> 适配器保存 platformMediaId（按 accountRef + sha256）
  -> 发布任务引用 platformMediaId
```

约束：

- 不将大视频放进控制面 JSON；
- 不让浏览器直接向平台上传（除非平台官方要求且可审计）；
- 签名 URL 过期前完成下载；
- 平台上传失败可单独重试；
- 素材平台 ID 过期后重新上传，不假设永久有效。

## 5. 视频发布状态

统一状态：

`queued` → `validating` → `uploading_media` → `publishing` → `pending_review` → `published`，异常分支 `needs_action` / `failed` / `canceled`。

平台状态映射：

| 平台结果 | 统一状态 | 说明 |
| --- | --- | --- |
| 上传成功、创建成功、审核中 | `pending_review` | 不能称已公开 |
| 平台明确返回作品 ID 且公开 | `published` | 保存 URL |
| 需要重新授权/实名 | `needs_action` | 不自动重试 |
| 审核拒绝 | `failed` | 保存原因 |
| 请求超时、结果不明 | 先查询 | 禁止直接重发 |

## 6. 视频数据指标

统一字段：

- `impressions`：曝光（平台提供时）；
- `plays`：播放；
- `likes`：点赞；
- `comments`：评论；
- `shares`：分享；
- `favorites`：收藏；
- `followersDelta`：涨粉；
- `completionRate`：完播率；
- `avgWatchTimeMs`：平均观看时长。

抖音 SDK 中已看到 `play_count`、`comment_count`、`share_count`、`forward_count`、`digg_count`、`download_count` 等字段。其他平台的数据接口和字段以逐平台文档为准，未核实不写入产品承诺。

## 7. 平台视频限制的建模

未知限制不能硬编码为全局常量。适配器在 `capabilities` 中返回：

```json
{
  "video": {
    "supported": true,
    "maxDurationMs": null,
    "maxBytes": null,
    "minWidth": null,
    "minHeight": null,
    "maxWidth": null,
    "maxHeight": null,
    "coverRequired": null,
    "formats": []
  }
}
```

值为 `null` 表示尚未核实。产品界面显示“以平台审核为准”，不伪造限制。拿到官方文档或实测结果后再填具体值。

## 8. 审核与人工接管

视频平台常见人工点：

- OAuth 重新授权；
- 账号实名/资质补全；
- 平台内容审核；
- 版权/音乐/封面驳回；
- B 站分区选择；
- 平台要求扫码确认。

这些情况统一通过 `needs_action` 表达。控制面提供平台提示、打开官方后台、重新授权和人工确认，不自动绕过。

## 9. 视频发布验收

- 视频从 `amei-media` ready 状态开始发布；
- 平台素材上传和内容创建可分别查询；
- 单平台视频失败不影响其他平台；
- 审核中与已发布严格区分；
- 平台作品 ID/URL 可追溯；
- 抖音完成真实视频发布；
- 快手根据当前官方文档完成验证后再启用；
- B 站鉴权方式未实测前不对外开启视频发布；
- 微博视频只对完成机构资质和接口开通的账号开启；
- 小红书视频、视频号视频在能力确认前禁用；
- 所有平台事实带来源和验证状态。
