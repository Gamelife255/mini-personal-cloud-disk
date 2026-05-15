package com.disk.entity;

import lombok.Data;

@Data
public class BrowsingHistory {
    private Long id;
    private Long userId;
    private Long topicId;
    private Long createdAt;
}
