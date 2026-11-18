# go-platform 基础设施部署（Docker Compose + kratosx WebServer）

本目录部署六台 Go 服务（`manager`、`configure`、`resource`、`gateway`、`cron`、`ai-agent`）以及两个静态站点：管理端 `7401`、PSou H5 `7402`。两者使用同一个最小镜像，核心静态能力直接复用 `kratosx webServerDir`；Host 分流、API 转发和证书由 Nginx 负责。
**不部署 PSou 在线服务**，也不修改现有 `psou.service`、PSou 数据库或 `/www/software/psou`。

## 端口规划

端口按用途分区，避免基础设施、应用、Web 和 gRPC 混用。除标注为公网入口的端口外，其余服务只监听回环地址或内网地址。

### 基础设施

| 组件 | 端口 | 说明 |
|---|---:|---|
| SSH | 22 | 服务器运维入口 |
| Nginx HTTP / HTTPS | 80 / 443 | 公网入口，反向代理到 gateway 或 Web 静态服务 |
| MySQL | 3306 | 平台与业务数据库，仅本机或内网访问 |
| Redis | 6379 | 平台缓存与锁，仅本机或内网访问 |
| MinIO S3 / Console | 9000 / 9001 | 自建对象存储（规划），仅内网访问，公网通过 Nginx 或网关暴露 |

基础设施使用标准端口，不占用应用端口段。

### 应用 HTTP（7200-7299）

| 服务 | HTTP | gRPC | 说明 |
|---|---:|---:|---|
| gateway | 7200 | - | 网关与网关管理 API |
| configure | 7201 | 8201 | 配置中心 |
| manager | 7202 | 8202 | 管理端 |
| resource | 7203 | 8203 | 资源中心 |
| cron | 7204 | 8204 | 定时任务调度中心 |
| notify | 7205 | 8205 | 预留 |
| ai-agent | 7206 | 8206 | AI 中台 |

### PSou（7300-7309）

| 服务 | 端口 | 说明 |
|---|---:|---|
| psou HTTP | 7301 | 公共 `/psou/api/*` 与管理 `/psou/admin/*` |
| psou gRPC | 7302 | 仅供内网调用 |
| 7303-7309 | - | PSou 后续服务扩展 |

PSou 使用独立端口段，不与平台通用应用 `7200-7299` 混用。本目录暂不部署 PSou。

### Web / 静态站点（7400-7409）

| 服务 | 端口 | 说明 |
|---|---:|---|
| admin-web | 7401 | 管理端 SPA，`kratosx webServerDir`，仅监听 `127.0.0.1` |
| psou-web | 7402 | PSou H5 SPA，`kratosx webServerDir`，仅监听 `127.0.0.1` |
| 7403-7404 | - | 预留给 PC、小程序 Web 静态服务 |
| 7405-7409 | - | 后续 Web 服务扩展 |

### gRPC（8200-8299）

平台通用服务使用 `8200-8299`：configure 为 `8201`、manager 为 `8202`、resource 为 `8203`、cron 为 `8204`、notify 为 `8205`、ai-agent 为 `8206`。PSou 的 gRPC 单独使用 `7302`。所有 gRPC 只监听内网或回环地址。

### 开发端口

开发端口不属于生产端口规划：admin-web 开发服务为 `3006`，PSou H5 为 `5175`，client-uniapp 默认 `5173`。生产环境不得使用这些端口对外提供服务。

PSou 新在线服务使用 `7301/7302`；旧服务端口 `7010/8010` 不再作为新服务端口使用。

## 前提

- 目标机：CentOS 7 x86_64，已安装 Docker 24.x 和 Docker Compose v2。
- MySQL 5.7+ 与 Redis 6+ 已在本机运行，默认地址分别为 `127.0.0.1:3306`、`127.0.0.1:6379`。Redis 开启 `requirepass` 时必须设置 `PLATFORM_REDIS_PASSWORD`。
- 目标目录：`/www/software/go-platform`，与 `/www/software/psou` 分开。
- 端口规划：`7200-7299` 为平台通用应用 HTTP，`7300-7309` 为 PSou 专用，`7400-7409` 为 Web/静态站点，`8200-8299` 为平台通用 gRPC；基础设施继续使用 `3306`、`6379`、`80`、`443` 等标准端口。

