# 手机号注册与登录

> 状态：方案设计
> 日期：2026-11-12
> 范围：`amei` 用户手机号注册/登录、短信验证码、可替换短信通道
> 关联文档：`04-account-management.md`、`09-deployment-security.md`、`14-platform-auth-evidence.md`

## 1. 目标与边界

本期实现 amei 自身的用户体系：用户使用手机号直接注册/登录，验证码通过可替换的短信通道发送。
本期不实现平台账号的手机号登录，平台登录由适配器负责，见 `02-adapter-contract.md` 和
`04-account-management.md`。

边界：

- 不把短信服务商写死在代码里；
- 不在日志、数据库或响应中保存验证码明文；
- 不做密码登录、邮箱登录、第三方登录；
- 不实现平台短信验证码识别或自动填写；
- 验证码发送和校验都做频率、次数和过期控制。

## 2. 登录流程

```text
用户输入手机号
  -> POST /amei/api/v1/auth/sms/send
  -> amei 生成 6 位验证码
  -> 通过 Sender 适配器发送短信
  -> 数据库保存 HMAC(手机号 + 验证码 + 场景)

用户输入验证码
  -> POST /amei/api/v1/auth/sms/verify
  -> 查找最新未消费验证码
  -> 校验过期、次数、HMAC
  -> 首次登录自动创建用户
  -> 签发 JWT
```

首次登录即注册，不区分“注册”和“登录”两个入口。用户创建后状态为 `active`。

## 3. 短信通道抽象

这里的“手机号登录 skill”指一个可独立复用、按配置装配的认证能力，不是把某个手机号、
短信供应商或页面流程写死在业务代码里。认证服务只依赖 `Sender` 接口和配置，短信通道、
验证码有效期、限流阈值都可以替换；平台账号绑定仍由适配器 OAuth 完成。

短信发送必须通过接口注入，不在业务代码中直接调用某家云厂商 SDK。

```go
type Sender interface {
    Send(ctx context.Context, phone, code, purpose string) error
}
```

第一阶段实现：

| Provider | 用途 | 行为 |
| --- | --- | --- |
| `dev` | 本地开发 | 日志打印验证码，不真实发送 |
| `webhook` | 生产通用适配 | 向配置的短信网关 POST 手机号、验证码、场景 |

生产可以按同一接口新增阿里云、腾讯云或企业短信网关实现，不改变 auth service。
`provider`、URL、token、超时都从配置读取，不在代码中硬编码。

Webhook 请求示例：

```json
{
  "phone": "13800138000",
  "code": "123456",
  "purpose": "login"
}
```

Webhook 返回 2xx 视为发送成功；非 2xx 或超时返回发送失败。发送失败不得把验证码写入数据库，
避免用户看到“发送成功”但实际没有收到。

## 4. 验证码规则

| 项目 | 规则 |
| --- | --- |
| 长度 | 6 位数字 |
| 有效期 | 5 分钟，可配置 |
| 重发间隔 | 60 秒，可配置 |
| 单验证码最大尝试次数 | 5 次，可配置 |
| 存储 | 只存 HMAC-SHA256，不存明文 |
| 消费 | 验证成功后立即标记已消费 |
| 场景 | 第一期只支持 `login`，预留 `bind_phone`、`change_phone` |

验证码生成使用 `crypto/rand`，不能使用可预测的伪随机数。

## 5. 接口

### 5.1 发送验证码

`POST /amei/api/v1/auth/sms/send`

请求：

```json
{
  "phone": "13800138000"
}
```

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "expiresIn": 300,
    "devCode": "123456"
  }
}
```

`devCode` 只在 `auth.exposeDevCode=true` 且短信 provider 为 `dev` 时返回；生产必须关闭。

错误：

| 场景 | HTTP | 错误信息 |
| --- | ---: | --- |
| 手机号格式错误 | 400 | 请输入正确的中国大陆手机号 |
| 发送过于频繁 | 429 | 验证码发送过于频繁，请稍后再试 |
| 短信通道失败 | 502 | 短信发送失败，请稍后重试 |

### 5.2 校验验证码并登录

`POST /amei/api/v1/auth/sms/verify`

请求：

```json
{
  "phone": "13800138000",
  "code": "123456"
}
```

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "token": "jwt...",
    "user": {
      "id": 1,
      "phone": "13800138000",
      "nickname": "用户8000",
      "status": "active"
    }
  }
}
```

JWT 建议：

- 算法 HS256；
- claims 至少包含 `uid`、`phone`、`iat`、`exp`、`iss`；
- 默认 24 小时有效；
- 密钥不得与短信 pepper、AES 密钥复用；
- 生产环境只接受 HTTPS。

### 5.3 当前用户

`GET /amei/api/v1/me`

必须带 `Authorization: Bearer <token>`，返回用户基础信息。不得返回短信验证码、JWT 密钥等敏感字段。

## 6. 数据表

### `amei_user`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint | 主键 |
| `phone` | varchar(20) | 手机号，唯一索引 |
| `nickname` | varchar(64) | 默认“用户+后四位” |
| `status` | varchar(16) | `active`、`disabled` |
| `created_at` | bigint | 毫秒时间戳 |
| `updated_at` | bigint | 毫秒时间戳 |

### `amei_otp`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint | 主键 |
| `phone` | varchar(20) | 手机号 |
| `purpose` | varchar(32) | 场景，第一期 `login` |
| `code_hash` | varchar(128) | HMAC 结果 |
| `expires_at` | bigint | 过期时间 |
| `consumed_at` | bigint | 消费时间，0 表示未消费 |
| `attempts` | int | 已尝试次数 |
| `created_at` | bigint | 创建时间 |
| `updated_at` | bigint | 更新时间 |

索引：

- `uk_amei_user_phone(phone)`；
- `idx_amei_otp_phone_purpose(phone, purpose, id)`；
- `idx_amei_otp_expires_at(expires_at)`。

## 7. 安全要求

1. 验证码只存 HMAC，不存明文；
2. 校验使用常量时间比较；
3. 手机号不在日志中完整打印，排障时脱敏为 `138****8000`；
4. 发送接口按手机号、IP、设备维度限流；
5. 验证码错误次数达到上限立即消费，必须重新获取；
6. JWT 密钥、OTP pepper 通过环境变量注入，不写入仓库；
7. 数据库账号只授予 amei 库权限；
8. 生产关闭 `exposeDevCode`；
9. 不在前端 localStorage 长期保存 JWT，优先使用 HttpOnly Cookie 或短期内存 + 刷新机制；
10. 短信通道失败要告警，不能静默。

## 8. 失败与降级

- 短信通道超时：返回“发送失败”，允许用户在 60 秒后重试；
- 短信通道限流：返回 429，不自行切换陌生通道；
- 数据库写入失败：不向用户返回成功；
- JWT 签发失败：不创建半登录状态；
- 同一手机号并发首次登录：依赖唯一索引，冲突后重新读取已有用户。

## 9. 验收标准

- 新手机号首次验证码校验成功后自动创建用户；
- 已存在手机号再次登录不重复创建用户；
- 验证码过期、错误、超过次数、重复消费都有明确错误；
- 60 秒内重复发送被拒绝；
- 日志中搜不到完整手机号、验证码明文、JWT 密钥；
- `dev` 和 `webhook` 两种短信通道可通过配置切换；
- 不修改业务代码即可新增第三种短信通道实现。
