-- Fresh manager DB seed: login entry app + base app registry.
-- Placeholder __JWT_SECRET__ is replaced by init-db.sh.
SET NAMES utf8mb4;

INSERT INTO `app`
  (`type`, `logo`, `favicon`, `keyword`, `name`, `show_name`, `private`, `loginable`,
   `status`, `reason`, `description`, `comment`, `setting`, `created_at`, `updated_at`)
VALUES
  ('app', '', '', 'manager', '系统管理', '统一应用管理平台', 0, 1, 1, NULL, NULL, NULL,
   '{"jwt":{"secret":"__JWT_SECRET__","expire":36000,"renewal":3600},"modules":["resource","configure","gateway","cron","ai-agent"]}',
   UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE
  `type` = VALUES(`type`),
  `name` = VALUES(`name`),
  `show_name` = VALUES(`show_name`),
  `private` = VALUES(`private`),
  `loginable` = VALUES(`loginable`),
  `status` = VALUES(`status`),
  `setting` = VALUES(`setting`),
  `updated_at` = VALUES(`updated_at`);

INSERT INTO `app`
  (`type`, `logo`, `favicon`, `keyword`, `name`, `show_name`, `private`, `loginable`,
   `status`, `reason`, `description`, `comment`, `setting`, `created_at`, `updated_at`)
VALUES
  ('base', '', '', 'resource', '资源管理', '资源管理', 0, 0, 1, NULL, NULL, NULL, '', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
  ('base', '', '', 'configure', '配置中心', '配置中心', 0, 0, 1, NULL, NULL, NULL, '', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
  ('base', '', '', 'gateway', '通用网关', '通用网关', 0, 0, 1, NULL, NULL, NULL, '', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
  ('base', '', '', 'cron', '定时任务', '定时任务', 0, 0, 1, NULL, NULL, NULL, '', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
  ('base', '', '', 'ai-agent', 'AI 中台', 'AI 中台', 0, 0, 1, NULL, NULL, NULL, '', UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE
  `type` = VALUES(`type`),
  `name` = VALUES(`name`),
  `show_name` = VALUES(`show_name`),
  `loginable` = VALUES(`loginable`),
  `status` = VALUES(`status`),
  `updated_at` = VALUES(`updated_at`);
