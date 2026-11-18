# 抖音开放平台调研

> 平台：抖音
> 平台编码：`douyin`
> 官方入口：https://open.douyin.com/
> 官方 SDK：https://github.com/bytedance/douyin-openapi-sdk-go
> 调研日期：2026-11-12
> 总体状态：视频/图文发布与作品数据能力 `已核实`；开发者手机号注册、应用审核、权限和额度 `登录后可见/待验证`

## 1. 结论

抖音是六个平台中首个可落地的官方 API 平台。官方 Go SDK 许可证为 Apache-2.0，提交
`a50593c5ccdc31ab5b7cb2153947dfad612bbed9`（2025-07-29），覆盖 OAuth、视频、图文和作品数据相关接口。

建议直接复用官方 SDK，不在 amei 内重写请求签名和响应模型。适配器只负责把 amei 统一内容转换为抖音字段。

## 2. 手机号与账号注册

### 2.1 amei 用户

amei 手机号 OTP 注册/登录，见 `../03-phone-auth.md`，与抖音账号无关。

### 2.2 抖音开发者账号

- 入口：抖音开放平台；
- 是否支持手机号注册：`登录后可见/待验证`；
- 是否需要企业主体、营业执照、行业资质：`登录后可见/待验证`；
- 应用审核、测试应用、回调域名配置：需登录后台确认；
- 不能把“有抖音账号”当成“有开发者应用资格”。

### 2.3 抖音内容账号

- 用户在抖音官方授权页完成登录/授权；
- 服务端不保存抖音密码，也不使用手机号+验证码直接模拟登录；
- 授权后适配器保存 access token / refresh token；
- 是否需要实名或特定内容权限：以后台为准。

## 3. 授权与请求

官方 SDK 中观察到的 passport/OAuth 路径：

```text
/passport/open/get_access_code
/oauth/stable_client_token/
/passport/open/get_client_code
```

请求头中观察到：

```text
access-token: <adapter-held-token>
```

业务请求通常带 `open_id`。这些路径和头字段来自官方 SDK，但完整 OAuth 参数、scope 名称、token 有效期、refresh 行为和应用审核要求仍需开发者后台确认。

## 4. 官方 API

### 4.1 视频

| 能力 | 方法与路径 | 关键字段 | 状态 |
| --- | --- | --- | --- |
| 创建视频 | `POST https://open.douyin.com/api/douyin/v1/video/create_video/?open_id=...` | `open_id`、`text`、`custom_cover_image_url`、`video_id`、`private_status`、`poi_id`、`at_users`、`task_id`、`cover_tsp` | 已核实 |
| 直传/普通上传 | `POST https://open.douyin.com/api/douyin/v1/video/upload_video/?open_id=...` | 视频文件 | 已核实 |
| 初始化分片 | `POST https://open.douyin.com/api/douyin/v1/video/init_video_part_upload/?open_id=...` | 分片上传初始化 | 已核实 |
| 上传分片 | `POST https://open.douyin.com/api/douyin/v1/video/upload_video_part/?open_id=...&part_number=...&upload_id=...` | `part_number`、`upload_id`、分片 | 已核实 |
| 完成分片 | `POST https://open.douyin.com/api/douyin/v1/video/complete_video_part_upload/?open_id=...` | `upload_id`、分片结果 | 已核实 |

### 4.2 图文

| 能力 | 方法与路径 | 关键字段 | 状态 |
| --- | --- | --- | --- |
| 上传图片 | `POST https://open.douyin.com/api/douyin/v1/video/upload_image/` | 图片文件 | 已核实 |
| 创建图文 | `POST https://open.douyin.com/api/douyin/v1/video/create_image_text/` | `image_list`、`text`、`open_id`、`private_status`、`task_id`、`music_id`、`poi_id` | 已核实 |

### 4.3 作品与数据

| 能力 | 方法与路径 | 说明 | 状态 |
| --- | --- | --- | --- |
| 作品列表 | `GET /api/douyin/v1/video/video_list/` | 按账号分页 | 已核实 |
| 作品基础信息 | `GET /api/douyin/v1/video/video_basic_info/` | 作品元数据 | 已核实 |
| 作品数据 | `GET /api/douyin/v1/video/video_data/` | 播放、点赞等 | 已核实 |
| 粉丝数据 | `GET /api/douyin/v1/user/fans_data/` | 账号粉丝 | 已核实 |
| 商业/分享相关 | `/api/apps/v1/video_bc/query/`、`/api/apps/v1/item/get_play/`、`/api/apps/v1/item_bc/get_share/` | 权限和用途需确认 | 已观察 |

