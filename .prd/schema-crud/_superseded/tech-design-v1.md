# admin-web CRUD JSON 渲染引擎 — 技术设计

> 状态：**已确认**（2026-08-31），§13 三项决策已锁定，进入开发。
> 目标产物：`src/schema-crud/` 一套编译器 + 一个通用页壳，让新增后台管理页从"写 300 行 .vue"变成"写一份 JSON"。
> 关联代码库：`web/admin-web`（前端引擎）、`server/manager`（P3 阶段的 `page_schema` 表）。

---

## 1. Context

### 1.1 为什么做

`web/admin-web` 现有 85 个 view / 21928 行，其中 **49 个页面使用 `useTable`，40 个是同一个模板的复制粘贴**。差异只有五处：`apiFn`、`searchItems`、`columnsFactory`、`formItems`、`operationItems`。

统计证据（全量扫描 `src/views/`）：

| 指标 | 数值 |
|---|---|
| `useTable` 页面 | 49 |
| `handleSearch` 完全相同 | 40 / 45 |
| `handleSubmit` 完全相同 | 38 / 40 |
| 列定义总数 | 316（平均 6.6 列/页） |
| `formatter` 中时间格式化 | 75 / 86 = 87% |
| `rules` 为 `{required, message, trigger}` 三件套 | ~157 / 156 处 ≈ 99% |
| `popConfirm` 分布 | 47 个文件各恰好 1 个（全是删除） |
| componentMap 24 种类型实际用到 | 13 种 |

目标：新增 App 或新增管理模块时，在线配置 JSON 即可出页面，一套代码管理多个 App。

### 1.2 后端已就绪的部分

`server/manager/internal/domain/entity/` 已有多 App 元数据模型：`app.go`（`type: base|app` + `Modules` 订阅）、`menu.go`（按 app 隔离，下发 `component` + `permission`）、`field.go` + `field_config.go`、`form_schema.go`（`UserForm`，带 `version` + 草稿/发布）、`entity.go`（可 `LoadEntity` 反射数据库表结构）。对应 `api/field`、`api/form`、`api/entity` proto 已生成。

### 1.3 前端已就绪的部分

- **表单 schema 引擎已上线**：`src/components/core/base/art-form-editor/`（2761 行），设计器 + `FormRenderer` 运行时，生产消费方 `src/views/authorize/fillinfo/index.vue`
- **五个通用组件已是 config 驱动**，不需要重写（见 §2.1）
- **菜单 → 组件路径映射已通**：`src/router/utils/registerRoutes.ts:16` 用 `import.meta.glob('../../views/**/*.vue')`，后端下发 `component: '/generic/crud'` 即可命中通用页壳

**本设计不新建渲染组件树，只新建一个"JSON → 现有组件 props"的编译器。** 这是工作量可控、风险可回滚的根本原因。

---

## 2. 现状事实（设计输入）

### 2.1 组件契约（已逐个读过源码核实）

| 组件 | 驱动 props | 逃生口 | 关键实现细节 |
|---|---|---|---|
| `ArtTable`<br>`tables/art-table/index.vue` | `columns: ColumnOption[]`、`data`、`pagination{current,size,total}`、`loading` | `useSlot`+`slotName` 具名插槽；`formatter(row)` 可返回 VNode | emits `pagination:size-change` / `pagination:current-change`；`ColumnOption` 有 `[key:string]: any` 直通 el-table-column |
| `ArtSearchBar`<br>`forms/art-search-bar/index.vue` | `items: SearchFormItem[]` + v-model | `render` | emits `search` / `reset` |
| `ArtForm`<br>`forms/art-form/index.vue` | `items: FormItem[]` + v-model | `render`；**每项另有具名插槽 `#[item.key]`** | `rules` 取自 `item.props.rules`（模板 `:rules="item.props?.rules"`）；`v-bind="getProps(item)"` 把 `item.props` 整包透传；`getNestedValue` 支持任意深度 `a.b.c` |
| `ArtOperation`<br>`forms/art-operation/index.vue` | `list: OperationItem[]` + `data: row` | `click(row)` 函数 | 内置 `hasPermission()` 过滤 + `popConfirm` 确认；`>2` 项自动折叠 dropdown |
| `ArtTableHeader`<br>`tables/art-table-header/index.vue` | `v-model:columns` + `layout` 逗号串 | `#left` / `#right` | emits `refresh` / `search` |
| `useTable`<br>`composables/useTable.ts` | `{core:{apiFn,apiParams,excludeParams,immediate,columnsFactory,paginationKey}, transform, performance, hooks, debug}` | `apiFn` 是任意函数 | 返回 `columns/columnChecks/data/loading/pagination/searchParams` + `getData/resetSearchParams/handleSizeChange/handleCurrentChange/refreshData/refreshCreate/refreshUpdate/refreshRemove` |

