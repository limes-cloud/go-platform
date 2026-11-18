# B 站开放平台调研

> 平台：B 站（哔哩哔哩）
> 平台编码：`bilibili`
> 官方入口：https://open.bilibili.com/
> 官方示例：https://github.com/bilibili-openplatform/demo
> 调研日期：2026-11-12
> 总体状态：视频上传、封面、分区、token 换发和稿件提交链路 `已核实`；鉴权方式、授权 URL、refresh、应用权限和数据接口 `待实测/待补充`

## 1. 结论

B 站有服务端视频稿件投递能力，官方归档 demo 已经把 token 换发、视频初始化、分片上传、合并、封面上传、分区查询和稿件提交串成完整链路。

但 demo 已归档且没有 License，只能作为协议参考，不能把代码复制进生产。更关键的是，demo 使用 query 参数，而另一份 OpenAPI 快照要求 HMAC-SHA256 签名头，二者必须用真实应用确认。

首轮策略：

- 申请开放平台应用和视频稿件投递权限；
- 用测试应用确定最终鉴权方式；
- 打通“上传 -> 封面 -> 分区 -> 投稿 -> resource_id”闭环；
- 数据接口未确认前只展示投稿结果，不承诺自动看板；
- 不做 Web/Studio 后台自动化。

## 2. 手机号与账号注册

### 2.1 amei 用户

amei 手机号 OTP 注册/登录，见 `../03-phone-auth.md`，与 B 站账号无关。

### 2.2 B 站开发者账号

- 开放平台入口存在；
- 是否支持纯手机号注册、个人/企业主体、实名和资质要求：`登录后可见/待验证`；
- 应用创建、scope、回调域名和视频投稿权限：开发者后台确认；
- 普通 B 站账号不自动拥有开放平台应用权限。

### 2.3 B 站内容账号

- 用户通过 B 站官方授权/授权 SDK 完成授权；
- 服务端用授权 code 换 access token；
- 服务端不能用手机号+验证码模拟 B 站登录；
- 完整 authorize URL、scope、state 和 refresh 规则仍需后台文档确认；
- token 只保存在适配器，不返回 amei 控制面。

## 3. OAuth 与 token

官方 demo 已核实 token 换发：

```http
POST https://api.bilibili.com/x/account-oauth2/v1/token
```

Query 参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `client_id` | 是 | 开放平台应用 ID |
| `client_secret` | 是 | 应用密钥，只在适配器 |
| `code` | 是 | 授权 SDK 返回的授权码 |
| `grant_type` | 是 | `authorization_code` |

响应中已核实 `access_token`、`refresh_token`、`expires_in`。demo 注释说明可用 refresh token 续期，但没有给出具体 refresh 端点，标记 `未核实/待补充`。

授权码来源在 demo 中只写了“通过授权 SDK 获取”，没有给出完整 authorize URL。不能自行拼接一个未经官方确认的授权地址。

## 4. 视频上传链

### 4.1 初始化

```http
POST https://member.bilibili.com/arcopen/fn/archive/video/init
```

Query：`client_id`、`access_token`。

JSON：

```json
{"name":"book-review.mp4"}
```

返回 `data.upload_token`。后续视频上传、合并和稿件提交都依赖这个 token。

### 4.2 分片上传

```http
POST https://openupos.bilivideo.com/video/v2/part/upload
```

Query：

- `upload_token`；
- `part_number`，从 1 开始。

Body：原始字节，`Content-Type: application/octet-stream`。

demo 使用 8 MiB 分片。真实分片大小、并发、超时和重试上限需以当前官方文档/实测为准，不能把 demo 常量当成永久平台规则。

demo 源码中的部分地址写成 `http://`，生产必须按当前官方文档使用正确的 HTTPS 域名，不能直接照抄明文 HTTP。

### 4.3 合并

```http
POST https://member.bilibili.com/arcopen/fn/archive/video/complete
```

