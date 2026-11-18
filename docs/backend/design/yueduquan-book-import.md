# 阅读圈分类资源加工流水线技术方案

> 历史方案提示：本文描述的是基于 `server/psou/tmp/bookpipe` 的离线批处理工具，不参与当前 cron 主链实现。当前书籍站内导入方案以 `docs/backend/design/book-import-chain.md` 为准；本文仅保留广告注入、repack、离线断点恢复等背景设计。
> 状态：待确认，尚未开始实现和批量执行
> 日期：2026-11-04
> 范围：把已经转存到 `/tmp_xiaoshuo/{分类 slug}` 的书籍资源，加工并发布到 `/psou/manual/书籍/{分类中文名称}/`
> 关联工具：`server/psou/tmp/catalogtransfer/main.go`

## 1. 结论

采用一个独立的离线命令工具 `bookpipe`，按状态机分阶段执行：

```text
转存 -> 解压 -> 生成文件清单 -> 规则过滤 -> 组织发布目录 -> 注入广告 TXT -> 再次压缩 -> 校验发布
```

核心约束：

1. 只操作本次转存产生的工作副本，不修改源分享。
2. 不调用任何网盘删除接口；过滤项统一移动到隔离目录。
3. 每个阶段完成后立即写台账，进程中断后可从最近的稳定状态继续。
4. 默认不覆盖同名文件、不猜测缺失的 `fs_id`、不把失败项当作成功。
5. 广告模板未提供时，流程停在 `blocked_ad_template`，不生成缺少广告的正式包。
6. 百度与夸克是两条独立执行链；任一平台的排队、限流、失败、重试或断点恢复都不影响另一个平台。

当前 `manhua` 已经有可复用的转存结果，因此实际第一批从 `unpack` 阶段开始，不需要重复转存。

## 2. 当前事实

根据现有 `tmp/yueduquan-transfer/manhua_records.tsv`：

| 项目 | 数量 |
| --- | ---: |
| 成功转存记录 | 409 |
| 去重后的站点书籍 ID | 200 |
| 百度账号 5（zhangke）成功记录 | 205 |
| 夸克账号 3（心地善良的青蛙）成功记录 | 204 |
| 已转存文件 | 409 个 ZIP |
| 已转存总大小 | 14,525,118,129 bytes，约 13.5 GiB |
| 夸克明确违规失败 | 1 条 |
| 迅雷不支持而跳过 | 190 条 |

有 10 个“账号 + 书籍 ID”下存在两条成功记录，例如同一本书的不同分册。默认全部保留，不按书籍 ID 强行去重。

## 3. 总体架构

### 3.1 工具边界

`server/psou/CLAUDE.md` 明确在线 HTTP 服务不新增 `cmd/`、离线转存和批量任务。因此本次工具放在：

```text
server/psou/tmp/bookpipe/
```

它是操作型离线工具，不新增在线 HTTP 路由，也不把批量任务挂到在线服务启动流程。

建议复用的现有实现：

| 能力 | 复用位置 |
| --- | --- |
| 转存、账号加载、TSV 记录 | `server/psou/tmp/catalogtransfer/main.go` |
| 文件名/扩展名/大小过滤规则 | `server/psou_bak_20261028_030143/internal/adclean/plan.go` |
| 广告规则关键词和名称清洗 | `server/psou_bak_20261028_030143/internal/adclean/rules.go` |
| checkpoint、TSV 审计 | `server/psou_bak_20261028_030143/cmd/queryreorgmove/` |
| 百度精确移动 | `server/psou_bak_20261028_030143/internal/infra/apis/baidu_adclean.go` |
| 在线解压 | `server/psou/internal/infra/apis/{baidu_files.go,quark_files.go}` |

### 3.2 处理粒度

资源唯一键：

```text
account_id + record_id
record_id = book_id:download_id
```

同一站点资源可能同时转存到百度和夸克，因此两个账号分别形成独立任务、独立目标目录和独立台账。不同平台从预检到发布的全部阶段都并发执行，不设置跨平台的阶段栏栅或全局队列。

同一平台内，单条记录按“解压 -> 过滤 -> 注入 -> 压缩”顺序执行；同一平台的不同记录可以并发，平台各自的并发上限只约束本平台。

