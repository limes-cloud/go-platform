-- Generated from the current local schema; schema only, no business data.
-- Target: MySQL 5.7+ (utf8mb4_unicode_ci, no MySQL 8.0-only syntax).
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `business` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  `app` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '应用标识',
  `keyword` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '变量标识',
  `type` varchar(32) NOT NULL COMMENT '变量类型',
  `description` varchar(128) NOT NULL DEFAULT '' COMMENT '配置说明',
  `extra` text COMMENT '渲染元数据（JSON）',
  PRIMARY KEY (`id`),
  KEY `idx_business_created_at` (`created_at`),
  KEY `idx_business_updated_at` (`updated_at`),
  KEY `idx_business_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='业务变量';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `business_value` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  `env_id` int unsigned NOT NULL COMMENT '环境id',
  `business_id` int unsigned NOT NULL COMMENT '业务变量id',
  `value` text NOT NULL COMMENT '业务变量id',
  PRIMARY KEY (`id`),
  UNIQUE KEY `env_id` (`env_id`,`business_id`),
  KEY `idx_business_value_created_at` (`created_at`),
  KEY `idx_business_value_updated_at` (`updated_at`),
  KEY `fk_business_value_env` (`env_id`),
  KEY `fk_business_values` (`business_id`),
  CONSTRAINT `fk_business_value_env` FOREIGN KEY (`env_id`) REFERENCES `env` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_business_values` FOREIGN KEY (`business_id`) REFERENCES `business` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='业务变量值';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `configure` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  `app` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '应用标识',
  `env_id` int unsigned NOT NULL COMMENT '环境id',
  `content` text NOT NULL COMMENT '配置内容',
  `version` varchar(32) NOT NULL COMMENT '配置版本',
  `format` varchar(32) NOT NULL COMMENT '配置格式',
  `description` varchar(128) DEFAULT NULL COMMENT '配置描述',
  PRIMARY KEY (`id`),
  KEY `idx_configure_updated_at` (`updated_at`),
  KEY `idx_configure_created_at` (`created_at`),
  KEY `fk_configure_env` (`env_id`),
  KEY `idx_configure_app` (`app`),
  CONSTRAINT `fk_configure_env` FOREIGN KEY (`env_id`) REFERENCES `env` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='配置内容';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `env` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  `keyword` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '环境标识',
  `name` varchar(64) NOT NULL COMMENT '环境名称',
  `description` varchar(255) DEFAULT NULL COMMENT '环境描述',
  `token` varchar(128) NOT NULL COMMENT '环境token',
  `status` tinyint(1) DEFAULT '0' COMMENT '环境状态',
  PRIMARY KEY (`id`),
  KEY `idx_env_created_at` (`created_at`),
  KEY `idx_env_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='环境信息';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gorm_init` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `init` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  `keyword` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '变量标识',
  `description` varchar(128) DEFAULT NULL COMMENT '资源说明',
  `fields` varchar(256) NOT NULL COMMENT '变量字段集合',
  `tag` varchar(32) NOT NULL COMMENT '变量标签',
  `private` tinyint(1) DEFAULT '0' COMMENT '是否私有',
  PRIMARY KEY (`id`),
  KEY `idx_resource_created_at` (`created_at`),
  KEY `idx_resource_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='资源变量';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource_app` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `app` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '应用标识',
  `resource_id` int unsigned NOT NULL COMMENT '资源id',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ar` (`app`,`resource_id`),
  KEY `idx_resource_server_created_at` (`created_at`),
  KEY `fk_resource_resource_server` (`resource_id`),
  KEY `idx_resource_app_created_at` (`created_at`),
  CONSTRAINT `fk_resource_resource_server` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='资源服务信息';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource_value` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  `env_id` int unsigned NOT NULL COMMENT '环境id',
  `resource_id` int unsigned NOT NULL COMMENT '资源id',
  `value` text NOT NULL COMMENT '资源id',
  PRIMARY KEY (`id`),
  UNIQUE KEY `er` (`env_id`,`resource_id`),
  KEY `idx_resource_value_updated_at` (`updated_at`),
  KEY `idx_resource_value_created_at` (`created_at`),
  KEY `fk_resource_resource_value` (`resource_id`),
  CONSTRAINT `fk_resource_resource_value` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_resource_value_env` FOREIGN KEY (`env_id`) REFERENCES `env` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='资源变量值';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `template` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  `app` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '应用标识',
  `namespace` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT 'conf' COMMENT '配置命名空间',
  `content` text NOT NULL COMMENT '模板内容',
  `version` varchar(32) NOT NULL COMMENT '模板版本',
  `is_use` tinyint(1) DEFAULT '0' COMMENT '是否使用',
  `format` varchar(32) NOT NULL COMMENT '模板格式',
  `description` varchar(128) NOT NULL COMMENT '模板描述',
  `compare` text NOT NULL COMMENT '变更详情',
  PRIMARY KEY (`id`),
  UNIQUE KEY `anv` (`app`,`namespace`,`version`),
  KEY `idx_template_created_at` (`created_at`),
  KEY `idx_template_updated_at` (`updated_at`),
  KEY `idx_template_app` (`app`),
  KEY `idx_template_app_namespace` (`app`,`namespace`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='配置模板';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `template_namespace` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(32) NOT NULL COMMENT '应用标识',
  `namespace` varchar(64) NOT NULL COMMENT '模板命名空间',
  `name` varchar(64) NOT NULL COMMENT '展示名称',
  `description` varchar(255) DEFAULT NULL COMMENT '描述',
  `sort` int unsigned NOT NULL DEFAULT '0' COMMENT '排序',
  `created_at` int unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` int unsigned NOT NULL DEFAULT '0' COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_namespace` (`app`,`namespace`),
  KEY `idx_app_sort` (`app`,`sort`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='模板命名空间';
/*!40101 SET character_set_client = @saved_cs_client */;

SET FOREIGN_KEY_CHECKS=1;