分页字段映射兜底：`src/utils/table/tableConfig.ts` — `recordFields: ['list','data','records','items','result','rows']`、`paginationKey: {current:'page', size:'pageSize'}`。

### 2.2 可直接复用的既有能力

| 复用对象 | 路径 | 用途 |
|---|---|---|
| `evaluateRelation(relation, formData)` | `art-form-editor/lib/relation.ts:10` | **条件求值引擎**，纯函数，13 种算子（`eq/neq/in/notIn/empty/notEmpty/gt/lt/gte/lte/contains/between/pattern`）。直接用于 schema 的 `hiddenWhen`/`disabledWhen`，不必自研表达式引擎 |
| `NodeRelation` 类型 | `art-form-editor/lib/types.ts` | 条件对象的词汇表，与已上线的表单设计器保持一致 |
| `toFormItems(fields)` | `src/router/utils/field.ts` | 后端 `Field` → `FormItem` 的既有转换器（**但有 bug，见 §7**） |
| `tableConfig` 模糊字段匹配 | `src/utils/table/tableConfig.ts` | 接不同后端返回结构 |
| `hasPermission()` | `src/composables/usePermission.ts`、`src/store/modules/menu.ts` | 权限过滤，schema 里放权限码字符串即可 |

⚠️ `evaluateRelation` 用 `formData[relation.field]` **平铺取值**，不支持 `a.b.c`。而项目里有 25 处嵌套 key。编译器需包一层 `getByPath`。

### 2.3 RESTful 约定与例外

标准约定（38/49 页面符合）：列表 `GET /{svc}/api/{res}s`、创建 `POST /{svc}/api/{res}`、更新 `PUT /{svc}/api/{res}`、删除 `DELETE /{svc}/api/{res}`。

**15 类例外**（这是 `apiFn` 必须保留任意函数逃生口的原因）：`/cron/api/v1/task_groups`（版本段 + snake_case）、`/manager/api/form/user-forms`（分组前缀 + kebab-case）、`ListCurrentRole` 无参且无 `total`、`DeleteDeptRole({deptId, roleId})` 复合键、`DeleteFile({ids:[]})` 收数组、`GetEnvToken(id)` 位置参数、`LoadEntity` 动态服务前缀模板串、`PUT /business/values` 批量 upsert、`POST /role/menus` 用 POST 做更新、`listNamespaceTable` 本地包装函数当 apiFn，等。

---

## 3. 方案：编译器，不是渲染器

### 3.1 三个候选方案

| # | 方案 | 评价 |
|---|---|---|
| a | 引入 amis | 成熟，但自带一套组件体系与主题，和 Element Plus + art-design-pro 的样式/暗色主题/i18n 体系冲突，包体积增加显著；48 个既有页面无法渐进迁移 |
| b | 自研 renderer 组件树（照 `FormRenderer` 的路子做 `TableRenderer`） | 重复劳动。`ArtTable`/`ArtSearchBar`/`ArtForm`/`ArtOperation` 已经是数组驱动，再包一层递归渲染器只是把 props 换个名字 |
| c | **编译器 + 一个通用页壳**（选定） | JSON → 现有组件 props。改动面最小，风险可逐页回滚，样式/主题/权限全部自动继承 |

### 3.2 数据流

```
后端 page_schema 表 (JSON)
   ↓  GetPageSchemaByApp({ app, keyword })
compileSchema(json)  ← 校验 + 编译 + 收集错误
   ↓
{ tableConfig, searchItems, columns, formItems, operations, toolbar }
   ↓  普通 props
GenericCrudPage.vue  →  ArtSearchBar + ArtTableHeader + ArtTable + ArtOperation + ElDialog/ArtForm
```

