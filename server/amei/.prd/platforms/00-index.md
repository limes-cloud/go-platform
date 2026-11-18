# 平台调研索引

> 日期：2026-11-12
> 范围：六个内容平台的开放平台能力与 GitHub 可复用性
> 说明：社区 SDK 不是官方文档；网页/逆向接口不是开放平台 API

## 1. 结论表

| 平台 | 文档 | 发布 API | GitHub 复用 | 自动发布 |
| --- | --- | --- | --- | --- |
| 抖音 | [douyin.md](douyin.md) | 视频、图文已核实 | 官方 Go SDK 可直接复用 | 权限获批后开启 |
| 快手 | [kuaishou.md](kuaishou.md) | 社区 SDK 有完整链路 | 旧社区 SDK，仅参考 | 官方复核后开启 |
| B 站 | [bilibili.md](bilibili.md) | 官方 demo 已核实上传、封面、分区和投稿；鉴权冲突待实测 | 官方 demo 仅参考，无 License | 权限与鉴权实测后开启 |
| 微博 | [weibo-video.md](weibo-video.md) | 文本/图片已核实；视频仅机构可申请 | 文本 SDK 可参考 | 文本/图片先开，视频按资质开通 |
| 小红书 | [xiaohongshu.md](xiaohongshu.md) | 未发现内容发布 API | 无可信实现 | 默认关闭 |
| 视频号 | [wechat-channels.md](wechat-channels.md) | 未发现公开视频发布 API | 无可信实现 | 默认关闭 |

## 2. 事实状态

| 平台 | 开发者手机号注册 | 用户 OAuth | 视频发布 | 图文发布 | 文章发布 | 数据 |
| --- | --- | --- | --- | --- | --- | --- |
| 抖音 | 登录后可见/待验证 | 已观察 OAuth 入口 | 已核实 | 已核实 | 不适用 | 已观察作品/粉丝接口 |
| 快手 | 登录后可见/待验证 | 社区 SDK 已观察 | 社区 SDK 已观察 | 未核实 | 未核实 | 社区 SDK 已观察 |
| B 站 | 登录后可见/待验证 | token 换发已核实，授权 URL 待验证 | 上传/封面/投稿链已核实，鉴权待实测 | 未核实 | 未核实 | 未核实 |
| 微博 | 登录后可见/待验证 | OAuth 已核实 | 仅政务/媒体/机构可申请 | 已核实 | 以长文微博替代 | 待验证 |
| 小红书 | 前端手机号流程迹象，待验证 | 未核实 | 未核实/待补充 | 未核实/待补充 | 未核实/待补充 | 未核实/待补充 |
| 视频号 | 未核实/待补充 | 平台后台/微信生态 | 无公开 API/未核实 | 无公开 API/未核实 | 不适用 | 未核实/待补充 |

## 3. 开源许可风险

- 抖音官方 SDK：Apache-2.0，可作为直接依赖；
- `biliup/biliup`：README 明确“禁止商业用途”，即使 MIT 也不能直接用于商业产品；
- 无许可证仓库：不得复制代码进入生产；
- 社区 SDK 应固定 commit、保留许可证、补充来源说明，并优先用官方文档校正字段。

## 4. 平台接入开关

每个平台必须具备独立开关：

- `enabled`：适配器是否上线；
- `publishEnabled`：是否允许创建发布任务；
- `videoEnabled`：视频能力；
- `imageTextEnabled`：图文能力；
- `articleEnabled`：长文能力；
- `metricsEnabled`：数据能力；
- `apiMode`：`official`、`community`；没有开放 API 的平台只做禁用占位。

本期不提供网页自动化模式，不保存 Cookie、storage state 或网页登录凭证。

完整的仓库、License、commit、授权链路和额度证据分别见 `../13-open-source-reuse.md`、
`../14-platform-auth-evidence.md`、`../16-quota-and-limits.md`。

## 5. 证据目录

本轮调研快照位于本机临时目录：

`/tmp/amei-research/amei-20261112/`

该目录不是代码仓库的一部分，正式交付时应把结论、URL、版本和 commit 固化到各平台文档；不要依赖临时文件作为长期引用。