Query：`upload_token`。demo 在全部上传后只做这一步完成，没有单独的“提交稿件”动作；稿件提交仍是后面的 `add-by-utoken`。

### 4.4 上传任务状态

建议适配器保存：

```text
accountRef
uploadToken
fileName / bytes / sha256
uploadedParts / totalParts
status = init/uploading/complete/failed
```

`upload_token` 不返回控制面，不写入普通日志。

## 5. 封面上传与分区

### 5.1 封面

```http
POST https://member.bilibili.com/arcopen/fn/archive/cover/upload
```

Query：`client_id`、`access_token`。Body 为 `multipart/form-data`，文件字段名 `file`。

返回 `data.url`，这个 URL 作为稿件提交的 `cover`。封面尺寸、格式、大小限制尚未核实，媒体层先提供通用封面变体，适配器提交前再按后台规则校验。

### 5.2 分区

```http
GET https://member.bilibili.com/arcopen/fn/archive/type/list
```

Query：`client_id`、`access_token`。分区字典应由适配器缓存，并记录刷新时间；不能把 demo 中的 `tid=21` 直接写死给所有内容。

## 6. 稿件提交

```http
POST https://member.bilibili.com/arcopen/fn/archive/add-by-utoken
```

请求体：

| 字段 | 必填 | 约束 | 说明 |
| --- | --- | --- | --- |
| `title` | 是 | 小于 80 字符，短时间内不能重复 | 稿件标题 |
| `tid` | 是 | 分区 ID | 来自分区接口 |
| `tag` | 是 | 英文逗号分隔，总长小于 200 | 标签 |
| `copyright` | 是 | 1 原创 / 2 转载 | 转载时 `source` 必填 |
| `cover` | 条件必填 | 必须来自封面上传接口 | demo 将其标为 required |
| `desc` | 否 | 小于 250 字符 | 简介 |
| `no_reprint` | 否 | 0 允许 / 1 不允许 | 转载设置 |

demo 的请求体还包含 `mid`，但字段依据与当前文档存在差异；适配器需在真实应用实测后确认是否必填。

响应：

```json
{
  "code": 0,
  "message": "0",
  "ttl": 1,
  "data": {
    "resource_id": "BV17B4y1s7R1"
  }
}
```

`resource_id` 保存为 `platformPostId`。投稿成功后进入审核，审核期间不对外开放。

## 7. 鉴权冲突

### 7.1 demo 方式

官方 demo 的 Go/Java/PHP 示例全部把 `client_id`、`access_token`、`upload_token` 放在 query 中，请求头只设置 `Content-Type`。

### 7.2 OpenAPI 快照方式

另一份“视频稿件提交”快照要求：

```text
Access-Token
Authorization
X-Bili-Accesskeyid
X-Bili-Content-Md5
X-Bili-Signature-Method: HMAC-SHA256
X-Bili-Signature-Nonce
X-Bili-Signature-Version: 2.0
X-Bili-Timestamp
Content-Type: application/json
```

### 7.3 处理原则

- 不能同时猜两套鉴权；
- 用同一测试应用分别验证 query 和签名头；
- 记录真实请求、错误码和平台工单回复；
- 鉴权策略做成适配器配置，不在业务代码散落；
- 确认前 B 站视频能力保持 `publishEnabled=false`。

## 8. 内容能力

| 类型 | 状态 | 说明 |
| --- | --- | --- |
| 视频 | 链路已核实，鉴权待实测 | 上传、封面、分区、投稿均有官方 demo 证据 |
| 图文/动态 | 未核实/待补充 | 未确认开放 API |
| 长文文章 | 未核实/待补充 | 不应从视频投稿外推 |

标题、标签、简介和分区限制有文档证据；视频编码、分辨率、码率、封面尺寸、单文件大小和时长上限仍未核实，`capabilities` 中先填 `null`。

## 9. 额度与限流

已核实：

