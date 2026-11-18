-- 非浏览器访问公开落地域名首页时，统一按 Spider 处理，转发到 Manager 动态渲染 SEO。
-- 仅匹配 GET/HEAD 和根路径，避免误伤 API、管理端及健康检查请求。
SET NAMES utf8mb4;

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

UPDATE `gw_route`
SET
  `description` = '公开落地域名的 GET/HEAD 首页，非浏览器或常见爬虫时转发到 Manager SEO 入口',
  `priority` = 990,
  `match_expression` = 'req_method_in("GET", "HEAD") && req_path_in("/") && req_host_in("asou.fun", "www.asou.fun", "poposo.cc", "www.poposo.cc", "psou.us", "www.psou.us") && (req_ua_contains_any("spider", "bot", "crawler", "slurp") || !req_header_value_contain("User-Agent", "Mozilla", true))'
WHERE `name` = '盘搜非浏览器首页 SEO';
