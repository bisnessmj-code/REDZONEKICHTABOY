-- PANEL ADMIN FIGHT LEAGUE - Staff Chat Table

CREATE TABLE IF NOT EXISTS `panel_staff_chat` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `staff_identifier` VARCHAR(60) NOT NULL,
    `staff_name` VARCHAR(100) NOT NULL,
    `staff_group` VARCHAR(50) NOT NULL,
    `message` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_staff_identifier` (`staff_identifier`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
