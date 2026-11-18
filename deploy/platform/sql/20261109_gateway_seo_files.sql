-- 盘搜 robots.txt / sitemap.xml 公共文件路由（可重复执行）。
SET NAMES utf8mb4;

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
