-- 流程调度批量执行：批次与批次行（MySQL 5.7+）
CREATE TABLE IF NOT EXISTS `chain_batch` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `app` varchar(32) NOT NULL COMMENT '所属应用（X-App-Key）',
  `chain_id` int unsigned NOT NULL COMMENT '目标链 chain.id',
  `chain_version_id` int unsigned NOT NULL COMMENT '发起时生效版本 chain_version.id（切换版本不影响本批）',
  `name` varchar(128) DEFAULT NULL COMMENT '批次名称；NULL = 自动生成',
  `file_name` varchar(255) NOT NULL COMMENT '上传文件名（仅展示）',
  `row_count` int unsigned NOT NULL COMMENT '数据行数（校验通过的行数）',
  `max_concurrent` int unsigned NOT NULL DEFAULT 10 COMMENT '批次最大并发运行数（1～100）',
  `status` varchar(16) NOT NULL DEFAULT 'pending' COMMENT 'pending | running | completed | canceled',
  `success_count` int unsigned NOT NULL DEFAULT 0 COMMENT '成功行数',
  `fail_count` int unsigned NOT NULL DEFAULT 0 COMMENT '失败行数',
  `canceled_count` int unsigned NOT NULL DEFAULT 0 COMMENT '取消行数',
  `created_by` varchar(64) NOT NULL COMMENT '创建人（管理端用户/IP，仅审计）',
  `started_at` bigint DEFAULT NULL COMMENT '首次下发时间（Unix 秒）',
  `finished_at` bigint DEFAULT NULL COMMENT '批次终态时间（Unix 秒）',
  `created_at` bigint DEFAULT NULL,
  `updated_at` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_app_status` (`app`, `status`),
  KEY `idx_finished` (`finished_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流程调度批量执行批次';

CREATE TABLE IF NOT EXISTS `chain_batch_item` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `batch_id` int unsigned NOT NULL COMMENT '所属批次 chain_batch.id',
  `row_no` int unsigned NOT NULL COMMENT 'xlsx 数据行号（从 2 开始）',
  `input` mediumtext NOT NULL COMMENT '入参 JSON（request.body），全量存储',
  `status` varchar(16) NOT NULL DEFAULT 'pending' COMMENT 'pending | running | success | fail | canceled',
  `run_id` char(36) DEFAULT NULL COMMENT '关联运行 chain_run.id；NULL = 未发起',
  `retry_at` bigint DEFAULT NULL COMMENT '重试退避时间（Unix 秒）；NULL = 可立即调度',
  `error_code` varchar(32) DEFAULT NULL COMMENT '失败错误名（Chain.*）',
  `error_msg` varchar(1024) DEFAULT NULL,
  `started_at` bigint DEFAULT NULL COMMENT '发起时间（Unix 秒）',
  `finished_at` bigint DEFAULT NULL COMMENT '行终态时间（Unix 秒）',
  `created_at` bigint DEFAULT NULL,
  `updated_at` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_batch_row` (`batch_id`, `row_no`),
  KEY `idx_batch_status` (`batch_id`, `status`),
  KEY `idx_run` (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流程调度批量执行批次行';
