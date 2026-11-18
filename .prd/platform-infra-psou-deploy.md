# go-platform 基础设施部署方案（psou）

> 状态：后端基础设施已部署（2026-10-29）  
> 目标主机：`psou`（`137.175.100.69:8999`，CentOS 7 x86_64）  
> 部署目录：`/www/software/go-platform`  
> 本次范围：platform 后端基础设施  
> 不包含：PSou 服务、PSou 路由、PSou 数据库、`admin-web`、MinIO、公网域名与证书

## 1. 目标与边界

本次在 `psou` 主机新建独立的 `go-platform` 部署，复用宿主机已有的 MySQL 8.0 和 Redis，只启动以下六个后端容器：

| 服务 | HTTP | gRPC | 作用 |
|---|---:|---:|---|
| gateway | 7200 | - | API 网关 |
| configure | 7201 | 8201 | 配置中心 |
| manager | 7202 | 8202 | 管理端 API |
| resource | 7203 | 8203 | 资源中心 |
| cron | 7204 | 8204 | 定时任务 |
| ai-agent | 7206 | 8206 | AI 中台 |

`notify` 的 `7205/8205` 保持预留，不启动。

### 本次包含

- 创建独立部署目录和 Compose 运行环境。
- 创建 `manager`、`configure`、`resource`、`gateway`、`cron`、`ai_agent` 六个数据库及独立账号。
- 导入各服务的空库 schema 和 gateway 路由种子。
- 启动六个后端容器并完成健康检查。
- 验证 gateway、manager、configure、resource、cron、ai-agent 的本机访问和网关鉴权。

### 本次不包含

- 不部署 PSou 在线服务，不占用 `7301/7302`。
- 不执行 `20261025_psou_client_route.sql` 或任何 PSou 路由迁移。
- 不修改 `psou.service`、`/www/software/psou`、`/www/software/pansou`、`psou.us.conf`。
- 不创建、查询或修改旧 PSou 数据库。
- 不部署 `admin-web`，不占用 `7401`。
- 不部署 MinIO，不配置 `resource.store`。
- 不修改 Nginx、域名解析或 TLS 证书。
- 不创建或重置 superadmin；后续单独确认密码后执行。

## 2. 现状与隔离边界

### 目标机现状

- Docker `26.1.4`、Docker Compose `v2.27.1` 可用。
- MySQL `8.0.45`，监听 `3306`；Redis 已运行，监听 `127.0.0.1:6379`。
- Nginx 占用 `80/443`。
- `7200-7206`、`7301/7302`、`7401` 当前均未占用。
- `/www/software` 目前有 `psou` 和 `pansou`，没有 `go-platform`。
- 现有 `psou.service` 正在运行，旧 PSou 使用 `7010`；本次不触碰。

### 必须保留的现有资源

| 资源 | 处理方式 |
|---|---|
| `psou.service` | 不停止、不重载、不覆盖 |
| `/www/software/psou` | 只读参考，不写入 |
| `/www/software/pansou` | 不写入 |
| `psou.us.conf` | 不修改 |
| 旧 PSou 数据库 | 不创建、不导入、不删除 |
| 7010 端口 | 保持现有服务使用 |

### 当前部署门禁

1. **MySQL 管理员凭据**：`init-db.sh` 需要能够执行 `CREATE DATABASE`、`CREATE USER`、`GRANT` 的管理员账号。现有 `psou` 账号只有 `psou.*` 权限，不能代替。
2. **镜像来源**：默认使用 `.env.example` 中的已发布镜像；如要部署当前本地未提交代码，必须先构建、发布并固定新镜像。
3. **公网入口**：本次默认只开放本机回环地址。`admin.qlime.cn`、`gw.qlime.cn` 属于 dev，`admin.psou.us` 当前 DNS 未解析，不能直接复用。
4. **superadmin 密码**：如本次需要初始化超级管理员，必须在执行前由用户明确提供；不得自行生成后静默使用。

## 3. 端口与监听策略

宿主机直接运行 MySQL、Redis 和 Nginx；platform 容器使用 host 网络，但服务配置必须绑定 `127.0.0.1`，不直接暴露公网。

| 类别 | 端口 | 本次处理 |
|---|---|---|
| 基础设施 | `22/80/443/3306/6379` | 复用现状，不改配置 |
| 平台 HTTP | `7200-7206` | 启动 `7200/7201/7202/7203/7204/7206` |
| 平台 gRPC | `8201-8206` | 启动 `8201/8202/8203/8204/8206` |
| PSou | `7301/7302` | 本次不使用 |
| Web | `7401` | 本次不使用 |
| MinIO | `9000/9001` | 本次不使用 |

预期只监听本机：

