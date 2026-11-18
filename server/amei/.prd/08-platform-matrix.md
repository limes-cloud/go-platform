# 平台能力矩阵

> 状态：调研结论 / 方案输入
> 日期：2026-11-12
> 范围：抖音、快手、B 站、微博、小红书、视频号
> 原则：只写已核实事实；社区 SDK 不能替代官方文档；额度未知不填估算值

## 1. 总览

| 平台 | 内容发布能力 | 数据能力 | 账号授权 | 公开额度 | 首轮结论 |
| --- | --- | --- | --- | --- | --- |
| 抖音 | 视频、图文 API 已核实 | 作品/粉丝数据接口已在 SDK 中出现 | OAuth 入口和 access-token 头已观察 | 未核实/待补充 | 第一优先，复用官方 SDK |
| 快手 | 社区 SDK 有视频全链路 | 作品列表有基础互动字段 | OAuth2 端点已在社区 SDK 中 | 未核实/待补充 | 第二优先，官方文档复核后启用 |
| B 站 | 上传、封面、分区和投稿链已在官方 demo 核实 | 数据接口未核实 | token 换发已核实，授权 URL 待验证 | 非正式会员单日最多 5 个稿件 | 申请权限并实测鉴权后开启 |
| 微博 | 文本/图片分享已核实；视频仅机构可申请 | 文本接口返回微博 ID；数据接口待验证 | OAuth access token | 接口有频次限制，数值未核实 | 先做文本/图片，视频按资质开通 |
| 小红书 | 未发现内容发布 API | 未发现内容数据 API | 开发者登录入口存在，字段待验证 | 未核实/待补充 | 默认禁用自动发布 |
| 视频号 | 未发现公开视频发布 API | 未发现公开内容数据 API | 仅平台后台/微信生态授权 | 未核实/待补充 | 默认禁用自动发布 |

### 1.1 内容类型支持

| 平台 | 文章 | 图文 | 视频 | 说明 |
| --- | --- | --- | --- | --- |
| 抖音 | 不适用 | 已核实 | 已核实 | 使用 `create_image_text` / `create_video` |
| 快手 | 未核实 | 未核实 | 社区 SDK 已观察 | 需官方文档复核 |
| B 站 | 未核实 | 未核实 | 上传/投稿链已核实 | 鉴权方式待实测 |
| 微博 | 以长文微博替代 | 已核实 | 仅机构可申请 | 文本必须带安全域 URL |
| 小红书 | 未核实/待补充 | 未核实/待补充 | 未核实/待补充 | 未发现内容发布 API |
| 视频号 | 不适用 | 无公开 API/未核实 | 无公开 API/未核实 | 只确认小店/商家能力 |

## 2. 逐平台摘要

### 2.1 抖音

- 开放平台入口：`https://open.douyin.com/`。
- 官方 Go SDK：`https://github.com/bytedance/douyin-openapi-sdk-go`。
- 许可证：Apache-2.0。
- 核实版本：`a50593c5ccdc31ab5b7cb2153947dfad612bbed9`，2025-07-29。
- 已观察能力：视频创建、视频上传、分片上传、图文创建、作品列表/基础信息/作品数据、粉丝数据。
- 用户授权：OAuth；SDK 中出现 access-token 头和 passport/oauth 路径。
- 手机号：开发者账号是否可用手机号注册、应用是否必须企业认证、内容发布权限如何申请，均需登录后台确认；当前标记 `登录后可见/待验证`。
- 额度：官方每日发布额度未核实。

### 2.2 快手

- 开放平台入口：`https://open.kuaishou.com/`。
- 社区 SDK：`https://github.com/bububa/kwai-openapi`。
- 许可证：Apache-2.0。
- 最后提交：`869b9bcd025a2764d04df844d870a63202cce31a`，2021-04-14。
- 已观察端点：OAuth2 authorize/access_token/refresh_token，视频 start_upload、upload、multipart、fragment、resume、complete、publish、list、delete。
- 用户授权：OAuth2。
- 手机号：开发者注册入口存在，是否支持纯手机号注册、个人/企业资质和权限审批需登录确认；`登录后可见/待验证`。
- 额度：未核实。

