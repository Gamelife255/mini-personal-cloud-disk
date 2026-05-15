package com.disk.mapper;

import com.disk.entity.Follow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

@Mapper
public interface FollowMapper {
    int insert(Follow follow);
    int delete(@Param("followerId") Long followerId, @Param("followingId") Long followingId);
    int exists(@Param("followerId") Long followerId, @Param("followingId") Long followingId);
    int countFollowers(Long userId);
    int countFollowing(Long userId);
    List<Map<String, Object>> findFollowers(@Param("userId") Long userId, @Param("offset") int offset, @Param("limit") int limit);
    List<Map<String, Object>> findFollowing(@Param("userId") Long userId, @Param("offset") int offset, @Param("limit") int limit);
}
