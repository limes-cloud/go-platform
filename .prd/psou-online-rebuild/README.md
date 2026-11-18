# PSou 在线服务重建方案（未上线，全新重建）

> 状态：实施中
> 日期：2026-10-28
> 当前交付：基础架构、`pan_account`、`category`、`resource`、`netdisk` 已完成；其余在线模块按表逐步实现
> 明确排除：`cmd/**`、内容生成、离线批量转存/分享/分发、SEO 推送、后台 cron、`query_raw` 分表

## 实施状态

- 已完成：基础架构、`pan_account`、`category`、`resource`、`netdisk`。
- `category` 已交付管理端两级分类树 CRUD、公共端根/子分类查询、首页唯一约束、删除引用保护、
  图标对象 key 到完整 URL 的解析，以及 admin-web 与 H5 接口接入。
- `resource`、`netdisk` 已交付后端管理/公共接口、admin-web 管理页面，以及 H5、微信小程序、PC 的公共接口接入。
- 待开发：`search_transfer`、`distribute_channel`、`distribute_account`。

## 1. 现状与结论

当前有两个 PSou 代码目录，但都没有在线服务：

- `~/software/psou`：旧基线项目，后续只运行 `cmd`，不再启动在线 HTTP；
- `server/psou`：从旧项目复制后做到一半的多租户/MySQL5.7 改造，未上线，当前有 138 项未提交改动。

因此本次不是“线上新旧服务切换”，也没有灰度、并行在线路由或旧在线回切。

最终方案：

1. 备份 `server/psou`，作为在线部分的主要行为、协议和实现参考；
2. 清空 `server/psou`，重建为只承载在线请求的新服务；
3. 新服务从第一天使用 `/psou/api/*` 公共接口、`/psou/admin/*` 管理接口；
4. 不做旧 `/psou/client/*` 兼容，不做路径重写；
5. 旧项目 `~/software/psou` 不修改，部署时只执行 `cmd` 子命令，不作为在线实现的主参考；
6. 新在线服务和旧 cmd 使用两套完全独立的数据库，互不读写、互不共享表；
7. 按表逐模块实现在线路由、handler、service 和 repository；当前已完成 `pan_account`、`category`。

数据隔离是硬边界：新服务只连接新在线库，旧 cmd 只连接旧 cmd 库。
本方案不考虑旧表结构、旧数据迁移、双写、跨库查询或旧 cmd 的兼容性。

## 2. 备份

- 源目录：`server/psou`
- 备份目录：`server/psou_bak_20261028_030143`
- 备份清单：`server/psou_bak_20261028_030143_MANIFEST.txt`
- Git：`main@a20652d6f62935c9b472caae7b6a7604d3056e17`
- 未提交改动：138 项，已随目录完整保留
- 体积：238MB，890 个文件
- 校验：排除运行期 `tmp/runtime/output.log` 后，源目录与备份目录 checksum 一致
- 备份包含完整 `.git`，可在备份目录内查看历史、diff 和恢复未提交改动

旧基线 `~/software/psou` 当前有 57 项未提交改动，本次不修改该目录。
如需长期保留这些改动，建议另行备份；它不再作为在线服务源码。

清空 `server/psou` 前必须再次校验备份，校验通过后才允许重建。

## 3. 服务边界

### 3.1 新服务只负责在线 HTTP

新服务只处理：

- `/psou/api/*`：H5、微信小程序、PC 公共接口；
- `/psou/admin/*`：管理后台接口；
- 健康检查、指标、内部只读探针。

在线请求链路包含搜索、`search` 转存通路提取，以及提取后临时分享所需的状态记录。
离线固定分享、批量转存和内容分发仍由旧项目的 `cmd` 负责，不进入新在线服务。

新服务明确不包含：

- `query_source` 生成；
- `query_raw` 生成、分享、分发；
- 旧 `cmd` 的 `query_resource` 生成与离线转存任务；
- `distribute_*` 批处理；
- SEO 推送；
- 任何业务 CLI 子命令；
- 任何依赖外部 crontab 的内容生产任务。

### 3.2 旧项目只运行 cmd

`~/software/psou` 保持原样，后续部署只执行它的 `cmd` 子命令，不启动 `main.go` 的 HTTP 服务。
它是在线部分的次要参考，只在备份 `server/psou` 缺少上下文时用于核对旧行为；
cmd 的实现和行为以 `~/software/psou` 为准。

旧 cmd 使用自己的旧数据库，继续访问现有表：

`query_source`、`query_raw`、`query_resource`、`distribute_record`、
`distribute_retry_record`、`seo_push_record`。

新服务既不读取这些表，也不连接旧库。

### 3.3 两套数据库完全隔离

新在线服务与旧 cmd 各用一套数据库：

- 新服务只连接新在线库，只使用自己的建表 SQL 创建的表；
- 旧 cmd 只连接旧 cmd 库，只使用旧表；
- 不跨库查询、不共享表、不做双写、不做数据同步；
- 新服务的数据库账号只授予新库权限，不能访问旧库；
- 旧库不做结构变更，不做数据迁移，不纳入新服务建表 SQL；
- 两套库可以是同一 MySQL 实例下的不同 database，但建议使用独立实例或至少独立账号和连接池，
  避免故障、连接数和资源互相影响；
- Redis 也按独立 DB 编号或独立实例隔离，新服务 key 统一带 `psou:{app}:` 前缀；
- 对象存储建议使用独立 bucket 或独立前缀，避免与旧 cmd 的写入混用。
- 账号池、渠道账号等数据也在新库重新初始化，不自动复制旧库。

第一阶段只启用 `psou` 是产品收敛选择，不再是旧 cmd 的兼容限制。
新库的表从第一天就按 app 维度设计，后续增加租户不需要改表结构。

注意：旧 cmd 产生的数据不会自动出现在新在线库。如果以后需要把旧 cmd 数据接入新服务，
必须作为独立的数据迁移项目重新设计映射和校验，不能靠共享库解决。

### 3.4 旧代码复用边界

参考优先级：

1. **主参考**：`server/psou_bak_20261028_030143`，在线接口、DTO、proto、前端、
   搜索/提取/资源逻辑、错误码和回归用例都以它为主；
