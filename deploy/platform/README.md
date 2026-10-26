# go-platform 基础设施部署（Docker Compose）

本目录只部署四台基础 Go 服务：`manager`、`configure`、`resource`、`gateway`。  
**不包含 PSou**，也不修改现有 `psou.service`、`psou.us` Nginx 配置、PSou 数据库或 `/www/software/psou`。

## 端口

| 服务 | HTTP | gRPC | 说明 |
|---|---:|---:|---|
| gateway | 7200 | - | 唯一对外入口，默认只监听 `127.0.0.1` |
| configure | 7201 | 8201 | 配置中心 |
| manager | 7202 | 8202 | 管理端 |
| resource | 7203 | 8203 | 资源中心 |
| cron | 7204 | 8204 | 预留，本次不启动 |
| notify | 7205 | 8205 | 预留 |
| ai-agent | 7206 | 8206 | 预留 |

现有 PSou 继续使用 `7010/8010`，两者不冲突。

## 前提

- 目标机：CentOS 7 x86_64，已安装 Docker 24.x 和 Docker Compose v2。
- MySQL 5.7+ 与 Redis 6+ 已在本机运行，默认地址分别为 `127.0.0.1:3306`、`127.0.0.1:6379`。Redis 开启 `requirepass` 时必须设置 `PLATFORM_REDIS_PASSWORD`。
- 目标目录：`/www/software/go-platform`，与 `/www/software/psou` 分开。
- 当前端口段 `7200-7299`、`8200-8299` 已确认空闲。

CentOS 7 建议使用 Docker 24.0.9。不要把宿主机 MySQL/Redis 容器化，本方案直接复用现有实例。

## 1. 镜像来源与部署包

四个服务镜像由各仓库的 GitHub Actions 构建并推送到阿里云：

```text
registry.cn-qingdao.aliyuncs.com/limes-cloud/{manager,configure,resource,gateway}:<version>
```

`docker-compose.yaml` 使用固定版本镜像，不再在目标机本地构建。升级时修改 `.env` 中对应的 `PLATFORM_*_IMAGE`（或更新 compose 默认值），再执行 `./start.sh` 拉取并重启。

部署包只需要 compose、脚本、配置和 SQL。若需要生成包含四个 Linux 二进制的离线包，可在仓库执行：

```bash
cd deploy/platform
./package.sh
```

`package.sh` 会交叉编译 Linux amd64 二进制，并把配置、静态资源、SQL 和脚本一起打进：

```text
dist/go-platform-deploy-YYYYmmddHHMMSS.tar.gz
dist/go-platform-deploy-YYYYmmddHHMMSS.tar.gz.sha256
```

也可以只生成部署目录、不打 tar：

```bash
./build.sh
```

生成物说明：

- `dist/`：四个 Linux 二进制，仅供本地构建/离线排查，镜像部署模式不会使用。
- `assets/`：manager/resource 静态资源、configure 初始化目录、gateway 迁移脚本。
- `conf/`：从各服务当前配置复制出的运行配置。
- `sql/`：建表与种子 SQL，随包里一起上传。

部署目录已带有 `conf/`、`sql/` 时，正常上线不需要本机安装 Go。`build.sh` 和 `package.sh` 只用于首次生成这些文件或做离线排查。

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
- 四个 `PLATFORM_*_DB_PASSWORD`
- `PLATFORM_REDIS_PASSWORD`（现有 Redis 有密码时必填）
- 如 MySQL 客户端不在 PATH，设置 `PLATFORM_MYSQL_BIN=/www/server/mysql/bin/mysql`

密码只使用 `A-Z a-z 0-9 . _ @ % + -`，避免 SQL/shell 转义问题。`.env` 不要提交到仓库。

生产默认值已经收紧：

- 四个服务只监听 `127.0.0.1`。
- manager pprof 关闭。
- `PLATFORM_DB_AUTO_CREATE=false`。
- gateway 管理 API 默认走 manager 的 token 校验接口；种子里的业务代理路由由各后端自行鉴权。

## 4. 初始化数据库

