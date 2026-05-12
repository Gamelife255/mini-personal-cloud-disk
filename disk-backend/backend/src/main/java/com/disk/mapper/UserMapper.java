package com.disk.mapper;

import com.disk.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface UserMapper {
    User findByUsername(String username);
    User findByEmail(String email);
    User findById(Long id);
    int insert(User user);
    int update(User user);
    int delete(Long id);
    List<User> findAll();
    int updateStatus(@Param("id") Long id, @Param("status") Integer status, @Param("updatedAt") Long updatedAt);
    int updatePassword(@Param("id") Long id, @Param("password") String password, @Param("updatedAt") Long updatedAt);
}
