-- Fresh ai-agent schema. Existing ai_agent databases must use deploy/migrations instead.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `secret_group` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `supplier` varchar(32) NOT NULL DEFAULT '' COMMENT '供应商',
  `name` varchar(64) NOT NULL DEFAULT '' COMMENT '分组名称',
  `host` varchar(255) NOT NULL DEFAULT '' COMMENT '服务地址',
  `created_at` bigint NOT NULL DEFAULT 0 COMMENT '创建时间',
  `updated_at` bigint NOT NULL DEFAULT 0 COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_secret_group_created_at` (`created_at`),
  KEY `idx_secret_group_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI 密钥分组';

CREATE TABLE IF NOT EXISTS `secret` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `group_id` int unsigned NOT NULL DEFAULT 0 COMMENT '分组ID',
  `token` text NOT NULL COMMENT '密钥',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态',
  `reason` varchar(255) DEFAULT NULL COMMENT '禁用原因',
  `name` varchar(64) NOT NULL DEFAULT '' COMMENT '名称',
  `created_at` bigint NOT NULL DEFAULT 0 COMMENT '创建时间',
  `updated_at` bigint NOT NULL DEFAULT 0 COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_secret_group_id` (`group_id`),
  KEY `idx_secret_created_at` (`created_at`),
  KEY `idx_secret_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI 密钥';

CREATE TABLE IF NOT EXISTS `model` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `type` varchar(32) NOT NULL DEFAULT '' COMMENT '模型类型：embedding | chat | image | video',
  `uuid` varchar(64) NOT NULL COMMENT '全局唯一标识',
  `keyword` varchar(64) NOT NULL DEFAULT '' COMMENT '供应商侧模型标识',
  `secret_group_id` int unsigned NOT NULL DEFAULT 0 COMMENT '密钥分组ID',
  `description` varchar(512) NOT NULL DEFAULT '' COMMENT '模型描述',
  `extra` text NOT NULL COMMENT '扩展配置 JSON',
  `status` tinyint unsigned DEFAULT 1 COMMENT '状态：0 禁用 | 1 启用',
  `created_at` bigint NOT NULL DEFAULT 0 COMMENT '创建时间',
  `updated_at` bigint NOT NULL DEFAULT 0 COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_model_uuid` (`uuid`),
  KEY `idx_model_secret_group_id` (`secret_group_id`),
  KEY `idx_model_created_at` (`created_at`),
  KEY `idx_model_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI 模型';

CREATE TABLE IF NOT EXISTS `prompt_classify` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(64) NOT NULL DEFAULT '' COMMENT '所属应用',
  `name` varchar(64) NOT NULL DEFAULT '' COMMENT '分类名',
  `description` varchar(512) NOT NULL DEFAULT '' COMMENT '分类描述',
  `created_at` bigint NOT NULL DEFAULT 0 COMMENT '创建时间',
  `updated_at` bigint NOT NULL DEFAULT 0 COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_prompt_classify_app_name` (`app`, `name`),
  KEY `idx_prompt_classify_created_at` (`created_at`),
  KEY `idx_prompt_classify_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI 提示词分类';

CREATE TABLE IF NOT EXISTS `prompt` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(64) NOT NULL DEFAULT '' COMMENT '所属应用',
  `uuid` varchar(64) NOT NULL COMMENT '应用内唯一标识',
  `title` varchar(255) NOT NULL DEFAULT '' COMMENT '提示词标题',
  `system` text COMMENT '系统提示',
  `prompt` longtext NOT NULL COMMENT '提示词模板',
  `status` tinyint unsigned DEFAULT 1 COMMENT '状态：0 禁用 | 1 启用',
  `description` varchar(512) NOT NULL DEFAULT '' COMMENT '描述',
  `extra` text NOT NULL COMMENT '扩展配置 JSON',
  `version` varchar(64) NOT NULL DEFAULT '' COMMENT '版本号',
  `model_id` int unsigned NOT NULL DEFAULT 0 COMMENT '模型ID',
  `classify_id` int unsigned NOT NULL DEFAULT 0 COMMENT '分类ID',
  `created_at` bigint NOT NULL DEFAULT 0 COMMENT '创建时间',
  `updated_at` bigint NOT NULL DEFAULT 0 COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_prompt_app_uuid` (`app`, `uuid`),
  KEY `idx_prompt_model_id` (`model_id`),
  KEY `idx_prompt_classify_id` (`classify_id`),
  KEY `idx_prompt_created_at` (`created_at`),
  KEY `idx_prompt_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI 提示词';

CREATE TABLE IF NOT EXISTS `call_log` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(64) NOT NULL DEFAULT '' COMMENT '应用标识',
  `model_id` int unsigned NOT NULL DEFAULT 0 COMMENT '模型 ID',
  `model_uuid` varchar(64) NOT NULL DEFAULT '' COMMENT '模型 UUID',
  `supplier` varchar(32) NOT NULL DEFAULT '' COMMENT '供应商',
  `scene` varchar(32) NOT NULL DEFAULT '' COMMENT '生成场景',
  `prompt_tokens` int unsigned NOT NULL DEFAULT 0 COMMENT '输入 token 数',
  `completion_tokens` int unsigned NOT NULL DEFAULT 0 COMMENT '输出 token 数',
  `latency_ms` bigint NOT NULL DEFAULT 0 COMMENT '生成耗时（毫秒）',
  `status` tinyint unsigned NOT NULL DEFAULT 0 COMMENT '状态：0 失败 | 1 成功',
  `error_message` varchar(1024) NOT NULL DEFAULT '' COMMENT '失败原因',
  `created_at` bigint NOT NULL DEFAULT 0 COMMENT '创建时间',
  `updated_at` bigint NOT NULL DEFAULT 0 COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_call_log_app_created` (`app`, `created_at`),
  KEY `idx_call_log_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI 生成调用日志';
