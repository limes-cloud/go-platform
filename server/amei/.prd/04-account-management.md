# 手机号用户与平台账号管理

> 状态：方案设计
> 日期：2026-11-12
> 范围：amei 手机号用户、平台 OAuth 账号绑定、状态、授权范围和额度边界
> 关联：`02-adapter-contract.md`、`03-phone-auth.md`、`07-data-model.md`、`14-platform-auth-evidence.md`

## 1. 账号层次

必须区分两个账号概念：

| 账号 | 归属 | 登录方式 | 存在位置 |
| --- | --- | --- | --- |
| amei 用户 | amei 产品 | 手机号 + 短信 OTP | `amei` 控制面 |
| 平台开放账号 | 抖音/快手/B 站/微博等 | OAuth/扫码/平台授权 | `amei-adapters` 本地加密存储 |

amei 手机号只是控制面主账号，不能用它直接调用平台接口，也不代表平台已经登录。

```text
amei_user(手机号)
  └─ 1:N amei_platform_account
          ├─ platformCode
          ├─ adapterId
          ├─ accountRef        # 适配器生成的不透明账号引用
          ├─ authType          # oauth / qr / manual
          ├─ scopes
          ├─ status
          ├─ tokenExpiresAt    # 仅展示提示，不是 token 本体
          └─ display profile
                 │
                 │ 逻辑关联
                 ▼
       adapter 本地账号库
          ├─ access token（加密）
          ├─ refresh token（加密）
          ├─ scope / open_id
          └─ platform media cache
```

## 2. 绑定流程

### 2.1 OAuth 发起

1. 用户在 amei 选择平台；
2. 控制面调用适配器 `POST /v1/oauth/authorize`；
3. 适配器返回 `authorizeUrl`，或返回平台要求的扫码 challenge；
4. 用户在平台官方页面完成登录和授权；
5. 平台回调适配器；
6. 适配器换取 token、加密保存，并返回 `accountRef`；
7. 控制面校验该 `accountRef` 是否已被其他用户绑定，再写入账号索引。

### 2.2 同账号重复绑定

- 同一用户重复绑定同一平台账号：更新 scope、头像、昵称和状态，不新增重复行；
- 不同用户尝试绑定同一平台账号：默认拒绝，提示联系管理员解绑；
- 平台账号身份判断使用适配器返回的不可伪造平台用户标识摘要，不靠昵称判断。

### 2.3 重新授权

`expired` 或 scope 不足时：

1. 控制面调用适配器生成新的授权 URL；
2. 用户重新授权；
3. 适配器沿用原 `accountRef`；
4. 控制面更新授权范围和过期提示。

不能在后台静默使用用户密码或扫码凭证续期。

## 3. 能力与 scope

平台 OAuth scope 决定能否发布、拉数据，不能把“登录成功”当成“有发布权限”。

账号记录保存：

- `scopes`：授权范围摘要；
- `grantedCapabilities`：由适配器根据 token 和平台返回推导的能力；
- `missingCapabilities`：例如缺少作品数据权限；
- `permissionCheckedAt`：最近一次权限探测时间。

示例：

```json
{
  "accountRef": "acc_douyin_001",
  "platformCode": "douyin",
  "displayName": "书评号",
  "status": "active",
  "authType": "oauth",
  "scopes": ["video.publish", "video.data"],
  "grantedCapabilities": ["video.publish", "image_text.publish", "post.metrics"],
  "missingCapabilities": [],
  "expiresAt": 1762592000000
}
```

平台实际 scope 名称以开发者后台为准，适配器负责映射为上述稳定能力名。

## 4. 账号状态机

```text
          bind success
               │
               ▼
            active ── token expired/revoked ──► expired
               │                                  │
               │                                  └─ reauth ─► active
               ├─ platform needs verification ──► needs_action
               │                                  │
               │                                  └─ user completes ─► active
               ├─ user unbind / platform disabled ─► disabled
               └─ adapter/network error ──────────► error
```