作品数据字段中已观察到：

```text
play_count
comment_count
share_count
forward_count
digg_count
download_count
```

字段是否全部对普通内容应用开放，需要在开发者后台确认。

## 5. 视频发布链

```text
读取 amei-media 签名 URL
  -> 下载并校验 sha256
  -> 调用 upload_video 或 init/upload_part/complete
  -> 取得平台视频 ID
  -> 调用 create_video
  -> 保存抖音作品 ID / 审核状态
```

注意：

- `create_video` 需要平台视频素材 ID 或可引用的视频标识；
- `custom_cover_image_url` 的封面来源、尺寸和是否必须先上传，需要实测；
- 分片大小、并发数、断点续传和超时以官方文档/实测为准；
- 大视频建议走分片上传；
- 发布成功后不要立即假设公开，需查询作品状态。

## 6. 图文发布链

```text
图片资产 ready
  -> 逐张 upload_image
  -> 得到 image_list
  -> create_image_text
  -> 保存作品 ID 和审核状态
```

需要实测：

- 单次图片数量上限；
- 图片格式、单张大小、总大小；
- 图片顺序与裁剪；
- `music_id` 是否必填；
- `private_status` 枚举；
- 图文是否有独立数据接口。

未知项在 `capabilities` 中返回 `null`，不要猜。

## 7. 状态与审核

待确认：

- `create_video`/`create_image_text` 返回值中是否包含审核状态；
- 是否有独立审核查询接口；
- 作品列表能否区分审核中、公开、仅自己可见；
- 删除/撤回接口和权限；
- 失败错误码字典。

在第一版中，创建成功但未确认公开时应标记 `pending_review` 或 `submit_accepted`，不能直接标 `published`。

## 8. 数据指标

推荐映射：

| 抖音字段 | amei 指标 |
| --- | --- |
| `play_count` | `plays` |
| `digg_count` | `likes` |
| `comment_count` | `comments` |
| `share_count` | `shares` |
| `forward_count` | `shares` 的补充或 `forwardCount` 扩展 |
| `download_count` | 扩展指标，非统一主指标 |

粉丝数据映射到账号级 `followers`/`followersDelta`。具体是累计值还是日增量需看接口返回。

## 9. GitHub 复用评估

| 仓库 | License | 提交 | 结论 |
| --- | --- | --- | --- |
| `bytedance/douyin-openapi-sdk-go` | Apache-2.0 | `a50593c5...`，2025-07-29 | 直接复用 |

复用原则：

- 固定 SDK 版本；
- 适配器内部封装 SDK 类型；
- 记录 SDK 升级变更；
- 不把 `access-token` 暴露给控制面；
- 官方 SDK 未覆盖的接口先补官方文档，不自行猜路径。

## 10. 自动化可行性

- 视频发布：服务端可自动，前提是应用拿到对应权限；
- 图文发布：服务端可自动，前提是权限和素材接口可用；
- 账号授权：需要用户在抖音官方页面 OAuth；
- 发布额度：`未核实/待补充`；
- 网页自动化：不提供，只走开放平台 API。

## 11. 人工接管点

- OAuth 授权过期；
- 应用 scope 不足；
- 账号实名/资质；
- 平台审核；
- 封面或音乐不合规；
- 开发者后台权限申请。

## 12. 风险

- 官方 SDK 覆盖并不等于当前应用已获权限；
- 作品数据和发布权限可能分开审批；
- 视频分片上传和审核状态需要真实账号实测；
- 书籍推广内容可能触发商业推广/版权审核；
- 额度未知，不能按“无限发布”设计。

## 13. 适配器实现建议

1. 直接依赖官方 SDK；
2. 实现 OAuth/token 加密与刷新；
3. 实现平台素材上传缓存；
4. 实现视频、图文两条发布路径；
5. 实现作品/账号指标拉取；
6. `capabilities` 明确标记未知限制；
7. 创建成功后查询状态，区分审核中和已公开；
8. 单任务幂等键按 `contentVersionId + accountRef` 生成。

## 14. 证据

| 证据 | 位置 | 状态 |
| --- | --- | --- |
| 官方 SDK | https://github.com/bytedance/douyin-openapi-sdk-go | 已核实 |
| SDK 提交 | `a50593c5ccdc31ab5b7cb2153947dfad612bbed9`，2025-07-29 | 已核实 |
| License | Apache-2.0 | 已核实 |
| 视频/图文接口 | SDK `client/client.go` 中路径与模型 | 已核实 |
| OAuth 细节/应用权限/额度 | 开发者后台 | 登录后可见/待验证 |
