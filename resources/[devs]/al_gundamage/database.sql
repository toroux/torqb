

CREATE TABLE IF NOT EXISTS `guns_damage_table` (
    `weapon` VARCHAR(100) NOT NULL,
    `damage` DECIMAL(5,2) NOT NULL DEFAULT 1.00,
    PRIMARY KEY (`weapon`),
    INDEX `idx_weapon` (`weapon`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `guns_recoil_table` (
    `weapon` VARCHAR(100) NOT NULL,
    `recoil` DECIMAL(5,2) NOT NULL DEFAULT 1.00,
    PRIMARY KEY (`weapon`),
    INDEX `idx_weapon` (`weapon`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `guns_durability_table` (
    `weapon` VARCHAR(100) NOT NULL,
    `durability` DECIMAL(5,2) NOT NULL DEFAULT 0.30,
    PRIMARY KEY (`weapon`),
    INDEX `idx_weapon` (`weapon`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `weapon_tuning_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_name` VARCHAR(255) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `license` VARCHAR(255) NOT NULL,
    `weapon` VARCHAR(100) NOT NULL,
    `damage` DECIMAL(5,2) NOT NULL,
    `recoil` DECIMAL(5,2) NOT NULL,
    `timestamp` DATETIME NOT NULL,
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_weapon` (`weapon`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
