-- Generated from the current local schema; schema only, no business data.
-- Target: MySQL 5.7+ (utf8mb4_unicode_ci, no MySQL 8.0-only syntax).
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '应用ID',
  `type` char(32) NOT NULL COMMENT '应用类型',
  `logo` varchar(128) NOT NULL COMMENT '应用logo',
  `favicon` varchar(128) DEFAULT NULL COMMENT '应用图标',
  `keyword` char(32) NOT NULL COMMENT '应用标识',
  `name` varchar(32) NOT NULL COMMENT '应用名称',
  `show_name` varchar(64) NOT NULL COMMENT '显示名称',
  `private` tinyint(1) DEFAULT NULL COMMENT '是否私有',
  `loginable` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否可作为登录入口',
  `status` tinyint(1) NOT NULL COMMENT '应用状态',
  `reason` tinytext COMMENT '禁用原因',
  `description` varchar(128) DEFAULT NULL COMMENT '应用描述',
  `comment` varchar(128) DEFAULT NULL COMMENT '备注',
  `setting` text COMMENT '应用配置',
  `created_at` bigint unsigned NOT NULL COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_app_keyword` (`keyword`),
  KEY `idx_app_created_at` (`created_at`),
  KEY `idx_app_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='应用表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_field` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `app` varchar(64) NOT NULL COMMENT '应用标识',
  `field_id` bigint unsigned NOT NULL COMMENT '关联字段 ID',
  `required` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否必填',
  `unique` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否唯一',
  `sort` int unsigned NOT NULL DEFAULT '0' COMMENT '排序（越小越前）',
  `created_at` bigint unsigned NOT NULL,
  `updated_at` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_field` (`app`,`field_id`),
  KEY `idx_app_sort` (`app`,`sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='应用字段绑定';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_form` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `app_keyword` varchar(64) NOT NULL COMMENT '应用标识',
  `form_id` bigint unsigned NOT NULL COMMENT '表单ID',
  `scene` varchar(64) NOT NULL COMMENT '场景标识（冗余）',
  `created_at` bigint unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_scene` (`app_keyword`,`scene`),
  KEY `idx_form_id` (`form_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='应用-表单关联';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_oauther` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(64) NOT NULL DEFAULT '',
  `oauther_id` bigint unsigned NOT NULL COMMENT '渠道id',
  `type` char(32) NOT NULL COMMENT '渠道类型',
  `created_at` bigint unsigned NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `app_type` (`type`),
  KEY `oauther_id` (`oauther_id`),
  KEY `idx_app` (`app`),
  CONSTRAINT `app_oauther_ibfk_1` FOREIGN KEY (`oauther_id`) REFERENCES `oauther` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='应用渠道表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `app` varchar(64) NOT NULL DEFAULT '',
  `menu_id` bigint unsigned NOT NULL COMMENT '菜单ID',
  `dept_id` bigint unsigned NOT NULL COMMENT '部门ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `created_at` (`created_at`),
  KEY `dept_user` (`dept_id`,`user_id`),
  KEY `idx_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='鉴权日志';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `authorize` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `tokens` text COMMENT 'token',
  `logged_at` bigint DEFAULT NULL COMMENT '登录时间',
  `expired_at` bigint DEFAULT NULL COMMENT '过期时间',
  `created_at` bigint unsigned NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `app_user` (`app_id`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `authorize_ibfk_1` FOREIGN KEY (`app_id`) REFERENCES `app` (`id`) ON DELETE CASCADE,
  CONSTRAINT `authorize_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户授权表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `casbin_rule` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ptype` varchar(100) DEFAULT NULL,
  `v0` varchar(100) DEFAULT NULL,
  `v1` varchar(100) DEFAULT NULL,
  `v2` varchar(100) DEFAULT NULL,
  `v3` varchar(100) DEFAULT NULL,
  `v4` varchar(100) DEFAULT NULL,
  `v5` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_casbin_rule` (`ptype`,`v0`,`v1`,`v2`,`v3`,`v4`,`v5`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Casbin权限规则表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dept` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '部门ID',
  `app` varchar(64) NOT NULL DEFAULT 'manager' COMMENT '应用标识',
  `classify_id` bigint unsigned NOT NULL COMMENT '分类id',
  `parent_id` bigint unsigned NOT NULL COMMENT '父级id',
  `keyword` char(32) NOT NULL COMMENT '部门标识',
  `name` varchar(64) NOT NULL COMMENT '部门名称',
  `logo` varchar(256) NOT NULL COMMENT '部门logo',
  `status` tinyint(1) DEFAULT '0' COMMENT '部门状态',
  `description` varchar(256) NOT NULL COMMENT '部门描述',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_dept_created_at` (`created_at`),
  KEY `idx_dept_updated_at` (`updated_at`),
  KEY `classify_id` (`classify_id`),
  KEY `idx_dept_app` (`app`),
  CONSTRAINT `dept_ibfk_2` FOREIGN KEY (`classify_id`) REFERENCES `dept_classify` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dept_classify` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(64) NOT NULL DEFAULT 'manager' COMMENT '应用标识',
  `keyword` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '分类标识',
  `name` varchar(64) NOT NULL COMMENT '分类名称',
  `description` varchar(256) DEFAULT NULL COMMENT '分类描述',
  `status` tinyint(1) DEFAULT '0' COMMENT '状态',
  `weight` int unsigned DEFAULT '0' COMMENT '排序权重',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_dept_classify_app_keyword` (`app`,`keyword`),
  KEY `idx_dept_classify_created_at` (`created_at`),
  KEY `idx_dept_classify_updated_at` (`updated_at`),
  KEY `idx_dept_classify_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门分类表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dept_closure` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `parent` bigint unsigned NOT NULL COMMENT '父级id',
  `children` bigint unsigned NOT NULL COMMENT '子级id',
  PRIMARY KEY (`id`),
  KEY `idx_dept_closure_parent` (`parent`),
  KEY `idx_dept_closure_children` (`children`),
  CONSTRAINT `dept_closure_ibfk_1` FOREIGN KEY (`parent`) REFERENCES `dept` (`id`) ON DELETE CASCADE,
  CONSTRAINT `dept_closure_ibfk_2` FOREIGN KEY (`children`) REFERENCES `dept` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门闭包表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dept_role` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(64) NOT NULL DEFAULT 'manager' COMMENT '应用标识',
  `role_id` bigint unsigned NOT NULL COMMENT '角色id',
  `dept_id` bigint unsigned NOT NULL COMMENT '部门id',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_dept_role_app_role_dept` (`app`,`role_id`,`dept_id`),
  KEY `dept_id` (`dept_id`),
  KEY `idx_dept_role_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门角色表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dictionary` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '字典ID',
  `keyword` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '字典标识',
  `type` char(32) NOT NULL COMMENT '字典类型',
  `name` varchar(64) NOT NULL COMMENT '字典名称',
  `description` varchar(256) DEFAULT NULL COMMENT '字典描述',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `keyword` (`keyword`),
  KEY `idx_dictionary_created_at` (`created_at`),
  KEY `idx_dictionary_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='字典表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dictionary_value` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '字典值ID',
  `dictionary_id` bigint unsigned NOT NULL COMMENT '字典id',
  `parent_id` bigint unsigned NOT NULL COMMENT '父级id',
  `label` varchar(128) NOT NULL COMMENT '标签',
  `value` varchar(128) NOT NULL COMMENT '值',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态',
  `weight` int unsigned DEFAULT '0' COMMENT '权重',
  `type` char(32) DEFAULT NULL COMMENT '类型',
  `extra` varchar(512) DEFAULT NULL COMMENT '扩展信息',
  `description` varchar(256) DEFAULT NULL COMMENT '描述',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `value` (`dictionary_id`,`value`),
  KEY `idx_dictionary_value_created_at` (`created_at`),
  KEY `idx_dictionary_value_updated_at` (`updated_at`),
  KEY `idx_dictionary_value_weight` (`weight`),
  CONSTRAINT `fk_dictionary_value_dict` FOREIGN KEY (`dictionary_id`) REFERENCES `dictionary` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='字典值表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `entity` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '实体ID',
  `app` varchar(64) NOT NULL DEFAULT '' COMMENT '应用标识',
  `database` varchar(64) NOT NULL COMMENT '数据库名',
  `name` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '实体名称',
  `comment` varchar(64) NOT NULL COMMENT '实体注释',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_entity_app_db_name` (`app`,`database`,`name`),
  KEY `idx_entity_created_at` (`created_at`),
  KEY `idx_entity_updated_at` (`updated_at`),
  KEY `idx_entity_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='实体表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `entity_field` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `entity_id` bigint unsigned NOT NULL COMMENT '实体ID',
  `name` varchar(64) NOT NULL COMMENT '字段名称',
  `comment` varchar(64) NOT NULL COMMENT '字段注释',
  `index` int NOT NULL COMMENT '字段顺序',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_entity_field_name` (`entity_id`,`name`),
  KEY `idx_entity_field_created_at` (`created_at`),
  KEY `idx_entity_field_updated_at` (`updated_at`),
  CONSTRAINT `entity_field_ibfk_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='实体字段表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `entity_rule` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '规则ID',
  `entity_id` bigint unsigned NOT NULL COMMENT '实体ID',
  `name` varchar(64) NOT NULL COMMENT '规则名称',
  `description` varchar(128) NOT NULL COMMENT '规则描述',
  `expression` text NOT NULL COMMENT '规则表达式',
  `status` tinyint(1) DEFAULT '0' COMMENT '规则状态',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_entity_rule_created_at` (`created_at`),
  KEY `idx_entity_rule_updated_at` (`updated_at`),
  KEY `entity_id` (`entity_id`),
  CONSTRAINT `entity_rule_ibfk_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='实体规则表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '反馈ID',
  `app` varchar(64) NOT NULL DEFAULT '',
  `user_id` bigint unsigned NOT NULL COMMENT '用户id',
  `classify_id` bigint unsigned NOT NULL COMMENT '分类id',
  `title` varchar(128) NOT NULL COMMENT '标题',
  `content` text NOT NULL COMMENT '内容',
  `status` char(32) NOT NULL COMMENT '状态',
  `images` tinytext COMMENT '图片',
  `contact` char(32) DEFAULT NULL COMMENT '联系方式',
  `device` text NOT NULL COMMENT '设备',
  `platform` char(32) NOT NULL COMMENT '平台',
  `version` varchar(32) DEFAULT NULL COMMENT '版本',
  `md5` varchar(64) NOT NULL COMMENT 'md5值',
  `processed_by` bigint unsigned DEFAULT NULL COMMENT '处理人',
  `processed_result` varchar(256) DEFAULT NULL COMMENT '处理结果',
  `created_at` bigint unsigned NOT NULL COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `md5` (`md5`),
  KEY `created_at` (`created_at`),
  KEY `updated_at` (`updated_at`),
  KEY `user_id` (`user_id`),
  KEY `classify_id` (`classify_id`),
  KEY `idx_app` (`app`),
  CONSTRAINT `feedback_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `feedback_ibfk_3` FOREIGN KEY (`classify_id`) REFERENCES `feedback_classify` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='反馈表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback_classify` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(32) NOT NULL COMMENT '分类名称',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='反馈分类表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `field` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `keyword` char(32) NOT NULL COMMENT '字段唯一标识',
  `type` char(32) NOT NULL COMMENT '组件类型：input/textarea/number/password/radio/checkbox/select/time/date/datetime/upload',
  `name` varchar(64) NOT NULL COMMENT '字段标签',
  `config` json DEFAULT NULL COMMENT '组件配置（placeholder/defaultValue/maxLength/options/rule 等）',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 禁用 1 启用',
  `description` varchar(256) DEFAULT NULL COMMENT '字段说明',
  `created_at` bigint unsigned NOT NULL,
  `updated_at` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_keyword` (`keyword`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='全局表单字段定义';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `form_scene` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `keyword` varchar(64) NOT NULL COMMENT '场景标识',
  `name` varchar(128) NOT NULL COMMENT '场景名称',
  `description` varchar(512) DEFAULT NULL COMMENT '场景描述',
  `created_at` bigint unsigned NOT NULL DEFAULT '0',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_keyword` (`keyword`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='表单场景枚举';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '职位ID',
  `app` varchar(64) NOT NULL DEFAULT 'manager' COMMENT '应用标识',
  `keyword` char(32) NOT NULL COMMENT '职位标识',
  `name` varchar(64) NOT NULL COMMENT '职位名称',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '职位状态',
  `weight` int unsigned DEFAULT NULL COMMENT '排序权重',
  `description` varchar(256) NOT NULL COMMENT '职位描述',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_job_weight` (`weight`),
  KEY `idx_job_created_at` (`created_at`),
  KEY `idx_job_updated_at` (`updated_at`),
  KEY `idx_job_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='职位表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_role` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(64) NOT NULL DEFAULT 'manager' COMMENT '应用标识',
  `role_id` bigint unsigned NOT NULL COMMENT '角色id',
  `job_id` bigint unsigned NOT NULL COMMENT '职位id',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_job_role_app_role_job` (`app`,`role_id`,`job_id`),
  KEY `job_id` (`job_id`),
  KEY `idx_job_role_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='职位角色表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `login_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `app` varchar(64) NOT NULL DEFAULT '',
  `type` char(32) NOT NULL COMMENT '类型',
  `ip` char(64) NOT NULL COMMENT 'ip',
  `address` varchar(128) NOT NULL COMMENT '地址',
  `device` varchar(128) NOT NULL COMMENT '设备',
  `browser` varchar(128) NOT NULL COMMENT '浏览器',
  `code` int NOT NULL COMMENT '状态码',
  `description` varchar(128) NOT NULL COMMENT '描述',
  `dept_id` bigint unsigned NOT NULL COMMENT '部门ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `created_at` (`created_at`),
  KEY `dept_user` (`dept_id`,`user_id`),
  KEY `idx_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='登录日志';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '菜单ID',
  `app` varchar(64) NOT NULL DEFAULT '' COMMENT '应用标识',
  `parent_id` bigint unsigned NOT NULL COMMENT '父ID',
  `title` varchar(128) NOT NULL COMMENT '菜单标题',
  `type` char(32) NOT NULL COMMENT '菜单类型',
  `keyword` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '菜单标识',
  `icon` char(32) DEFAULT NULL COMMENT '菜单图标',
  `api` varchar(128) DEFAULT NULL COMMENT '接口信息',
  `method` varchar(12) DEFAULT NULL COMMENT '请求方法',
  `path` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '路由路径',
  `permission` varchar(128) DEFAULT NULL COMMENT '权限标识',
  `component` varchar(128) DEFAULT NULL COMMENT '组件路径',
  `url` varchar(512) DEFAULT NULL COMMENT '站外url',
  `redirect` varchar(128) DEFAULT NULL COMMENT '重定向地址',
  `weight` int unsigned DEFAULT '0' COMMENT '菜单权重',
  `is_iframe` tinyint(1) DEFAULT NULL COMMENT '是否iframe',
  `is_hidden` tinyint(1) DEFAULT NULL COMMENT '是否隐藏',
  `is_cache` tinyint(1) DEFAULT NULL COMMENT '是否缓存',
  `is_home` tinyint(1) DEFAULT NULL COMMENT '是否首页',
  `is_affix` tinyint(1) DEFAULT NULL COMMENT '是否固定',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_menu_app_keyword` (`app`,`keyword`),
  UNIQUE KEY `uidx_menu_app_path` (`app`,`path`),
  UNIQUE KEY `uidx_menu_app_api_method` (`app`,`api`,`method`),
  KEY `idx_menu_created_at` (`created_at`),
  KEY `idx_menu_updated_at` (`updated_at`),
  KEY `idx_menu_weight` (`weight`),
  KEY `idx_menu_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='菜单表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu_closure` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `parent` bigint unsigned NOT NULL COMMENT '父级id',
  `children` bigint unsigned NOT NULL COMMENT '子级id',
  PRIMARY KEY (`id`),
  KEY `parent` (`parent`),
  KEY `children` (`children`),
  CONSTRAINT `menu_closure_ibfk_1` FOREIGN KEY (`children`) REFERENCES `menu` (`id`) ON DELETE CASCADE,
  CONSTRAINT `menu_closure_ibfk_2` FOREIGN KEY (`parent`) REFERENCES `menu` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='菜单闭包表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notice` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '通知ID',
  `app` varchar(64) NOT NULL DEFAULT '',
  `classify_id` bigint unsigned NOT NULL COMMENT '分类id',
  `title` varchar(128) NOT NULL COMMENT '通知标题',
  `description` varchar(512) NOT NULL COMMENT '通知简介',
  `unit` varchar(128) NOT NULL COMMENT '发布单位',
  `content` longtext NOT NULL COMMENT '通知内容',
  `is_top` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否置顶',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '通知状态',
  `created_at` bigint NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `classify_id` (`classify_id`),
  KEY `created_at` (`created_at`),
  KEY `updated_at` (`updated_at`),
  KEY `idx_app` (`app`),
  CONSTRAINT `notice_ibfk_2` FOREIGN KEY (`classify_id`) REFERENCES `notice_classify` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notice_classify` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(32) NOT NULL COMMENT '分类名称',
  `logo` varchar(128) NOT NULL COMMENT '分类LOGO',
  `weight` int unsigned DEFAULT NULL COMMENT '排序权重',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知分类表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notice_user` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `notice_id` bigint unsigned NOT NULL COMMENT '通知id',
  `user_id` bigint unsigned NOT NULL COMMENT '用户id',
  `created_at` bigint NOT NULL DEFAULT '0' COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `notice_id` (`notice_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `notice_user_ibfk_1` FOREIGN KEY (`notice_id`) REFERENCES `notice` (`id`) ON DELETE CASCADE,
  CONSTRAINT `notice_user_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知用户表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `oauther` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '渠道ID',
  `logo` varchar(128) NOT NULL COMMENT '渠道logo',
  `keyword` char(32) NOT NULL COMMENT '渠道标识',
  `name` varchar(32) NOT NULL COMMENT '渠道名称',
  `type` varchar(32) NOT NULL COMMENT '渠道类型',
  `ak` varchar(32) DEFAULT NULL COMMENT '渠道ak',
  `sk` varchar(32) DEFAULT NULL COMMENT '渠道sk',
  `description` varchar(256) DEFAULT NULL COMMENT '渠道描述',
  `status` tinyint(1) NOT NULL COMMENT '启用状态',
  `setting` text COMMENT '渠道配置',
  `created_at` bigint unsigned NOT NULL COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `keyword` (`keyword`),
  KEY `idx_channel_created_at` (`created_at`),
  KEY `idx_channel_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='登录渠道';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '角色ID',
  `app` varchar(64) NOT NULL DEFAULT 'manager' COMMENT '应用标识',
  `parent_id` bigint unsigned NOT NULL COMMENT '父id',
  `keyword` char(32) NOT NULL COMMENT '角色标识',
  `name` varchar(64) NOT NULL COMMENT '角色名称',
  `status` tinyint(1) DEFAULT '0' COMMENT '角色状态',
  `description` varchar(128) NOT NULL COMMENT '角色描述',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_role_app_keyword` (`app`,`keyword`),
  KEY `idx_role_created_at` (`created_at`),
  KEY `idx_role_updated_at` (`updated_at`),
  KEY `idx_role_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_closure` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `parent` bigint unsigned NOT NULL COMMENT '父级id',
  `children` bigint unsigned NOT NULL COMMENT '子级id',
  PRIMARY KEY (`id`),
  KEY `idx_role_closure_parent` (`parent`),
  KEY `idx_role_closure_children` (`children`),
  CONSTRAINT `role_closure_ibfk_1` FOREIGN KEY (`parent`) REFERENCES `role` (`id`) ON DELETE CASCADE,
  CONSTRAINT `role_closure_ibfk_2` FOREIGN KEY (`children`) REFERENCES `role` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色闭包表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_entity` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(64) NOT NULL DEFAULT 'manager' COMMENT '应用标识',
  `role_id` bigint unsigned NOT NULL COMMENT '角色id',
  `entity_id` bigint unsigned NOT NULL COMMENT '实体id',
  `action` char(32) NOT NULL COMMENT '操作类型',
  `scope` char(32) NOT NULL COMMENT '数据范围',
  `depts` varchar(512) DEFAULT NULL COMMENT '部门范围',
  `rules` varchar(512) NOT NULL COMMENT '规则范围',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_role_entity_app_role_entity_action` (`app`,`role_id`,`entity_id`,`action`),
  KEY `entity_id` (`entity_id`),
  KEY `idx_role_entity_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色实体表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_menu` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(64) NOT NULL DEFAULT 'manager' COMMENT '应用标识',
  `role_id` bigint unsigned NOT NULL COMMENT '角色id',
  `menu_id` bigint unsigned NOT NULL COMMENT '菜单id',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_role_menu_app_role_menu` (`app`,`role_id`,`menu_id`),
  KEY `menu_id` (`menu_id`),
  KEY `idx_role_menu_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色菜单表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `avatar` varchar(256) DEFAULT NULL COMMENT '用户头像',
  `nickname` varchar(64) NOT NULL COMMENT '用户昵称',
  `signature` varchar(256) DEFAULT NULL COMMENT '用户签名',
  `username` char(64) NOT NULL COMMENT '用户账户',
  `password` varchar(256) NOT NULL COMMENT '用户密码',
  `status` tinyint(1) DEFAULT '0' COMMENT '用户状态',
  `reason` varchar(128) DEFAULT NULL COMMENT '禁用原因',
  `logged_at` bigint NOT NULL DEFAULT '0' COMMENT '登录时间',
  `created_at` bigint NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint NOT NULL DEFAULT '0' COMMENT '更新时间',
  `deleted_at` bigint NOT NULL DEFAULT '0' COMMENT '删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_user_username` (`username`,`deleted_at`),
  KEY `idx_user_created_at` (`created_at`),
  KEY `idx_user_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_dept` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app` varchar(64) NOT NULL DEFAULT 'manager' COMMENT '应用标识',
  `user_id` bigint unsigned NOT NULL COMMENT '用户id',
  `dept_id` bigint unsigned NOT NULL COMMENT '部门id',
  `main` tinyint(1) DEFAULT '0' COMMENT '是否主部门',
  `job_id` bigint unsigned NOT NULL COMMENT '职位id',
  `created_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_user_dept_app_user_dept_job` (`app`,`user_id`,`dept_id`,`job_id`),
  KEY `dept_id` (`dept_id`),
  KEY `job_id` (`job_id`),
  KEY `idx_user_dept_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户部门表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_form` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `scene` varchar(64) NOT NULL COMMENT '场景标识（关联 form_scene.keyword）',
  `name` varchar(128) NOT NULL COMMENT '表单名称',
  `description` varchar(512) DEFAULT NULL COMMENT '表单用途描述',
  `schema` json NOT NULL COMMENT '设计器导出的完整 JSON',
  `version` int unsigned NOT NULL DEFAULT '1' COMMENT '版本号',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0草稿 1已发布',
  `created_at` bigint unsigned NOT NULL DEFAULT '0',
  `updated_at` bigint unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_scene` (`scene`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表单定义';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_oauther` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `oauther_id` bigint unsigned NOT NULL COMMENT '渠道ID',
  `oid` varchar(128) NOT NULL COMMENT '开放ID',
  `token` varchar(512) NOT NULL COMMENT 'token',
  `logged_at` bigint DEFAULT NULL COMMENT '登录时间',
  `expired_at` bigint DEFAULT NULL COMMENT '过期时间',
  `extra` text COMMENT '扩展信息',
  `created_at` bigint unsigned NOT NULL COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `keyword` (`user_id`,`oauther_id`,`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户渠道表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `userinfo` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `field` char(32) NOT NULL COMMENT '字段',
  `value` varchar(512) NOT NULL COMMENT '字段值',
  `value_md5` varchar(512) NOT NULL COMMENT '字段和值md5',
  `created_at` bigint unsigned NOT NULL COMMENT '创建时间',
  `updated_at` bigint unsigned NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_field` (`user_id`,`field`),
  KEY `value_md5` (`value_md5`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户信息';
/*!40101 SET character_set_client = @saved_cs_client */;

SET FOREIGN_KEY_CHECKS=1;
