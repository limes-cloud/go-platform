-- 将 psou.us / www.psou.us 纳入盘搜静态站点路由，供两个域名经网关转发到最新 7402 前端。
SET NAMES utf8mb4;

UPDATE `gw_route`
SET `match_expression` = 'req_host_in("asou.fun", "www.asou.fun", "poposo.cc", "www.poposo.cc", "psou.us", "www.psou.us")'
WHERE `name` = '盘搜静态站点';