### 3.3 平台隔离原则

平台隔离是整条流水线的固定约束，不只针对转存：

1. 百度、夸克分别启动独立的 platform runner，各自维护工作队列、并发信号量、重试次数和 checkpoint。
2. 不存在“等待两个平台都完成解压，再一起过滤”的阶段同步点；每条记录可以在任一平台内独立向后推进。
3. 百度失败、限流或等待人工处理时，夸克继续执行；反过来同样成立。
4. 一个平台的用户级锁、文件锁、临时磁盘配额或任务调度不能阻塞另一个平台。
5. 某平台能力探测失败时，只把该平台记录标记为 `blocked_capability`，另一个平台照常运行。
6. 分类级总进度只是两个平台进度的汇总视图，不参与任务调度。

### 3.4 命令形态

一个二进制，按阶段拆子命令，便于先单步验收再全量恢复执行：

```text
bookpipe transfer  --category manhua --accounts 5,3
bookpipe unpack    --category manhua --accounts 5,3
bookpipe inventory --category manhua
bookpipe filter    --category manhua
bookpipe organize  --category manhua
bookpipe inject    --category manhua --ad-template ./ad.txt
bookpipe repack    --category manhua
bookpipe verify    --category manhua
bookpipe run       --category manhua --through publish
```

如果希望保留“转存 + 解压一个命令”的操作习惯，提供 `bookpipe ingest` 作为 `transfer` 与 `unpack` 的组合别名；内部仍分别落状态，不能把两步做成不可恢复的单事务。

`bookpipe run --accounts 5,3` 在同一个进程内并发启动两个 platform runner；也可以分别执行 `--accounts 5` 和 `--accounts 3`，两者之间不共享锁。

## 4. 目录模型

以下 `{slug}` 是分类英文标识，例如 `manhua`；`{category_name}` 是分类中文名称，例如 `漫画绘本`；`{book_key}` 默认是 `{book_id}-{download_id}`。

### 4.1 网盘工作目录

```text
源目录       /tmp_xiaoshuo/{slug}
解压目录     /tmp_xiaoshuo/_work/{slug}/{platform}-{account_id}/{book_key}/
隔离目录     /tmp_xiaoshuo/_quarantine/{slug}/{platform}-{account_id}/{book_key}/{rule_name}/...
发布暂存目录 /tmp_xiaoshuo/_publish/{slug}/{platform}-{account_id}/{book_key}/{safe_title}/...
最终目录     /psou/manual/书籍/{category_name}/
```

说明：

1. 现有 ZIP 不移动，只作为解压来源保留在原目录。
2. 每条记录创建独立解压目录，避免几百个 ZIP 同目录解压时互相覆盖。
3. `_work`、`_quarantine`、`_publish` 都位于 `/tmp_xiaoshuo` 下，并按平台和账号再次分区；即使百度、夸克并发处理同一本书，也不会共享工作目录。
4. 最终目录只接收校验通过的 ZIP，不把未过滤或未注入广告的中间目录写进去。
5. `{safe_title}` 需要去掉 `/`、`\\`、控制字符和平台非法字符，并限制名称长度。

### 4.2 最终文件布局

默认每个成功转存记录生成一个 ZIP，直接放在分类目录下：

```text
/psou/manual/书籍/漫画绘本/书名.zip
/psou/manual/书籍/漫画绘本/书名__208-7868.zip   # 仅同名冲突时使用
```

ZIP 内部默认结构：

```text
书名/
  正文或图片等保留文件...
  广告.txt
```

同一本书有多条成功下载记录时，默认每条记录各生成一个 ZIP；如果标题和内容完全一致，只在台账标记 `duplicate_candidate`，不自动丢弃。

## 5. 分阶段设计

### 5.1 预检

在产生任何远端写入前检查：

1. 账号存在、状态正常，平台与台账一致。
2. 账号具备在线解压能力；当前在线服务要求 `ext.isVip=true`。
3. 解析 `/tmp_xiaoshuo`、分类目录和账号 `manual` 通路目录。
4. 解析并创建需要使用的 `_work`、`_quarantine`、`_publish` 目录。
5. 确认百度移动能力可用。
6. 确认夸克移动能力可用；不可用时夸克记录直接阻断，不回退到“删除后重建”。
7. 确认在线压缩能力；不可用时按配置决定是否允许“下载 -> 本地打包 -> 上传”的兜底。
8. 检查目标分类目录写权限和剩余空间。

