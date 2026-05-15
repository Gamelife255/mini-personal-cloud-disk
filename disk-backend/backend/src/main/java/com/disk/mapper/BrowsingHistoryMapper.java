package com.disk.mapper;

import com.disk.entity.BrowsingHistory;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

@Mapper
public interface BrowsingHistoryMapper {
    int insert(BrowsingHistory history);
    List<Map<String, Object>> findByUserId(@Param("userId") Long userId, @Param("offset") int offset, @Param("limit") int limit);
    int countByUserId(Long userId);
    int deleteByUserIdAndTopicId(@Param("userId") Long userId, @Param("topicId") Long topicId);
}
