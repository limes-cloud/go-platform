# 内容数据拉取

> 状态：方案设计
> 日期：2026-11-12
> 范围：文章、图文、视频的作品级和账号级指标；官方 API 拉取、聚合和人工补录
> 关联：`02-adapter-contract.md`、`05-publish.md`、`07-data-model.md`

## 1. 目标与边界

amei 需要知道每条内容在每个平台上的表现，用于判断选题、标题、封面和平台适配质量。

包含：

- 作品级曝光、播放、阅读、互动、收藏、涨粉；
- 视频完播率、平均播放时长（平台提供时）；
- 账号级粉丝和总作品数据（平台提供时）；
- 定时拉取、手动刷新、失败重试；
- 缺失字段、数据来源和新鲜度标记；
- 人工 CSV/JSON 补录。

不包含：

- 非授权抓取、破解后台、逆向私有接口；
- 秒级实时数据；
- 评论正文、私信、粉丝画像；
- 广告归因和跨平台统一用户识别；
- 用 0 代替平台未提供的指标。

## 2. 数据粒度

### 2.1 作品快照

每条记录表示某个 `platformPostId` 在某个统计日期的数据：

```json
{
  "accountId": "pa_1001",
  "contentVersionId": "cv_1001",
  "platformCode": "douyin",
  "platformPostId": "7123456789",
  "statDate": "2026-11-11",
  "source": "official_api",
  "metrics": {
    "impressions": null,
    "plays": 12000,
    "reads": null,
    "likes": 231,
    "comments": 18,
    "shares": 9,
    "favorites": 45,
    "followersDelta": null,
    "completionRate": null,
    "avgWatchTimeMs": null
  },
  "availableFields": ["plays", "likes", "comments", "shares", "favorites"],
  "pulledAt": 1760000000000,
  "rawRef": "metric_raw/2026/11/11/..."
}
```

### 2.2 账号快照

`platformPostId` 为空，记录账号级粉丝、总播放、总互动等；只在平台提供时采集。

### 2.3 累计值与日增量

平台接口通常返回作品累计值，不是日增量：

- `metric_snapshot` 保存接口返回的累计值；
- `metric_daily_delta` 由相邻快照差值计算，负值按 0 处理并标记异常；
- 控制面不得直接把累计值重复累加；
- 如果平台明确返回日粒度，`granularity=day`，无需差分。

## 3. 指标字典

| 字段 | 含义 | 典型平台 |
| --- | --- | --- |
| `impressions` | 曝光/展现 | 视平台能力 |
| `plays` | 播放次数 | 抖音、快手、B 站、视频号 |
| `reads` | 阅读/点击 | 图文、文章、微博 |
| `likes` | 点赞/喜欢 | 全部 |
| `comments` | 评论数 | 全部 |
| `shares` | 分享/转发 | 全部 |
| `favorites` | 收藏 | 部分平台 |
| `followersDelta` | 当日涨粉 | 部分平台账号数据 |
| `completionRate` | 完播率 | 部分视频平台 |
| `avgWatchTimeMs` | 平均观看时长 | 部分视频平台 |

字段为 `null` 表示平台不提供或尚未拉到，不能当成 0。

## 4. 拉取方式

### 4.1 官方 API

控制面调用适配器 `POST /v1/metrics/tasks`。适配器根据平台能力选择：

- 作品列表接口定位平台作品；
- 作品基础信息接口；
- 作品数据接口；
- 账号粉丝/总数据接口。

适配器负责：

- 把平台字段名映射为统一指标；
- 把时间窗口转换为平台参数；
- 处理分页、限流、token 刷新；
- 返回 `availableFields` 和平台原始状态；
- 保留脱敏原始响应摘要用于排障。

### 4.2 手动补录

仅在平台没有公开数据接口、权限未获批，或用户需要导入历史数据时使用。

`POST /amei/api/v1/metrics/import`

```json
{
  "accountId": "pa_1001",
  "platformPostId": "7123456789",
  "statDate": "2026-11-11",
  "metrics": {
    "plays": 12000,
    "likes": 231,
    "comments": 18,
    "shares": 9,
    "favorites": 45
  },
  "source": "manual_csv",
  "evidence": "运营从平台后台导出"
}
```