### 2.3 B 站

- 开放平台入口：`https://open.bilibili.com/`。
- 官方 demo：`https://github.com/bilibili-openplatform/demo`，已归档、无 License，仅作链路参考。
- 已核实 OAuth 换 token：`POST https://api.bilibili.com/x/account-oauth2/v1/token`，参数为 `client_id`、`client_secret`、`code`、`grant_type=authorization_code`。
- 已核实视频上传：`/arcopen/fn/archive/video/init` -> `/video/v2/part/upload`（8 MiB 分片）-> `/arcopen/fn/archive/video/complete`。
- 已核实封面上传：`POST /arcopen/fn/archive/cover/upload`，multipart `file`，返回 `data.url`。
- 已核实分区查询：`GET /arcopen/fn/archive/type/list`。
- 已核实服务端投稿：`POST https://member.bilibili.com/arcopen/fn/archive/add-by-utoken`。
- 必填字段：`title`（<80 字符）、`tid`、`tag`（总长 <200）、`copyright`（1 原创 / 2 转载）。
- 可选字段：`cover`、`desc`（<250）、`no_reprint`。
- 返回：`data.resource_id`，例如 `BV17B4y1s7R1`。
- 公开额度：非正式会员单日最多投递 5 个稿件；正式会员限制需以后台为准。
- 鉴权冲突：demo 仅用 query 参数；另一份 OpenAPI 快照要求 `Access-Token`、`Authorization`、`X-Bili-*` HMAC-SHA256 签名头。必须以真实应用实测确认，不能写死。
- 缺口：授权 URL、refresh 端点、数据接口、应用权限和真实上传规格未核实。
- 开源：官方 demo 只能参考，不复制；`biliup/biliup` 是 Web/Studio 协议实现且 README 禁止商用；`jiejiebiezheyang/biligo` 仅直播能力。均不作为生产依赖。

### 2.4 微博

- 开放平台入口：`https://open.weibo.com/`。
- 已核实文本/图片接口：
  - `POST https://api.weibo.com/2/statuses/share.json`
  - `POST https://api.weibo.com/2/statuses/upload_url_text.json`
- `statuses/share` 要求 OAuth token、正文不超过 140 个汉字、不能包含 `#话题词#`、必须包含调用方绑定安全域下的网页 URL。
- 图片支持 JPEG/GIF/PNG，小于 5 MB。
- `upload_url_text` 是高级接口，需要额外授权/频次权限；支持 `is_long_text=1` 和最多 9 个 `pic_id`。
- 视频文档 `https://open.weibo.com/wiki/Video/api` 已核实：接入方必须是政务、媒体、机构等实体，个人暂时无法接入；需联系蓝 V 客服或政务运营开通并获取文档。
- 视频端点/字段不能从空页面或社区代码推断，默认 `video.supported=false`。
- 手机号：开发者注册入口存在，具体资质和手机号绑定需登录确认。
- 额度：接口有频次限制，公开数值未核实。

### 2.5 小红书

- 开放平台入口：`https://open.xiaohongshu.com/`。
- 当前文档导航仅见公共 API、订单 API、售后 API、商品 API、库存 API、素材中心 API、物流 API、财务 API、即时零售 API、会员通 API、供货商 API。
- 未发现笔记/视频内容发布 API。
- 开发者前端存在 `/api/developer/sendCode`、`/api/developer/register`、`/api/developer/ssoLogin`、`/api/developer/updateMobilePhone`，只能说明可能有手机号注册/登录流程；字段、协议和权限未核实。
- 开源：未找到可信、许可清晰、覆盖内容发布的项目；商家/订单/营销 SDK 不能用于内容发布。
- 结论：`未核实/待补充`，生产默认禁用自动发布。

### 2.6 视频号