2. **次参考**：`~/software/psou`，只用于 cmd 行为，以及备份中缺少上下文时的旧在线行为核对；
3. 备份里有 138 项未完成改动，不能当作已验证实现；
   多租户、MySQL5.7、路由和表结构相关改动都要逐项确认后再用。

可以作为参考，但必须逐项评审后重写接入：

- 对外 HTTP 路径与请求/响应字段；
- `api/**/proto` 中的协议定义（重新生成，不直接拷贝生成物）；
- 在线表的表结构与索引（重新编写建表 SQL，不拷贝旧 `data.sql`）；
- 前端 H5 / 小程序 / PC 页面与接口封装；
- pansou、百度、夸克适配器中的协议细节和踩坑逻辑；
- 旧服务的回归用例、错误码和边界条件。

路径映射只作为行为参考，不作为兼容层：

- 备份中的 `/psou/client/*` → 新服务 `/psou/api/*`；
- 备份中的管理 `/psou/api/*` → 新服务 `/psou/admin/*`。

不进入新服务：

- 旧 `internal/domain`、`internal/infra` 中的实现不整体复用，只按新分层重写对应能力；
- 带全局 DB/Redis 单例的仓储实现；
- 启动时自动执行 SQL 初始化；
- `AdminIntranetOnly`；
- 任何 `cmd` 子命令和内容生产代码；
- `query_raw` 分表相关逻辑。

### 3.5 运行形态

- 新在线服务：只部署 `server/psou` 构建出的二进制，HTTP 监听内网 `:7301`，gRPC 监听内网 `:7302`；
- 旧 cmd：使用 `~/software/psou` 构建的二进制，按需执行子命令，不监听 HTTP；
- 新服务只连新在线库，旧 cmd 只连旧库，两者数据库配置不共享；
- 旧 `server/psou` 的代码和配置只保留在备份中，不再部署；
- 不再保留 `:7030` 的在线旧服务，也不保留旧在线回切入口；
- 回滚指回滚新服务镜像，不是回到旧在线服务。

## 4. 目标架构

### 4.1 形态

采用 **单体在线服务**：

- 一个在线服务进程；
- 公共端和管理端在同一代码库、同一二进制；
- 通过路由前缀和中间件隔离权限。

第一阶段不建议直接拆微服务。当前业务量、数据耦合和团队维护成本不支持过早拆分。

### 4.2 技术栈

沿用 go-platform 现有底座：

- Go 1.25+
- Kratos v2
- kratosx v1.3.3+
- GORM
- MySQL 5.7+
- Redis
- protobuf + HTTP annotations
- resource 服务作为对象存储 URL 解析依赖

不引入新的 Web 框架、ORM 或 RPC 框架。

### 4.3 部署拓扑

```text
[静态资源]
浏览器 / H5 / 小程序 / 管理后台
              |
              v
        CDN / Nginx  ---> H5 / PC / admin-web 静态产物


[公共 API]
H5 / 小程序 / PC
              |
              v
  https://<公共 app 域名>/psou/api/*
              |
              v
  Nginx / LB（公共 app 域名，TLS，保留 Host）
              |
              v
  gateway :7200  /psou/api/* 公开路由，不要求 manager token
              |
              v
  psou :7301  ---> 按 Host 向 manager 解析 app


[管理 API]
admin-web
              |
              v
  https://gw.qlime.cn/psou/admin/*
              |
              v
  gateway :7200  /psou/admin/* 管理路由，要求 manager 鉴权
          |             |
          |             v
          |        psou :7301
          v
   manager :7202


[psou 依赖]
psou :7301
  |-- MySQL：新在线库
  |-- Redis：新实例或独立 DB
  |-- resource gRPC :8203
  |-- pansou / 百度 / 夸克等外部 API


[鉴权]
gateway :7200 --HTTP--> manager :7202  /manager/api/authorize/check
psou :7301    --gRPC--> manager :8202  ParseToken（内网兜底/调试）


[旧 cmd]
~/software/psou cmd
  |-- MySQL：旧 cmd 库
  |-- Redis：旧实例或独立 DB
  |-- 外部平台
```

关键点：

- H5、小程序、PC、管理后台的 API 全部经过 `gw`，不再由 Nginx 直连 psou；
- 公共 API 必须通过租户自己的公共域名访问，不能直接使用 `gw.qlime.cn`；
  否则 psou 看到的是网关域名，无法按 Host 解析 app；
- 微信小程序的合法域名应配置公共 app 域名，不配置 `gw.qlime.cn`；
- 静态资源走 CDN/Nginx，API 服务不负责前端构建产物；
- 公共站点域名、管理静态域名、gateway 域名必须使用不同的 `server_name`；
- Nginx 转发到 gateway、gateway 转发到 psou 都必须保留原始 `Host`，
  不能配置 `hostRewrite`，否则 psou 无法按域名解析 app；
- gateway 的 `/psou/api/*` 必须放在公开路由组，不挂 manager token 校验；
- gateway 的 `/psou/admin/*` 必须挂 manager 鉴权，并保留原始路径，不做前缀重写；
- psou 只对内网暴露 `:7301`（HTTP）和 `:7302`（gRPC），不对公网开放；
- resource 是内部 gRPC 依赖，pansou/百度/夸克是外部 HTTP 依赖，二者不要混在同一层；
- 旧 cmd 不监听 HTTP，且不连接新在线库、新 Redis。

## 5. 数据库设计

### 5.1 约定