预检按平台分别执行。百度预检失败只阻断百度 runner，夸克预检继续并在自己的队列中运行；任何平台都不等待另一个平台的预检结果。

### 5.2 转存

当前 `manhua` 已完成后默认跳过。其他分类复用现有 `catalogtransfer` 逻辑：

1. 创建 `/tmp_xiaoshuo/{slug}`。
2. 百度账号 5 和夸克账号 3 各自启动转存队列并立即并发执行，不能按平台串行处理。
3. 以 `account_id + record_id` 做幂等，已有成功记录直接复用。
4. 每个落地文件记录 `fs_id`、文件名、大小和目标目录。

### 5.3 解压

对每条成功转存记录：

1. 创建 `/tmp_xiaoshuo/_work/{slug}/{platform}-{account_id}/{book_key}/` 作为本记录的稳定解压根目录。
2. 每个压缩包解压到独立的 `archive-01/`、`archive-02/` 子目录，避免多包同名冲突。
3. 调用现有 `PanClient.Unzip`；百度 `ParentRef`、夸克 `to_pdir_fid` 都指向该子目录。
4. 如果一条记录落地多个压缩包，全部解压到同一记录根目录下的不同子目录。
5. 如果发现嵌套压缩包，默认最多递归 2 层；超过上限标记 `nested_too_deep`，不删除。
6. 如果落地项本身是普通文件或目录，直接登记为待处理内容。
7. 解压后重新列举目录，取得并记录 `unpack_dir_fs_id`；不能只信任异步任务返回值。
8. 目录为空或解压失败时标记 `unpack_failed`，保留源 ZIP。

本阶段不移动、不删除源 ZIP。

解压同样按平台独立推进；百度记录进入解压时，夸克不等待百度解压完成，任何平台的解压重试也只占用本平台 worker。

### 5.4 文件清单

递归列举解压目录，生成文件级清单：

1. 记录 `fs_id`、父目录 `fs_id`、相对路径、名称、扩展名、大小、是否目录。
2. 按相对路径稳定排序，便于计划复核和断点校验。
3. 把清单写入本地 JSONL，TSV 只保留摘要和引用，避免大文件清单反复写表。
4. 空目录、0 字节文件也进入清单，后续由过滤规则处理。

### 5.5 过滤

复用备份里的 `adclean.PlanFile` 和 `adclean.PlanDirectory`。现有规则依据“名称 + 扩展名 + 大小”，不读取 EPUB/PDF/ZIP 内部正文；本方案不把它描述成内容级审查。

动作映射：

| 现有规则动作 | 新流水线动作 |
| --- | --- |
| `delete` | 移动到 `_quarantine/.../{rule_name}/`，绝不删除 |
| `review` | 默认保留并标记 `review_pending`；不阻断整本书 |
| `rename` | 默认不执行，保留原名并写 `rename_candidate`；是否允许改名由用户确认 |
| `protect` | 原样保留 |
| 系统垃圾文件 | 移动到 `_quarantine/.../junk/` |

默认过滤原则：

1. 高置信度广告载体移入隔离区。
2. 不确定项保留，避免误伤正文。
3. 隔离区名称加上原 `fs_id` 前缀，确保同名文件不覆盖。
4. 目录级规则命中时也只移动，不做递归删除。
5. 每个动作记录命中规则、原因、源路径、目标路径和结果 `fs_id`。

过滤、组织、广告注入和压缩都沿用平台独立队列。一个平台进入压缩时，另一个平台仍可以处于解压或过滤阶段，不要求阶段对齐。

### 5.6 组织发布目录

1. 在 `_publish` 下创建 `{safe_title}` 目录。
2. 把过滤后保留的文件/目录移动到该目录，保持原有相对层级。
3. 同名冲突使用稳定后缀 `__f{fs_id后8位}`，不覆盖。
4. 移动后按 `fs_id` 重新查询落点，确认成功。
5. 没有被保留文件的记录标记 `empty_after_filter`，不进入广告和压缩阶段。

