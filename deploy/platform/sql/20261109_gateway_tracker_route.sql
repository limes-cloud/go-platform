-- 点位上报独立路由：保留真实 HTTP 状态码并原样透传 raw handler 响应。
SET NAMES utf8mb4;

INSERT INTO `gw_route`
  (`name`, `description`, `enabled`, `priority`, `match_expression`, `rewrites`, `upstream`, `response`, `middlewares`, `metadata`)
SELECT
  '点位上报 API',
  'tracker raw ingest，原样透传响应体',
  1, 500,
  'req_path_in("/manager/api/tracker/collect")',
  JSON_ARRAY(),
  '{"protocol":"HTTP","timeoutMs":10000,"backends":[{"target":"127.0.0.1:7202"}]}',
  '{"format":false,"headers":{}}',
  NULL,
  NULL
WHERE NOT EXISTS (SELECT 1 FROM `gw_route` WHERE `name` = '点位上报 API');

UPDATE `gw_route`
SET `priority` = 500,
    `match_expression` = 'req_path_in("/manager/api/tracker/collect")',
    `response` = '{"format":false,"headers":{}}',
    `enabled` = 1
WHERE `name` = '点位上报 API';
