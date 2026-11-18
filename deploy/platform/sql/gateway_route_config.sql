-- Gateway 路由配置表（新转发模型）
--
-- 说明：
--   1) 表建在 gateway 自有库；
--   2) 本文件供全新环境初始化使用；
--   3) 已有旧表请执行 server/gateway/deploy/migrations/20261108_gateway_forwarding_upgrade.sql。

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `gw_endpoint` (
  `id`           BIGINT       NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(128) NOT NULL DEFAULT '',
  `description`  VARCHAR(512) NOT NULL DEFAULT '',
  `enabled`      TINYINT(1)   NOT NULL DEFAULT 1,
  `priority`     INT          NOT NULL DEFAULT 0,
  `action`       VARCHAR(16)  NOT NULL,
  `match_host`   VARCHAR(191) NOT NULL DEFAULT '',
  `match_path`   VARCHAR(512) NOT NULL,
  `match_method` VARCHAR(32)  NOT NULL DEFAULT '*',
  `upstream`     JSON         NULL,
  `forward`      JSON         NULL,
  `redirect`     JSON         NULL,
  `response`     JSON         NULL,
  `middlewares`  JSON         NULL,
  `metadata`     JSON         NULL,
  `created_at`   DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`   DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_gw_endpoint_match` (`match_host`, `match_path`, `match_method`),
  KEY `idx_gw_endpoint_enabled_priority` (`enabled`, `priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='网关路由配置表';

CREATE TABLE IF NOT EXISTS `gw_endpoint_history` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `version`    BIGINT       NOT NULL,
  `snapshot`   JSON         NOT NULL,
  `operator`   VARCHAR(64)  NOT NULL,
  `remark`     VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_gw_endpoint_history_version` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='网关路由发布历史表';

INSERT INTO `gw_endpoint`
  (`name`, `description`, `enabled`, `priority`, `action`, `match_host`, `match_path`, `match_method`,
   `upstream`, `forward`, `redirect`, `response`, `middlewares`, `metadata`)
VALUES
  (
    '管理端 API',
    'manager 管理端 API（保留后端 /manager/api/* 路径）',
    1, 0, 'proxy', '', '/manager/*', '*',
    '{"protocol":"HTTP","timeoutMs":10000,"backends":[{"target":"127.0.0.1:7202"}]}',
    '{"host":"","path":{"stripPrefix":"","pattern":"","replacement":"","preserveQuery":true},"requestHeaders":{},"forwarded":{"enable":true,"trustIncoming":true}}',
    NULL,
    '{"format":true,"headers":{}}',
    NULL,
    NULL
  ),
  (
    '资源中心 API',
    'resource 资源中心 API',
    1, 0, 'proxy', '', '/resource/api/*', '*',
    '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7203"}]}',
    '{"host":"","path":{"stripPrefix":"","pattern":"","replacement":"","preserveQuery":true},"requestHeaders":{},"forwarded":{"enable":true,"trustIncoming":true}}',
    NULL,
    '{"format":true,"headers":{}}',
    '[{"name":"auth","options":{"url":"http://127.0.0.1:7202/manager/api/v1/authorize/token/parse","method":"POST","contentType":"application/json;charset=utf8","whitelist":[{"path":"/resource/api/file/object-by-key","method":"GET"},{"path":"/resource/api/file/read-by-key","method":"GET"},{"path":"/*","method":"OPTIONS"}]}}]',
    NULL
  ),
  (
    '配置中心 API',
    'configure 配置中心 API',
    1, 0, 'proxy', '', '/configure/api/*', '*',
    '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7201"}]}',
    '{"host":"","path":{"stripPrefix":"","pattern":"","replacement":"","preserveQuery":true},"requestHeaders":{},"forwarded":{"enable":true,"trustIncoming":true}}',
    NULL,
    '{"format":true,"headers":{}}',
    NULL,
    NULL
  ),
  (
    '定时任务服务',
    'cron 定时任务服务',
    1, 0, 'proxy', '', '/cron/api/*', '*',
    '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7204"}]}',
    '{"host":"","path":{"stripPrefix":"","pattern":"","replacement":"","preserveQuery":true},"requestHeaders":{},"forwarded":{"enable":true,"trustIncoming":true}}',
    NULL,
    '{"format":true,"headers":{}}',
    '[{"name":"auth","options":{"url":"http://127.0.0.1:7202/manager/api/v1/authorize/token/parse","method":"POST","contentType":"application/json;charset=utf8","whitelist":[{"path":"/*","method":"OPTIONS"},{"path":"/cron/api/v1/open/*","method":"POST"}]}}]',
    NULL
  ),
  (
    'AI 中台服务',
    'ai-agent AI 中台服务',
    1, 0, 'proxy', '', '/ai-agent/api/*', '*',
    '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7206"}]}',
    '{"host":"","path":{"stripPrefix":"","pattern":"","replacement":"","preserveQuery":true},"requestHeaders":{},"forwarded":{"enable":true,"trustIncoming":true}}',
    NULL,
    '{"format":true,"headers":{}}',
    '[{"name":"auth","options":{"url":"http://127.0.0.1:7202/manager/api/v1/authorize/token/parse","method":"POST","contentType":"application/json;charset=utf8","whitelist":[{"path":"/*","method":"OPTIONS"}]}}]',
    NULL
  ),
  (
    '盘搜公共 API',
    'psou H5、小程序与 PC 公共 API',
    1, 0, 'proxy', '', '/psou/api/*', '*',
    '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7301"}]}',
    '{"host":"","path":{"stripPrefix":"","pattern":"","replacement":"","preserveQuery":true},"requestHeaders":{},"forwarded":{"enable":true,"trustIncoming":true}}',
    NULL,
    '{"format":true,"headers":{}}',
    NULL,
    NULL
  ),
  (
    '盘搜管理 API',
    'psou 网盘账号与在线管理 API',
    1, 0, 'proxy', '', '/psou/admin/*', '*',
    '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7301"}]}',
    '{"host":"","path":{"stripPrefix":"","pattern":"","replacement":"","preserveQuery":true},"requestHeaders":{},"forwarded":{"enable":true,"trustIncoming":true}}',
    NULL,
    '{"format":true,"headers":{}}',
    '[{"name":"auth","options":{"url":"http://127.0.0.1:7202/manager/api/v1/authorize/token/parse","method":"POST","contentType":"application/json;charset=utf8","whitelist":[{"path":"/*","method":"OPTIONS"}]}}]',
    NULL
  )
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `description` = VALUES(`description`),
  `enabled` = VALUES(`enabled`),
  `priority` = VALUES(`priority`),
  `action` = VALUES(`action`),
  `upstream` = VALUES(`upstream`),
  `forward` = VALUES(`forward`),
  `redirect` = VALUES(`redirect`),
  `response` = VALUES(`response`),
  `middlewares` = VALUES(`middlewares`),
  `metadata` = VALUES(`metadata`);