菜单侧接入零改动：后端菜单 `component` 填 `/generic/crud`，`path` 或 `meta` 带 schema key，`registerRoutes.ts` 的 `import.meta.glob` 自动命中 `src/views/generic/crud/index.vue`。

### 3.3 目录结构（新增）

```
src/schema-crud/
├── types.ts          # PageSchema 及子类型定义
├── validate.ts       # JSON Schema 校验 + 错误收集
├── compile/
│   ├── index.ts      # compileSchema() 总入口
│   ├── columns.ts    # → ColumnOption[]
│   ├── search.ts     # → SearchFormItem[]
│   ├── form.ts       # → FormItem[]（含 rules 生成、hidden/disabled 求值）
│   ├── actions.ts    # → OperationItem[] + 工具栏按钮
│   └── api.ts        # → apiFn（RESTful 生成器 + registry 查找）
├── registry.ts       # 逃生口注册表
└── presets/
    ├── formatters.ts # datetime / enum / filesize / mapping
    └── slots.ts      # statusSwitch / avatar / image / tag
src/views/generic/crud/index.vue   # 通用页壳
```

---

## 4. PageSchema 设计

### 4.1 顶层结构

```ts
interface PageSchema {
  version: 1
  name: string                    // 页面名（弹窗标题、消息文案的词根）
  api: ApiSpec                     // 见 4.2
  rowKey?: string                  // 默认 'id'
  tree?: boolean                   // true → 不分页 + excludeParams:['page','pageSize']
  paginated?: boolean              // 默认 true；tree=true 时强制 false
  toolbar?: ToolbarItem[]
  search?: SearchItemSchema[]
  columns: ColumnSchema[]
  form?: FormSchema_               // 弹窗表单
  operations?: ActionSchema[]      // 行操作
}
```

### 4.2 ApiSpec — 声明式 + 逃生口

```ts
type ApiSpec =
  | { resource: string; service: string; version?: string; naming?: 'plural'|'snake'|'kebab' }
  | { ref: string }               // 逃生口：registry 中注册的具名 apiFn 集合
  | { list: EndpointSpec; create?: EndpointSpec; update?: EndpointSpec; remove?: EndpointSpec }
```

`{ service:'manager', resource:'role' }` 展开为 `GET /manager/api/roles` + `POST|PUT|DELETE /manager/api/role`，覆盖 38/49 页面。剩余 11 个用 `{ref}` 或显式 `EndpointSpec`。

### 4.3 ColumnSchema

```ts
interface ColumnSchema {
  prop?: string
  label: string
  width?: number | string
  minWidth?: number | string
  sortable?: boolean
  index?: boolean                 // → { type:'index', width:'60', label:'#' }
  selection?: boolean             // → { type:'selection' }
  format?: FormatSpec             // 替代 formatter 函数
  slot?: SlotSpec                 // 替代 useSlot + slotName
}

type FormatSpec =
  | 'datetime' | 'date' | 'filesize'
  | { type: 'enum'; options: OptionsSource }     // 枚举查表，替代 87%+8% 的 formatter
  | { type: 'ref'; name: string }                // 逃生口 → registry.formatters

type SlotSpec =
  | { type: 'statusSwitch'; api?: EndpointSpec; confirm?: string; permission?: string }
  | { type: 'avatar'; size?: number }
  | { type: 'image'; width?: number; previewable?: boolean }
  | { type: 'tag'; options: OptionsSource }
  | { type: 'ref'; name: string }                // 逃生口 → registry.slots
```

覆盖度依据：`formatter` 86 处 = 时间 77 + 枚举查表 7 + 单位换算 1 + VNode 1；非 operation 插槽 = 开关 14 + 头像 10 + 图片 6 + 标签 6 + 纯文本 6。前四种预设吃掉 36/48。

### 4.4 OptionsSource — options 的三种来源

```ts
type OptionsSource =
  | Array<{ label: string; value: any }>                        // 字面量，16 处
  | { api: EndpointSpec; labelField?: string; valueField?: string; remote?: boolean }  // 接口，21 处
  | { from: 'self' }                                            // 引用本表格 data（自引用树，4 处）
```

