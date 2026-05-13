CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    role VARCHAR(20) NOT NULL DEFAULT 'user',
    status INT NOT NULL DEFAULT 1,
    created_at BIGINT,
    updated_at BIGINT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS files (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT,
    file_type VARCHAR(50),
    file_hash VARCHAR(64),
    parent_id BIGINT DEFAULT 0,
    is_folder TINYINT DEFAULT 0,
    created_at BIGINT,
    remark VARCHAR(500) DEFAULT NULL,
    updated_at BIGINT,
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Migration: add remark column to existing files table
-- 数据迁移：向现有文件表新增备注字段
-- ALTER TABLE files ADD COLUMN remark VARCHAR(500) DEFAULT NULL;
-- 更改表结构：为 files 表添加 remark 字段，字符长度 500，默认值为空；