### 5.7 广告注入

模板和文件名由参数提供，不硬编码：

```text
--ad-template /path/to/ad-template.txt
--ad-filename 广告.txt
```

建议模板占位符：

```text
{{book_title}}
{{book_id}}
{{record_id}}
{{category_slug}}
{{category_name}}
{{published_at}}
```

执行规则：

1. 读取模板并渲染到内存，校验非空和编码。
2. 上传到发布暂存目录的 `{safe_title}/` 下。
3. 同名广告文件存在时先比较内容哈希：相同则复用，不同则阻断，不覆盖。
4. 模板缺失、占位符非法或上传失败时标记 `blocked_ad_template` / `inject_failed`，默认不进入压缩发布。
5. 广告 TXT 默认只放一份在 ZIP 内书籍目录根部；如果要求每个子目录都放一份，需要单独确认。

### 5.8 再次压缩

目标：每个成功记录生成一个 ZIP，写入 `/psou/manual/书籍/{category_name}/`。

优先方案是平台在线压缩。现有 `PanClient` 没有压缩能力，实施前必须先完成能力探测；百度、夸克分别验证，不根据旧文档猜测接口。

如果平台没有稳定在线压缩接口，允许降级为：

```text
云端下载保留文件 -> 本地临时 ZIP -> 上传到目标分类目录 -> 校验
```

兜底模式的特点：

1. 云端源文件不删除。
2. 本地临时文件只在本机清理，不属于网盘删除。
3. 按单文件流式处理，避免 14.5 GiB 同时落盘。
4. 必须记录本地临时目录、下载大小、SHA256、上传 `fs_id`。

压缩完成后校验：

1. ZIP 文件存在且大小大于 0。
2. `fs_id` 与台账一致。
3. ZIP 内包含书籍目录和广告 TXT。
4. 同名已存在时，如果台账证明是同一记录的重跑则复用；否则追加 `__{book_id}-{download_id}`，不覆盖。

### 5.9 发布校验

每条记录完成前检查：

1. 最终目标目录 `fs_id` 可解析。
2. 最终 ZIP `fs_id`、名称、大小与台账一致。
3. 至少有一个正文文件。
4. 广告注入状态是 `succeeded`。
5. 没有调用删除接口。
6. 源 ZIP、解压目录和隔离目录仍可按台账追溯。

只有通过校验的记录才标记 `published`。

## 6. 状态机与断点恢复

记录级状态：

```text
discovered
  -> transferred
  -> unpacking
  -> unpacked
  -> inventoried
  -> filtered
  -> organized
  -> injected
  -> repacked
  -> verified
  -> published
```

终止或阻断状态：

```text
transfer_failed
unpack_failed
empty_after_filter
blocked_ad_template
inject_failed
repack_failed
verify_failed
blocked_capability
needs_manual_review
```

每次状态迁移必须在远端动作验证成功后落盘。重跑时：

1. 已完成且输入 `fs_id`、路径、大小未变化的记录直接跳过。
2. 中间状态从最后一个已验证阶段继续。
3. 台账记录存在但远端对象缺失时标记 `state_mismatch`，不自动重建或删除。
4. 本地锁粒度为 `{slug}/{platform}-{account_id}`；不同平台可以同时运行，同一平台同一账号不能重复执行。
5. 所有状态写入采用临时文件 + rename 的原子替换；事件流使用追加写并 `fsync`。

## 7. 台账设计

默认按平台和账号分区，避免并发写同一 TSV：

```text
tmp/yueduquan-transfer/import/{slug}/{platform}-{account_id}/
```

如需分类汇总，可另生成只读的 `summary.tsv`，由各平台 runner 的最终结果汇总；汇总文件不参与调度，也不作为另一个平台继续执行的前置条件。

### 7.1 记录级 TSV：`records.tsv`

```text
run_id
record_id
category_slug
category_name
book_id
book_title
account_id
account_platform
account_remark
source_fs_id
source_name
source_path
source_size
work_dir_path
work_dir_fs_id
publish_dir_path
publish_dir_fs_id
final_zip_name
final_zip_fs_id
final_zip_size
kept_files
quarantined_files
review_files
ad_txt_fs_id
ad_sha256
status
error
started_at
updated_at
```

