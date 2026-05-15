-- ============================================
-- Mini Personal Cloud Disk — 数据库初始化脚本
-- 适用于新环境从零搭建
-- ============================================

CREATE DATABASE IF NOT EXISTS cloud_disk
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_general_ci;

USE cloud_disk;

-- --------------------------------------------
-- 用户表
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    username   VARCHAR(50)  NOT NULL UNIQUE,
    password   VARCHAR(255) NOT NULL,
    email      VARCHAR(100),
    role       VARCHAR(20)  NOT NULL DEFAULT 'user'  COMMENT 'user / admin',
    status     INT          NOT NULL DEFAULT 1        COMMENT '1=正常, 0=禁用',
    created_at BIGINT,
    updated_at BIGINT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- 文件表
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS files (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id    BIGINT       NOT NULL,
    file_name  VARCHAR(255) NOT NULL,
    file_path  VARCHAR(500) NOT NULL,
    file_size  BIGINT,
    file_type  VARCHAR(50),
    file_hash  VARCHAR(64),
    parent_id  BIGINT       DEFAULT 0,
    is_folder  TINYINT      DEFAULT 0,
    remark     VARCHAR(500) DEFAULT NULL              COMMENT '用户备注',
    created_at BIGINT,
    updated_at BIGINT,
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- 论坛 - 分类表
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS forum_categories (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50)  NOT NULL UNIQUE  COMMENT '分类名称',
    description VARCHAR(255) DEFAULT NULL     COMMENT '分类描述',
    sort_order  INT          DEFAULT 0        COMMENT '排序',
    topic_count INT          DEFAULT 0        COMMENT '主题数',
    created_at  BIGINT,
    updated_at  BIGINT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- 论坛 - 主题表
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS forum_topics (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    title         VARCHAR(200) NOT NULL        COMMENT '标题',
    content       TEXT         NOT NULL        COMMENT '内容',
    category_id   BIGINT       NOT NULL        COMMENT '分类ID',
    user_id       BIGINT       NOT NULL        COMMENT '作者ID',
    view_count    INT          DEFAULT 0       COMMENT '浏览数',
    reply_count   INT          DEFAULT 0       COMMENT '回复数',
    like_count    INT          DEFAULT 0       COMMENT '点赞数',
    status        TINYINT      DEFAULT 1       COMMENT '1=正常, 0=删除',
    last_reply_at BIGINT       DEFAULT NULL    COMMENT '最后回复时间',
    last_reply_by BIGINT       DEFAULT NULL    COMMENT '最后回复用户ID',
    created_at    BIGINT,
    updated_at    BIGINT,
    FOREIGN KEY (category_id) REFERENCES forum_categories(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- 论坛 - 回复表
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS forum_replies (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    topic_id   BIGINT  NOT NULL                COMMENT '主题ID',
    user_id    BIGINT  NOT NULL                COMMENT '回复者ID',
    content    TEXT    NOT NULL                COMMENT '回复内容',
    status     TINYINT DEFAULT 1               COMMENT '1=正常, 0=删除',
    created_at BIGINT,
    updated_at BIGINT,
    FOREIGN KEY (topic_id) REFERENCES forum_topics(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- 论坛 - 标签表
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS forum_tags (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(30) NOT NULL UNIQUE      COMMENT '标签名',
    created_at BIGINT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- 论坛 - 主题标签关联表
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS forum_topic_tags (
    id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    topic_id BIGINT NOT NULL,
    tag_id   BIGINT NOT NULL,
    UNIQUE KEY uk_topic_tag (topic_id, tag_id),
    FOREIGN KEY (topic_id) REFERENCES forum_topics(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES forum_tags(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- 论坛 - 点赞表
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS forum_likes (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    topic_id   BIGINT NOT NULL,
    user_id    BIGINT NOT NULL,
    created_at BIGINT,
    UNIQUE KEY uk_topic_user (topic_id, user_id),
    FOREIGN KEY (topic_id) REFERENCES forum_topics(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 初始分类数据
INSERT IGNORE INTO forum_categories (name, description, sort_order, created_at, updated_at) VALUES
('综合讨论', '各类话题自由讨论', 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
('技术分享', '编程技术、开发经验交流', 2, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
('资源分享', '学习资源、工具推荐', 3, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
('问题求助', '遇到问题来这里寻求帮助', 4, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);
