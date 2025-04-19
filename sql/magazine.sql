-- Drop existing tables if they exist
DROP TABLE IF EXISTS `player_magazines`;
DROP TABLE IF EXISTS `magazine_pages`;
DROP TABLE IF EXISTS `magazine_editions`;

-- Create editions table
CREATE TABLE IF NOT EXISTS `magazine_editions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `edition_number` int(11) NOT NULL,
    `title` varchar(100) NOT NULL,
    `is_active` tinyint(1) DEFAULT 0,
    `is_published` tinyint(1) DEFAULT 0,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_edition` (`edition_number`),
    INDEX `idx_edition_number` (`edition_number`),
    INDEX `idx_is_active` (`is_active`),
    INDEX `idx_is_published` (`is_published`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create magazine pages table
CREATE TABLE IF NOT EXISTS `magazine_pages` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `page_number` int(11) NOT NULL DEFAULT 0,
    `image_url` varchar(255) NOT NULL,
    `edition_number` int(11) NOT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_pages_edition` (`edition_number`),
    FOREIGN KEY `fk_pages_edition` (`edition_number`)
        REFERENCES `magazine_editions` (`edition_number`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;