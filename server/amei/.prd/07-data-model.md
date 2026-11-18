# 数据模型

> 状态：方案设计
> 日期：2026-11-12
> 存储：MySQL 8.0；时间戳统一 bigint 毫秒
> 边界：控制面只存业务索引，不存平台凭据；素材二进制由 `amei-media` 管理

## 1. 实体关系

- `amei_user` 1:N `amei_platform_account`
- `amei_user` 1:N `amei_content` 1:N `amei_content_version` 1:N `amei_content_media`
- `amei_publish_batch` 1:N `amei_publish_task` 1:N `amei_publish_attempt`
- `amei_publish_task` 1:1 `amei_platform_post`
- `amei_user` 1:N `amei_metric_pull_job`、`amei_metric_snapshot`、`amei_audit_log`
- `amei_adapter_registry` 为系统级适配器注册表

平台 OAuth token、refresh token、平台素材缓存属于适配器数据库，不在本模型内。

## 2. 用户与 OTP

### `amei_user`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `phone` | varchar(20) | 手机号，唯一 |
| `nickname` | varchar(64) | 默认“用户+后四位” |
| `status` | varchar(16) | `active`、`disabled` |
| `created_at` | bigint | 创建时间 |
| `updated_at` | bigint | 更新时间 |

索引：`uk_amei_user_phone(phone)`。

### `amei_otp`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `phone` | varchar(20) | 手机号 |
| `purpose` | varchar(32) | `login`，预留 `bind_phone` |
| `code_hash` | varchar(128) | HMAC-SHA256 |
| `expires_at` | bigint | 过期时间 |
| `consumed_at` | bigint | 0 表示未消费 |
| `attempts` | int | 尝试次数 |
| `ip_hash` | varchar(64) | 请求 IP 摘要 |
| `created_at` | bigint | 创建时间 |
| `updated_at` | bigint | 更新时间 |

索引：`idx_amei_otp_phone_purpose(phone, purpose, id)`、`idx_amei_otp_expires_at(expires_at)`。

## 3. 平台账号

### `amei_platform_account`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `user_id` | bigint unsigned | 归属用户 |
| `platform_code` | varchar(32) | `douyin`、`kuaishou`、`bilibili`、`weibo`、`xiaohongshu`、`wechat_channels` |
| `adapter_id` | varchar(64) | 适配器实例 |
| `account_ref` | varchar(128) | 适配器生成的不透明账号标识 |
| `display_name` | varchar(128) | 平台昵称 |
| `avatar_url` | varchar(512) | 头像 URL |
| `auth_type` | varchar(16) | `oauth`、`qr`、`manual` |
| `scopes_json` | text | 授权范围摘要 |
| `granted_capabilities_json` | text | 可用能力列表 |
| `missing_capabilities_json` | text | 缺失能力列表 |
| `status` | varchar(16) | `active`、`expired`、`needs_action`、`disabled`、`error` |
| `token_expires_at` | bigint | 仅过期提示，不是 token |
| `last_checked_at` | bigint | 最近状态探测 |
| `last_success_at` | bigint | 最近成功调用 |
| `platform_user_hint` | varchar(128) | 脱敏账号提示，可空 |
| `created_at` | bigint | 创建时间 |
| `updated_at` | bigint | 更新时间 |

索引：

- `uk_amei_account_user_platform_ref(user_id, platform_code, account_ref)`；
- `uk_amei_account_platform_ref(platform_code, account_ref)`，防止跨用户重复绑定；
- `idx_amei_account_user_status(user_id, status, id)`。

约束：不包含 `password`、`cookie`、`access_token`、`refresh_token` 字段。

## 4. 内容与版本

### `amei_content`

内容逻辑条目，可编辑标题、封面、书籍引用；发布时使用版本快照。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `user_id` | bigint unsigned | 归属用户 |
| `content_type` | varchar(16) | `article`、`image_text`、`video` |
| `title` | varchar(255) | 当前标题 |
| `status` | varchar(16) | `draft`、`ready`、`archived` |
| `book_ref` | varchar(128) | PSou 书籍引用，可空 |
| `latest_version_id` | bigint unsigned | 最新版本 |
| `created_at` | bigint | 创建时间 |
| `updated_at` | bigint | 更新时间 |

