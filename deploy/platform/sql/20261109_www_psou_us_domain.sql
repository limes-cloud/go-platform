-- 将 www.psou.us 绑定到现有 psou_us 应用，作为 psou.us 的非主域名。
SET NAMES utf8mb4;

INSERT INTO `app_domain` (`app_keyword`, `domain`, `is_primary`)
SELECT 'psou_us', 'www.psou.us', 0
FROM DUAL
WHERE EXISTS (SELECT 1 FROM `app` WHERE `keyword` = 'psou_us')
ON DUPLICATE KEY UPDATE
  `app_keyword` = VALUES(`app_keyword`),
  `is_primary` = VALUES(`is_primary`);
