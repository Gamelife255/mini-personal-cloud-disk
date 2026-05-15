package com.disk.mapper;

import com.disk.entity.TopicTag;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface TopicTagMapper {
    int insert(TopicTag topicTag);
    int deleteByTopicId(Long topicId);
    List<Long> findTagIdsByTopicId(Long topicId);
    List<TopicTag> findByTagId(@Param("tagId") Long tagId, @Param("offset") int offset, @Param("limit") int limit);
}
