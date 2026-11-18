# 手机号、开发者账号与平台授权证据

> 状态：事实分级清单
> 日期：2026-11-12
> 目的：严格区分 amei 手机号登录、平台开发者账号注册、平台内容账号授权
> 原则：手机号 OTP 不能替代平台 OAuth；扫码授权也不能被描述成“手机号登录 API”

## 1. 三层身份，不能混用

| 层级 | 归属 | 解决什么问题 | 典型凭证 | 能否直接发布内容 |
| --- | --- | --- | --- | --- |
| amei 用户 | amei 控制面 | 用户注册、登录、隔离自己的内容与账号 | amei JWT | 否 |
| 平台开发者账号/应用 | 各平台开放平台 | 创建应用、申请 scope、配置回调、获得 client id/secret | 开发者后台账号、应用密钥 | 否，只代表应用资格 |
| 平台内容账号 | 各内容平台 | 代表具体创作者账号执行发布和取数 | 平台 OAuth access/refresh token | 是，前提是 scope 和账号状态有效 |

因此产品必须同时满足：

```text
amei 手机号用户已登录
  + 开发者应用已获批对应能力
  + 内容账号已完成官方 OAuth/授权
  + 账号 scope 覆盖目标内容类型
  = 才允许创建发布任务
```

缺任何一项都不能用网页登录、Cookie 或逆向接口补齐。

## 2. amei 自有手机号登录

### 2.1 流程

```text
用户输入手机号
  -> POST /amei/api/v1/auth/sms/send
  -> 短信通道发送 OTP
  -> POST /amei/api/v1/auth/sms/verify
  -> 校验通过，手机号不存在则自动建号
  -> 返回 amei JWT
```

### 2.2 API

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `POST` | `/amei/api/v1/auth/sms/send` | 发送登录验证码 |
| `POST` | `/amei/api/v1/auth/sms/verify` | 校验验证码并登录/自动注册 |
| `GET` | `/amei/api/v1/me` | 获取当前手机号用户 |

### 2.3 边界

- 短信服务商通过 provider 接口抽象，不把某一家 SDK 写死；
- 验证码只存 HMAC，5 分钟过期、60 秒重发、5 次尝试；
- 手机号是 amei 用户唯一标识，不是平台账号标识；
- 不根据手机号自动查找或绑定平台内容账号；
- 平台账号必须由用户主动点击绑定并完成平台授权。

## 3. 逐平台授权与注册证据

### 3.1 抖音

| 项目 | 结论 | 证据状态 |
| --- | --- | --- |
| amei 手机号登录 | 控制面 OTP | 已设计 |
| 开发者账号注册 | 开放平台登录入口存在；是否支持纯手机号注册、个人/企业资质和审核要求需登录后台 | 登录后可见/待验证 |
| 内容账号授权 | 官方 OAuth，SDK 中观察到 `/oauth/access_token/`、`/oauth/refresh_token/`、`/oauth/userinfo/` | 已观察，参数待后台确认 |
| 内容发布凭证 | 适配器保存 access token，请求头使用 `access-token` | 已观察 |
| 发布权限 | 由应用 scope 和接口权限决定 | 登录后可见/待验证 |

已观察到的 SDK 路径：

```text
/passport/open/get_access_code
/passport/open/get_client_code
/oauth/access_token/
/oauth/refresh_token/
/oauth/refresh_biz_token/
/oauth/userinfo/
```

注意：SDK 中存在路径不代表应用已拥有该 scope。开发者应用、用户授权和 scope 必须分别校验。

### 3.2 快手

| 项目 | 结论 | 证据状态 |
| --- | --- | --- |
| amei 手机号登录 | 控制面 OTP | 已设计 |
| 开发者账号注册 | 开放平台注册入口存在；纯手机号注册、主体资质、应用审核需登录确认 | 登录后可见/待验证 |
| 内容账号授权 | OAuth2 authorize/access_token/refresh_token | 社区 SDK 已观察，官方待复核 |
| 二维码授权 | `/oauth2/qr_code` 是平台授权挑战，不是手机号注册 API | 社区 SDK 已观察 |
| 内容发布凭证 | 适配器保存 access token | 已观察 |

社区 SDK 中的授权链路：

```text
https://open.kuaishou.com/oauth2/authorize
  app_id + scope + response_type=code + redirect_uri + state

https://open.kuaishou.com/oauth2/qr_code
  app_id + scope + response_type=code + redirect_uri + state + qrcode_size

https://open.kuaishou.com/oauth2/access_token
https://open.kuaishou.com/oauth2/refresh_token
```

这些端点必须用当前官方文档复核后才能进入生产适配器。

### 3.3 B 站

| 项目 | 结论 | 证据状态 |
| --- | --- | --- |
| amei 手机号登录 | 控制面 OTP | 已设计 |
| 开发者账号注册 | 开放平台入口存在；手机号注册、主体资质、实名和权限审批待确认 | 登录后可见/待验证 |
| 内容账号授权 | `POST https://api.bilibili.com/x/account-oauth2/v1/token` | 官方 demo 已核实 |
| 授权码来源 | demo 注释为“通过授权 SDK 获取”，完整授权 URL 未在 demo 中给出 | 未核实/待补充 |
| token 续期 | demo 说明可使用 refresh token，但未给出具体端点 | 未核实/待补充 |

已核实 token 换发参数：

```text
POST https://api.bilibili.com/x/account-oauth2/v1/token
query: client_id, client_secret, code, grant_type=authorization_code
response: access_token, refresh_token, expires_in
```

