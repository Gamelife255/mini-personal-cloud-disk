package com.disk.entity;

import lombok.Data;

@Data
public class TopicTag {
    private Long id;
    private Long topicId;
    private Long tagId;
}
