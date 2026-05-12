package com.disk.service;

import com.disk.entity.User;

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
}