B 站不能写成“服务端手机号+验证码登录”。内容账号必须通过官方授权流程取得 code，再在适配器换 token。

### 3.4 微博

| 项目 | 结论 | 证据状态 |
| --- | --- | --- |
| amei 手机号登录 | 控制面 OTP | 已设计 |
| 开发者账号注册 | 开放平台入口存在；手机号、主体、应用审核待后台确认 | 登录后可见/待验证 |
| 内容账号授权 | OAuth authorize + access_token | 官方文档/社区 SDK 已核实 |
| 文本/图片发布 | `statuses/share`、`statuses/upload_url_text` | 已核实 |
| 视频发布 | 只对政务、媒体、机构等实体开放，个人暂不能接入 | 官方页面已核实 |
| 视频接入方式 | 联系蓝 V 客服/政务运营开通并获取文档 | 已核实 |

社区 SDK 出现的 OAuth 端点：

```text
https://api.weibo.com/oauth2/authorize
https://api.weibo.com/oauth2/access_token
```

微博应用还必须配置安全域名；`statuses/share` 的正文 URL 必须属于调用方应用绑定的安全域。

### 3.5 小红书

| 项目 | 结论 | 证据状态 |
| --- | --- | --- |
| amei 手机号登录 | 控制面 OTP | 已设计 |
| 开发者账号注册 | 前端存在 `/api/developer/sendCode`、`/api/developer/register` 等路径迹象 | 仅入口迹象，未核实 |
| 内容账号授权 | 未确认面向内容创作者的 OAuth 发布 scope | 未核实/待补充 |
| 内容发布 | 公开导航只有电商、订单、商品、素材等能力 | 无公开 API/未核实 |

不能把开发者前端的手机号登录/注册接口当成公开 API。它们不是内容发布授权接口，也不应被抓包复用。

### 3.6 微信视频号

| 项目 | 结论 | 证据状态 |
| --- | --- | --- |
| amei 手机号登录 | 控制面 OTP | 已设计 |
| 开发者/商家账号 | 视频号小店和商家后台存在；是否手机号独立注册、是否必须绑定微信待确认 | 未核实/待补充 |
| 内容账号授权 | 未确认第三方 OAuth 发布 scope | 未核实/待补充 |
| 内容发布 | 官方文档只确认小店/交易/商家能力 | 无公开 API/未核实 |
| 微信生态登录 | 不能外推为“视频号内容发布授权” | 已确认边界 |

视频号小店能力不等于视频内容发布能力。没有官方授权 scope 时只做禁用占位，不保存扫码登录态。

## 4. 授权挑战类型

适配器可以返回三类官方挑战：

| `type` | 使用场景 | 允许保存 |
| --- | --- | --- |
| `oauth_url` | 标准 OAuth 授权页 | state、PKCE verifier（适配器侧）、回调 code |
| `qr` | 平台官方提供的扫码授权 | 一次性 challenge/ticket，短 TTL |
| `manual_confirm` | 平台仅支持后台人工授权 | 人工操作记录，不含账号密码 |

禁止保存：

- 平台密码；
- 浏览器 Cookie、localStorage、storage state；
- 网页后台验证码；
- 抓包得到的私有请求签名；
- 用户微信/微博/抖音账号的二维码登录 ticket 长期副本。

## 5. 平台账号与 amei 用户绑定

```text
amei 用户 u_1001
  └─ 平台账号 pa_1001（douyin，accountRef=douyin_xxx）
  └─ 平台账号 pa_1002（bilibili，accountRef=bili_xxx）
```

- 一个手机号用户可以绑定多个平台、多个账号；
- 同一平台账号不能静默绑定到第二个用户；
- 控制面只保存 `accountRef`、脱敏昵称、头像、状态和能力摘要；
- 适配器保存真实 token、refresh token、scope 和平台素材缓存；
- 解绑时先撤销平台授权，再软删除控制面绑定；
- 重新授权不能让控制面看到 authorization code 或 token。

## 6. 发布前权限校验

适配器必须返回并持续更新：

```json
{
  "accountRef": "acc_douyin_001",
  "platformCode": "douyin",
  "status": "active",
  "authType": "oauth",
  "grantedCapabilities": ["video.publish", "image_text.publish", "post.metrics"],
  "missingCapabilities": [],
  "tokenExpiresAt": 1762592000000,
  "permissionCheckedAt": 1760000000000
}
```

控制面创建任务前必须确认 `grantedCapabilities` 包含目标能力。不能仅凭“账号绑定成功”就显示发布按钮。

## 7. 证据与待办

| 平台 | 已核实 | 仍需登录后台确认 |
| --- | --- | --- |
| 抖音 | 官方 SDK、OAuth 路径、发布/取数端点 | 应用主体、scope、发布权限、额度 |
| 快手 | 旧社区 SDK 的授权与上传路径 | 当前官方契约、scope、额度、资质 |
| B 站 | token 换发、上传/封面/分区/投稿链、5 条/日额度 | 授权 URL、refresh、签名方式、数据接口、应用权限 |
| 微博 | OAuth、文本/图片接口、视频仅机构 | 高级接口、频次、视频开通流程、数据接口 |
| 小红书 | 公开导航无内容发布 API | 是否存在创作者发布 API |
| 视频号 | 官方文档只覆盖小店/商家 | 是否存在内容发布 API 与授权 scope |

待办必须落到开发者后台截图、应用配置或真实测试结果，不能以“网上说可以”作为验收依据。
