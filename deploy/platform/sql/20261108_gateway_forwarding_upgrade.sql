-- Gateway 转发能力升级：旧扁平路由表 -> 新 action/match/upstream/forward/response 模型
--
-- 警告：本迁移只执行一次。执行前请备份 gateway 库。
-- 旧表会保留为 gw_endpoint_legacy / gw_endpoint_history_legacy，便于人工核对和回退。

SET NAMES utf8mb4;

RENAME TABLE `gw_endpoint` TO `gw_endpoint_legacy`,
             `gw_endpoint_history` TO `gw_endpoint_history_legacy`;

CREATE TABLE `gw_endpoint` (
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

CREATE TABLE `gw_endpoint_history` (
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
   `upstream`, `forward`, `redirect`, `response`, `middlewares`, `metadata`, `created_at`, `updated_at`)
SELECT
  IFNULL(NULLIF(`title`, ''), `path`),
  `description`,
  `enabled`,
  0,
  'proxy',
  `host`,
  `path`,
  IF(`method` = '', '*', `method`),
  JSON_OBJECT(
    'protocol', IFNULL(NULLIF(`protocol`, ''), 'HTTP'),
    'timeoutMs', `timeout_ms`,
    'backends', CAST(`backends` AS JSON),
    'retry', CAST(`retry` AS JSON)
  ),
  '{"host":"","path":{"stripPrefix":"","pattern":"","replacement":"","preserveQuery":true},"requestHeaders":{},"forwarded":{"enable":true,"trustIncoming":true}}',
  NULL,
  IF(`response_format` = 1,
     CAST('{"format":true,"headers":{}}' AS JSON),
     CAST('{"format":false,"headers":{}}' AS JSON)),
  `middlewares`,
  `metadata`,
  `created_at`,
  `updated_at`
FROM `gw_endpoint_legacy`;