CentOS 7 建议使用 Docker 24.0.9。不要把宿主机 MySQL/Redis 容器化，本方案直接复用现有实例。

## 1. 镜像来源与部署包

六个服务镜像由各仓库的 GitHub Actions 构建并推送到阿里云：

```text
registry.cn-qingdao.aliyuncs.com/limes-cloud/{manager,configure,resource,gateway}:<version>
registry.cn-qingdao.aliyuncs.com/limes-cloud/cron:v1.0.25
registry.cn-qingdao.aliyuncs.com/limes-cloud/ai-agent:v0.1.0
```

`docker-compose.yaml` 使用版本镜像，不再在目标机本地构建。`ai-agent` 从 `v0.1.0` 开始按 `vX.Y.Z` tag 发布。升级时修改 `.env` 中对应的 `PLATFORM_*_IMAGE`，再执行 `./start.sh` 拉取并重启。

本地自建镜像必须保持与 Compose 配置挂载一致的目录：`configure` 使用 `/app`，其余服务使用 `/go/build`。先执行 `./build.sh`，再用统一脚本构建，避免二进制因找不到 `conf/conf.yaml` 而启动失败：

```bash
./build-image.sh manager go-platform-manager:local
```

部署包只需要 compose、脚本、配置和 SQL。若需要生成包含六个 Linux 二进制的离线包，可在仓库执行：

```bash
cd deploy/platform
./package.sh
```

`package.sh` 会交叉编译 Linux amd64 二进制、构建 H5/管理端静态文件，并把配置、静态资源、SQL 和脚本一起打进：

```text
dist/go-platform-deploy-YYYYmmddHHMMSS.tar.gz
dist/go-platform-deploy-YYYYmmddHHMMSS.tar.gz.sha256
```

也可以只生成部署目录、不打 tar：

```bash
./build.sh
```

生成物说明：

- `dist/`：六个业务服务二进制和通用 `web-server` 二进制，仅供本地构建/离线排查。
- `assets/`：manager/resource 静态资源、configure 初始化目录、gateway 迁移脚本。
- `web/client/`：PSou H5 构建产物。
- `web/admin/`：管理端 Vite 构建产物，由 `build-admin-web.sh` 生成。
- `conf/`：从各服务当前配置复制出的运行配置。
- `sql/`：建表与种子 SQL，随包里一起上传。

打包机需要 Go 1.26+、Node.js、pnpm；目标机只需要 Docker 和 Docker Compose。若目标机已有单独的 `web/admin/` 构建产物，可在打包时设置 `SKIP_ADMIN_WEB_BUILD=1`。

`build-admin-web.sh` 会临时写入 `web/admin-web/.env.production.local`：

```dotenv
VITE_BASE_URL = https://47.108.186.217/
VITE_API_URL =
```

`VITE_BASE_URL` 在这里是 Vite 的静态资源 base，默认取 `web-assets.env` 的 `WEB_ASSET_ORIGIN`；同源部署时显式传 `ADMIN_BASE_URL=/` 覆盖。构建完成后恢复原文件。构建产物只保留相对 API 路径（如 `/manager/api/...`），`web-server` 启动时读取 `conf/web-*.yaml` 的 `server.http.injection`，在内存中向 `index.html` 注入运行时配置；不需要为不同环境重新打包。

### Web 静态资源托管在 rustfs（47）

psou 机器（`137.175.100.69`）到国内的访问速度很慢，所以 `admin-web` 和 `psou-web` 的 JS/CSS/字体等构建产物统一放到 rustfs 机器（`47.108.186.217`，rs 节点名 `rustfs`）的 nginx 上直出，`index.html` 直接引用 `https://47.108.186.217/assets/...`。页面本身仍由 psou 上的 `web-server` 提供，`/monacoeditorwork/`、`/api` 等非静态路径不变。

相关文件：