- 官方入口：`https://channels.weixin.qq.com/platform`。
- 开发文档：`https://developers.weixin.qq.com/doc/channels/index.md`。
- 已核实文档只覆盖视频号小店/交易等能力，未确认公开的视频内容发布 API。
- 手机号：微信生态账号绑定和资质以平台后台为准，当前 `未核实/待补充`。
- 开源：没有可信可复用的公开内容发布 SDK；禁止使用抓包、下载、逆向工程实现。
- 结论：`无公开 API / 未核实`，默认禁用自动发布。

## 3. GitHub 复用清单

| 平台 | 仓库 | License | 最后提交 | 覆盖 | 结论 |
| --- | --- | --- | --- | --- | --- |
| 抖音 | `bytedance/douyin-openapi-sdk-go` | Apache-2.0 | 2025-07-29 | 官方视频/图文/数据 SDK | 直接复用 |
| 快手 | `bububa/kwai-openapi` | Apache-2.0 | 2021-04-14 | OAuth、视频上传、发布、列表 | 只作参考，不能当官方文档 |
| B 站 | `bilibili-openplatform/demo` | 无 License | 2024-11-06 | 官方 token/上传/封面/分区/投稿示例 | 仅参考，不复制 |
| B 站 | `biliup/biliup` | MIT（README 禁止商用） | 2026-11-09 | Web/Studio 上传/投稿 | 不进入生产依赖 |
| B 站 | `jiejiebiezheyang/biligo` | MIT | 2026-10-02 | 直播开放能力 | 不覆盖视频投稿，不复用 |
| B 站 | `SocialSisterYi/bilibili-API-collect` | 无有效许可/已归档 | - | 社区整理 | 不可用 |
| 微博 | `axiaoxin-com/weibo` | MIT | 2020-11-23 | OAuth、文本/图片分享 | 参考协议封装，视频不复用 |
| 微博 | `yafengio/weibogo` | 无许可证 | - | 微博 API | 不可用于生产 |
| 微博 | `bububa/biz-weibo` | Apache-2.0 | - | 广告/营销 API | 不是内容发布 SDK |
| 小红书 | 未找到 | - | - | - | 不引入 |
| 视频号 | 未找到 | - | - | - | 不引入 |

## 4. 额度与限流

### 4.1 已核实

| 平台 | 规则 | 来源 |
| --- | --- | --- |
| B 站 | 非正式会员单日最多投递 5 个稿件 | B 站开放平台“视频稿件提交”文档 |

### 4.2 未核实

抖音、快手、微博、小红书、视频号的每日发布额度当前为 `未核实/待补充`。接口频次限制也可能按应用、用户、IP、接口分别计算，需要登录开发者后台查看。完整口径见 `16-quota-and-limits.md`。

### 4.3 amei 内部软额度

内部软额度不作为平台事实展示。建议初始仅用于保护新账号：

- 新账号首日 1 条，稳定后再提高；
- 每平台独立计数；
- 平台返回限流时优先遵守 `retryAfter`；
- 不支持通过多账号或代理绕过平台限制。

## 5. 优先级

| 阶段 | 平台 | 条件 |
| --- | --- | --- |
| P0 | 抖音 | 开发者应用获批，OAuth 与视频/图文权限可用 |
| P1 | 快手 | 官方当前文档复核，测试应用完成上传/发布/数据闭环 |
| P2 | B 站 | 获得稿件投递权限，实测 query/签名头鉴权并完成上传/封面/投稿闭环 |
| P2 | 微博 | 文本/图片接口可用；视频能力另行确认 |
| P3 | 小红书 | 确认内容发布 API 后再排期 |
| P3 | 视频号 | 确认公开内容发布 API 后再排期 |

## 6. 统一结论

- 六个平台不使用网页自动化模板；没有官方 API 时只做禁用占位，不强行接入。
- 抖音可以最快做出官方 API 闭环；快手需要以当前官方文档重新校验；B 站、微博存在可核实能力但有明显缺口。
- 小红书和视频号在内容发布能力确认前只做账号入口、能力展示和“暂不支持”提示。
- 任何平台新增能力，先补 `platforms/*.md` 证据，再更新 `capabilities`，最后才允许打开发布开关。