索引：`idx_amei_content_user_type(user_id, content_type, id)`。

### `amei_content_version`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `content_id` | bigint unsigned | 内容条目 |
| `version_no` | int | 版本号 |
| `content_type` | varchar(16) | 类型快照 |
| `title` | varchar(255) | 标题快照 |
| `summary` | text | 摘要 |
| `body_format` | varchar(16) | `markdown`、`html`、`plain_text` |
| `body` | longtext | 正文快照 |
| `canonical_url` | varchar(1024) | 来源 URL |
| `tags_json` | text | 标签数组 |
| `category_hints_json` | text | 分类提示 |
| `options_json` | text | 原创、转载、可见性、商业标识 |
| `content_hash` | varchar(64) | 规范化内容 SHA-256 |
| `created_by` | bigint unsigned | 创建人 |
| `created_at` | bigint | 创建时间，创建后不可变 |

索引：`uk_amei_content_version(content_id, version_no)`、`idx_amei_content_version_hash(content_id, content_hash)`。

版本一旦被发布任务引用，不允许原地修改。修改内容必须创建新版本。

### `amei_content_media`

控制面只保存媒体引用，不保存媒体二进制。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `content_version_id` | bigint unsigned | 内容版本 |
| `asset_id` | varchar(128) | `amei-media` 资产 ID |
| `role` | varchar(32) | `primary_video`、`cover`、`inline`、`gallery`、`subtitle` |
| `mime` | varchar(128) | MIME |
| `bytes` | bigint | 字节数 |
| `width` | int | 宽，可空 |
| `height` | int | 高，可空 |
| `duration_ms` | bigint | 视频时长，可空 |
| `sha256` | varchar(64) | 内容哈希 |
| `sort_order` | int | 图片/附件排序 |
| `created_at` | bigint | 创建时间 |

索引：`idx_amei_content_media_version(content_version_id, role, sort_order)`。

## 5. 发布批次与任务

### `amei_publish_batch`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `user_id` | bigint unsigned | 用户 |
| `content_version_id` | bigint unsigned | 内容版本 |
| `content_type` | varchar(16) | 类型快照 |
| `mode` | varchar(16) | `now`、`schedule` |
| `scheduled_at` | bigint | 计划时间，0 表示立即 |
| `status` | varchar(24) | 批次派生状态 |
| `idempotency_key` | varchar(128) | 客户端幂等键 |
| `total` | int | 任务总数 |
| `published_count` | int | 已发布 |
| `pending_review_count` | int | 审核中 |
| `needs_action_count` | int | 人工处理 |
| `failed_count` | int | 失败 |
| `created_at` | bigint | 创建时间 |
| `updated_at` | bigint | 更新时间 |

索引：

- `uk_amei_batch_user_idem(user_id, idempotency_key)`；
- `idx_amei_batch_user_status(user_id, status, id)`；
- `idx_amei_batch_schedule(status, scheduled_at, id)`。

### `amei_publish_task`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `batch_id` | bigint unsigned | 批次 |
| `user_id` | bigint unsigned | 用户，冗余便于鉴权 |
| `content_version_id` | bigint unsigned | 内容版本 |
| `account_id` | bigint unsigned | 平台账号 |
| `platform_code` | varchar(32) | 平台 |
| `content_type` | varchar(16) | 类型 |
| `status` | varchar(24) | 任务状态 |
| `adapter_id` | varchar(64) | 适配器实例 |
| `adapter_task_id` | varchar(128) | 适配器任务 ID |
| `idempotency_key` | varchar(160) | 控制面内部幂等键 |
| `platform_post_id` | varchar(128) | 平台作品 ID |
| `platform_url` | varchar(1024) | 平台作品 URL |
| `status_source` | varchar(32) | `platform_api`、`manual_confirm`、`submit_accepted` |
| `platform_error_code` | varchar(64) | 平台错误码 |
| `error_code` | varchar(64) | 统一错误码 |
| `error_message` | varchar(1024) | 脱敏错误 |
| `attempts` | int | 尝试次数 |
| `next_retry_at` | bigint | 下次重试 |
| `scheduled_at` | bigint | 计划发布 |
| `published_at` | bigint | 平台确认时间 |
| `created_at` | bigint | 创建时间 |
| `updated_at` | bigint | 更新时间 |