- `web-assets.env`：资源基址、rs 节点名、47 落盘目录、两个 Web 站点的目录与服务名。
- `nginx/47-assets.conf`：47 上 `/assets/` 的 nginx location 片段（CORS、gzip_static、immutable 缓存、OPTIONS 204）。
- `publish-web-assets.sh`：发布构建产物并改写 Web 节点 `index.html`。

首次安装 47 的 nginx 片段：把 `nginx/47-assets.conf` 的内容放进 `/www/server/panel/vhost/nginx/47.108.186.217.conf` 的 server 块，然后 `nginx -t && nginx -s reload`。

构建与发布：

```bash
cd deploy/platform
./build-web.sh                 # admin/psou 的 JS/CSS 都指向 47，/static 保持同源
./publish-web-assets.sh all    # 上传 assets 到 47，并改写两侧 index.html / 重启服务
```

psou 使用 uni-app，需要成对配置：

- Vite `base` 设为 47，保证入口和所有动态 chunk 都直接从 47 加载；
- `web/psou/src/manifest.json` 的 `h5.router.base` 固定为 `/`，否则 uni 运行时的 `__uniConfig.router.base` 会变成 47，把 `src/static` 下的本地图片（如 `/static/loading/baidu.png`）也带到 47 的 `/static/`，而 47 只有 `/assets/` 路由，会落到 RustFS 反代返回 403。

`publish-web-assets.sh` 只接受 `admin`、`psou`、`all`，可选 `--no-restart`。两个站点的 assets 合并到 `/www/wwwroot/47.108.186.217/assets`，依靠带 content hash 的文件名区分；脚本会在 47 上保留各站点的 sha256 清单并交叉校验，出现同名不同内容会直接失败。每次发布会先打备份：`/www/wwwroot/47.108.186.217/assets.backup.<时间戳>.tgz`，`index.html` 也会生成 `.bak.web-assets-<时间戳>`。

验证：

```bash
curl -I https://47.108.186.217/assets/                 # 404 即可，说明路由生效且未越权列目录
curl -I https://admin.psou.us/ | grep 47.108.186.217   # 入口已指向 47
curl -I https://pre.psou.us/   | grep 47.108.186.217
```

回滚时把对应的 `index.html.bak.web-assets-*` 恢复回去并重启服务即可；47 上的归档包可直接解压覆盖。

> 备注（2026-11-14 首次切换）：线上 release 目录里的 `index.html` 是热改的，下次直接替换 release 会回到同源路径。后续发布必须走上面的 `build-web.sh` + `publish-web-assets.sh`，不要手工改 release 里的入口文件。

## 2. 上传并准备远端目录

```bash
ssh root@137.175.100.69
mkdir -p /www/software/go-platform
```

上传并解压：

```bash
scp dist/go-platform-deploy-*.tar.gz root@137.175.100.69:/tmp/
ssh root@137.175.100.69
cd /www/software/go-platform
tar -xzf /tmp/go-platform-deploy-*.tar.gz
```

## 3. 配置 `.env`

```bash
cd /www/software/go-platform
cp .env.example .env
chmod 600 .env
openssl rand -hex 32
```

把生成值填入 `PLATFORM_MANAGER_JWT_SECRET`，并补齐：

- `PLATFORM_MYSQL_ADMIN_USER` / `PLATFORM_MYSQL_ADMIN_PASSWORD`
- 六个 `PLATFORM_*_DB_PASSWORD`，以及 `PLATFORM_CRON_DB_*`、`PLATFORM_AI_AGENT_DB_*`
- `PLATFORM_REDIS_PASSWORD`（现有 Redis 有密码时必填）
- `PSOU_SIGN_SK`，必须与 `psou/.env` 中的同名值一致，供 cron 离线调用 psou 管理接口时自动签名
- `PSOU_HTTP_URL`，调度链使用 `http://psou/...` 时的实际服务地址，只填协议和 host；默认 `http://127.0.0.1:7301`。例如 `http://psou/psou/admin/...` 会解析为 `http://127.0.0.1:7301/psou/admin/...`
- 如 MySQL 客户端不在 PATH，设置 `PLATFORM_MYSQL_BIN=/www/server/mysql/bin/mysql`

