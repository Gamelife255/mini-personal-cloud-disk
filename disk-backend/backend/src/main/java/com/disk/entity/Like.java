package com.disk.entity;

import lombok.Data;

@Data
public class Like {
    private Long id;
    private Long topicId;
    private Long userId;
    private Long createdAt;
}
