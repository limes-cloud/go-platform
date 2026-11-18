-- 为需要浏览器跨域访问的受保护路由放行 CORS 预检。
-- OPTIONS 不携带业务 Token，必须在 auth 中间件之前放行；真正的 CORS 响应头由上游服务返回。
SET NAMES utf8mb4;

UPDATE `gw_route`
SET `middlewares` = '[{"name":"auth","options":{"url":"http://127.0.0.1:7202/manager/api/v1/authorize/token/parse","method":"POST","contentType":"application/json;charset=utf8","whitelist":[{"path":"/*","method":"OPTIONS"}]}}]'
WHERE `name` IN ('定时任务服务', '盘搜管理 API');
