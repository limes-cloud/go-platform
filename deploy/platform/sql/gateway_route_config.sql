-- gateway 网关路由配置表迁移脚本
--
-- 依据：.prd/gateway-route-config-db.md（权威，含字段说明）。本文件只放 DDL 与种子数据。
-- 使用方式：部署后手工执行一次。注意：
--   1) 表建在 gateway 自有库（与业务库分离）；
--   2) 全库不用 MySQL 8.0 专属语法；
--   3) 种子数据与迁移前 config/config.yaml 中的 6 条路由一一对应（幂等，可重复执行）。

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 1. gw_endpoint —— 网关路由配置表
-- 唯一键 (host, path, method) 保证同一 host 下路由不重复；enabled=0 为软禁用。
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `gw_endpoint` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `path`            VARCHAR(512) NOT NULL COMMENT '路由匹配路径',
  `title`           VARCHAR(64)  NOT NULL DEFAULT ''  COMMENT '路由名称',
  `method`          VARCHAR(32)  NOT NULL DEFAULT ''  COMMENT 'HTTP 方法',
  `host`            VARCHAR(64)  NOT NULL DEFAULT ''  COMMENT 'Host 头匹配',
  `protocol`        VARCHAR(16)  NOT NULL DEFAULT 'HTTP' COMMENT '协议类型',
  `response_format` TINYINT(1)   NOT NULL DEFAULT 0   COMMENT '是否格式化响应',
  `timeout_ms`      BIGINT       NOT NULL DEFAULT 0   COMMENT '请求超时（毫秒）',
  `description`     VARCHAR(255) NOT NULL DEFAULT ''  COMMENT '备注',
  `metadata`        JSON         NULL                 COMMENT '元数据',
  `backends`        JSON         NOT NULL             COMMENT '后端列表',
  `middlewares`     JSON         NULL                 COMMENT '中间件列表',
  `retry`           JSON         NULL                 COMMENT '重试策略',
  `enabled`         TINYINT(1)   NOT NULL DEFAULT 1   COMMENT '启用状态',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_gw_endpoint` (`host`, `path`, `method`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='网关路由配置表';

-- ---------------------------------------------------------------------------
-- 2. gw_endpoint_history —— 网关路由发布历史表
-- 发布制（.prd 第四节）的版本与回滚依据；version 全局唯一。
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `gw_endpoint_history` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `version`    BIGINT       NOT NULL COMMENT '发布版本号',
  `snapshot`   JSON         NOT NULL COMMENT '全量下发配置快照',
  `operator`   VARCHAR(64)  NOT NULL COMMENT '发布人',
  `remark`     VARCHAR(255) NOT NULL DEFAULT '' COMMENT '发布说明',
  `created_at` DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_gw_endpoint_history_version` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='网关路由发布历史表';

-- ---------------------------------------------------------------------------
-- 3. 种子数据：与当前 server/ 目录实际服务一一对应（notify/usercenter/psou 暂不接入）
-- 端口为各服务 conf 中的实际 HTTP 端口；幂等：唯一键冲突时更新内容。
-- ---------------------------------------------------------------------------
INSERT INTO `gw_endpoint` (`path`, `title`, `method`, `host`, `protocol`, `response_format`, `timeout_ms`, `description`, `metadata`, `backends`, `middlewares`, `retry`, `enabled`)
VALUES
  ('/manager/api/*',      '管理端 API',   '', '', 'HTTP', 1, 10000, 'manager 管理端 API',     NULL, '[{"target":"127.0.0.1:7202"}]', NULL, NULL, 1),
  ('/resource/api/*',     '资源中心 API', '', '', 'HTTP', 1, 60000, 'resource 资源中心 API',   NULL, '[{"target":"127.0.0.1:7203"}]', NULL, NULL, 1),
  ('/configure/api/*',    '配置中心 API', '', '', 'HTTP', 1, 60000, 'configure 配置中心 API',  NULL, '[{"target":"127.0.0.1:7201"}]', NULL, NULL, 1),
  ('/cron/api/*',         '定时任务服务', '', '', 'HTTP', 1, 60000, 'cron 定时任务服务',       NULL, '[{"target":"127.0.0.1:7204"}]', NULL, NULL, 1),
  ('/ai-agent/api/*',     'AI 中台服务',  '', '', 'HTTP', 1, 60000, 'ai-agent AI 中台服务',    NULL, '[{"target":"127.0.0.1:7206"}]', NULL, NULL, 1)
ON DUPLICATE KEY UPDATE
  `title`           = VALUES(`title`),
  `protocol`        = VALUES(`protocol`),
  `response_format` = VALUES(`response_format`),
  `timeout_ms`      = VALUES(`timeout_ms`),
  `description`     = VALUES(`description`),
  `backends`        = VALUES(`backends`),
  `middlewares`     = VALUES(`middlewares`),
  `retry`           = VALUES(`retry`),
  `enabled`         = VALUES(`enabled`);
