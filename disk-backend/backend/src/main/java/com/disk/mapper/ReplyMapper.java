package com.disk.mapper;

import com.disk.entity.Reply;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

@Mapper
public interface ReplyMapper {
    List<Map<String, Object>> findByTopicId(@Param("topicId") Long topicId,
                                             @Param("offset") int offset,
                                             @Param("limit") int limit);
    int countByTopicId(Long topicId);
    Map<String, Object> findById(Long id);
    int insert(Reply reply);
    int softDelete(Long id);
}
