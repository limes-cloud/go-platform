-- 定时链执行入参：exec_type=chain 时保存 request.body JSON。
-- 可在已有 cron 库重复执行；新库直接使用 cron_schema.sql。
SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'task'
    AND column_name = 'chain_input'
);
SET @ddl = IF(
  @column_exists = 0,
  'ALTER TABLE `task` ADD COLUMN `chain_input` mediumtext DEFAULT NULL COMMENT ''执行指定流程的入参 JSON（request.body）'' AFTER `exec_value`',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