`{from:'self'}` 专门解决 `data: [{ id:0, name:'顶级部门', children: data.value }]` 这个模式（`manager/dept`、`manager/role`、`manager/app/menu`、`recipe/recipe/classify`）。

### 4.5 FormSchema_ — 弹窗表单

```ts
interface FormSchema_ {
  width?: string                  // 默认 '480px'
  span?: number
  jsonFields?: string[]           // 声明哪些字段是 JSON 字符串，壳层自动 parse/stringify
  items: FormItemSchema[]
}

interface FormItemSchema {
  key: string                     // 支持 'setting.jwt.secret' 三层嵌套
  label: string
  type: FormItemType              // 限定在实际用到的 13 种
  tip?: string
  span?: number
  divider?: string
  defaultValue?: any
  placeholder?: string
  options?: OptionsSource
  required?: boolean              // → 自动生成 {required, message:`请输入${label}`, trigger:['blur','change']}
  pattern?: 'identifier' | 'url' | 'email' | string
  props?: Record<string, any>     // 直通 ArtForm 的 props
  hiddenWhen?: Condition | Condition[]
  disabledWhen?: Condition | Condition[] | 'edit'   // 'edit' 是 14 处 dialogType==='edit' 的简写
  logic?: 'and' | 'or'
}

// 复用 art-form-editor/lib/types.ts 的 NodeRelation 词汇
interface Condition {
  field: string
  condition: 'eq'|'neq'|'in'|'notIn'|'empty'|'notEmpty'|'gt'|'lt'|'gte'|'lte'|'contains'|'between'|'pattern'
  value?: any
}
```

`FormItemType` 白名单：`input | textarea | select | number | upload | treeselect | radiogroup | code | rich | icon | slider | inputtag | sqlbuilder`（实测用到的 13 种，`textarea` 编译为 `type:'input'` + `props.type:'textarea'`）。

`hiddenWhen` 求值直接调 `evaluateRelation()`，外包一层 `getByPath` 支持嵌套 key。

### 4.6 ActionSchema — 行操作 10 类归并为 6 类声明 + 1 逃生口

```ts
type ActionSchema = {
  label: string
  icon?: string
  color?: 'primary'|'warning'|'danger'|'success'|'info'
  permission?: string
  confirm?: boolean | string      // → popConfirm + popTitle
  hiddenWhen?: Condition | Condition[]   // 按行数据求值（现有代码缺失的能力，见 §7）
} & (
  | { do: 'edit' }                                    // 36 处
  | { do: 'edit'; prefetch: EndpointSpec }            // 6 处：先 GetXxx 再开弹窗
  | { do: 'delete'; api?: EndpointSpec }              // 47 处
  | { do: 'addChild'; parentKey?: string }            // 3 处：树形新增子节点
  | { do: 'navigate'; to: string; query?: Record<string,string> }  // 8 处 router.push
  | { do: 'request'; api: EndpointSpec; refresh?: 'data'|'update'|'none'; message?: string }  // 3 处动作接口
  | { do: 'download'; urlRef: string }                // 2 处
  | { do: 'ref'; name: string }                       // 逃生口：drawer 8 处、ref.show 1 处、clipboard 1 处
)
```

`query` 支持 `{ app: '$row.keyword' }` 这类行字段引用，覆盖 `manager/app/index.vue` 的 4 个跳转。

### 4.7 ToolbarItem

```ts
type ToolbarItem =
  | { type: 'create'; label?: string; permission?: string }              // 41 处
  | { type: 'navigate'; label: string; to: string; permission?: string } // 11 处
  | { type: 'exportSelected'; api: EndpointSpec; permission?: string }   // 1 处
  | { type: 'ref'; name: string }
```

### 4.8 完整示例 — `cron/task/group.vue`（94 行 → 约 40 行 JSON）

