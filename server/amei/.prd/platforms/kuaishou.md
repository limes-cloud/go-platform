# 快手开放平台调研

> 平台：快手
> 平台编码：`kuaishou`
> 官方入口：https://open.kuaishou.com/
> 参考实现：https://github.com/bububa/kwai-openapi
> 调研日期：2026-11-12
> 总体状态：社区 SDK 视频链 `已观察`；官方当前文档、手机号注册、应用权限和额度 `未核实/待补充`

## 1. 结论

快手开放平台官网可访问，但页面是 SPA，未登录时无法取得完整文档正文。当前最完整的实现线索来自
`bububa/kwai-openapi`，许可证 Apache-2.0，最后提交 `869b9bcd025a2764d04df844d870a63202cce31a`（2021-04-14）。

该仓库可用来核对 OAuth 和视频上传链，但版本陈旧，不能直接作为“当前官方事实”或唯一生产实现。
应先用当前开发者后台文档和测试应用复核端点、字段、签名、额度。

## 2. 手机号与账号注册

### 2.1 amei 用户

amei 手机号 OTP 注册/登录统一走控制面，不依赖快手。

### 2.2 快手开发者账号

- 入口：快手开放平台；
- 页面存在注册/登录资源，但未登录看不到完整字段；
- 是否支持纯手机号注册：`登录后可见/待验证`；
- 是否需要企业主体、实名、应用审核：`登录后可见/待验证`；
- 开发者手机号是否可用于登录开放平台：需后台确认。

### 2.3 快手内容账号

- 用户通过 OAuth2 在快手官方页面授权；
- 社区 SDK 中出现 authorize、access_token、refresh_token、qr_code 等入口；
- 服务端不使用手机号密码模拟登录；
- 快手用户手机号接口 `openapi/user_phone` 是取得已授权用户加密手机号的能力，不是注册接口；
- 具体 scope 和授权页交互以当前官方文档为准。

## 3. OAuth2

社区 SDK 中观察到的端点：

```text
https://open.kuaishou.com/oauth2/authorize
https://open.kuaishou.com/oauth2/access_token
https://open.kuaishou.com/oauth2/refresh_token
https://open.kuaishou.com/oauth2/connect
https://open.kuaishou.com/oauth2/qr_code
```

需要复核：

- `app_id`、`app_secret`、`scope`、`state` 参数；
- access token 有效期和 refresh 窗口；
- 用户信息接口；
- 授权码回调；
- 二维码授权是否为独立产品能力；
- 发布权限是否单独申请。

## 4. 官方/社区 API 链

### 4.1 视频上传

| 步骤 | 端点 | 关键参数 | 状态 |
| --- | --- | --- | --- |
| 初始化 | `POST https://open.kuaishou.com/openapi/photo/start_upload` | `app_id`、`access_token` | 社区 SDK 已观察 |
| 单次上传 | `POST https://open.kuaishou.com/api/upload` | `upload_token`、文件 | 社区 SDK 已观察 |
| 文件 multipart | `POST https://open.kuaishou.com/api/upload/multipart` | `upload_token`、文件 | 社区 SDK 已观察 |
| 分片上传 | `POST https://open.kuaishou.com/api/upload/fragment` | `upload_token`、`fragment_id`、分片 | 社区 SDK 已观察 |
| 断点查询 | `POST https://open.kuaishou.com/api/upload/resume` | `upload_token` | 社区 SDK 已观察 |
| 完成上传 | `POST https://open.kuaishou.com/api/upload/complete` | `upload_token`、`fragment_count` | 社区 SDK 已观察 |

`start_upload` 返回 `upload_token` 和 `endpoint`。分片上传使用 `fragment_id`，完成后提交分片数量。

### 4.2 发布

`POST https://open.kuaishou.com/openapi/photo/publish`

社区 SDK 字段：

```text
upload_token
cover
caption
stero_type   # NOT_SPHERICAL_VIDEO / SPHERICAL_VIDEO_360 / SPHERICAL_VIDEO_180
```

响应包含 `video_info`。当前官方文档需复核字段拼写、封面来源、可见性和审核返回。

### 4.3 作品列表与删除

| 能力 | 端点 | 备注 |
| --- | --- | --- |
| 作品列表 | `/openapi/photo/list` | 返回 `photo_id`、`caption`、`cover`、`play_url`、`create_time` 等 |
| 删除 | `/openapi/photo/delete` | 需确认权限和是否可撤回审核中作品 |