索引：

- `uk_amei_task_batch_account(batch_id, account_id)`；
- `uk_amei_task_idem(user_id, idempotency_key)`；
- `idx_amei_task_status_retry(status, next_retry_at, id)`；
- `idx_amei_task_user_status(user_id, status, id)`。

### `amei_publish_attempt`

追加式审计表，不更新历史行。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `task_id` | bigint unsigned | 发布任务 |
| `attempt` | int | 第几次 |
| `request_id` | varchar(128) | 控制面请求 ID |
| `adapter_request_id` | varchar(128) | 适配器请求 ID |
| `status_before` | varchar(24) | 变更前 |
| `status_after` | varchar(24) | 变更后 |
| `http_status` | int | HTTP 状态 |
| `error_code` | varchar(64) | 错误码 |
| `platform_error_code` | varchar(64) | 平台错误码 |
| `latency_ms` | int | 耗时 |
| `created_at` | bigint | 创建时间 |

索引：`idx_amei_attempt_task(task_id, id)`。

### `amei_platform_post`

平台作品索引，用于数据拉取和去重。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `user_id` | bigint unsigned | 用户 |
| `account_id` | bigint unsigned | 平台账号 |
| `platform_code` | varchar(32) | 平台 |
| `platform_post_id` | varchar(128) | 平台作品 ID |
| `platform_url` | varchar(1024) | 作品 URL |
| `content_version_id` | bigint unsigned | 内容版本 |
| `publish_task_id` | bigint unsigned | 发布任务 |
| `content_type` | varchar(16) | 类型 |
| `published_at` | bigint | 平台发布时间 |
| `created_at` | bigint | 创建时间 |

索引：`uk_amei_platform_post(platform_code, account_id, platform_post_id)`、`idx_amei_post_content(content_version_id)`。

## 6. 指标

### `amei_metric_snapshot`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `user_id` | bigint unsigned | 用户 |
| `account_id` | bigint unsigned | 账号 |
| `platform_code` | varchar(32) | 平台 |
| `platform_post_id` | varchar(128) | 账号级为空字符串 |
| `content_version_id` | bigint unsigned | 内容版本，可空 |
| `stat_date` | date | 统计日期 |
| `granularity` | varchar(16) | `day`、`cumulative` |
| `impressions` | bigint | nullable |
| `plays` | bigint | nullable |
| `reads` | bigint | nullable |
| `likes` | bigint | nullable |
| `comments` | bigint | nullable |
| `shares` | bigint | nullable |
| `favorites` | bigint | nullable |
| `followers_delta` | bigint | nullable |
| `completion_rate` | decimal(8,6) | nullable |
| `avg_watch_time_ms` | bigint | nullable |
| `available_fields_json` | text | 已提供字段 |
| `source` | varchar(32) | `official_api`、`manual_csv`、`platform_export` |
| `raw_ref` | varchar(512) | 原始响应对象存储引用 |
| `pulled_at` | bigint | 拉取时间 |
| `created_at` | bigint | 创建时间 |
| `updated_at` | bigint | 更新时间 |

指标列必须允许 `NULL`，用于表达平台未提供。唯一索引：
`uk_amei_metric(account_id, stat_date, platform_post_id, granularity)`。