```json
{
  "version": 1,
  "name": "任务分组",
  "api": { "service": "cron", "resource": "task_group", "version": "v1", "naming": "snake" },
  "toolbar": [{ "type": "create", "permission": "cron:task:group:add" }],
  "search": [{ "key": "name", "label": "分组名称", "type": "input", "placeholder": "请输入分组名称" }],
  "columns": [
    { "index": true },
    { "prop": "name", "label": "分组名称" },
    { "prop": "description", "label": "分组描述" },
    { "prop": "createdAt", "label": "创建时间", "sortable": true, "format": "datetime" },
    { "label": "操作", "width": 120 }
  ],
  "form": {
    "items": [
      { "key": "name", "label": "分组名称", "type": "input", "required": true },
      { "key": "description", "label": "分组描述", "type": "textarea", "required": true }
    ]
  },
  "operations": [
    { "label": "修改分组", "do": "edit", "color": "warning", "permission": "cron:task:group:update" },
    { "label": "删除分组", "do": "delete", "color": "danger", "confirm": true, "permission": "cron:task:group:delete" }
  ]
}
```

---

## 5. 逃生口设计（方案能否长期存活的关键）

统计显示 49 个页面里 9 个无法用通用 schema 表达。**不留逃生口，这 9 个页面就会逼着修改公共 renderer，风险比改单页面大得多。**

```ts
// src/schema-crud/registry.ts
export const registry = {
  formatters: {} as Record<string, (row: any) => any>,        // 返回 string 或 VNode
  slots:      {} as Record<string, Component>,                // 列插槽自定义组件
  actions:    {} as Record<string, (row: any, ctx: CrudCtx) => void | Promise<void>>,
  apis:       {} as Record<string, ApiFnSet>                  // { list, create, update, remove }
}
export function registerCrud(ns: string, defs: Partial<typeof registry>): void
```

`CrudCtx` 暴露给 action 的能力：`{ row, refresh: {data,create,update,remove}, openDialog, closeDialog, router, message }`。

三条使用原则：

1. **注册表按页面命名空间隔离**：`registerCrud('manager.role', {...})`，schema 里写 `{ do:'ref', name:'manager.role.menuTree' }`
2. **9 个特殊页面可以完全不迁移**：卡片网格 3 个（`manager/app`、`manager/oauther`、`configure/env`）、5 弹窗设计器页（`manager/user-form`）、手写 ElForm 页（`cron/task/index`）等继续走本地 `.vue`，菜单 `component` 指向原路径。混合模式是终态，不是过渡态
3. **主从布局（3 对页面）不进引擎**：`manager/dictionary`、`manager/app/entity`、`resource/file` 的左栏继续手写，右栏可以用引擎（接受 props 驱动 + `watch` 重置 `searchParams`）

---

## 6. 模块拆分与依赖

按依赖顺序（前者先做，后者依赖前者）：

| ID | 模块 | 范围 | 依赖 |
|---|---|---|---|
| **M0** | 修既存缺陷 | `src/router/utils/field.ts`、`art-form/index.vue`、`art-search-bar/index.vue` 的类型名映射与告警 | — |
| **M1** | 类型与校验 | `src/schema-crud/types.ts`、`validate.ts` | — |
| **M2** | 编译器 | `src/schema-crud/compile/*`、`presets/*` | M1 |
| **M3** | 逃生口注册表 | `src/schema-crud/registry.ts` | M1 |
| **M4** | 通用页壳 | `src/views/generic/crud/index.vue` | M2, M3 |
| **M5** | Schema 来源 | 阶段一：`src/schema-crud/local/*.json` + devtools 预览页；阶段二：后端 `page_schema` 表 + proto + 管理页 | M4 |
| **M6** | 逐页迁移 | 40 个页面，每页独立可回滚 | M5 |

M0 与 M1 可并行。M5 阶段二涉及后端改动（`server/manager`），是独立交付物。

`page_schema` 表设计照抄已验证的 `UserForm`（`server/manager/internal/domain/entity/form_schema.go`）：

```
app        varchar   -- 应用标识，关联 app.keyword
keyword    varchar   -- 页面标识，菜单通过它引用
name       varchar
schema     json      -- PageSchema 完整 JSON
version    uint32    -- 每次保存自增
status     bool      -- false=草稿 true=已发布
```

---

## 7. M0：必须先修的既存缺陷

这些缺陷不修，引擎会继承它们，而且 JSON 驱动下**静默失败比报错危险得多**。

### 7.1 类型名映射不一致（已核实，生产中）

`src/router/utils/field.ts` 的 `toFormItems()` 产出驼峰，`art-form/index.vue:128` 的 `componentMap` 键是全小写，`getComponent()` 第 316 行 `|| componentMap['input']` **静默降级**：