- 新在线库独立部署，MySQL 5.7+，`utf8mb4_unicode_ci`，`ROW_FORMAT=DYNAMIC`。
- 所有业务表必须有 `app`，唯一键和主要索引以 `app` 开头。
- `app` 主数据在 manager：`manager.app.keyword` 是唯一租户标识，psou 不复制 `app` 表。
- 公共域名解析依赖 manager 的通用应用域名能力；该能力另行独立改造，本方案不包含 manager 侧表、接口和缓存变更。
- psou 不保留 `app`、`app_domain` 表；应用名称、状态、JWT、权限、域名均以 manager 为准。
- 公共端解析链路：Host 归一化 → psou 本地缓存 → miss 时调用 manager 解析 → 校验 app `status=1` → 写入 app context。
- 管理端直接使用 manager 鉴权结果中的 app，不再查本地 app 表。
- psou 本地解析缓存 TTL 建议 60s；manager 不可用时拒绝新的域名解析。
- PSou 在 manager 中应创建为 `type=app` 的业务应用，不使用 `type=base`。
- 不使用外键；关联只在应用层保证。
- 时间统一使用 `bigint` Unix 秒。
- 本节只给全局 DDL、索引和初始化数据；字段语义、状态机、容量和查询模式后续按表单独说明。

### 5.2 表清单

| 表 | 用途 |
| --- | --- |
| `category` | 分类树 |
| `resource` | 资源主档 |
| `netdisk` | 资源网盘副本 |
| `pan_account` | 网盘账号池 |
| `distribute_channel` | 内容分发渠道字典（预留，在线 v1 不读写） |
| `distribute_account` | 内容分发渠道账号（预留，在线 v1 不读写） |
| `search_transfer` | 在线提取记录 |

### 5.3 初始化 SQL

```sql
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `category` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app` varchar(32) NOT NULL COMMENT '应用',
  `parent_id` bigint unsigned NOT NULL DEFAULT '0' COMMENT '父分类ID',
  `name` varchar(64) NOT NULL COMMENT '分类名称',
  `icon` varchar(512) NOT NULL DEFAULT '' COMMENT '图标',
  `status` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '状态',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `is_home` tinyint(1) NOT NULL DEFAULT '0' COMMENT '首页',
  `created_at` bigint NOT NULL COMMENT '创建时间',
  `updated_at` bigint NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_parent_name` (`app`, `parent_id`, `name`),
  KEY `idx_app_parent_status_sort` (`app`, `parent_id`, `status`, `sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='分类树';