### `amei_metric_pull_job`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `user_id` | bigint unsigned | 用户 |
| `account_id` | bigint unsigned | 账号 |
| `platform_post_id` | varchar(128) | 可选 |
| `from_date` | date | 起始 |
| `to_date` | date | 结束 |
| `granularity` | varchar(16) | 粒度 |
| `status` | varchar(16) | `queued`、`running`、`succeeded`、`needs_action`、`failed`、`canceled` |
| `attempts` | int | 次数 |
| `next_run_at` | bigint | 下次执行 |
| `last_error` | varchar(1024) | 脱敏错误 |
| `created_at` | bigint | 创建时间 |
| `updated_at` | bigint | 更新时间 |

索引：`idx_amei_metric_job_status_next(status, next_run_at, id)`。

### `amei_metric_import`

人工补录审计：`id`、`user_id`、`account_id`、`platform_post_id`、`stat_date`、`file_name`、`row_count`、`success_count`、`failed_count`、`operator_id`、`created_at`。

## 7. 适配器注册与审计

### `amei_adapter_registry`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `adapter_id` | varchar(64) | 唯一 |
| `platform_code` | varchar(32) | 平台 |
| `base_url` | varchar(512) | 内网地址 |
| `api_mode` | varchar(16) | `official`、`community` |
| `enabled` | tinyint | 是否启用 |
| `capabilities_json` | longtext | 最近一次能力快照 |
| `last_health_at` | bigint | 最近健康检查 |
| `health_status` | varchar(16) | `healthy`、`degraded`、`down` |
| `created_at` | bigint | 创建时间 |
| `updated_at` | bigint | 更新时间 |

索引：`uk_amei_adapter_id(adapter_id)`、`idx_amei_adapter_platform(platform_code)`。

### `amei_audit_log`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | bigint unsigned | 主键 |
| `user_id` | bigint unsigned | 用户 |
| `action` | varchar(64) | 动作 |
| `subject` | varchar(64) | 对象类型 |
| `subject_id` | varchar(128) | 对象 ID |
| `detail_json` | text | 脱敏详情 |
| `request_id` | varchar(128) | 请求 ID |
| `created_at` | bigint | 创建时间 |

索引：`idx_amei_audit_user_time(user_id, created_at)`、`idx_amei_audit_subject(subject, subject_id)`。

## 8. 状态枚举

| 对象 | 状态 |
| --- | --- |
| 用户 | `active`、`disabled` |
| 平台账号 | `active`、`expired`、`needs_action`、`disabled`、`error` |
| 内容 | `draft`、`ready`、`archived` |
| 发布任务 | `queued`、`validating`、`uploading_media`、`publishing`、`pending_review`、`needs_action`、`published`、`failed`、`canceled`、`skipped` |
| 批次 | `queued`、`running`、`pending_review`、`needs_action`、`published`、`partial`、`failed`、`canceled` |
| 取数任务 | `queued`、`running`、`succeeded`、`needs_action`、`failed`、`canceled` |

## 9. 关键约束

1. 控制面不存平台凭据、cookie、浏览器 profile；
2. 内容版本创建后不可变，发布任务引用固定版本；
3. 一个批次中同一账号只能有一个任务；
4. 发布任务状态变更先写 attempt，再更新任务；
5. 指标缺失为 `NULL`，不能写 0 冒充未知；
6. 所有用户数据查询必须带 `user_id`；
7. 删除账号前检查运行中任务，解绑不级联删除审计；
8. 适配器表由管理员维护，普通用户只读能力摘要；
9. 平台额度与内部软额度分字段存储，不混用。

## 10. 数据保留

| 数据 | 保留策略 |
| --- | --- |
| 用户/平台账号 | 注销或解绑后按法规保留必要审计 |
| 内容版本 | 长期，删除为软删除 |
| 发布任务/尝试 | 至少 2 年 |
| 指标快照 | 365 天 |
| 指标原始响应 | 90 天 |
| 审计日志 | 至少 2 年 |
| OTP | 过期后 7 天清理 |

## 11. 迁移原则

- 空库首建，不迁移任何旧网页自动化或 Cookie 登录数据；
- 生产使用版本化 SQL，不依赖 ORM AutoMigrate；
- 每次迁移附回滚 SQL；
- 新字段可空或带默认值，避免大表锁；
- 指标表达到容量阈值后再评估按月分区或归档。