宝塔 MySQL 如果没有可通过 TCP 登录的 root，请先在宝塔面板创建一个有 `CREATE DATABASE`、`CREATE USER`、`GRANT` 权限的临时管理员账号，填入 `.env`。

执行：

```bash
cd /www/software/go-platform
./init-db.sh
```

脚本会：

1. 创建 `ns_manager_v2`、`configure`、`resource`、`gateway` 四个库。
2. 为每个库创建独立的最小权限用户（`127.0.0.1` 与 `localhost` 两个 host）。
3. 仅在库为空时导入建表 SQL。
4. 空 manager 库额外写入 manager 登录入口应用和基础应用登记。
5. 始终幂等执行 gateway 路由种子。

数据库对应关系：

| 数据库 | SQL | 说明 |
|---|---|---|
| `ns_manager_v2` | `sql/manager_schema.sql` + `sql/manager_seed.sql` | 38 张表；种子只含应用登记，不含用户 |
| `configure` | `sql/configure_schema.sql` | 10 张表；启动时 `deploy/data.sql` 初始化标记 |
| `resource` | `sql/resource_schema.sql` | 8 张表；对象存储 AK/SK 需单独录入 |
| `gateway` | `sql/gateway_route_config.sql` | 路由表 + 四条路由种子，不含 PSou |

**不会执行** `20261025_psou_client_route.sql`，本阶段不通网关接入 PSou。

如果 manager 库从已有生产备份恢复，脚本检测到 `app` 表非空会跳过种子；不要把开发库直接当生产库使用。

## 5. 启动

```bash
cd /www/software/go-platform
./start.sh
```

启动顺序由 Compose 健康检查控制：

```text
manager -> configure/resource -> gateway
```

首次启动会从阿里云拉取四个固定版本镜像。私有仓库需先执行 `docker login registry.cn-qingdao.aliyuncs.com`；如果目标机无法访问该仓库，可在其他机器拉取后通过 `docker save` / `docker load` 导入。

## 6. 验证

```bash
cd /www/software/go-platform
./verify.sh
```

手工检查：

```bash
docker compose ps
ss -lntp | grep -E ':(7200|7201|8201|7202|8202|7203|8203)\b'
curl -fsS http://127.0.0.1:7200/gateway/api/health
curl -fsS http://127.0.0.1:7202/manager/api/system/setting
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7201/
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7203/
```

预期：

- gateway health 返回 200。
- manager setting 返回 200。
- configure/resource 根路径返回 404 或 2xx 都算监听正常。
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

## 9. Nginx 接入（下一阶段）

当前不要改 `psou.us`。等 `admin.psou.us` DNS 就绪后，新增独立 server，把请求整体转发到 `127.0.0.1:7200`：

```nginx
server {
    listen 80;
    server_name admin.psou.us;

    location / {
        proxy_pass http://127.0.0.1:7200;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

不要复用 `psou.us` 的 server 块，否则会影响现有 PSou 流量。

## 10. 回滚

只停止本组容器：

```bash
cd /www/software/go-platform
./stop.sh
```

如需再删除镜像：

```bash
docker compose images
docker image rm <manager-image> <configure-image> <resource-image> <gateway-image>
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
```

常见问题：

- `manager` 起不来：先确认 `ns_manager_v2` 已导入表结构，MySQL 用户可连接。
- `gateway` 502：确认 7201/7202/7203 都在监听，路由种子已导入。
- 登录失败：确认 `app` 表存在 `manager` 行，且 `loginable=1`、`status=1`。
- 配置未生效：容器挂载的是 `conf/<service>.yaml`，修改后执行 `docker compose restart <service>`。
- 网关管理 API 401：确认请求带 manager 登录 token，且 `PLATFORM_GATEWAY_ADMIN_AUTH_URL` 指向 `7202`。

## 12. 当前阶段边界

- 不部署 `admin-web`。其生产 `VITE_API_URL` 尚未切换，`admin.psou.us` 也还没有 DNS。
- 不部署 PSou、cron、notify、ai-agent。
- 不改公网 Nginx、证书和 DNS。
- 不在仓库保存生产数据库密码、JWT secret、对象存储 AK/SK。
