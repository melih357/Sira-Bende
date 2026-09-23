-- Sıra Bende - mevcut eski kurulumları Revize 1 yapısına yükseltmek için
-- Taze kurulumda yalnızca database.sql içe aktarılmalıdır.
USE sirabende;
SET NAMES utf8mb4;

DELIMITER $$
DROP PROCEDURE IF EXISTS add_column_if_missing$$
CREATE PROCEDURE add_column_if_missing(IN p_table VARCHAR(64), IN p_column VARCHAR(64), IN p_definition TEXT)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND COLUMN_NAME=p_column
  ) THEN
    SET @sql_text=CONCAT('ALTER TABLE `',p_table,'` ADD COLUMN `',p_column,'` ',p_definition);
    PREPARE stmt FROM @sql_text; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;

CALL add_column_if_missing('users','held_credits','DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER credit_balance');
CALL add_column_if_missing('users','total_help_minutes','INT UNSIGNED NOT NULL DEFAULT 0 AFTER trust_score');
CALL add_column_if_missing('users','availability','VARCHAR(255) NULL AFTER bio');
CALL add_column_if_missing('users','verification_code','VARCHAR(10) NULL');
CALL add_column_if_missing('users','verification_expires_at','DATETIME NULL');
CALL add_column_if_missing('users','phone_verified_at','DATETIME NULL');
CALL add_column_if_missing('listings','complexity_bonus','DECIMAL(4,2) NOT NULL DEFAULT 0 AFTER estimated_minutes');
CALL add_column_if_missing('listings','special_conditions','TEXT NULL');
CALL add_column_if_missing('listings','featured','TINYINT(1) NOT NULL DEFAULT 0');
CALL add_column_if_missing('exchanges','requester_confirmed','TINYINT(1) NOT NULL DEFAULT 0');
CALL add_column_if_missing('exchanges','provider_confirmed','TINYINT(1) NOT NULL DEFAULT 0');
CALL add_column_if_missing('exchanges','dispute_reason','TEXT NULL');
CALL add_column_if_missing('groups','messaging_enabled','TINYINT(1) NOT NULL DEFAULT 1');
CALL add_column_if_missing('group_members','is_muted','TINYINT(1) NOT NULL DEFAULT 0');
CALL add_column_if_missing('group_members','muted_until','DATETIME NULL');
DROP PROCEDURE IF EXISTS add_column_if_missing;

CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  message VARCHAR(500) NOT NULL,
  link VARCHAR(255) NULL,
  read_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_notifications_user(user_id,read_at,created_at),
  CONSTRAINT fk_notifications_user_migration FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  actor_id BIGINT UNSIGNED NULL,
  action VARCHAR(100) NOT NULL,
  target_type VARCHAR(50) NOT NULL,
  target_id BIGINT UNSIGNED NULL,
  metadata JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_target(target_type,target_id),
  INDEX idx_audit_date(created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS group_messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  group_id BIGINT UNSIGNED NOT NULL,
  sender_id BIGINT UNSIGNED NOT NULL,
  message TEXT NULL,
  attachment_path VARCHAR(255) NULL,
  attachment_type ENUM('image','document') NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_group_messages_date(group_id,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
