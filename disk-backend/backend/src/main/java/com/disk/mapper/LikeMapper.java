package com.disk.mapper;

import com.disk.entity.Like;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface LikeMapper {
    int insert(Like like);
    int delete(@Param("topicId") Long topicId, @Param("userId") Long userId);
    int exists(@Param("topicId") Long topicId, @Param("userId") Long userId);
    int countByTopicId(Long topicId);
}
