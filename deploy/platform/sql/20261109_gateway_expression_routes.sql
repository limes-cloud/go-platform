-- Gateway 单表路由 + 路由内条件重写
-- 破坏性升级：不再创建 gw_rewrite_rule，也不参与旧 gw_endpoint 模型。

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `gw_route` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(128) NOT NULL,
  `description` VARCHAR(512) NOT NULL DEFAULT '',
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `priority` INT NOT NULL DEFAULT 0,
  `match_expression` VARCHAR(4096) NOT NULL,
  `rewrites` JSON NULL,
  `upstream` JSON NULL,
  `response` JSON NULL,
  `middlewares` JSON NULL,
  `metadata` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_gw_route_enabled_priority` (`enabled`, `priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='网关路由与路由内条件重写';

-- 兼容已经创建过上一版 gw_route 的开发库。
SET @has_rewrites := (
  SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'gw_route' AND column_name = 'rewrites'
);
SET @sql := IF(@has_rewrites = 0,
  'ALTER TABLE `gw_route` ADD COLUMN `rewrites` JSON NULL AFTER `match_expression`',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_forward := (
  SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'gw_route' AND column_name = 'forward'
);
SET @sql := IF(@has_forward > 0,
  'ALTER TABLE `gw_route` DROP COLUMN `forward`',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TABLE IF EXISTS `gw_rewrite_rule`;

CREATE TABLE IF NOT EXISTS `gw_route_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `version` BIGINT NOT NULL,
  `snapshot` LONGTEXT NOT NULL,
  `operator` VARCHAR(128) NOT NULL DEFAULT '',
  `remark` VARCHAR(512) NOT NULL DEFAULT '',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_gw_route_history_version` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='网关路由发布历史';

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '盘搜 SEO 文件',
  '固定 robots.txt / sitemap.xml 路径按 Host 转发到 Manager 动态渲染',
  1, 1100,
  'req_method_in("GET", "HEAD") && (req_path_in("/robots.txt") || req_path_in("/sitemap.xml"))',
  JSON_ARRAY(JSON_OBJECT(
    'name', 'SEO 文件转到 Manager',
    'priority', 100,
    'match', JSON_OBJECT(
      'expression', 'req_method_in("GET", "HEAD")',
      'terminal', TRUE
    ),
    'actions', JSON_ARRAY(JSON_OBJECT(
      'type', 'PATH_REGEX_REPLACE',
      'params', JSON_OBJECT(
        'pattern', '^/(robots\\.txt|sitemap\\.xml)$',
        'replacement', '/manager/$1'
      )
    ))
  )),
  '{"protocol":"HTTP","timeoutMs":10000,"backends":[{"target":"127.0.0.1:7202"}]}',
  '{"format":false,"headers":{}}',
  NULL,
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '盘搜 SEO 文件');

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '盘搜蜘蛛首页 SEO',
  'User-Agent 不区分大小写包含 spider 时转发到 Manager SEO 入口',
  1, 1000,
  'req_header_value_contain("User-Agent", "spider", true)',
  JSON_ARRAY(JSON_OBJECT(
    'name', '蜘蛛走 SEO',
    'priority', 100,
    'match', JSON_OBJECT(
      'expression', 'req_method_in("GET", "HEAD")',
      'terminal', TRUE
    ),
    'actions', JSON_ARRAY(JSON_OBJECT(
      'type', 'PATH_SET',
      'params', JSON_OBJECT('value', '/manager/seo')
    ))
  )),
  '{"protocol":"HTTP","timeoutMs":10000,"backends":[{"target":"127.0.0.1:7202"}]}',
  '{"format":false,"headers":{}}',
  NULL,
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '盘搜蜘蛛首页 SEO');

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '盘搜非浏览器首页 SEO',
  '公开落地域名的 GET/HEAD 首页，非浏览器或常见爬虫时转发到 Manager SEO 入口',
  1, 990,
  'req_method_in("GET", "HEAD") && req_path_in("/") && req_host_in("asou.fun", "www.asou.fun", "poposo.cc", "www.poposo.cc", "psou.us", "www.psou.us") && (req_ua_contains_any("spider", "bot", "crawler", "slurp") || !req_header_value_contain("User-Agent", "Mozilla", true))',
  JSON_ARRAY(JSON_OBJECT(
    'name', '非浏览器走 SEO',
    'priority', 100,
    'match', JSON_OBJECT(
      'expression', 'req_method_in("GET", "HEAD")',
      'terminal', TRUE
    ),
    'actions', JSON_ARRAY(JSON_OBJECT(
      'type', 'PATH_SET',
      'params', JSON_OBJECT('value', '/manager/seo')
    ))
  )),
  '{"protocol":"HTTP","timeoutMs":10000,"backends":[{"target":"127.0.0.1:7202"}]}',
  '{"format":false,"headers":{}}',
  NULL,
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '盘搜非浏览器首页 SEO');

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '管理端 API',
  'manager 管理端 API（保留 /manager/* 路径）',
  1, 0,
  'req_path_prefix_in("/manager/", false) || req_path_in("/manager")',
  JSON_ARRAY(),
  '{"protocol":"HTTP","timeoutMs":10000,"backends":[{"target":"127.0.0.1:7202"}]}',
  '{"format":true,"headers":{}}',
  NULL,
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '管理端 API');

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '资源中心 API',
  'resource 资源中心 API',
  1, 0,
  'req_path_prefix_in("/resource/api/", false) || req_path_in("/resource/api")',
  JSON_ARRAY(),
  '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7203"}]}',
  '{"format":true,"headers":{}}',
  '[{"name":"auth","options":{"url":"http://127.0.0.1:7202/manager/api/v1/authorize/token/parse","method":"POST","contentType":"application/json;charset=utf8","whitelist":[{"path":"/resource/api/file/object-by-key","method":"GET"},{"path":"/resource/api/file/read-by-key","method":"GET"},{"path":"/*","method":"OPTIONS"}]}}]',
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '资源中心 API');

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '配置中心 API',
  'configure 配置中心 API',
  1, 0,
  'req_path_prefix_in("/configure/api/", false) || req_path_in("/configure/api")',
  JSON_ARRAY(),
  '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7201"}]}',
  '{"format":true,"headers":{}}',
  NULL,
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '配置中心 API');

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '定时任务服务',
  'cron 定时任务服务 API',
  1, 0,
  'req_path_prefix_in("/cron/api/", false) || req_path_in("/cron/api")',
  JSON_ARRAY(),
  '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7204"}]}',
  '{"format":true,"headers":{}}',
  '[{"name":"auth","options":{"url":"http://127.0.0.1:7202/manager/api/v1/authorize/token/parse","method":"POST","contentType":"application/json;charset=utf8","whitelist":[{"path":"/*","method":"OPTIONS"}]}}]',
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '定时任务服务');

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  'AI 中台服务',
  'ai-agent API',
  1, 0,
  'req_path_prefix_in("/ai-agent/api/", false) || req_path_in("/ai-agent/api")',
  JSON_ARRAY(),
  '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7206"}]}',
  '{"format":true,"headers":{}}',
  NULL,
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = 'AI 中台服务');

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '盘搜公共 API',
  'PSou 公共 API',
  1, 0,
  'req_path_prefix_in("/psou/api/", false) || req_path_in("/psou/api")',
  JSON_ARRAY(),
  '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7301"}]}',
  '{"format":true,"headers":{}}',
  NULL,
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '盘搜公共 API');

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '盘搜管理 API',
  'PSou 管理 API',
  1, 0,
  'req_path_prefix_in("/psou/admin/", false) || req_path_in("/psou/admin")',
  JSON_ARRAY(),
  '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7301"}]}',
  '{"format":true,"headers":{}}',
  '[{"name":"auth","options":{"url":"http://127.0.0.1:7202/manager/api/v1/authorize/token/parse","method":"POST","contentType":"application/json;charset=utf8","whitelist":[{"path":"/*","method":"OPTIONS"}]}}]',
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '盘搜管理 API');

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '盘搜静态站点',
  'asou.fun / poposo.cc 静态 SPA，优先级低于 API 与 SEO 路由',
  1, -100,
  'req_host_in("asou.fun", "www.asou.fun", "poposo.cc", "www.poposo.cc", "psou.us", "www.psou.us")',
  JSON_ARRAY(),
  '{"protocol":"HTTP","timeoutMs":60000,"backends":[{"target":"127.0.0.1:7402"}]}',
  '{"format":false,"headers":{}}',
  NULL,
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '盘搜静态站点');