| field.ts 产出 | componentMap 实际键 | 结果 |
|---|---|---|
| `inputNumber` | `number` | ❌ 降级为 ElInput |
| `radioGroup` | `radiogroup` | ❌ |
| `checkboxGroup` | `checkboxgroup` | ❌ |
| `timePicker` | `timepicker` | ❌ |
| `datePicker` | `date` | ❌ |
| `password` | 不存在 | ❌ |
| `input` / `select` / `upload` | 同名 | ✅ |

9 种里 6 种失效。消费方 `src/views/manager/user/index.vue:558` 正在生产使用——后端配的数字/单选/多选/日期/时间/密码字段，现在全渲染成普通文本框。

修法：`componentMap` 查找前做 key 归一化（小写 + 去连字符），补 `password` 与 `textarea` 别名，**未命中时 `console.warn` 而不是静默 fallback**。

### 7.2 日期变体形同虚设（新发现）

`date` / `daterange` / `datetime` / `datetimerange` 四个键都映射到同一个 `ElDatePicker`，但代码里没有任何地方把 `type` 传给它（`art-form/index.vue:137-140`、`art-search-bar/index.vue:134-136`）。写 `type:'daterange'` 得不到范围选择器。

修法：`getProps()` 时按 schema type 推导补上 `props.type`。

### 7.3 迁移会自动消灭的死配置（无需单独修）

| 问题 | 处数 | 位置 |
|---|---|---|
| `:show-button="false"`（ArtForm 无此 prop） | 27 | 各 CRUD 页模板 |
| `suffix` / `suffixTip`（ArtForm 无此渲染） | 5 / 2 | `recipe/*`、`ai-agent/model` |
| `show: (record)=>...`（ArtOperation 只认布尔 `hide`） | 1 | `manager/user-form/index.vue:476` — "发布"按钮对已发布表单也显示 |
| `type:'input-number'`（应为 `number`） | 1 | `configure/template/index.vue:194` |
| `type:'host'` rule（async-validator 无此 type，校验失效） | 1 | `manager/oauther/index.vue:304` |
| `formItems` 写成二维数组（渲染出 2 个空表单项） | 1 | `recipe/recipe/index.vue:235` |
| `cellClassName:'test'` 调试残留 | 1 | `resource/file/file.vue:387` |
| 伪 `computed`（无响应式依赖） | 7 | `configure/business` 等 |

注意 §7.3 第 3 条：`manager/user-form` 想做"按行数据动态显隐按钮"但写坏了。这说明该能力是真实需求 → 已纳入 §4.6 的 `ActionSchema.hiddenWhen`。

---

## 8. 决策确定性与备选方案

| 决策 | 确定性 | 依据 / plan_b |
|---|---|---|
| 编译器方案（而非新渲染器） | **高** | 五个组件的 props 契约已逐个读源码核实，全部是数组/对象驱动 |
| 4 种插槽预设覆盖 36/48 非 operation 插槽 | **高** | 全量统计：开关 14 + 头像 10 + 图片 6 + 标签 6 |
| `format` 声明式替代 `formatter` | **高** | 86 处中 84 处可声明化，仅 1 处 VNode（`manager/app/menu/index.vue:170`）+ 1 处单位换算走 `{type:'ref'}` |
| rules 自动生成 | **高** | 156 处中约 99% 是 `{required,message,trigger}` 三件套；12 处 `pattern` 中 11 处是同一个 identifier 正则 |
| **条件对象 vs 字符串表达式** | 中 | 选结构化 `Condition` 对象，复用 `evaluateRelation()`。53 处 `hidden` 全部形如 `field !== value`，不需要表达式引擎。**可逆性**：结构化对象将来可编译成表达式，反向不成立，所以先选受限的一侧 |
| `ApiSpec` 生成器覆盖 38/49 | 中 | plan_b：`{ref}` 指向 registry 注册的具名 apiFn 集合，逃生口已在 §4.2 设计内 |
| **自引用树 `{from:'self'}`** | 低 | treeselect 的 `data` 引用表格自身 `data.value` 存在时序/循环依赖风险。plan_b：若壳层无法干净表达，这 4 个页面（`manager/dept`、`manager/role`、`manager/app/menu`、`recipe/recipe/classify`）留本地 `.vue` |
| **JSON 字符串字段双向映射** | 低 | `extra` ⇄ `extraObject` 涉及 5 个文件 25 处嵌套 key，边界情况（null / 空串 / 非法 JSON / 提交时字段裁剪）未穷尽。plan_b：`jsonFields` 声明失败则这 5 页留本地 `.vue` |