### 7.2 文件级 TSV：`files.tsv`

```text
run_id
record_id
account_id
source_fs_id
parent_fs_id
source_path
name
ext
size
is_dir
action
rule
reason
proposed_name
target_path
target_fs_id
status
error
updated_at
```

`action` 固定为：

```text
keep
quarantine
rename
review
skip
```

### 7.3 事件流：`events.jsonl`

每个阶段开始、成功、失败、重试都追加一条：

```text
run_id, record_id, stage, attempt, status, input_fingerprint, started_at, finished_at, error
```

### 7.4 计划文件

`filter`、`organize`、`repack` 先生成计划 JSONL，执行前计算 SHA256。全量执行必须带 `--confirm-sha`，防止扫描后规则或清单变化却被直接执行。

## 8. 平台能力与实现风险

### 8.1 百度

高置信度可复用：

1. 精确移动已验证可用：`filemanager?opera=move`。
2. 在线解压已有实现。
3. 上传 TXT 已有实现。

需要在离线工具中增加统一移动适配，并保留两条保护：

1. 移动前按 `fs_id` 检查源路径和大小。
2. 移动后按 `fs_id` 检查目标落点，拒绝覆盖同名项。

### 8.2 夸克

当前仓库没有通用移动和压缩实现。已知删除、重命名、解压、上传存在。

必须先做能力探测：

1. 在夸克账号 3 的唯一测试目录中移动一个小文件，确认 `fs_id` 不变且落点正确。
2. 测试目录移动是否支持。
3. 测试在线压缩 API 是否可用。
4. 测试结果不通过时，夸克记录标记 `blocked_capability`，不伪造成功。

夸克不能退化为“下载 -> 删除 -> 重传”，因为这违反不删除约束，也会丢失原 `fs_id` 追溯关系。

### 8.3 压缩

这是第二个必须先探测的能力。现有代码只有解压，没有压缩。若两个平台都不支持在线压缩，只能使用下载、本地打包、上传的兜底方案，这会影响耗时、带宽和服务器临时磁盘需求，需要用户明确授权。

### 8.4 解压限制

现有在线服务入口要求账号 `ext.isVip=true`。离线工具虽然绕过 HTTP 层，也必须显式检查 VIP 能力，否则会在批量中期大量失败。

### 8.5 限流和重试

1. 网络错误、429、平台临时任务失败：指数退避重试，默认 3 次；重试队列按平台隔离。
2. 登录失效、违规、空间不足、非 VIP：不重试，直接阻断。
3. 同一资源内严格串行，避免并发移动同一目录。
4. 百度与夸克 platform runner 同时启动；平台内部默认每个账号并发 2 条记录，参数可调。
5. 任一平台到达重试退避或人工阻断状态时，只暂停该平台对应记录，不暂停另一个平台。

## 9. 并发与执行策略

```text
分类级：可并发
平台级：百度与夸克独立 runner，始终并发，无全局栏栅
账号级：同一平台内按账号并发，平台之间互不共享信号量
记录级：可并发，受所属平台账号的信号量限制
单条记录内部：严格顺序
文件动作：同一目录内串行
```

调度器不得实现 `allPlatformsFinished(stage)` 一类等待条件。平台 runner 的状态机各自推进，分类汇总只做只读聚合。

`manhua` 第一批建议按平台分别放量：

1. 百度账号 5、夸克账号 3 各取 1 条记录做全链路 canary。
2. 两个 canary 可以同时执行，各自独立人工检查最终 ZIP、广告 TXT、隔离区、台账。
3. 哪个平台的 canary 先通过，哪个平台就先跑自己的全量；不得等待另一个平台 canary 通过。

## 10. 安全与审计

1. Token 不进入日志、TSV、错误信息或命令输出。
2. 所有远端写入前后都按 `fs_id` 校验。
3. 工具内部封装 `MoveOnly` 网关，代码层面禁止调用 `DeleteEntry`、`Delete`、`DeletePaced`。
4. 路径只允许落在已配置的源根、工作根、隔离根和目标根下，拒绝 `/`、相对路径和 `..`。
5. ZIP 递归深度、单记录解压总量和文件数设上限，防止压缩炸弹。
6. 操作日志保留原 `fs_id` 和最终 `fs_id`，便于版权审计和重复文件追踪。