### 4.4 数据字段

社区 SDK 的作品列表字段包含：

```text
photo_id
caption
cover
play_url
create_time
like_count
comment_count
view_count
pending
```

`pending` 可用于辅助判断审核/处理中，但正式状态语义需官方文档确认。

## 5. 视频发布链

```text
amei-media 视频资产 ready
  -> start_upload 获取 upload_token
  -> upload / multipart / fragment 上传
  -> resume 可选断点续传
  -> complete 完成上传
  -> publish(upload_token, cover, caption)
  -> 保存 photo_id / 审核状态
```

适配器应：

- 优先使用分片上传处理大文件；
- 失败时先调用 resume，避免从头重传；
- 保存 `upload_token` 与本地任务绑定；
- 发布幂等键按账号 + 内容版本生成；
- 发布后用 `photo/list` 辅助核对作品是否出现。

## 6. 内容能力

| 类型 | 状态 | 说明 |
| --- | --- | --- |
| 视频 | 社区 SDK 已观察 | 有上传、发布、列表、删除 |
| 图文 | 未核实/待补充 | 未在社区 SDK 中确认 |
| 长文文章 | 未核实/待补充 | 不应推断支持 |

视频限制、封面比例、标题长度、文件大小、时长、码率均未从当前官方文档核实，`capabilities` 先填 `null`。

## 7. 审核与状态

需要确认：

- `publish` 返回后是否直接公开；
- 审核中如何查询；
- 审核拒绝错误码；
- 作品列表的 `pending` 含义；
- 被限流/封禁时返回什么；
- 是否可以删除或撤回。

第一版不应把 `publish` HTTP 成功直接当作已公开；至少保存 `submit_accepted`，再用 `photo/list` 或官方状态接口确认。

## 8. 数据指标

| 快手字段 | amei 指标 | 备注 |
| --- | --- | --- |
| `view_count` | `plays` | 需确认是否为播放 |
| `like_count` | `likes` |  |
| `comment_count` | `comments` |  |
| 分享/收藏 | 未核实 | 社区模型未确认字段 |

账号粉丝、完播率、平均观看时长未核实。

## 9. GitHub 复用评估

| 仓库 | License | 最后提交 | 判断 |
| --- | --- | --- | --- |
| `bububa/kwai-openapi` | Apache-2.0 | 2021-04-14 | 只作参考，不能作为唯一生产实现 |

原因：

- 最后提交距当前超过 4 年；
- 不能证明当前官方 API 仍完全一致；
- 缺少当前应用审核、scope 和额度信息；
- 社区库字段可能来自旧版本协议。

## 10. 自动化可行性

- 视频上传/发布：测试应用验证后可自动；
- 用户授权：OAuth2；
- 手机号注册：`未核实/待补充`；
- 官方每日额度：`未核实/待补充`；
- 未确认前不得用网页自动化补位。

## 11. 人工接管点

- OAuth 重新授权；
- 应用审核/scope；
- 账号实名或资质；
- 平台审核；
- 封面/视频规格不合规；
- 上传结果未知时人工核对后台。

## 12. 风险

- 2021 年社区 SDK 与当前官方接口可能不一致；
- 快手官网未登录无法获取完整文档；
- 手机号注册和权限路径未核实；
- 发布额度未知；
- 书评/图书推广可能触发商业推广审核；
- 不应使用逆向或网页后台接口替代开放平台。

## 13. 适配器实现建议

1. 先用官方当前文档建立 endpoint/field 基线；
2. 社区 SDK 只用于交叉核对；
3. 固定 `app_id`、scope 和回调配置；
4. 实现分片上传和断点续传；
5. 上传、发布、作品列表三段分别记录状态；
6. 对未知字段使用 `null`，不写死限制；
7. 测试应用完成一条真实视频后才打开发布开关。

## 14. 证据

| 证据 | 位置 | 状态 |
| --- | --- | --- |
| 开放平台 | https://open.kuaishou.com/ | 已访问，文档需登录 |
| 社区 SDK | https://github.com/bububa/kwai-openapi | 已核实 |
| 提交 | `869b9bcd025a2764d04df844d870a63202cce31a`，2021-04-14 | 已核实 |
| License | Apache-2.0 | 已核实 |
| 当前官方额度/权限/手机号注册 | 开发者后台 | 登录后可见/待验证 |