导入必须：

- 校验账号属于当前用户；
- 校验日期和数据为非负；
- 标记 `source=manual_csv`；
- 与 API 数据按 `account + date + post` 幂等覆盖；
- 保留操作人和导入文件名摘要。

## 5. 调度

建议默认：

- 发布后 1 小时拉一次；
- 发布后 6 小时拉一次；
- 24 小时、3 天、7 天各拉一次；
- 7 天后每天一次，持续 30 天；
- 之后每周一次，直到用户停止追踪。

平台不提供实时数据时降低频率。调度表保存 `next_run_at`，worker 重启后扫描数据库恢复，不依赖内存 timer。

### 5.1 防止重复拉取

唯一运行键：

```text
(account_id, platform_post_id, from_date, to_date, granularity)
```

已有 `queued/running` 任务时复用，不创建重复任务。手动刷新可以缩短 `next_run_at`，但不并发调用同一平台账号。

## 6. 存储与原始数据

主表：`amei_metric_snapshot`

唯一键：`(account_id, stat_date, platform_post_id, granularity)`。

原始响应只保存脱敏后的关键字段或对象存储引用：

- 不保存 access token；
- 不保存用户隐私字段；
- 大响应存对象存储，数据库只存 `raw_ref`；
- 原始数据保留 90 天，聚合指标保留 365 天。

## 7. 数据质量

| 标记 | 含义 |
| --- | --- |
| `source=official_api` | 官方开放 API |
| `source=manual_csv` | 人工导入 |
| `source=platform_export` | 平台后台导出文件 |
| `partial=true` | 部分作品或字段缺失 |
| `stale=true` | 超过刷新周期未更新 |
| `unavailableFields` | 平台不提供的字段 |
| `status=needs_action` | 授权/权限问题导致无法拉取 |

界面展示“未提供”而不是 0。历史数据拉取失败不删除最后一次成功数据，只标记 stale。

## 8. 指标 API

### 8.1 查询聚合

`GET /amei/api/v1/metrics?accountId=&contentVersionId=&from=&to=&granularity=day`

返回：

```json
{
  "items": [
    {
      "platformCode": "douyin",
      "contentVersionId": "cv_1001",
      "platformPostId": "7123456789",
      "statDate": "2026-11-11",
      "metrics": {
        "plays": 12000,
        "likes": 231,
        "comments": 18,
        "shares": 9,
        "favorites": 45
      },
      "availableFields": ["plays", "likes", "comments", "shares", "favorites"],
      "source": "official_api",
      "pulledAt": 1760000000000
    }
  ]
}
```

### 8.2 手动刷新

`POST /amei/api/v1/metrics/refresh`

### 8.3 导入

`POST /amei/api/v1/metrics/import`

## 9. 平台侧已知字段

| 平台 | 已核实字段/接口 | 状态 |
| --- | --- | --- |
| 抖音 | `play_count`、`comment_count`、`share_count`、`forward_count`、`digg_count`、`download_count` | 官方 SDK 已核实；具体接口权限待后台确认 |
| 快手 | `photo/list` 包含 `like_count`、`comment_count`、`view_count` 等 | 社区 SDK 观察，官方当前文档待复核 |
| B 站 | 稿件提交可拿 `resource_id`；数据接口未核实 | 未核实/待补充 |
| 微博 | 分享接口返回微博 ID；数据接口权限未核实 | 未核实/待补充 |
| 小红书 | 未发现内容数据 API | 未核实/待补充 |
| 视频号 | 未发现内容发布/数据 API | 未核实/待补充 |

平台字段以适配器实测为准，文档数字不得直接变成产品承诺。

## 10. 验收标准

- 发布成功后能为每个平台作品创建指标任务；
- 作品级和账号级数据可区分；
- 重复拉取不累加、不翻倍；
- 缺失指标为 `null` 并展示“未提供”；
- 拉取失败不清空历史数据；
- 人工导入有来源和审计；
- 不通过浏览器后台或逆向接口补数据。
