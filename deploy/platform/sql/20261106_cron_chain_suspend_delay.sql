-- 调度链挂起策略：重试耗尽后延迟重跑，首次挂起时间用于累计 maxWait。
-- 可在已有 cron 库重复执行；新库直接使用 server/cron/deploy/data.sql。
SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'chain_run_node'
    AND column_name = 'suspend_expire_at'
);
SET @ddl = IF(
  @column_exists = 0,
  'ALTER TABLE `chain_run_node` ADD COLUMN `suspend_expire_at` bigint DEFAULT NULL COMMENT ''挂起最终截止时间（Unix 秒）；NULL = 未处于挂起'' AFTER `deadline_at`',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