低确定性项都有明确 plan_b，且 plan_b 都是"退回本地 .vue"——因为混合模式本来就是终态，退回不是失败。

---

## 9. 失败预案

**最大风险：在线改 JSON 写错一个字段 → 整页白屏，且没有调用栈可查。**

对策，按优先级：

1. **JSON Schema 校验**（M1）：保存时校验 + 运行时加载后校验。校验失败**不渲染页面，渲染错误面板**——列出出错的 JSON 路径、期望类型、实际值。绝不白屏
2. **编译期错误收集**：`compileSchema()` 返回 `{ result, errors[] }` 而不是抛异常。单列/单表单项出错只降级该项，其余正常渲染
3. **类型名未命中告警**：见 §7.1，静默 fallback 一律改成 `console.warn` + 错误面板收集
4. **版本 + 草稿/发布 + 回滚**：`page_schema` 表带 `version` 自增和 `status` 草稿态，与已验证的 `UserForm` 一致。改错了能回滚到上一版
5. **预览沙箱**：devtools 下加一个 schema 预览页（参考已有 `src/views/devtools/form-designer.vue` 的做法），发布前可见效果

**演进性（可逆性）**：

- 每个页面独立选择走 schema 或本地 `.vue`，由后端菜单 `component` 字段决定。逐页迁移、逐页回滚，粒度最细
- 引擎不修改现有 48 个页面的代码，M0 之外零侵入
- 技术债风险点：`registry` 里的自定义 action 会逐渐变多。约定每季度盘点一次，出现 3 个以上同形态的 `ref` 就提炼成新的声明式 `do:` 类型

---

## 10. 迁移路径

| 阶段 | 内容 | 回滚方式 |
|---|---|---|
| P0 | M0 修缺陷 | 独立 commit，直接 revert |
| P1 | M1+M2+M3+M4，schema 存 `src/schema-crud/local/*.json`，加 devtools 预览页 | 不接线到任何生产菜单，无影响 |
| P2 | **等价性验证**（见 §11），不通过则回到 P1 调整 schema 设计 | 同上 |
| P3 | M5 后端 `page_schema` 表 + proto + 管理页 | 表新增，不影响既有接口 |
| P4 | M6 逐页迁移，建议顺序：4 个 cron 页（最简）→ 20 个标准 CRUD → 16 个带树/嵌套的 | 每页改回菜单 `component` 指向原 `.vue` 即可 |

**不存在不可逆节点**：任何阶段出问题，把菜单 `component` 指回原路径就恢复原状，原 `.vue` 文件在 P4 全部完成并稳定运行前不删除。

---

## 11. 验证方式

### 11.1 等价性验证（P2 的准入门槛）

选 2 个页面做逐项像素级 + 行为级对照，两个都通过才继续：

| 目标 | 为什么选它 |
|---|---|
| `src/views/cron/task/group.vue`（94 行） | **黄金基线**：全字面量配置、无 computed、无 SCSS。1 个搜索项 / 2 个表单项 / 2 个行操作 / 5 列。跑不通说明方案错了 |
| `src/views/manager/role/index.vue`（355 行） | **压力测试**：恰好覆盖全部难点——status 开关插槽 + `formatTime` formatter + treeselect 自引用表格数据 + `disabled: dialogType==='edit'` + identifier 正则校验 + 5 种行操作（含 `router.push` 和 `menu.value?.show()` 局部子组件）+ `excludeParams` 不分页 + `ListCurrentRole` 无参无 total 的 API 例外 |

对照清单：列渲染/排序/宽度、搜索与重置、分页、新增、编辑、删除确认、状态切换确认、权限码生效（切换无权限账号验证按钮消失）、树层级展开。

### 11.2 运行验证

