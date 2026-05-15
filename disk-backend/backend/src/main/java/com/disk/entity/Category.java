package com.disk.entity;

import lombok.Data;

@Data
public class Category {
    private Long id;
    private String name;
    private String description;
    private Integer sortOrder;
    private Integer topicCount;
    private Long createdAt;
    private Long updatedAt;
}
