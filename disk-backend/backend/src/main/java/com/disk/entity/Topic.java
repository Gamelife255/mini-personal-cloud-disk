package com.disk.entity;

import lombok.Data;

@Data
public class Topic {
    private Long id;
    private String title;
    private String content;
    private Long categoryId;
    private Long userId;
    private Integer viewCount;
    private Integer replyCount;
    private Integer likeCount;
    private Integer status;
    private Long lastReplyAt;
    private Long lastReplyBy;
    private Long createdAt;
    private Long updatedAt;
}
