package com.disk.mapper;

import com.disk.entity.Topic;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

@Mapper
public interface TopicMapper {
    List<Map<String, Object>> findByCategoryId(@Param("categoryId") Long categoryId,
                                                @Param("offset") int offset,
                                                @Param("limit") int limit,
                                                @Param("sortBy") String sortBy);
    int countByCategoryId(@Param("categoryId") Long categoryId);
    List<Map<String, Object>> findByUserId(@Param("userId") Long userId,
                                            @Param("offset") int offset,
                                            @Param("limit") int limit);
    int countByUserId(Long userId);
    Map<String, Object> findByIdWithAuthor(@Param("id") Long id);
    int insert(Topic topic);
    int update(Topic topic);
    int softDelete(Long id);
    int incrementViewCount(Long id);
    int updateReplyInfo(@Param("id") Long id,
                        @Param("lastReplyAt") Long lastReplyAt,
                        @Param("lastReplyBy") Long lastReplyBy);
    int incrementLikeCount(Long id);
    int decrementLikeCount(Long id);
}