## 11. 验收标准

### 11.1 功能验收

1. 任一成功记录可从 `transferred` 自动推进到 `published`。
2. 最终 ZIP 位于 `/psou/manual/书籍/{category_name}/`。
3. ZIP 内有书籍目录、正文文件和广告 TXT。
4. 隔离文件位于 `_quarantine`，`fs_id` 可追溯。
5. 原 ZIP、`_work`、`_publish` 均未删除。

### 11.2 数据验收

对每个分类应满足：

```text
成功转存记录数
= published + skipped + blocked + failed + needs_manual_review
```

每个状态都能在 `records.tsv` 和 `events.jsonl` 中找到原因。

### 11.3 幂等验收

1. `published` 记录重跑不重复创建 ZIP。
2. 中断在任意阶段后重跑，不从已经完成的阶段重新开始。
3. 同名目标存在时没有覆盖。
4. 重跑前后 `fs_id` 和最终路径一致。
5. 百度、夸克同时启动后，两边都能在另一个平台尚未完成当前阶段时继续向后推进或独立重试。

## 12. 实施顺序

### 阶段 A：能力探测

1. 百度、夸克分别并发验证账号 VIP/解压、移动和在线压缩能力。
2. 每个平台只使用自己的唯一测试目录和单条 canary 记录，不跑全量。
3. 一个平台能力通过后即可进入自己的全链路 canary，不等待另一个平台。
4. 一个平台能力失败时只阻断该平台；是否允许下载/上传兜底也按平台单独确认。

### 阶段 B：工具骨架

1. 建 `bookpipe`、状态机、TSV 台账、文件锁和 dry-run。
2. 接入解压、清单和过滤计划；只生成计划，不执行移动。
3. 输出计划摘要和 SHA256 供确认。

### 阶段 C：单条全链路

1. 百度、夸克各跑一条，并行执行。
2. 每个平台分别生成广告、压缩、发布并人工验收。
3. 每个平台分别修正规则、路径和台账，不把另一个平台的阻塞作为前置条件。

### 阶段 D：`manhua` 全量

1. 每个平台在自己的 canary 通过后，分别执行自己的解压和过滤计划。
2. 每个平台分别确认数量、隔离项和失败项。
3. 某个平台确认后即可执行该平台的组织、广告、压缩和发布，不等待另一个平台。

### 阶段 E：其余分类

按分类并发执行；每个分类内再按平台拆成独立 runner，每个 `{slug}/{platform}-{account_id}` 使用自己的目录、台账、锁和 run_id，互不共享状态。

## 13. 需要用户确认

以下选项已有默认值；没有异议即按默认值实施：

1. **目标根路径**：默认 `/psou/manual/书籍/{分类中文名称}/`。确认 `**manual` 是表达省略前缀，而不是字面目录名 `**manual`。
2. **最终布局**：默认每个成功下载记录一个 ZIP，直接放在分类目录下；ZIP 内顶层是 `{书名}/`。是否改为“分类下每本书一个子目录”？
3. **同名与重复资源**：默认保留全部成功记录；同名时追加 `__{book_id}-{download_id}`，完全相同的内容只标记 `duplicate_candidate`，不自动丢弃。
4. **是否允许重命名**：默认严格执行“只移动”，过滤规则给出的 `rename` 只登记、不执行。是否允许在移动时顺带清洗广告文件名/目录名？
5. **广告 TXT**：请提供模板和固定文件名，并确认只放在 ZIP 内书籍根目录，还是每个子目录都放一份。默认文件名参数为 `广告.txt`，广告模板就绪前流程阻断。
6. **压缩兜底**：如果百度或夸克没有稳定在线压缩接口，是否允许“云端下载 -> 本地打包 -> 上传”；云端源文件仍保留，不删除。
7. **平台独立策略**：确认所有阶段百度、夸克均独立并发，任一平台失败、限流或等待不会阻塞另一个平台。
8. **夸克能力不足时的策略**：默认把夸克记录标记为 `blocked_capability`，继续处理百度，不为了“跑完”而降级为删除后重建。

