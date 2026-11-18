# GitHub 开源复用调研

> 状态：调研结论 / 开工输入
> 日期：2026-11-12
> 范围：抖音、快手、B 站、微博、小红书、视频号的官方 SDK 与 GitHub 可复用实现
> 判定口径：只评估开放平台内容发布、账号授权、素材上传和数据拉取；网页后台、Cookie、抓包和逆向实现不进入生产候选

## 1. 结论

本轮只确认一个可以进入生产依赖的仓库：抖音官方 Go SDK
`bytedance/douyin-openapi-sdk-go`。其余仓库分为“仅参考协议”“能力不覆盖”“许可证或使用限制不允许”“网页自动化反例”四类。

“GitHub 有仓库”不等于“可以直接发六个平台”。直接复用必须同时满足：

1. 许可证允许商业使用，且仓库没有额外禁止条款；
2. 覆盖目标开放平台的授权、上传、发布或取数链路；
3. 仍在维护，或由平台官方维护；
4. 不是创作者中心网页协议、Cookie 登录或逆向接口；
5. 能固定版本，并接受后续官方文档回归测试。

## 2. 决策总表

| 仓库 | 归属/性质 | License | 核实提交 | 最近提交 | 覆盖能力 | 决策 |
| --- | --- | --- | --- | --- | --- | --- |
| `bytedance/douyin-openapi-sdk-go` | 抖音官方 | Apache-2.0 | `a50593c5ccdc31ab5b7cb2153947dfad612bbed9` | 2025-07-29 | OAuth 相关客户端、视频上传/创建、图文、作品与粉丝数据 | **直接复用** |
| `bilibili-openplatform/demo` | B 站官方示例，已归档 | 无 License | `331ed2d8918cbb8a3b069dec488129f19383e4b9` | 2024-11-06 | OAuth token、视频 init/分片/complete、封面、分区、稿件提交 | **仅参考，不复制进生产** |
| `bububa/kwai-openapi` | 社区 | Apache-2.0 | `869b9bcd025a2764d04df844d870a63202cce31a` | 2021-04-14 | OAuth2、上传、发布、作品列表 | **仅参考，不作为当前官方契约** |
| `axiaoxin-com/weibo` | 社区 | MIT | `bcf4f185ff5c2eff1507c4d678ca3000dc257b35` | 2020-11-23 | OAuth、`statuses/share` 等文本接口 | **仅参考，不直接引入** |
| `bububa/biz-weibo` | 社区 | Apache-2.0 | `ac4cc0c084159e607b523c35bf8732d3fa3bb87d` | 2024-05-03 | 广告/营销 API | **不采用** |
| `yafengio/weibogo` | 社区 | 无 License | `4418c270149d9d743348435525f36977ba739700` | 2025-07-23 | 微博接口封装 | **不采用** |
| `biliup/biliup` | 社区 | MIT，README 另有禁止商用声明 | `0def139d35a3046ab35b0a4b7e072ed88e2b7705` | 2026-11-09 | Web/Studio/App 上传与投稿 | **不采用** |
| `jiejiebiezheyang/biligo` | 社区 | MIT | `907e1b4db9872b21697af5b0437636bcfbc5352e` | 2026-10-02 | B 站直播开放能力 | **不采用，能力不匹配** |
| `dreammis/social-auto-upload` | 社区 | MIT | `3847fff01f5434a8a32829833163cd6723cabc59` | 2026-10-23 | Patchright/Playwright + Cookie + 创作者后台 | **反例，不采用** |
| 小红书内容发布实现 | 未找到可信仓库 | - | - | - | 公开导航只有电商/商家类 API | **无可用实现** |
| 视频号内容发布实现 | 未找到可信仓库 | - | - | - | 官方文档只确认小店/商家能力 | **无可用实现** |

## 3. 抖音：唯一直接复用项

### 3.1 复用范围

- 固定 SDK 提交或 Go module 版本，不跟随 `main` 浮动；
- 适配器通过内部接口封装 SDK，不把 SDK 类型透传给控制面；
- 视频、图文、作品数据和粉丝数据优先走 SDK；
- token 由适配器注入，SDK 调用方只持有 `accountRef`；
- 对平台返回码做统一错误映射，保留原始错误码用于排查。

### 3.2 不能由 SDK 替代的事项

- 开发者应用主体、权限申请、scope 和回调域名；
- 用户授权页面的实际参数和审核；
- 当前应用是否已获得某个发布/取数接口权限；
- 应用级 QPS、每日配额和平台审核规则；
- 书评/图书推广是否属于商业推广内容。

### 3.3 升级策略

- 适配器记录 SDK 版本和提交；
- CI 执行协议测试和核心字段快照测试；
- 升级前对真实测试账号跑“上传 -> 发布 -> 状态/取数”回归；
- 不允许为了赶进度直接把未知 SDK 字段投放到所有用户。

## 4. B 站：官方 demo 只作链路参考

`bilibili-openplatform/demo` 是 B 站官方仓库，但 README 明确写明“已归档，不推荐使用”，仓库没有有效 License 文件。它适合用来核对服务端投稿链路，不适合复制代码进生产。

已从 demo 核实的链路：