- `gateway`：`127.0.0.1:7200`
- `configure`：`127.0.0.1:7201`、`127.0.0.1:8201`
- `manager`：`127.0.0.1:7202`、`127.0.0.1:8202`
- `resource`：`127.0.0.1:7203`、`127.0.0.1:8203`
- `cron`：`127.0.0.1:7204`、`127.0.0.1:8204`
- `ai-agent`：`127.0.0.1:7206`、`127.0.0.1:8206`

## 4. 镜像与部署包

### 默认镜像策略

使用仓库已发布的固定版本，不在目标机构建源码：

```text
manager   v1.2.10
configure v1.0.51
resource  v1.2.4
gateway   v1.2.1
cron      v1.0.25
ai-agent  v0.1.0
```

原因：当前工作区存在大量未提交修改和 dirty submodule。直接使用 registry 镜像可以保证本次部署可复现，也不会把未验证的 PSou/manager/resource 改动带入线上。`ai-agent` 已建立首个版本 tag `v0.1.0` 并按版本发布镜像。

如确认要部署本地代码，则改为：先在本地构建 amd64 镜像，推送到阿里云仓库并写入不可变 tag，再更新 `.env`。不使用 `latest`，`ai-agent` 使用 `v0.1.0`。

### 部署包内容

从 `deploy/platform` 打包以下内容：

- `docker-compose.yaml`
- `init-db.sh`、`stop.sh`
- `conf/*.yaml`
- `sql/*.sql`
- `.env.example`
- 必要的说明文件

本次不打包、不安装 `admin-web` 二进制和静态文件。由于 `start.sh` 会安装 `admin-web`，本次不调用完整 `start.sh`，直接执行 `docker compose`。`verify.sh` 同理只使用其中的后端检查项。

## 5. 数据库设计

### 数据库与账号

| 数据库 | 账号 | 用途 |
|---|---|---|
| `manager` | `manager` | 用户、应用、菜单、角色 |
| `configure` | `configure` | 配置中心 |
| `resource` | `resource` | 资源中心 |
| `gateway` | `gateway` | 网关路由 |
| `cron` | `cron` | 定时任务 |
| `ai_agent` | `ai_agent` | AI 中台 |

每个账号分别授权 `127.0.0.1` 和 `localhost`，只拥有对应数据库权限。字符集统一 `utf8mb4`，排序规则 `utf8mb4_unicode_ci`。

### 初始化策略

`init-db.sh` 在目标机执行，负责：

1. 校验管理员连接。
2. 不存在时创建六个数据库和账号；存在时更新账号密码并补齐授权。
3. 库为空时导入对应 schema，已有表时跳过 schema 导入。
4. 为新 manager 库写入 manager 应用和基础应用注册。
5. 导入 gateway 路由种子。
6. 明确不执行 PSou 路由迁移。

执行前先检查六个目标库是否已存在。若存在同名库，停止部署并先做 `mysqldump` 备份，确认归属后再继续；不直接覆盖或删除。

### 关键环境变量

- `PLATFORM_DB_AUTO_CREATE=false`：建库建表只由 `init-db.sh` 完成。
- `PLATFORM_MANAGER_JWT_SECRET`：使用 `openssl rand -hex 32` 生成。
- 六个 `PLATFORM_*_DB_PASSWORD`：分别生成独立随机密码。
- `PLATFORM_REDIS_PASSWORD`：按宿主机 Redis 实际配置填写。
- 所有密码只写入远端 `.env`，权限 `600`，不回显、不写入仓库、不出现在命令输出和交付文档中。

## 6. 部署步骤

### 阶段 A：预检

1. 确认 `rs health psou` 正常。
2. 记录 `psou.service`、7010 端口、Nginx 站点和 Docker 容器现状。
3. 检查目标目录不存在；存在则先备份。
4. 检查 `7200-7206`、`8201-8206` 无冲突。
5. 检查 MySQL 管理员权限、Redis 认证方式、磁盘空间。
6. 校验镜像在目标机可拉取，并核对 amd64 架构。

### 阶段 B：打包与上传

1. 在本地生成不含 `.env`、不含 `admin-web` 产物的部署压缩包。
2. 计算 SHA256。
3. 通过 `rs push` 上传到 `/www/software`。
4. 在目标机校验 SHA256 后解压到 `/www/software/go-platform`。
5. 检查文件权限，脚本保持可执行。

### 阶段 C：配置

1. 基于 `.env.example` 创建 `/www/software/go-platform/.env`。
2. 写入数据库密码、JWT secret、Redis 密码和镜像版本。
3. 将 `.env` 权限设为 `600`。
4. 校验 Compose 配置：`docker compose --env-file .env config`。
5. 确认不存在 PSou 服务、PSou 端口或 PSou 迁移。

### 阶段 D：数据库初始化

1. 如目标库已存在，先备份。
2. 执行 `./init-db.sh`。
3. 校验六个库、六个账号、基础表和 gateway 路由数量。
4. 校验 `20261025_psou_client_route.sql` 未被执行。