```bash
cd web/admin-web
pnpm dev            # 起开发服务，访问 devtools 预览页
pnpm build          # vue-tsc --noEmit && vite build，必须零类型错误
pnpm lint           # eslint
```

项目当前无测试框架（`package.json` 无 vitest/jest，无 `*.spec.ts`），本期**不引入**。验证完全依赖：`pnpm build` 的 `vue-tsc` 类型检查、`pnpm lint`、以及 §11.1 两个页面的人工对照。

代价需要知情：编译器的边界情况（嵌套 key 取值、条件求值、API 例外分支）没有自动回归保护。缓解措施——`compileSchema()` 设计成纯函数且返回 `{result, errors[]}`，将来补单测的成本很低；§9 的错误面板承担运行时兜底。

---

## 12. 明确不做

**引擎不实现（现有 49 页面零使用，不要预先支持）**：
`ColumnOption` 的 `checked`/`filters`/`filterMethod`/`align`/`showOverflowTooltip`/`useHeaderSlot`/`type:'expand'`/`type:'globalIndex'`；`span-method`；`summary-method`；行拖拽排序；可编辑单元格；服务端排序（`@sort-change`）；日期类搜索项（componentMap 支持 18 种，实际 0 使用）；`FormItem.render`（0 使用）；`transform.*`；`performance.*`（`TableCache` 全链路是死代码）；`paginationKey`（全靠全局 `tableConfig`）；`hooks.onError/onCacheHit/onLoading`；批量删除；`ArtExcelImport`/`ArtExcelExport`（组件存在但从未被引用）；字典驱动 options（项目无 `useDict` 机制）。

**表单只走 ArtForm，不接 `FormRenderer` 逃生口**（已决策）。数据支持这个选择：动态增删行 0 处、分步表单 0 处、唯一的分组表单（`manager/app/index.vue`）靠 `divider` + `span` 实现而 ArtForm 原生支持，三层嵌套 key 也已被 `getNestedValue` 覆盖。`FormRenderer` 的增量能力（嵌套容器 row/col/card/tabs、子表单重复段、计算字段）在 49 个 CRUD 页面里无人使用。表单复杂到 ArtForm 表达不了的页面，整页留本地 `.vue`。

**不做的范围**：任意页面布局、图表看板、多步向导、流程编排。这类继续写 `.vue`。

---

## 13. 已确认的决策

| 问题 | 决定 |
|---|---|
| 第一阶段 schema 来源 | **本地 JSON 文件** `src/schema-crud/local/*.json` + devtools 预览页；等价性验证通过后再做 P3 后端 `page_schema` 表 |
| 弹窗表单渲染 | **只做 ArtForm**，不保留 `FormRenderer` schema 逃生口；表单过于复杂的页面整页留本地 `.vue` |
| 单元测试 | **本期不引入 vitest**；靠 `pnpm build` 类型检查 + `pnpm lint` + 两个页面人工对照 |

### 首个交付批次（P0 + P1 + P2）

1. **M0** 修 §7.1 类型名映射（含 `console.warn`）与 §7.2 日期 type 推导
2. **M1** `src/schema-crud/types.ts` + `validate.ts`
3. **M2** `src/schema-crud/compile/*` + `presets/*`
4. **M3** `src/schema-crud/registry.ts`
5. **M4** `src/views/generic/crud/index.vue` 通用页壳
6. **M5-a** `src/schema-crud/local/` 放两份 schema + devtools 预览页
7. **P2** 用 `cron/task/group.vue` 与 `manager/role/index.vue` 做等价性对照，通过后再谈后端表与逐页迁移

---

## 附：流程说明

我调用了 `tech-design` skill，但其流程依赖上游产物 `.prd-gen/output/{topic}/prd.yaml` 与 `.code-analyze/output/{topic}/analysis.yaml`——我已确认仓库内这两个目录均不存在；其产出物也需写入 `.tech-design/output/{topic}/`，而当前 plan 模式仅允许我写 plan 文件。

因此本文档借用了该 skill 的设计严谨度（现状扫描 → 全局设计检查 → 决策确定性分级 + plan_b → L0-L3 质量透镜 → 模块拆分 → 迁移路径 → 校验清单），但渲染为可读文档。若你需要 `.tech-design/output/` 那套正式 `design.yaml` + `design.md` 产物，确认后我补生成。