CREATE TABLE IF NOT EXISTS `resource` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app` varchar(32) NOT NULL COMMENT '应用',
  `title` varchar(255) NOT NULL COMMENT '标题',
  `title_md5` char(32) NOT NULL COMMENT '标题MD5',
  `summary` varchar(512) NOT NULL COMMENT '摘要',
  `description` text NOT NULL COMMENT '描述',
  `category_id` bigint unsigned NOT NULL COMMENT '分类ID',
  `tags` text NOT NULL COMMENT '标签',
  `score` decimal(3,1) NOT NULL COMMENT '评分',
  `cover` varchar(512) NOT NULL COMMENT '封面',
  `view_count` bigint unsigned NOT NULL DEFAULT '0' COMMENT '浏览量',
  `click_count` bigint unsigned NOT NULL DEFAULT '0' COMMENT '点击次数',
  `weight` int NOT NULL DEFAULT '0' COMMENT '权重',
  `is_banner` tinyint(1) NOT NULL DEFAULT '0' COMMENT '轮播',
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '状态',
  `source` varchar(32) NOT NULL DEFAULT 'system' COMMENT '来源',
  `ext` text COMMENT '扩展',
  `created_at` bigint NOT NULL COMMENT '创建时间',
  `updated_at` bigint NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_title_category` (`app`, `title_md5`, `category_id`),
  KEY `idx_app_category_created` (`app`, `category_id`, `status`, `created_at`),
  KEY `idx_app_category_updated` (`app`, `category_id`, `status`, `updated_at`, `id`),
  KEY `idx_app_category_score` (`app`, `category_id`, `status`, `score`),
  KEY `idx_app_category_view` (`app`, `category_id`, `status`, `view_count`),
  KEY `idx_app_category_home` (`app`, `category_id`, `status`, `weight`, `score`),
  KEY `idx_app_banner` (`app`, `is_banner`, `status`),
  KEY `idx_app_status_created` (`app`, `status`, `created_at`),
  KEY `idx_app_source` (`app`, `source`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='资源主档';

CREATE TABLE IF NOT EXISTS `netdisk` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app` varchar(32) NOT NULL COMMENT '应用',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `account_id` bigint unsigned NOT NULL COMMENT '账号ID',
  `fs_id` varchar(128) NOT NULL COMMENT '文件ID',
  `resource_id` bigint unsigned NOT NULL COMMENT '资源ID',
  `platform` varchar(16) NOT NULL COMMENT '平台',
  `share_url` varchar(512) NOT NULL COMMENT '分享链接',
  `from_url` varchar(512) NOT NULL COMMENT '来源链接',
  `size` bigint unsigned NOT NULL COMMENT '大小',
  `format_summary` varchar(64) NOT NULL DEFAULT '' COMMENT '格式摘要',
  `file_count` int unsigned NOT NULL DEFAULT '0' COMMENT '文件数',
  `status` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '状态',
  `last_checked_at` bigint NOT NULL DEFAULT '0' COMMENT '最近检测时间',
  `ext` text COMMENT '扩展',
  `created_at` bigint NOT NULL COMMENT '创建时间',
  `updated_at` bigint NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_resource_platform` (`app`, `resource_id`, `platform`),
  KEY `idx_app_platform_status` (`app`, `platform`, `status`),
  KEY `idx_app_user` (`app`, `user_id`),
  KEY `idx_app_account` (`app`, `account_id`),
  KEY `idx_app_check_queue` (`app`, `status`, `last_checked_at`),
  KEY `idx_app_share_url` (`app`, `share_url`(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='资源网盘副本';

CREATE TABLE IF NOT EXISTS `pan_account` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app` varchar(32) NOT NULL COMMENT '应用',
  `platform` varchar(32) NOT NULL COMMENT '平台',
  `name` varchar(128) NOT NULL COMMENT '账号名称',
  `user_id` bigint unsigned DEFAULT NULL COMMENT '平台用户ID',
  `token` text NOT NULL COMMENT '凭证',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态',
  `priority` int NOT NULL DEFAULT '0' COMMENT '优先级',
  `error_code` varchar(64) DEFAULT NULL COMMENT '错误码',
  `storage_total` bigint unsigned DEFAULT NULL COMMENT '总容量',
  `storage_used` bigint unsigned DEFAULT NULL COMMENT '已用容量',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `ext` text COMMENT '扩展',
  `created_at` bigint NOT NULL COMMENT '创建时间',
  `updated_at` bigint NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_platform_user` (`app`, `platform`, `user_id`),
  KEY `idx_app_platform_user` (`app`, `platform`, `user_id`),
  KEY `idx_app_platform_status_priority` (`app`, `platform`, `status`, `priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='网盘账号池';

CREATE TABLE IF NOT EXISTS `distribute_channel` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app` varchar(32) NOT NULL COMMENT '应用',
  `code` varchar(32) NOT NULL COMMENT '渠道编码',
  `name` varchar(64) NOT NULL COMMENT '渠道名称',
  `status` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '状态',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `ext` text COMMENT '扩展',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_at` bigint NOT NULL COMMENT '创建时间',
  `updated_at` bigint NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_code` (`app`, `code`),
  KEY `idx_app_status_sort` (`app`, `status`, `sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='分发渠道';

CREATE TABLE IF NOT EXISTS `distribute_account` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app` varchar(32) NOT NULL COMMENT '应用',
  `channel_code` varchar(32) NOT NULL COMMENT '渠道编码',
  `pan_account_id` bigint unsigned DEFAULT NULL COMMENT '网盘账号ID',
  `name` varchar(128) NOT NULL DEFAULT '' COMMENT '账号名称',
  `uid` varchar(128) DEFAULT NULL COMMENT '渠道用户ID',
  `token` text COMMENT '渠道凭证',
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '状态',
  `reason` varchar(512) DEFAULT NULL COMMENT '原因',
  `priority` int NOT NULL DEFAULT '0' COMMENT '优先级',
  `error_code` varchar(64) DEFAULT NULL COMMENT '错误码',
  `quota` int unsigned DEFAULT NULL COMMENT '额度',
  `used_quota` bigint unsigned DEFAULT NULL COMMENT '已用额度',
  `ext` text COMMENT '扩展',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_at` bigint NOT NULL COMMENT '创建时间',
  `updated_at` bigint NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_channel_pan_account` (`app`, `channel_code`, `pan_account_id`),
  UNIQUE KEY `uk_app_channel_uid` (`app`, `channel_code`, `uid`),
  KEY `idx_app_channel_status_priority` (`app`, `channel_code`, `status`, `priority`),
  KEY `idx_app_pan_account` (`app`, `pan_account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='分发渠道账号';

CREATE TABLE IF NOT EXISTS `search_transfer` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app` varchar(32) NOT NULL COMMENT '应用',
  `account_id` bigint unsigned NOT NULL COMMENT '账号ID',
  `keyword` varchar(128) NOT NULL COMMENT '关键词',
  `client_ip` varchar(64) NOT NULL COMMENT '来源IP',
  `from_url` varchar(255) NOT NULL COMMENT '来源链接',
  `fs_id` varchar(128) NOT NULL COMMENT '文件ID',
  `share_url` varchar(512) NOT NULL DEFAULT '' COMMENT '分享链接',
  `expires_at` bigint NOT NULL COMMENT '过期时间',
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '状态',
  `cleanup_fail_count` int unsigned NOT NULL DEFAULT '0' COMMENT '清理失败次数',
  `fail_reason` varchar(512) NOT NULL DEFAULT '' COMMENT '失败原因',
  `created_at` bigint NOT NULL COMMENT '创建时间',
  `updated_at` bigint NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_app_from_url` (`app`, `from_url`, `id`),
  KEY `idx_app_status_expires` (`app`, `status`, `expires_at`),
  KEY `idx_app_account` (`app`, `account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='在线提取记录';

INSERT INTO `distribute_channel` (`app`, `code`, `name`, `status`, `sort`, `created_at`, `updated_at`)
VALUES ('psou', 'zhidao', '百度知道', 1, 10, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);
```

### 5.4 表字段说明

- `app` 统一对应 `manager.app.keyword`。
- `created_at`、`updated_at` 以及业务时间字段均为 Unix 秒。
- `ext` 为 TEXT 扩展字段，数据库存 JSON 文本，实体使用 `*XxxExt` 和 `serializer:json` 映射。

#### `category`

| 字段 | 类型 | 可空 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `id` | bigint unsigned | 否 | 自增 | 主键 |
| `app` | varchar(32) | 否 | - | 应用标识 |
| `parent_id` | bigint unsigned | 否 | 0 | 父分类 ID，0 表示根分类 |
| `name` | varchar(64) | 否 | - | 分类名称 |
| `icon` | varchar(512) | 否 | 空字符串 | 图标 key 或 URL |
| `sort` | int | 否 | 0 | 排序值，越小越靠前 |
| `status` | tinyint unsigned | 否 | 1 | 0 隐藏，1 展示 |
| `is_home` | tinyint(1) | 否 | 0 | 0 非首页分类，1 首页分类 |
| `created_at` | bigint | 否 | - | 创建时间 |
| `updated_at` | bigint | 否 | - | 更新时间 |

#### `resource`

| 字段 | 类型 | 可空 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `id` | bigint unsigned | 否 | 自增 | 主键 |
| `app` | varchar(32) | 否 | - | 应用标识 |
| `title` | varchar(255) | 否 | - | 标题 |
| `title_md5` | char(32) | 否 | - | 标题 MD5，用于幂等唯一键 |
| `summary` | varchar(512) | 否 | - | 摘要 |
| `description` | text | 否 | - | 详情 |
| `category_id` | bigint unsigned | 否 | - | 分类 ID |
| `tags` | text | 否 | - | 标签数组，以 JSON 字符串存储 |
| `score` | decimal(3,1) | 否 | - | 评分，保留 1 位小数 |
| `cover` | varchar(512) | 否 | - | 封面地址 |
| `view_count` | bigint unsigned | 否 | 0 | 浏览量 |
| `click_count` | bigint unsigned | 否 | 0 | 点击次数 |
| `weight` | int | 否 | 0 | 排序权重 |
| `is_banner` | tinyint(1) | 否 | 0 | 0 非轮播，1 轮播 |
| `status` | tinyint unsigned | 否 | 0 | 0 下架，1 上架 |
| `source` | varchar(32) | 否 | system | 来源标识 |
| `ext` | text | 是 | NULL | 扩展字段，以 JSON 字符串存储 |
| `created_at` | bigint | 否 | - | 创建时间 |
| `updated_at` | bigint | 否 | - | 更新时间 |

#### `netdisk`

| 字段 | 类型 | 可空 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `id` | bigint unsigned | 否 | 自增 | 主键 |
| `app` | varchar(32) | 否 | - | 应用标识 |
| `user_id` | bigint unsigned | 否 | - | 上传用户 ID |
| `account_id` | bigint unsigned | 否 | - | 保存副本的网盘账号 ID |
| `fs_id` | varchar(128) | 否 | - | 平台文件 ID |
| `resource_id` | bigint unsigned | 否 | - | 资源 ID |
| `platform` | varchar(16) | 否 | - | 网盘平台标识 |
| `share_url` | varchar(512) | 否 | - | 分享链接 |
| `from_url` | varchar(512) | 否 | - | 来源链接 |
| `size` | bigint unsigned | 否 | - | 文件大小，单位字节 |
| `format_summary` | varchar(64) | 否 | 空字符串 | 格式摘要，多个格式用 `/` 分隔 |
| `file_count` | int unsigned | 否 | 0 | 文件数量 |
| `status` | tinyint unsigned | 否 | 1 | 0 失效，1 正常 |
| `last_checked_at` | bigint | 否 | 0 | 最近检测时间，0 表示未检测 |
| `ext` | text | 是 | NULL | 扩展字段，以 JSON 字符串存储 |
| `created_at` | bigint | 否 | - | 创建时间 |
| `updated_at` | bigint | 否 | - | 更新时间 |

#### `pan_account`

| 字段 | 类型 | 可空 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `id` | bigint unsigned | 否 | 自增 | 主键 |
| `app` | varchar(32) | 否 | - | 应用标识 |
| `platform` | varchar(32) | 否 | - | 网盘平台标识 |
| `name` | varchar(128) | 否 | - | 账号展示名称 |
| `user_id` | bigint unsigned | 是 | NULL | 平台用户 ID，相同应用与平台内非空值唯一 |
| `token` | text | 否 | - | 平台凭证，不对外返回 |
| `status` | tinyint | 否 | 1 | -1 失效，0 停用，1 正常 |
| `priority` | int | 否 | 0 | 调度优先级，数值越大越优先 |
| `error_code` | varchar(64) | 是 | NULL | 最近一次平台错误码 |
| `storage_total` | bigint unsigned | 是 | NULL | 总容量，单位字节 |
| `storage_used` | bigint unsigned | 是 | NULL | 已用容量，单位字节 |
| `remark` | varchar(255) | 是 | NULL | 备注 |
| `ext` | text | 是 | NULL | 扩展字段，以 JSON 字符串存储 |
| `created_at` | bigint | 否 | - | 创建时间 |
| `updated_at` | bigint | 否 | - | 更新时间 |

#### `distribute_channel`

| 字段 | 类型 | 可空 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `id` | bigint unsigned | 否 | 自增 | 主键 |
| `app` | varchar(32) | 否 | - | 应用标识 |
| `code` | varchar(32) | 否 | - | 渠道编码 |
| `name` | varchar(64) | 否 | - | 渠道名称 |
| `status` | tinyint unsigned | 否 | 1 | 0 停用，1 启用 |
| `sort` | int | 否 | 0 | 展示排序，越小越靠前 |
| `ext` | text | 是 | NULL | 扩展字段，以 JSON 字符串存储 |
| `remark` | varchar(255) | 是 | NULL | 备注 |
| `created_at` | bigint | 否 | - | 创建时间 |
| `updated_at` | bigint | 否 | - | 更新时间 |

#### `distribute_account`

| 字段 | 类型 | 可空 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `id` | bigint unsigned | 否 | 自增 | 主键 |
| `app` | varchar(32) | 否 | - | 应用标识 |
| `channel_code` | varchar(32) | 否 | - | 渠道编码，关联 `distribute_channel.code` |
| `pan_account_id` | bigint unsigned | 是 | NULL | 复用网盘账号时关联 `pan_account.id`，独立账号为 NULL |
| `name` | varchar(128) | 否 | 空字符串 | 账号名称 |
| `uid` | varchar(128) | 是 | NULL | 渠道用户 ID，独立账号用于去重 |
| `token` | text | 是 | NULL | 独立渠道凭证，不对外返回 |
| `status` | tinyint unsigned | 否 | 0 | 0 正常，1 失效，2 冻结，3 停用，4 限流，5 无权限，6 封禁 |
| `reason` | varchar(512) | 是 | NULL | 暂停原因，正常时为 NULL |
| `priority` | int | 否 | 0 | 渠道内调度优先级，数值越大越优先 |
| `error_code` | varchar(64) | 是 | NULL | 最近一次平台错误码 |
| `quota` | int unsigned | 是 | NULL | 额度上限，NULL 表示不限 |
| `used_quota` | bigint unsigned | 是 | NULL | 平台返回的已用额度，NULL 表示未获取 |
| `ext` | text | 是 | NULL | 扩展字段，以 JSON 字符串存储 |
| `remark` | varchar(255) | 是 | NULL | 备注 |
| `created_at` | bigint | 否 | - | 创建时间 |
| `updated_at` | bigint | 否 | - | 更新时间 |

#### `search_transfer`

`search_transfer` 只承载在线搜索提取，固定属于 `search` 转存通路，因此不增加
`channel_code` 或 `transfer_route` 字段，也不参与内容分发渠道路由。

| 字段 | 类型 | 可空 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `id` | bigint unsigned | 否 | 自增 | 主键 |
| `app` | varchar(32) | 否 | - | 应用标识 |
| `account_id` | bigint unsigned | 否 | - | 执行转存的网盘账号 ID |
| `keyword` | varchar(128) | 否 | - | 触发转存的搜索关键词 |
| `client_ip` | varchar(64) | 否 | - | 请求来源 IP |
| `from_url` | varchar(255) | 否 | - | 来源链接 |
| `fs_id` | varchar(128) | 否 | - | 临时容器平台引用 |
| `share_url` | varchar(512) | 否 | 空字符串 | 转存后生成的分享链接 |
| `expires_at` | bigint | 否 | - | 0 处理截止，1 分享过期，4 清理触发 |
| `status` | tinyint unsigned | 否 | 0 | 0 转存中，1 已分享，2 清理放弃，3 已清理，4 失败 |
| `cleanup_fail_count` | int unsigned | 否 | 0 | 清理失败累计次数 |
| `fail_reason` | varchar(512) | 否 | 空字符串 | 失败原因，失败状态下使用 |
| `created_at` | bigint | 否 | - | 创建时间 |
| `updated_at` | bigint | 否 | - | 更新时间 |

### 5.5 Go 实体结构

> 本节定义目标实体结构。已实现模块以 `server/psou/internal/domain/entity` 中的实际代码为准，
> 尚未实现的模块在开发时按本节结构落地。

公共字段统一嵌入 `model.BaseModel` 并放在结构体最后。
字段是否使用指针取决于合法值是否可能为 Go 零值，与数据库列是否可空无关：

- 合法值包含 `0`、`""`、`false` 的字段使用指针，保证 `Updates(struct)` 能表达“显式设为默认值”；
- 数据库 `NOT NULL DEFAULT` 字段仍可使用指针，例如 `Status *uint8`、`Sort *int32`、`IsHome *bool`；
- 创建记录时由 service 显式填充必填的默认值，不能依赖 GORM 对 nil 指针自动套用数据库默认值；
- 必填且永不等于 Go 零值的字段使用值类型，例如名称、标题、URL。

`Category.ParentId`、`Category.Icon`、`Resource.Summary`、`Resource.Description`、
`Resource.Tags`、`Resource.Score`、`Resource.Cover` 为必填字段，使用值类型。
`Netdisk.UserId`、`Netdisk.AccountId`、`Netdisk.FsId`、`Netdisk.FromUrl`、`Netdisk.Size` 为必填字段，使用值类型。
`PanAccount.Name` 为必填字段，使用值类型。
`SearchTransfer.Keyword`、`SearchTransfer.ClientIP`、`SearchTransfer.FsId` 为必填字段，使用值类型。

| 表 | 实体 | EXT 类型 |
| --- | --- | --- |
| `category` | `Category` | 无 |
| `resource` | `Resource` | `ResourceExt` |
| `netdisk` | `Netdisk` | `NetdiskExt` |
| `pan_account` | `PanAccount` | `AccountExt` |
| `distribute_channel` | `DistributeChannel` | `DistributeChannelExt` |
| `distribute_account` | `DistributeAccount` | `DistributeAccountExt` |
| `search_transfer` | `SearchTransfer` | 无 |

所有 `ext` 列保持 `text`，实体字段使用 `*XxxExt`，通过 GORM 的 `serializer:json` 自动序列化和反序列化。
不再使用 `*string`、`decodeExt`、`encodeExt` 或 `GetExt`、`SetExt` 做手工转换。

```go
Ext *NetdiskExt `json:"ext" gorm:"column:ext;serializer:json"`
```

使用指针可以保留数据库 `NULL` 语义，并避免在部分字段更新时写入空 JSON 对象。
`ext` 按整体 JSON 更新；并发修改其中的计数（例如 `dailyTransfers`、`dailyShares`）时，repository 层必须使用行锁或 SQL 原子更新。

#### `Category`

```go
type Category struct {
	App      string      `json:"app"      gorm:"column:app"`
	ParentId uint32      `json:"parentId" gorm:"column:parent_id"` // 必填；0=一级分类
	Name     string      `json:"name"     gorm:"column:name"`
	Icon     string      `json:"icon"     gorm:"column:icon"`     // 必填；图标 key 或 URL
	Sort     *int32      `json:"sort"     gorm:"column:sort"`     // 越小越靠前
	Status   *uint8      `json:"status"   gorm:"column:status"`   // 0隐藏 1展示
	IsHome   *bool       `json:"isHome"   gorm:"column:is_home"`  // false否 true是
	Children []*Category `json:"children" gorm:"-"`
	model.BaseModel
}

func (Category) TableName() string { return "category" }
```

#### `Resource`

```go
type Resource struct {
	App         string       `json:"app"         gorm:"column:app"`
	Title       string       `json:"title"       gorm:"column:title"`
	TitleMd5    string       `json:"-"           gorm:"column:title_md5"`
	Summary     string       `json:"summary"     gorm:"column:summary"`
	Description string       `json:"description" gorm:"column:description"`
	CategoryId  uint32       `json:"categoryId"  gorm:"column:category_id"`
	Tags        []string     `json:"tags"        gorm:"column:tags;serializer:json"`
	Score       float64      `json:"score"       gorm:"column:score"`
	Cover       string       `json:"cover"       gorm:"column:cover"`
	ViewCount   uint64       `json:"viewCount"   gorm:"column:view_count"`
	ClickCount  uint64       `json:"clickCount"  gorm:"column:click_count"`
	Weight      *int32       `json:"weight"      gorm:"column:weight"`    // 越大越靠前
	IsBanner    *bool        `json:"isBanner"    gorm:"column:is_banner"` // false否 true是
	Status      *uint8       `json:"status"      gorm:"column:status"`    // 0下架 1上架
	Source      string       `json:"source"      gorm:"column:source"`
	Ext         *ResourceExt `json:"ext"         gorm:"column:ext;serializer:json"`
	model.BaseModel
}

func (Resource) TableName() string { return "resource" }

type ResourceExt struct{}
```

#### `Netdisk`

```go
type Netdisk struct {
	App            string      `json:"app"            gorm:"column:app"`
	UserId         int64       `json:"userId"         gorm:"column:user_id"`         // 必填
	AccountId      uint32      `json:"accountId"      gorm:"column:account_id"`      // 必填
	FsId           string      `json:"fsId"           gorm:"column:fs_id"`           // 必填
	ResourceId     uint32      `json:"resourceId"     gorm:"column:resource_id"`
	Platform       string      `json:"platform"       gorm:"column:platform"`
	ShareUrl       string      `json:"shareUrl"       gorm:"column:share_url"`
	FromUrl        string      `json:"fromUrl"        gorm:"column:from_url"` // 必填
	Size           int64       `json:"size"           gorm:"column:size"`     // 必填；字节
	FormatSummary  *string     `json:"formatSummary"  gorm:"column:format_summary"` // 空=无
	FileCount      *uint32     `json:"fileCount"      gorm:"column:file_count"`
	Status         *uint8      `json:"status"         gorm:"column:status"`          // 0失效 1正常
	LastCheckedAt  *int64      `json:"lastCheckedAt"  gorm:"column:last_checked_at"` // 0=未检测
	Ext            *NetdiskExt `json:"ext"            gorm:"column:ext;serializer:json"`
	model.BaseModel
}

func (Netdisk) TableName() string { return "netdisk" }

type NetdiskExt struct {
	Files []*NetdiskFile `json:"files,omitempty"`
}

type NetdiskFile struct {
	Name     string         `json:"name"`
	Path     string         `json:"path"`
	IsDir    bool           `json:"isDir"`
	Size     int64          `json:"size"`
	Children []*NetdiskFile `json:"children,omitempty"`
}
```

`NetdiskExt.Files` 为根节点列表；目录节点通过 `Children` 递归展开，文件节点的 `Children` 为空。

#### `PanAccount`

```go
type PanAccount struct {
	App          string      `json:"app"          gorm:"column:app"`
	Platform     string      `json:"platform"     gorm:"column:platform"`
	Name         string      `json:"name"         gorm:"column:name"` // 必填
	UserId       *uint64     `json:"userId"       gorm:"column:user_id"`
	Token        string      `json:"-"            gorm:"column:token"`
	Status       *int8       `json:"status"       gorm:"column:status"`   // -1失效 0停用 1正常
	Priority     *int32      `json:"priority"     gorm:"column:priority"` // 越大越优先
	ErrorCode    *string     `json:"errorCode"    gorm:"column:error_code"`
	StorageTotal *uint64     `json:"storageTotal" gorm:"column:storage_total"` // 总容量，字节
	StorageUsed  *uint64     `json:"storageUsed"  gorm:"column:storage_used"`  // 已用容量，字节
	Remark       *string     `json:"remark"       gorm:"column:remark"`
	Ext          *AccountExt `json:"ext"          gorm:"column:ext;serializer:json"`
	model.BaseModel
}

func (PanAccount) TableName() string { return "pan_account" }

type TransferRoute string

const (
	TransferRouteFixed    TransferRoute = "fixed"          // 固定分享文件的批量转存
	TransferRouteTransfer TransferRoute = "transfer"       // 内容生产链路转存
	TransferRouteSearch   TransferRoute = "search"         // 在线搜索提取转存
	TransferRouteManual   TransferRoute = "manual"         // 分类资源手动转存
)

type AccountExt struct {
	LastCheckAt    *int64                       `json:"lastCheckAt,omitempty"`    // 最近检测时间
	LimitedAt      *int64                       `json:"limitedAt,omitempty"`      // 最近限流时间
	LimitOp        *string                      `json:"limitOp,omitempty"`        // 限流触发来源，由触发方写入
	TransferDirs   map[TransferRoute]*TransferDirRef `json:"transferDirs,omitempty"` // 按转存通路配置的转存目录
	DailyTransfers map[TransferRoute]*DailyStat `json:"dailyTransfers,omitempty"` // 按转存通路统计转存次数及上限
	DailyShares    map[TransferRoute]*DailyStat `json:"dailyShares,omitempty"`    // 按转存通路统计分享次数及上限
}

type TransferDirRef struct {
	Path string `json:"path"`           // 转存目录路径
	FsID string `json:"fsId,omitempty"` // 百度 fs_id / 夸克 fid
}

type DailyStat struct {
	Date  string `json:"date"`  // YYYY-MM-DD
	Count int32  `json:"count"` // 当日次数
	Limit int32  `json:"limit"` // 每日上限，<=0 表示不限
}
```

`AccountExt` 只保留网盘账号的转存通路配置、每日额度和探测状态；内容生产与分发账号配置不进入该结构。

`fixed`、`transfer`、`search`、`manual` 是转存通路，不是内容分发渠道，与 `distribute_channel` 没有关联：

- 在线搜索提取只读取 `TransferDirs[TransferRouteSearch]`、`DailyTransfers[TransferRouteSearch]` 和 `DailyShares[TransferRouteSearch]`；
- `manual` 只用于分类资源的人工触发转存，不进入自动调度；读取 `TransferDirs[TransferRouteManual]`、`DailyTransfers[TransferRouteManual]` 和 `DailyShares[TransferRouteManual]`；
- 未配置对应通路的目录时，由平台适配器回退到默认根目录；账号创建、目录配置变化或登录态更新时解析并创建目录，路径不得包含 `..`；
- `TransferDirRef.Path` 用于展示、日志和失效恢复；`FsID` 保存百度 `fs_id` 或夸克 `fid`，供转存、分享、删除直接使用，避免重复按路径查询；
- 目录初始化失败时账号创建或更新必须失败，不得落库未完成初始化的账号；旧版仅保存路径字符串的 `ext` 数据需兼容读取；
- 执行前按对应 Map 的 `Count >= Limit` 判断是否达到上限；Map 无该通路或 `Limit <= 0` 表示不限；
- 操作成功后 `Count` 加 1；跨日时将 `Date` 更新为当天、`Count` 重置为 1，保留 `Limit`；
- 并发更新必须使用行锁或原子更新，避免次数或上限被覆盖。

#### `DistributeChannel`

```go
type DistributeChannel struct {
	App    string                `json:"app"    gorm:"column:app"`
	Code   string                `json:"code"   gorm:"column:code"`
	Name   string                `json:"name"   gorm:"column:name"`   // 必填
	Status *uint8                `json:"status" gorm:"column:status"` // 0停用 1启用
	Sort   *int32                `json:"sort"   gorm:"column:sort"`   // 越小越靠前
	Ext    *DistributeChannelExt `json:"ext"    gorm:"column:ext;serializer:json"`
	Remark *string               `json:"remark" gorm:"column:remark"`
	model.BaseModel
}

func (DistributeChannel) TableName() string { return "distribute_channel" }

type DistributeChannelExt struct{}
```

#### `DistributeAccount`

```go
type DistributeAccount struct {
	App          string                `json:"app"          gorm:"column:app"`
	ChannelCode  string                `json:"channelCode"  gorm:"column:channel_code"`
	PanAccountId *uint32               `json:"panAccountId" gorm:"column:pan_account_id"` // NULL=独立账号
	Name         *string               `json:"name"         gorm:"column:name"`
	Uid          *string               `json:"uid"          gorm:"column:uid"`
	Token        *string               `json:"-"            gorm:"column:token"`
	Status       *uint8                `json:"status"       gorm:"column:status"` // 0正常 1失效 2冻结 3停用 4限流 5无权限 6封禁
	Reason       *string               `json:"reason"       gorm:"column:reason"`
	Priority     *int32                `json:"priority"     gorm:"column:priority"`
	ErrorCode    *string               `json:"errorCode"    gorm:"column:error_code"`
	Quota        *uint32               `json:"quota"        gorm:"column:quota"` // NULL=不限
	UsedQuota    *int64                `json:"usedQuota"    gorm:"column:used_quota"`
	Ext          *DistributeAccountExt `json:"ext"          gorm:"column:ext;serializer:json"`
	Remark       *string               `json:"remark"       gorm:"column:remark"`
	model.BaseModel
}

func (DistributeAccount) TableName() string { return "distribute_account" }

type DistributeAccountExt struct {
	LastCheckAt *int64 `json:"lastCheckAt,omitempty"` // 最近检测时间
	LimitedAt   *int64 `json:"limitedAt,omitempty"`   // 最近限流时间
	BanDays     *int32 `json:"banDays,omitempty"`     // 封禁剩余天数
}
```

#### `SearchTransfer`

```go
type SearchTransfer struct {
	App              string  `json:"app"              gorm:"column:app"`
	AccountId        uint32  `json:"accountId"        gorm:"column:account_id"`
	Keyword          string  `json:"keyword"          gorm:"column:keyword"`
	ClientIP         string  `json:"clientIp"         gorm:"column:client_ip"`
	FromUrl          string  `json:"fromUrl"          gorm:"column:from_url"`
	FsId             string  `json:"fsId"             gorm:"column:fs_id"`
	ShareUrl         *string `json:"shareUrl"         gorm:"column:share_url"`      // 空=未生成
	ExpiresAt        *int64  `json:"expiresAt"        gorm:"column:expires_at"`     // 状态截止时间
	Status           *uint8  `json:"status"           gorm:"column:status"`         // 0转存中 1已分享 2清理放弃 3已清理 4失败
	CleanupFailCount *uint32 `json:"cleanupFailCount" gorm:"column:cleanup_fail_count"`
	FailReason       *string `json:"failReason"       gorm:"column:fail_reason"`
	model.BaseModel
}

func (SearchTransfer) TableName() string { return "search_transfer" }
```

## 6. 目录设计

按 `server/psou/.claude/rules` 的 DDD 分层设计，不新增平行层级。

```text
server/psou/
├── main.go
├── go.mod
├── buf.yaml
├── Makefile
├── Dockerfile
├── conf/
│   └── conf.yaml
├── api/                          # 独立 Go module
│   ├── go.mod
│   ├── errors/
│   │   ├── proto/
│   │   └── *.pb.go               # 生成代码，不手改
│   └── <domain>/
│       ├── proto/
│       └── *.pb.go               # 生成代码，不手改
├── internal/
│   ├── app/                      # handler、依赖注入、init 自注册
│   ├── core/                     # InitApp、Conf、Context、日志、事务
│   ├── middleware/               # Host 租户、管理端鉴权、限流、请求ID、恢复
│   ├── types/                    # 请求/查询 DTO
│   ├── domain/
│   │   ├── entity/               # GORM 实体
│   │   ├── repository/           # 仓储和外部客户端接口
│   │   └── service/              # 业务逻辑
│   └── infra/
│       ├── dbs/                  # GORM 仓储实现
│       ├── apis/                 # pansou/百度/夸克等外部 HTTP 客户端
│       └── rpcs/                 # manager/resource gRPC 客户端
├── deploy/
│   ├── schema.sql                # 全量建表与初始化 SQL，手动执行
│   └── ...                       # compose、运行配置
├── tests/
│   ├── integration/
│   └── fixtures/
└── README.md
```

规则：

- `main.go` 只负责启动、注册 `app.Register` 和 `middleware.Middleware()`，不写业务逻辑。
- `api/` 作为独立 Go module，只放 proto 和生成代码，不写业务逻辑。
- `internal/app` 实现 proto handler，并在 `NewXxx()` 中完成 service、repository、infra 的依赖注入。
- `internal/core` 提供 `InitApp`、全局 `Conf`、`core.Context`、日志和事务封装；不新增 `config/` 层。
- Host 解析放在 `internal/middleware`，通过 `domain/repository` 接口调用 `infra/rpcs` 的 manager 客户端，不新增 `tenant/` 包。
- DB/Redis 使用 kratosx 的 `ctx.DB()` / `ctx.Redis()`；对象存储通过 resource gRPC，外部 HTTP 走 `infra/apis`，不新增 `platform/` 包。
- `domain/repository` 的每个方法都必须显式接收或读取 app scope，不允许隐式默认 `psou`。
- `domain/service` 不依赖 HTTP/gRPC 类型；`internal/app` 负责 proto 与 `internal/types`/entity 的转换。
- `domain` 不 import `infra`；`infra` 实现 `domain/repository` 接口，依赖方向为 `app → domain ← infra`。
- `deploy/schema.sql` 是唯一 schema 来源；禁止 `AutoMigrate` 和启动时自动执行 SQL。
- 不包含 `cmd/`、`query_*` 表、`tenant/`、`platform/`、旧的扁平 `model/repository/service/handler/dto` 和前端构建产物。