### 阶段 E：启动

1. 拉取固定版本镜像。
2. 执行 `docker compose --env-file .env up -d --remove-orphans`。
3. 等待容器依赖链完成：`manager -> configure/resource/cron/ai-agent -> gateway`。
4. 查看 `docker compose ps` 和最近日志。
5. 任一容器不健康时停止后续验证，修复后重新启动，不带病进入验收。

## 7. 验收标准

### 容器与服务

- 六个容器均为 `healthy` 或 `running`。
- 无重启循环，日志中无数据库连接、schema、时区或端口错误。
- `7200/7201/7202/7203/7204/7206` 和 `8201/8202/8203/8204/8206` 正常监听。

### 接口

| 检查 | 预期 |
|---|---|
| `GET http://127.0.0.1:7200/gateway/api/health` | `200` |
| `GET http://127.0.0.1:7200/manager/api/system/setting` | `200` |
| `GET http://127.0.0.1:7202/manager/api/system/setting` | `200` |
| `GET http://127.0.0.1:7201/` | 返回非连接错误 |
| `GET http://127.0.0.1:7203/` | 返回非连接错误 |
| `GET http://127.0.0.1:7200/cron/api/v1/task_groups` 无 token | `401/403` |
| `GET http://127.0.0.1:7200/ai-agent/api/models` 无 token | `401/403` |

### 隔离检查

- `psou.service` 仍为 active。
- 旧 PSou 7010 端口仍正常。
- 没有启动 `7301/7302`、`7401`、`9000/9001`。
- 没有改动 `psou.us.conf` 和 `/www/software/psou`。
- 新数据库中不出现 PSou 客户端路由或 PSou 业务表。

## 8. 回滚

1. 停止并移除本次 Compose 容器：`docker compose --env-file .env down`。
2. 保留 `.env`、数据库和日志，先定位问题，不立即删库。
3. 如 schema 导入失败，按执行前的空库/备份状态恢复；仅删除本次新创建且已确认无业务数据的库。
4. 如端口冲突，只调整本次 platform 端口或停止本次容器，不影响 PSou。
5. 全程不执行 `systemctl stop psou`，不修改旧 Nginx 站点。

## 9. 后续阶段（本次不执行）

### 公网入口

需要先提供或确认两个独立域名：

- 管理端静态站域名
- 网关域名

确认后再配置 DNS、Nginx、TLS，并部署 `admin-web`。不复用 `psou.us` 站点，不复用 dev 的 `admin.qlime.cn`、`gw.qlime.cn`。

### admin-web

后端稳定后单独部署，监听 `127.0.0.1:7401`；API 地址通过 `/etc/default/go-platform-admin-web` 注入，不写死到前端构建产物。

### MinIO / 对象存储

需要单独确认使用第三方 S3 还是自建 MinIO。自建时只监听 `127.0.0.1:9000/9001`，通过独立域名和 Nginx/TLS 暴露 S3 API；bucket 默认 `platform`，不启用匿名读。

### superadmin

执行前询问用户所需用户名和密码，生成 bcrypt SQL，导入 manager 数据库后删除临时 SQL 文件。不得复制本地库账号或密码哈希。

## 10. 开始部署前待确认

1. 提供 MySQL 管理员账号和密码，或确认由宝塔面板预先创建六个数据库/账号后跳过 `init-db.sh`。
2. 确认使用已发布镜像；若必须部署当前本地改动，先完成镜像发布。
3. 确认本次只做本机回环部署、不配置公网入口；如要公网访问，提供新的管理端域名和网关域名。

上述三项确认后，按“阶段 A 至 E”执行，并在验收通过前不进入 `admin-web`、MinIO 和 PSou 部署。

## 11. 部署结果（2026-10-29）

- 主机：`psou`，部署目录 `/www/software/go-platform`。
- 六个容器均 `healthy`，重启次数为 `0`：manager `v1.2.10`、configure `v1.0.51`、resource `v1.2.4`、gateway `v1.2.1`、cron `v1.0.25`、ai-agent `v0.1.0`。
- MySQL 已创建六个独立库和账号；表数量：manager `39`、configure `10`、resource `8`、gateway `2`、cron `7`、ai_agent `6`。
- gateway 健康接口返回 `200`，manager 设置接口返回 `200`，cron 与 ai-agent 网关鉴权返回 `403`。
- 所有平台端口仅监听 `127.0.0.1`；`7301/7302/7401/9000/9001` 未启动。
- gateway 路由共 `5` 条，PSou 路由 `0` 条；`psou.service`、7010 端口和 `psou.us.conf` 保持不变。
- 管理员临时凭据已从 `.env` 和临时文件清除，`.env` 权限为 `600`。
- superadmin 已创建并通过 bcrypt 校验；尚未部署公网入口、`admin-web`、MinIO。
