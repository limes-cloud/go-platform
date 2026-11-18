-- 批次状态改为纯进度语义：pending | running | completed | canceled
UPDATE `chain_batch` SET `status` = 'completed' WHERE `status` IN ('success', 'fail');

ALTER TABLE `chain_batch`
  MODIFY COLUMN `status` varchar(16) NOT NULL DEFAULT 'pending'
  COMMENT 'pending | running | completed | canceled';