密码只使用 `A-Z a-z 0-9 . _ @ % + -`，避免 SQL/shell 转义问题。`.env` 不要提交到仓库。

生产默认值已经收紧：

- 六个服务只监听 `127.0.0.1`。
- manager pprof 关闭。
- `PLATFORM_DB_AUTO_CREATE=false`。
- gateway 管理 API 默认走 manager 的 token 校验接口；`resource`、`cron`、`ai-agent` 的业务代理路由也在网关校验 token。

## 4. 初始化数据库

宝塔 MySQL 如果没有可通过 TCP 登录的 root，请先在宝塔面板创建一个有 `CREATE DATABASE`、`CREATE USER`、`GRANT` 权限的临时管理员账号，填入 `.env`。

执行：

```bash
cd /www/software/go-platform
./init-db.sh
```

脚本会：

1. 创建 `manager`、`configure`、`resource`、`gateway`、`cron`、`ai_agent` 六个库。
2. 为每个库创建独立的最小权限用户（`127.0.0.1` 与 `localhost` 两个 host）。
3. 仅在库为空时导入建表 SQL。
4. 空 manager 库额外写入 manager 登录入口应用和基础应用登记。
5. 始终幂等执行 `sql/20261109_gateway_expression_routes.sql`，创建 `gw_route` 单表路由与路由内条件重写种子。
6. 旧 `gw_endpoint` / `gw_rewrite_rule` 模型不再参与运行时路由。

数据库对应关系：

| 数据库 | SQL | 说明 |
|---|---|---|
| `manager` | `sql/manager_schema.sql` + `sql/manager_seed.sql` | 38 张表；种子只含应用登记，不含用户 |
| `configure` | `sql/configure_schema.sql` | 10 张表；启动时 `deploy/data.sql` 初始化标记 |
| `resource` | `sql/resource_schema.sql` | 8 张表；对象存储 AK/SK 需单独录入 |
| `gateway` | `sql/20261109_gateway_expression_routes.sql` | `gw_route` 单表路由 + 路由内条件重写 + 基础业务路由，含 `resource`/`cron`/`ai-agent` 鉴权 |
| `cron` | `sql/cron_schema.sql` | 调度、任务、节点、执行意图和日志表，不含测试节点 |
| `ai_agent` | `sql/ai_agent_schema.sql` | 密钥、模型、Prompt 和调用日志表 |

**不会执行** `20261025_psou_client_route.sql`，本阶段不通网关接入 PSou。

已有 `cron` 库升级到支持挂起延迟重跑的版本前，先执行 `sql/20261106_cron_chain_suspend_delay.sql`（脚本可重复执行），再启动新的 cron 服务。

`ai-agent` 的 `003_psou_resource_prompt.sql` 依赖已存在的模型 ID，因此首次部署不自动导入；配置模型后按需手工执行。

如果 manager 库从已有生产备份恢复，脚本检测到 `app` 表非空会跳过种子；不要把开发库直接当生产库使用。

## 5. 启动

```bash
cd /www/software/go-platform
./start.sh
```

`start.sh` 会停止旧的 systemd `admin-web`，再启动 Compose：

```text
psou-web (7402)  admin-web (7401)
manager -> configure/resource/cron/ai-agent -> gateway
```

### 运行时 API 地址

两个静态容器使用同一镜像，但分别挂载自己的配置文件：

```yaml
server:
  http:
    host: 127.0.0.1
    port: 7402
    webServerDir: /app/web/client
    injection:
      - marker: "<!--__PSOU_WEB_CONFIG__-->"
        type: script
        value:
          apiBaseUrl: https://prod-gw.qlime.cn
```

- H5 配置位于 `conf/web-client.yaml`，管理端配置位于 `conf/web-admin.yaml`。
- 注入配置是数组，按顺序执行；`type: script` 时从 marker 中读取变量名并生成 `window.<name>=<JSON>;`，marker 必须形如 `<!--__PSOU_WEB_CONFIG__-->`。
- `type: html` 时 marker 可以是任意字符串，`value` 必须是字符串并原样插入。
- 注入只修改内存缓存，不改写容器内静态文件；找不到 marker 或配置非法时服务启动失败。
- `apiBaseUrl` 留空时会注入空字符串，前端回退到构建时变量；填写完整地址则直接使用该后端 host。
- 跨域部署时，网关必须允许管理端 Origin，并放行 `Authorization`、`Content-Type`、`X-App-Key` 等请求头。
- 修改配置后执行 `docker compose up -d platform-web platform-admin-web`，不需要重新构建前端。

