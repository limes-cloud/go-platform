-- Resource 服务建表脚本（8 张表）
--
-- 依据：.prd/SQL设计.md（权威）。本文件只放 DDL；值域校验与跨表引用一律不进 DDL，
-- 由服务层写入校验 + 启动自检兜底（12-工程与交付 §1）。
--
-- 使用方式：部署后手工执行一次。注意：
--   1) store 初始行含真实 AK/SK，其 INSERT **不进 git**，由运维单独执行（见下方注释）；
--   2) 全库不用 MySQL 8.0 专属语法（无 CTE、无窗口函数、无 utf8mb4_0900_*）；
--   3) 表级排序规则统一 utf8mb4_unicode_ci；唯一键一律显式声明列级 _bin 字符集。

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 1. store —— 对象存储后端
-- 行只增不减：没有删除，只有 status=0 停用（keyword 是全库引用目标 + 亿级历史行的桶指针）。
-- 本表不建 status 索引（全表几十行，且读路径走启动时全量加载进进程内 map）。
-- ---------------------------------------------------------------------------
CREATE TABLE `store` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `keyword`         CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '后端标识',
  `name`            VARCHAR(64)  NOT NULL COMMENT '显示名称',
  `provider`        VARCHAR(32)  NOT NULL COMMENT '厂商标识',
  `endpoint`        VARCHAR(255) NOT NULL COMMENT '厂商API域名',
  `region`          VARCHAR(64)  NOT NULL COMMENT '地域',
  `bucket`          VARCHAR(63)  NOT NULL COMMENT '桶名',
  `ak`              VARCHAR(128) NOT NULL COMMENT '访问密钥ID',
  `sk`              VARCHAR(512) NOT NULL COMMENT '访问密钥',
  `public_base_url` VARCHAR(255) NOT NULL COMMENT '公网访问地址前缀',
  `cdn_auth_type`   VARCHAR(16)  NOT NULL DEFAULT 'none' COMMENT '临时URL鉴权方式',
  `cdn_auth_key`    VARCHAR(255) NULL COMMENT 'CDN鉴权key',
  `status`          TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态 1启用 0停用',
  `description`     VARCHAR(256) NULL COMMENT '备注',
  `updated_by`      INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改人',
  `created_at`      BIGINT UNSIGNED NOT NULL COMMENT '创建时间',
  `updated_at`      BIGINT UNSIGNED NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_store_keyword` (`keyword`),
  UNIQUE KEY `uidx_store_endpoint_bucket` (`endpoint`, `bucket`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='对象存储后端';

-- store 初始行（含真实 SK）示例，**不要提交进 git**，由运维部署后单独执行：
-- INSERT INTO `store`
--   (`keyword`,`name`,`provider`,`endpoint`,`region`,`bucket`,`ak`,`sk`,
--    `public_base_url`,`cdn_auth_type`,`cdn_auth_key`,`status`,`description`,`updated_by`,
--    `created_at`,`updated_at`)
-- VALUES
--   ('bdemo','示例桶','bos','s3.bj.bcebos.com','bj','bdemo','<AK>','<SK>',
--    'https://cdn.example.com','none',NULL,1,NULL,0,
--    UNIX_TIMESTAMP(),UNIX_TIMESTAMP());

-- ---------------------------------------------------------------------------
-- 2. app_config —— 应用存储配置
-- 被数据面引用的配置行：不提供删除，下线 = status=0（走 Update 写动词，自动带延迟双删）。
-- 本表只有 uidx_app_config_app 一个索引（读路径走唯一键 + Redis 回填）。
-- ---------------------------------------------------------------------------
CREATE TABLE `app_config` (
  `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app`                  CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '应用标识',
  `store_keyword`        CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '上传落地的存储后端',
  `export_store_keyword` CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL COMMENT '导出产物的存储后端',
  `default_accept`       VARCHAR(255) NOT NULL COMMENT '默认允许后缀',
  `default_max_size`     INT UNSIGNED NOT NULL COMMENT '默认单文件上限',
  `temp_url_ttl`         INT UNSIGNED NOT NULL DEFAULT 900 COMMENT '临时URL有效期',
  `export_ttl`           INT UNSIGNED NOT NULL DEFAULT 259200 COMMENT '导出产物保留期',
  `quota`                BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '存储配额(字节),0=不限',
  `used_bytes`           BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '已用量(字节)',
  `status`               TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态 1启用 0停用',
  `updated_by`           INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改人',
  `created_at`           BIGINT UNSIGNED NOT NULL COMMENT '创建时间',
  `updated_at`           BIGINT UNSIGNED NOT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_app_config_app` (`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='应用存储配置';

-- ---------------------------------------------------------------------------
-- 3. directory —— 应用目录树（物化路径，无 parent_id）
-- 限深 10 是 path 列长成立的前提：10×64 + 10 = 650 ≤ 660。
-- uidx_directory_app_path 条目 32×4 + 660×4 + 2 = 2770 < 3072，故必须 ROW_FORMAT=DYNAMIC。
-- ---------------------------------------------------------------------------
CREATE TABLE `directory` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app`        CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '应用标识',
  `name`       VARCHAR(64)  NOT NULL COMMENT '目录名',
  `path`       VARCHAR(660) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '物化路径',
  `accept`     VARCHAR(255) NOT NULL COMMENT '允许后缀',
  `max_size`   INT UNSIGNED NOT NULL COMMENT '单文件上限',
  `updated_by` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改人',
  `created_at` BIGINT UNSIGNED NOT NULL COMMENT '创建时间',
  `updated_at` BIGINT UNSIGNED NOT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_directory_app_path` (`app`, `path`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='应用目录树';

-- ---------------------------------------------------------------------------
-- 4. object —— 物理对象（内容寻址）
-- 只服务写侧（去重判定）与回收侧（GC、离线核对），公共读一次库都不查。
-- 没有 app / object_key / etag / ref_count / status 列。
-- ---------------------------------------------------------------------------
CREATE TABLE `object` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_keyword` CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '存储后端标识',
  `md5`           CHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '内容摘要（分片摘要的摘要）',
  `ext`           VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT '后缀',
  `size`          BIGINT UNSIGNED NOT NULL COMMENT '对象大小',
  `created_at`    BIGINT UNSIGNED NOT NULL COMMENT '创建时间',
  `updated_at`    BIGINT UNSIGNED NOT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_object_store_md5` (`store_keyword`, `md5`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='物理对象';

-- ---------------------------------------------------------------------------
-- 5. upload —— 分片上传会话（只有活跃会话，"行存在 = 会话活着"）
-- updated_at 是 GC 的滑动过期时钟（计时列，唯一 UPDATE 是 TouchUpload）。
-- ---------------------------------------------------------------------------
CREATE TABLE `upload` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_keyword` CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '存储后端标识',
  `md5`           CHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '内容摘要（分片摘要的摘要）',
  `ext`           VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT '后缀',
  `user_id`       INT UNSIGNED NOT NULL COMMENT '发起用户ID，必须>0',
  `directory_id`  INT UNSIGNED NOT NULL COMMENT '目标目录ID',
  `name`          VARCHAR(256) NOT NULL COMMENT '业务文件名',
  `upload_id`     VARCHAR(512) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '厂商分片上传ID',
  `total_size`    BIGINT UNSIGNED NOT NULL COMMENT '声明总大小',
  `created_at`    BIGINT UNSIGNED NOT NULL COMMENT '创建时间',
  `updated_at`    BIGINT UNSIGNED NOT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_upload_upload_id` (`upload_id`),
  UNIQUE KEY `uidx_upload_session` (`store_keyword`, `md5`, `user_id`, `directory_id`),
  KEY `idx_upload_updated` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='分片上传会话';

-- ---------------------------------------------------------------------------
-- 6. file —— 业务文件条目
-- 结构不变式 file.app ≡ directory.app（完成事务从 directory 派生）。
-- ---------------------------------------------------------------------------
CREATE TABLE `file` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app`          CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '应用标识',
  `user_id`      INT UNSIGNED NOT NULL COMMENT '上传用户ID，必须>0',
  `directory_id` INT UNSIGNED NOT NULL COMMENT '目录ID',
  `name`         VARCHAR(256) NOT NULL COMMENT '业务文件名',
  `object_id`    INT UNSIGNED NOT NULL COMMENT '物理对象ID',
  `upload_id`    VARCHAR(512) CHARACTER SET ascii COLLATE ascii_bin NULL COMMENT '产出该行的上传会话ID',
  `status`       TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1正常 2待删除',
  `created_at`   BIGINT UNSIGNED NOT NULL COMMENT '创建时间',
  `updated_at`   BIGINT UNSIGNED NOT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_file_upload_id` (`upload_id`),
  KEY `idx_file_app_user` (`app`, `user_id`),
  KEY `idx_file_app_directory` (`app`, `directory_id`),
  KEY `idx_file_object` (`object_id`),
  KEY `idx_file_status` (`status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='业务文件';

-- ---------------------------------------------------------------------------
-- 7. export_task —— 导出产出物与生产状态
-- ⏸ 首版不实现导出功能，但两张表 DDL 首版照建（供启动自检覆盖）。
-- leased_at / failed_at 是计时列；updated_at 是纯审计列。
-- ---------------------------------------------------------------------------
CREATE TABLE `export_task` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app`           CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '应用标识',
  `md5`           CHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '导出内容MD5',
  `store_keyword` CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '产出物落地的存储后端',
  `size`          BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '产出物大小',
  `status`        TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态 0待执行 1执行中 2成功 3失败 4已过期',
  `retry`         TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '已尝试次数',
  `reason`        VARCHAR(512) NULL COMMENT '最后一次失败原因',
  `expired_at`    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '产出物过期时间',
  `leased_at`     BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'worker 最后一次领取或心跳时间（Unix 秒），0=从未领取',
  `failed_at`     BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '本轮退避的计时起点（最后一次失败时间，Unix 秒），0=本轮未失败过',
  `created_at`    BIGINT UNSIGNED NOT NULL COMMENT '创建时间',
  `updated_at`    BIGINT UNSIGNED NOT NULL COMMENT '修改时间（纯审计，由 GORM 自动维护）',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_export_task_app_md5` (`app`, `md5`),
  KEY `idx_export_task_claim` (`status`, `failed_at`),
  KEY `idx_export_task_expire` (`status`, `expired_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='导出产出物';

-- ---------------------------------------------------------------------------
-- 8. export —— 用户导出请求记录
-- 结构不变式 export.app ≡ export_task.app（创建请求的同一事务内从任务行派生）。
-- ---------------------------------------------------------------------------
CREATE TABLE `export` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app`        CHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '应用标识',
  `task_id`    INT UNSIGNED NOT NULL COMMENT '导出产出物ID',
  `user_id`    INT UNSIGNED NOT NULL COMMENT '发起用户ID',
  `name`       VARCHAR(256) NOT NULL COMMENT '用户可见名称',
  `created_at` BIGINT UNSIGNED NOT NULL COMMENT '创建时间',
  `updated_at` BIGINT UNSIGNED NOT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_export_app_user` (`app`, `user_id`),
  KEY `idx_export_task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='导出请求记录';
