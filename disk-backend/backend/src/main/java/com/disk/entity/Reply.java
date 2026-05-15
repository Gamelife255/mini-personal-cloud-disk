package com.disk.entity;

import lombok.Data;

@Data
public class Reply {
    private Long id;
    private Long topicId;
    private Long userId;
    private String content;
    private Integer status;
    private Long createdAt;
    private Long updatedAt;
}