### 爬虫首页渲染

普通用户和搜索蜘蛛都先进入 Gateway（7200）。Gateway 用 `gw_route.match_expression` 识别流量，再执行命中路由内的 `rewrites`：

- 蜘蛛路由：`req_header_value_contain("User-Agent", "spider", true)`，命中后把 GET/HEAD 首页重写到 `/manager/seo`，转发 Manager（7202）返回完整 HTML。
- 静态站点路由：`req_host_in("asou.fun", "www.asou.fun", "poposo.cc", "www.poposo.cc")`，转发 `platform-web`（7402）返回静态 SPA。

Nginx 不再判断蜘蛛，只负责把客户端请求和客户端 Header 原样交给 Gateway：

```nginx
location / {
    proxy_pass http://127.0.0.1:7200;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

- Gateway 是中介层，不生成或覆盖 `X-Forwarded-*`；Nginx 传入什么，业务服务就收到什么。
- Manager 通过 `X-Forwarded-Host`（优先）或 `Host` 查询 `app_domain`，读取 `setting.seo`，直接返回 `text/html; charset=utf-8`。
- 应用未绑定域名、SEO 未开启或首页 HTML 为空时 Manager 返回 `404`；需要在 Gateway 路由侧配置回退策略时，再加低优先级静态站点路由。
- `web-server` 不请求 Manager、不缓存 HTML，只负责静态资源和 SPA。

首次启动会从阿里云拉取六个固定版本镜像。私有仓库需先执行 `docker login registry.cn-qingdao.aliyuncs.com`；如果目标机无法访问该仓库，可在其他机器拉取后通过 `docker save` / `docker load` 导入。

## 6. 验证

```bash
cd /www/software/go-platform
./verify.sh
```

手工检查：

```bash
docker compose ps
ss -lntp | grep -E ':(7200|7201|8201|7202|8202|7203|8203|7204|8204|7206|8206|7401|7402)\b'
curl -fsS http://127.0.0.1:7200/gateway/api/health
curl -fsS http://127.0.0.1:7202/manager/api/system/setting
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7201/
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7203/
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7204/
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7206/
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7200/cron/api/v1/task_groups
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7200/ai-agent/api/models
curl -fsS http://127.0.0.1:7401/apps/resource/store
curl -fsS http://127.0.0.1:7402/psou/account
curl -fsS http://127.0.0.1:7402/index.html
curl -fsS -H 'Host: asou.fun' -H 'User-Agent: Baiduspider' http://127.0.0.1:7202/manager/seo | grep '<title>'
```

预期：

- gateway health 返回 200。
- manager setting 返回 200。
- configure/resource/cron/ai-agent 根路径返回 404 或 2xx 都算监听正常。
- 未带 token 访问 `/cron/api/*`、`/ai-agent/api/*` 返回 401 或 403。
- 两个静态站都能返回 SPA，不要求请求携带 `Accept: text/html`；缺失的 JS/CSS 等静态资源仍返回 404。API 路径由 Nginx 优先转发到网关，不属于静态服务路由。
- 现有 `psou.service` 仍为 active，`7010` 仍在监听。

## 7. 首次登录 manager

空库启动后，manager 已有 `manager` 登录入口应用，但没有用户。通过管理端注册首个用户：

```text
用户名：superadmin
```

`manager` 配置中的 `business.superAdminUsernames` 包含 `superadmin`，该用户会绕过 API 权限检查。注册时由操作者设置密码，不在 SQL 或仓库里保留默认密码。

如果使用已有备份恢复，直接使用备份中的管理员账号，不要重复注册。

## 8. 资源中心对象存储

`resource` 的 `store` 表需要真实对象存储 AK/SK。该行**不入 git**，由运维在 DB 初始化后单独执行。字段模板见 `server/resource/deploy/schema.sql` 顶部注释。

### 本地图片迁移到 MinIO

本地数据库中的图片对象可用 `migrate-local-images.sh` 搬到远端 MinIO，并把对象元数据、`app_config`、PSou 分类和资源一起同步：

```bash
./deploy/platform/migrate-local-images.sh             # 下载并校验，只预览
./deploy/platform/migrate-local-images.sh --apply     # 上传 MinIO、备份并导入远端
```

脚本默认把本地 `store_keyword` 映射为远端 `minio`，图片 key 保持 `<md5>.<ext>` 不变；远端导入前会备份 `object`、`app_config`、`category`、`resource`。历史图片的 key 不一定等于文件内容 MD5，脚本只按数据库中的 `size` 和下载后计算的 SHA-256 校验，不修改 key。

## 9. 域名与网关接入

站点和证书统一由宝塔维护，仓库不保存 Nginx 配置副本。管理端与 H5 分别反代到两个回环端口：

```text
admin domain / -> 127.0.0.1:7401
H5 domains   / -> 127.0.0.1:7402
```

业务 API 统一走 `https://gw.qlime.cn`，或在各域名下把 `/psou/api`、`/psou/admin`、`/manager/api` 等路径优先反代到网关。静态服务不识别 API 前缀，Nginx 必须保证 API location 优先于 `location /`。

不要把管理端和网关混在同一组 Nginx location 中，也不要复用 `psou.us` 的 server 块，否则会影响现有 PSou 流量。

## 10. 回滚

只停止本组容器：

```bash
cd /www/software/go-platform
./stop.sh
```

如需再删除镜像：

```bash
docker compose images
docker image rm <manager-image> <configure-image> <resource-image> <gateway-image> <cron-image> <ai-agent-image>
```

不要停止或删除：

- `psou.service`
- `/www/software/psou`
- `/www/server/panel/vhost/nginx/psou.us.conf`
- 现有 PSou 数据库

## 11. 日志与排障

```bash
docker compose logs -f platform-manager
docker compose logs -f platform-gateway
docker compose ps
docker inspect -f '{{json .State.Health}}' platform-manager
docker logs --tail 100 platform-web
docker logs --tail 100 platform-admin-web
```

常见问题：

- `manager` 起不来：先确认 `manager` 库已导入表结构，MySQL 用户可连接。
- `gateway` 502：确认 7201/7202/7203/7204/7206 都在监听，路由种子已导入。
- `cron`/`ai-agent` 起不来：确认数据库用户可连接、表结构已导入，并检查 `docker compose logs platform-cron` 或 `platform-ai-agent`。
- `admin-web` 打不开：确认 `platform-admin-web` 为 healthy、7401 在监听、`web/admin/index.html` 存在。
- H5 打不开：确认 `platform-web` 为 healthy、7402 在监听、`web/client/index.html` 存在。
- 静态页打开但 API 404：先检查 Nginx 的 API location 是否优先命中并转发到网关，再检查页面中的 `window.__PSOU_WEB_CONFIG__` / `window.__ADMIN_WEB_CONFIG__`。
- 登录失败：确认 `app` 表存在 `manager` 行，且 `loginable=1`、`status=1`。
- 配置未生效：容器挂载的是 `conf/<service>.yaml`，修改后执行 `docker compose restart <service>`。
- 网关管理 API 401：确认请求带 manager 登录 token，且 `PLATFORM_GATEWAY_ADMIN_AUTH_URL` 指向 `7202`。

## 12. 当前阶段边界

- `admin-web` 和 H5 都使用 `kratosx webServerDir`，分别监听 `127.0.0.1:7401` 与 `127.0.0.1:7402`。
- 管理端业务 API 统一经过 `https://gw.qlime.cn`；`gateway` 同时提供 `/gateway/api/*` 和网关管理页。
- 不部署 PSou、notify。
- 不改公网 Nginx、证书和 DNS。
- 不在仓库保存生产数据库密码、JWT secret、对象存储 AK/SK。