```text
POST https://api.bilibili.com/x/account-oauth2/v1/token
  client_id + client_secret + code + grant_type=authorization_code

POST https://member.bilibili.com/arcopen/fn/archive/video/init
  client_id + access_token + {"name":"xxx.mp4"}
  -> data.upload_token

POST https://openupos.bilivideo.com/video/v2/part/upload
  upload_token + part_number + raw bytes

POST https://member.bilibili.com/arcopen/fn/archive/video/complete
  upload_token

POST https://member.bilibili.com/arcopen/fn/archive/cover/upload
  client_id + access_token + multipart file
  -> data.url

GET https://member.bilibili.com/arcopen/fn/archive/type/list
  client_id + access_token

POST https://member.bilibili.com/arcopen/fn/archive/add-by-utoken
  client_id + access_token + upload_token + 稿件 JSON
  -> data.resource_id
```

待实测冲突：

- demo 只使用 query 参数传 `client_id`、`access_token`、`upload_token`；
- 另一份 OpenAPI 快照要求 `Access-Token`、`Authorization`、`X-Bili-Accesskeyid`、`X-Bili-Content-Md5`、`X-Bili-Signature-*` 等头，并使用 HMAC-SHA256；
- 必须以真实应用、当前后台文档和测试稿件确认最终鉴权方式；
- 在确认前，B 站适配器不能把某一种签名方式写死为事实。

## 5. 快手：旧社区 SDK 不足以直接上线

`bububa/kwai-openapi` 的许可证没有问题，但最后一次提交停在 2021-04-14，且关键端点来自当时的社区整理：

```text
https://open.kuaishou.com/oauth2/authorize
https://open.kuaishou.com/oauth2/access_token
https://open.kuaishou.com/oauth2/refresh_token
https://open.kuaishou.com/oauth2/qr_code
https://open.kuaishou.com/openapi/photo/start_upload
https://open.kuaishou.com/openapi/photo/publish
https://open.kuaishou.com/openapi/photo/list
```

这些端点可以作为适配器草案和联调线索，但不能作为“当前官方额度/权限”的证据。必须先用当前开发者后台文档与测试应用复核字段、scope、签名、错误码和审核状态。

## 6. 微博：文本可参考，视频不是普通开发者能力

`axiaoxin-com/weibo` 已核实 MIT，包含 `oauth2/authorize`、`oauth2/access_token` 和 `statuses/share` 等封装，但最后提交为 2020-11-23，且包含历史上的二维码/模拟登录思路。生产只参考公开 OAuth 和接口字段，不复用登录实现。

微博视频官方说明已核实：

- `https://open.weibo.com/wiki/Video/api` 说明短视频接入方为政务、媒体、机构等实体；
- 个人暂时无法接入；
- 需联系蓝 V 客服或政务运营开通视频上传接口并获取文档；
- 因此微博视频默认 `supported=false`，不是“缺一个开源 SDK”。

## 7. 明确排除的仓库

### `biliup/biliup`

- 使用 Web/Studio/App 协议，不是本方案的开放平台服务端投稿；
- LICENSE 为 MIT，但 README 写明“禁止商业用途”；
- 许可文本与额外限制存在冲突，商业产品按最保守口径处理；
- 不复制代码、不作为依赖、不把其端点写进官方适配器。

### `dreammis/social-auto-upload`

- 使用 Patchright/Playwright 操作创作者后台；
- 依赖浏览器登录态/Cookie；
- 与本项目“从开放平台调用”的边界直接冲突；
- 仅作为“为什么不做网页自动化”的反例记录。

### 无 License 仓库

`yafengio/weibogo` 没有 License，B 站官方 demo 也没有 License。按照默认版权规则，不得复制代码进入生产；只能阅读公开事实并自行实现协议。

## 8. 小红书与视频号

两者都没有找到满足以下条件的实现：

- 官方或明确维护方；
- 许可证清晰；
- 调用开放平台内容发布 API；
- 能提供账号授权、发布和取数的完整证据。

因此不引入任何“自动上传/自动发布”社区项目。产品侧只保留账号状态、能力说明和人工发布任务，不把网页自动化包装成开放平台能力。

## 9. 开源复用验收清单

| 检查项 | 要求 |
| --- | --- |
| License | 商业使用、修改、分发均允许，且无 README 额外禁令 |
| 来源 | 官方或可追溯维护者，固定 commit/tag |
| 协议边界 | 只使用开放平台 API，不使用网页协议或 Cookie |
| 覆盖能力 | 至少覆盖目标内容类型的一个完整发布阶段 |
| 维护状态 | 近期有提交，或有官方兼容承诺 |
| 安全 | 不要求把 token 写入日志、URL 或前端 |
| 可测试 | 能用开发者测试应用完成真实回归 |
| 替换性 | 适配器接口在 SDK 外，可降级或替换实现 |

## 10. 需要登录开发者后台确认的事项

以下事项无法从 GitHub 仓库直接得到，必须作为开工前置：

- 抖音：应用主体、发布权限、scope、每日配额的当前值；
- 快手：当前官方文档、OAuth scope、发布字段和额度；
- B 站：实际鉴权方式、应用权限、上传限制、数据接口；
- 微博：高级接口权限、安全域名、机构视频资质；
- 小红书：是否存在面向内容创作者的开放发布 API；
- 视频号：是否存在第三方内容发布 API 和授权 scope。

在这些事项确认前，统一以 `enabled=false` 或 `supported=false` 展示，不用社区实现替代审批。
