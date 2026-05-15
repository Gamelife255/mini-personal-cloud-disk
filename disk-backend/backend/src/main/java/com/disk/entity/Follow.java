package com.disk.entity;

import lombok.Data;

@Data
public class Follow {
    private Long id;
    private Long followerId;
    private Long followingId;
    private Long createdAt;
}
