# 12 Schema 治理

**这是配置驱动系统最大的运维风险，而两个参考项目都没碰。** alien-form 服务端只有 `created_at` / `updated_at` 两个时间戳，无 version、无历史表、无回滚、无并发写冲突检测（PUT 直接整份覆盖）。

## 1. 后端表设计

照抄已在生产验证的 `UserForm`（`server/manager/internal/domain/entity/form_schema.go`）的形态，补上它没有的历史表。

### `page_schema` — 当前版本

```go
// PageSchema CRUD 页面配置
type PageSchema struct {
    App         string  `json:"app"         gorm:"column:app"`          // 应用标识，关联 app.keyword
    Keyword     string  `json:"keyword"     gorm:"column:keyword"`      // 页面标识，菜单通过它引用
    Name        string  `json:"name"        gorm:"column:name"`         // 页面名称
    Schema      string  `json:"schema"      gorm:"column:schema;type:json"` // ModelSchema 完整 JSON
    Version     uint32  `json:"version"     gorm:"column:version"`      // 版本号，每次发布自增
    Status      *bool   `json:"status"      gorm:"column:status"`       // false=草稿 true=已发布
    Description *string `json:"description" gorm:"column:description"`  // 用途描述
    model.BaseModel                                                      // Id + CreatedAt + UpdatedAt
}
```

唯一约束：`(app, keyword)`。

### `page_schema_history` — 历史版本

```go
// PageSchemaHistory 页面配置历史版本（只增不改）
type PageSchemaHistory struct {
    SchemaId  uint32 `json:"schemaId"  gorm:"column:schema_id"`  // 关联 page_schema.id
    Version   uint32 `json:"version"   gorm:"column:version"`    // 该次发布的版本号
    Schema    string `json:"schema"    gorm:"column:schema;type:json"`
    Operator  string `json:"operator"  gorm:"column:operator"`   // 发布人
    Comment   string `json:"comment"   gorm:"column:comment"`    // 变更说明
    model.CreateModel                                             // Id + CreatedAt
}
```

每次发布往历史表插一条。回滚 = 取历史版本的 `schema` 写回 `page_schema` 并 `version++`（**不是把 version 减回去**，回滚也是一次前进的变更，保证历史线性）。

## 2. 生命周期

```
草稿(status=false) ──保存──> 草稿          # 可反复保存，version 不变
                   ──发布──> 已发布        # version++，写历史表
已发布             ──编辑──> 新草稿         # 不影响线上正在用的版本
已发布             ──回滚──> 已发布(新版本)  # 取历史 schema，version++
```

关键点：**编辑已发布的配置产生的是草稿，不直接生效。** 线上运行时只读 `status=true` 的版本。

## 3. 下发接口

```
GET  /manager/api/page/schemas               列表（摘要，不含 schema 正文）
GET  /manager/api/page/schema                单个（按 id）
GET  /manager/api/page/schema/runtime        运行时下发：入参 { app, keyword }，只返回 status=true 的
POST /manager/api/page/schema                创建草稿
PUT  /manager/api/page/schema                更新草稿（乐观锁，见 §4）
PUT  /manager/api/page/schema/publish        发布
PUT  /manager/api/page/schema/rollback       回滚到指定 version
GET  /manager/api/page/schema/histories      历史版本列表
```

`runtime` 接口独立出来的理由：它是高频只读、可强缓存、不需要返回草稿和历史，权限也不同（所有登录用户可读 vs 仅配置管理员可写）。

对齐 [03](03-模型协议.md) 的多 App 隔离：`runtime` 接口必须校验请求方 App 对该 `app` 的可见性（复用 `App.HasModule()` 的逻辑）。

## 4. 并发写保护

alien-form 的 PUT 是整份覆盖无保护，两个人同时编辑后者静默覆盖前者。我们用乐观锁：

```
PUT /manager/api/page/schema  { id, schema, baseVersion, baseUpdatedAt }
```

服务端比对 `baseUpdatedAt` 与当前记录的 `updated_at`，不一致则返回冲突错误，前端提示「配置已被他人修改，请刷新后重试」并提供 diff 查看（项目已有 `configure/template/configure/components/compare.vue` 的 diff 组件可参考）。

## 5. 灰度

**最小可行方案**：不做百分比灰度，做**白名单预览**。

```
GET /manager/api/page/schema/runtime?preview=1
```

- 携带 `preview=1` 且当前用户在配置的 `previewUsers` 里 → 返回**草稿版本**
- 否则返回已发布版本

这样配置管理员可以在真实环境里验证草稿，其他人不受影响。成本远低于百分比灰度，覆盖了主要场景。

若将来需要真灰度，扩展点是 `page_schema` 加 `rollout` 字段（`{ percent, appWhitelist, userWhitelist }`），运行时按用户 id 哈希判定。**本期不做，但表设计要留字段位置。**

## 6. 前端缓存与失效

| 层 | 策略 |
|---|---|
| 运行时 schema | 按 `(app, keyword)` 缓存，TTL 5 分钟；`version` 变化即失效 |
| 编译产物 `Compiled` | key = `schemaId:version:permissionFingerprint`（权限指纹见 [10](10-权限模型.md) §4） |
| 预取的外键字典 | 单次 `compile()` 作用域内的 `store`，不跨编译共享 |

**版本号必须参与缓存 key**，否则发布新配置后老用户要等 TTL 过期才生效。

发布后主动失效：暂不做服务端推送，靠 TTL + 页面刷新。若后续需要，可在 `runtime` 响应头带 `X-Schema-Version`，前端轮询比对。

## 7. 配置写权限是新的攻击面

**谁能改 `page_schema`，就能改所有人看到的页面。** 这是引入配置驱动后新增的风险，必须显式管控：

1. 写接口的权限码独立且收紧：`manager:page:schema:create` / `:update` / `:publish` / `:rollback`，**不与页面查看权限混用**
2. 发布操作记录审计日志（`operator` + `comment` + 时间），复用现有 `manager/log` 模块
3. **表达式引擎禁止 `eval`/`new Function`** —— 这是为什么不用 Formily 的 `{{ }}`（`packages/json-schema/src/compiler.ts:26` 是 `new Function` + `with`）。详见 [07](07-联动与表达式.md)
4. `@handler` 只能引用前端已注册的具名函数，**配置无法定义新函数** —— 这是设计上的安全边界，不是限制

## 8. Schema 演进与兼容

`ModelSchema` 顶层有 `version: 1`（协议版本，不是配置版本号）。协议升级时：

- **只做加法**：新增可选字段，旧配置继续可用
- 必须破坏兼容时，`version` 升到 2，编译器保留 `migrateV1ToV2()` 转换函数，加载时按 `version` 分派
- **禁止静默改变已有字段的语义** —— 那会让线上配置行为悄悄变化

参考 alien-form 的做法（`migrate.ts:19-29`）：它的 schema 演进也只做加法（`PRAGMA table_info` 比对后 `ALTER TABLE ADD COLUMN`），改类型/删列/重命名都不处理。这个保守策略是对的。

## 9. 与 JSON Schema 元校验的关系

`validate.ts` 的 JSON Schema 必须与 `types.ts` 同源生成（见 [11](11-错误与可观测.md) §3）。

**服务端也要校验**：`POST`/`PUT` 时用同一份 JSON Schema 拦一道，避免非法配置入库。Go 侧可用 `santhosh-tekuri/jsonschema`，或简化为「前端校验 + 后端只做基础结构校验（是合法 JSON、有必需字段）」。

倾向后者：**前端是唯一的 schema 语义权威**，后端只做存储和基础结构守卫，避免两处维护语义。
