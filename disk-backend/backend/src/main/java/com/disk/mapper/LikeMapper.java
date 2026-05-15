package com.disk.mapper;

import com.disk.entity.Like;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

@Mapper
public interface LikeMapper {
    int insert(Like like);
    int delete(@Param("topicId") Long topicId, @Param("userId") Long userId);
    int exists(@Param("topicId") Long topicId, @Param("userId") Long userId);
    int countByTopicId(Long topicId);
    List<Map<String, Object>> findByUserId(@Param("userId") Long userId, @Param("offset") int offset, @Param("limit") int limit);
    int countByUserId(Long userId);
}
