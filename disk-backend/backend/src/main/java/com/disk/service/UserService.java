package com.disk.service;

import com.disk.entity.User;

public interface UserService {
    User login(String username, String password);
    User register(User user);
    User findById(Long id);
    User update(User user);
    int delete(Long id);
}