- 非正式会员单日最多投递 5 个稿件；
- 可在主站通过答题转为正式会员解除限制；
- 正式会员规则以后台为准；
- API QPS、应用配额、上传并发和审核并发未核实。

适配器必须把“非正式会员 5 条/日”作为平台事实返回，不能把内部软额度混进去。完整口径见 `../16-quota-and-limits.md`。

## 10. 审核与数据

已核实：

- 稿件提交后进入审核；
- 审核期间不对外开放；
- 投稿返回 `resource_id`。

未核实：

- 审核状态查询接口；
- 审核拒绝原因和可重试性；
- 稿件列表、删除/撤回；
- 播放、点赞、评论、分享、收藏、完播率；
- 账号粉丝数据；
- 数据更新延迟。

数据接口缺失时只允许人工补录，标记 `source=platform_export` 或 `manual_csv`，不能从网页抓数冒充官方 API。

## 11. GitHub 开源实现

| 仓库 | License | 提交/日期 | 覆盖 | 结论 |
| --- | --- | --- | --- | --- |
| `bilibili-openplatform/demo` | 无 License | `331ed2d8...`，2024-11-06 | 官方 token、上传、封面、分区、投稿示例 | 已归档，仅参考，不复制 |
| `biliup/biliup` | MIT + README 禁止商用 | `0def139d...`，2026-11-09 | Web/Studio/App 上传与投稿 | 不采用 |
| `jiejiebiezheyang/biligo` | MIT | `907e1b4d...`，2026-10-02 | 直播开放能力 | 不覆盖投稿，不采用 |
| `SocialSisterYi/bilibili-API-collect` | 无有效许可/已归档 | - | 社区整理 | 不采用 |

`biliup` 的 `member.bilibili.com/x/vu/web/add`、`preupload` 等属于 Web/Studio 协议，不是本方案使用的开放平台服务端链路。

## 12. 自动化可行性

| 项目 | 结论 |
| --- | --- |
| 视频上传 | 链路有官方 demo 证据，鉴权确认后可自动 |
| 封面/分区/投稿 | 链路有官方 demo 证据 |
| 用户授权 | token 换发已核实，授权 URL/refresh 待补 |
| 开发者手机号注册 | `登录后可见/待验证` |
| 数据回流 | 未核实 |
| 网页后台自动化 | 禁用 |

## 13. 人工接管点

- 开放平台应用/投稿权限；
- 授权 URL 和回调配置；
- 实名、会员资格；
- 鉴权方式实测；
- 封面/视频规格不合规；
- 分区和标签选择；
- 审核拒绝；
- 每日 5 条额度；
- 数据接口未开通。

## 14. 适配器实现建议

1. 先锁定一个测试应用，完成 OAuth 和 token 换发；
2. 用 8 MiB 分片跑通小视频，再测大文件和断点；
3. 封面上传后保存返回 URL，确认尺寸/格式要求；
4. 分区列表缓存并记录版本；
5. 鉴权方式作为配置，不在代码中同时保留两套猜测；
6. 投稿成功后只标 `pending_review`，不直接标公开；
7. 数据接口未确认前不实现自动指标；
8. 不引入 `biliup` 或网页协议实现。

## 15. 证据

| 证据 | 位置 | 状态 |
| --- | --- | --- |
| 官方 demo | https://github.com/bilibili-openplatform/demo | 已归档，已核实 |
| token 换发 | `POST /x/account-oauth2/v1/token` | 已核实 |
| 视频 init/分片/complete | demo `golang/upvideo.go`、`main.go` | 已核实 |
| 封面上传 | demo `golang/upcover.go` | 已核实 |
| 分区查询 | demo `golang/typelist.go` | 已核实 |
| 稿件提交 | `/arcopen/fn/archive/add-by-utoken` | 已核实 |
| 每日额度 | 非正式会员单日最多 5 个稿件 | 已核实 |
| 签名头冲突 | OpenAPI 快照 vs demo | 待实测 |
| 数据接口/应用权限 | 开发者后台 | 未核实/待补充 |
