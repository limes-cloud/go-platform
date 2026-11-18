-- Fresh cron schema. Existing cron databases continue to use server/cron/deploy/data.sql migrations.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `task_group` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(32) NOT NULL DEFAULT '' COMMENT '所属应用',
  `name` varchar(32) NOT NULL COMMENT '名称',
  `description` varchar(256) DEFAULT NULL COMMENT '描述',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_group_name` (`name`),
  KEY `idx_app` (`app`),
  KEY `idx_task_group_updated_at` (`updated_at`),
  KEY `idx_task_group_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务分组';

CREATE TABLE IF NOT EXISTS `worker_group` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(32) NOT NULL COMMENT '名称',
  `description` varchar(256) DEFAULT NULL COMMENT '描述',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_worker_group_name` (`name`),
  KEY `idx_worker_group_updated_at` (`updated_at`),
  KEY `idx_worker_group_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='节点分组';

CREATE TABLE IF NOT EXISTS `worker` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(32) NOT NULL COMMENT '名称',
  `ip` varchar(64) NOT NULL COMMENT 'ip',
  `ak` varchar(64) NOT NULL DEFAULT '' COMMENT '签名AK',
  `sk` varchar(64) NOT NULL DEFAULT '' COMMENT '签名SK',
  `group_id` int unsigned DEFAULT NULL COMMENT '分组',
  `status` tinyint(1) DEFAULT NULL COMMENT '状态',
  `last_check_at` bigint DEFAULT NULL COMMENT '最后一次探测时间',
  `last_heartbeat` bigint DEFAULT NULL COMMENT '最后一次有效探测时间',
  `last_error` text COMMENT '最后一次探测失败原因',
  `description` varchar(256) DEFAULT NULL COMMENT '描述',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_worker_ip` (`ip`),
  KEY `idx_worker_updated_at` (`updated_at`),
  KEY `idx_worker_created_at` (`created_at`),
  KEY `group_id` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='节点信息';

CREATE TABLE IF NOT EXISTS `worker_app` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `worker_id` int unsigned NOT NULL COMMENT '节点ID',
  `app` varchar(32) NOT NULL COMMENT '可用应用',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_worker_app` (`worker_id`, `app`),
  KEY `idx_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='节点可用应用授权';

CREATE TABLE IF NOT EXISTS `task` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(32) NOT NULL DEFAULT '' COMMENT '所属应用',
  `group_id` int unsigned DEFAULT NULL COMMENT '分组id',
  `name` varchar(64) NOT NULL COMMENT '名称',
  `tag` varchar(32) NOT NULL COMMENT '标签',
  `spec` varchar(32) NOT NULL COMMENT '表达式',
  `worker_type` char(32) NOT NULL COMMENT '选机类型',
  `route_type` varchar(16) NOT NULL DEFAULT 'single' COMMENT '路由方式：group | single',
  `worker_group_id` int unsigned DEFAULT NULL COMMENT '节点分组id',
  `worker_id` int unsigned DEFAULT NULL COMMENT '节点id',
  `exec_type` varchar(32) NOT NULL COMMENT '执行类型',
  `exec_value` text NOT NULL COMMENT '执行内容',
  `chain_input` mediumtext DEFAULT NULL COMMENT '执行指定流程的入参 JSON（request.body）',
  `expect_code` int NOT NULL DEFAULT 0 COMMENT '预期状态码',
  `retry_count` int NOT NULL DEFAULT 0 COMMENT '重试次数',
  `retry_wait_time` int NOT NULL DEFAULT 0 COMMENT '等待时长',
  `max_exec_time` int NOT NULL DEFAULT 0 COMMENT '最大执行时长',
  `misfire` varchar(16) NOT NULL DEFAULT 'latest' COMMENT '错过补偿策略',
  `status` tinyint(1) DEFAULT NULL COMMENT '状态',
  `version` varchar(64) NOT NULL COMMENT '版本',
  `description` varchar(256) DEFAULT NULL COMMENT '描述',
  `start` bigint DEFAULT NULL COMMENT '开始时间',
  `end` bigint DEFAULT NULL COMMENT '结束时间',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_version` (`version`),
  KEY `idx_app` (`app`),
  KEY `idx_task_updated_at` (`updated_at`),
  KEY `idx_task_created_at` (`created_at`),
  KEY `group_id` (`group_id`),
  KEY `worker_group_id` (`worker_group_id`),
  KEY `worker_id` (`worker_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务信息';

CREATE TABLE IF NOT EXISTS `execution` (
  `id` varchar(64) NOT NULL COMMENT '执行意图ID',
  `app` varchar(32) NOT NULL DEFAULT '' COMMENT '所属应用',
  `task_id` int unsigned NOT NULL COMMENT '任务ID',
  `trigger_at` bigint NOT NULL COMMENT '触发时刻',
  `trigger_type` varchar(16) NOT NULL DEFAULT 'cron' COMMENT '触发方式',
  `worker_id` int unsigned DEFAULT NULL COMMENT '实际执行节点',
  `log_uuid` varchar(64) DEFAULT NULL COMMENT '关联执行日志',
  `executor` varchar(64) DEFAULT NULL COMMENT '执行体标识',
  `status` varchar(16) NOT NULL DEFAULT 'pending' COMMENT '状态',
  `heartbeat_at` bigint DEFAULT NULL COMMENT '最近心跳',
  `started_at` bigint DEFAULT NULL COMMENT '开始执行时间',
  `finished_at` bigint DEFAULT NULL COMMENT '结束时间',
  `retry_count` int NOT NULL DEFAULT 0 COMMENT '连接重试次数',
  `last_error` text COMMENT '最近一次错误',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_trigger` (`task_id`, `trigger_at`),
  KEY `idx_app` (`app`),
  KEY `idx_status_heartbeat` (`status`, `heartbeat_at`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务执行意图';

CREATE TABLE IF NOT EXISTS `log` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(32) NOT NULL DEFAULT '' COMMENT '所属应用',
  `uuid` varchar(64) NOT NULL COMMENT '标识',
  `worker_id` int unsigned NOT NULL COMMENT '节点id',
  `worker_snapshot` varchar(2048) NOT NULL COMMENT '节点快照',
  `task_id` int unsigned NOT NULL COMMENT '任务id',
  `task_snapshot` varchar(2048) NOT NULL COMMENT '任务快照',
  `start_at` bigint unsigned NOT NULL COMMENT '开始时间',
  `end_at` bigint unsigned NOT NULL COMMENT '结束时间',
  `content` text NOT NULL COMMENT '执行日志',
  `status` char(32) NOT NULL COMMENT '执行结果',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_uuid` (`uuid`),
  KEY `idx_app` (`app`),
  KEY `idx_log_worker_id` (`worker_id`),
  KEY `idx_log_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日志信息';
