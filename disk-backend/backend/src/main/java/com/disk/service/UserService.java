package com.disk.service;

import com.disk.entity.User;

import java.util.List;

public interface UserService {
    User login(String username, String password);
    User register(User user);
    User findById(Long id);
    User findByEmail(String email);
    User update(User user);
    int delete(Long id);
    void sendVerificationCode(String email);
    User registerWithCode(User user, String code);
    void sendPasswordResetCode(String email);
    void resetPassword(String email, String code, String newPassword);
    List<User> findAll();
    int updateStatus(Long id, Integer status);
    int adminResetPassword(Long id, String newPassword);
}