| 状态 | 是否可发布 | 说明 |
| --- | --- | --- |
| `active` | 是（按 scope） | 授权和账号均可用 |
| `expired` | 否 | token 过期或被撤销 |
| `needs_action` | 否 | 需要扫码、补资料、平台实名或人工确认 |
| `disabled` | 否 | 用户解绑或平台停用 |
| `error` | 否 | 适配器无法判断，需排查 |

账号状态以适配器探测为准。“上次发布成功”不能证明当前 token 仍有效。

## 5. 额度模型

必须区分三种限制：

| 类型 | 归属 | 示例 | 展示方式 |
| --- | --- | --- | --- |
| 平台官方额度 | 平台 | B 站非正式会员每日 5 个稿件 | 标注来源与验证状态 |
| 应用/API 权限额度 | 平台开放平台 | 应用每日配额、接口 QPS | 登录开发者后台确认 |
| amei 内部软额度 | 产品 | 新账号每日先发 1 篇 | 可配置，不冒充官方 |

账号页展示：

- `platformDailyLimit`：`null` 表示未核实；
- `platformLimitStatus`：`已核实`、`未核实/待补充` 等；
- `internalDailyLimit`：产品配置；
- `usedToday`：当日成功创建任务数；
- `lastRateLimitedAt`：最近限流时间。

平台限流时，适配器返回 `PLATFORM_RATE_LIMITED` 和 `retryAfterMs`。控制面不得通过多账号、代理或自动换号规避平台限制。

## 6. 账号 API

### 6.1 发起绑定

`POST /amei/api/v1/accounts/authorize`

```json
{
  "platformCode": "douyin"
}
```

响应：

```json
{
  "challengeId": "chl_01",
  "type": "oauth_url",
  "authorizeUrl": "https://open.douyin.com/...",
  "expiresAt": 1760007200000
}
```

### 6.2 查询账号

`GET /amei/api/v1/accounts`

支持按 `platformCode`、`status` 筛选；只返回当前手机号用户自己的账号。

### 6.3 重新授权

`POST /amei/api/v1/accounts/{id}/reauth`

### 6.4 解绑

`DELETE /amei/api/v1/accounts/{id}`

解绑时：

- 若存在运行中的发布任务，先拒绝或要求先取消；
- 调用适配器撤销授权；
- 控制面软删除账号绑定；
- 适配器清理 token 和平台素材缓存；
- 保留必要的审计记录，不保留 token 明文。

### 6.5 刷新状态

`POST /amei/api/v1/accounts/{id}/check`

只做状态探测，不发内容。

## 7. 账号归属与权限

- 所有账号查询必须带 `user_id` 条件；
- `accountRef` 对用户不可见或只展示脱敏摘要；
- 用户不能把账号共享给其他 amei 用户；
- 管理员查看账号只能看到脱敏信息；
- 操作审计包含 `user_id`、`account_id`、`platform_code`、`action`、`request_id`；
- 解绑、重新授权、修改 scope 都写审计日志。

## 8. 平台能力差异

账号详情页需要显示每个平台真实能力，而不是统一显示“可发布”：

| 能力 | 来源 |
| --- | --- |
| 视频发布 | 适配器 `capabilities.contentTypes.video` |
| 图文发布 | 适配器 `capabilities.contentTypes.imageText` |
| 长文/文章 | 适配器 `capabilities.contentTypes.article` |
| 定时发布 | 适配器 `publishModes` |
| 作品数据 | 适配器 `metricsTypes` |
| 平台授权剩余天数 | 适配器 session |
| 发布额度 | 平台事实 + 内部软限制分别展示 |

小红书、视频号等未确认内容发布能力的平台，账号即使授权成功，也必须显示“发布能力未开通”，不能给出可点击发布按钮。

## 9. 验收标准

- 一个手机号用户可以绑定多个平台账号；
- 重复绑定同一平台账号不产生重复记录；
- 未授权或 scope 不足时发布按钮禁用；
- 控制面数据库和接口响应中不存在平台 token/cookie；
- token 过期后状态变为 `expired` 并可重新授权；
- 账号能力按适配器声明展示；
- 平台额度与内部软额度分开显示；
- 解绑会撤销授权且保留审计记录。
