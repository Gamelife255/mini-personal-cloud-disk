package com.disk.mapper;

import com.disk.entity.User;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserMapper {
    User findByUsername(String username);
    User findByEmail(String email);
    User findById(Long id);
    int insert(User user);
    int update(User user);
    int delete(Long id);
}
