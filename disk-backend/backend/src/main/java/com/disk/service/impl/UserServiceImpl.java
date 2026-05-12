package com.disk.service.impl;

import com.disk.entity.User;
import com.disk.mapper.UserMapper;
import com.disk.service.EmailService;
import com.disk.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserServiceImpl implements UserService {
    @Autowired
    private UserMapper userMapper;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Autowired
    private EmailService emailService;

    @Override
    public User login(String username, String password) {
        User user = userMapper.findByUsername(username);
        if (user != null && passwordEncoder.matches(password, user.getPassword())) {
            if (user.getStatus() != null && user.getStatus() == 0) {
                throw new RuntimeException("账户已被禁用");
            }
            return user;
        }
        return null;
    }

    @Override
    public User register(User user) {
        User existingUser = userMapper.findByUsername(user.getUsername());
        if (existingUser != null) {
            throw new RuntimeException("用户名已存在");
        }
        user.setRole(user.getRole() != null ? user.getRole() : "user");
        user.setStatus(user.getStatus() != null ? user.getStatus() : 1);
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        user.setCreatedAt(System.currentTimeMillis());
        user.setUpdatedAt(System.currentTimeMillis());
        userMapper.insert(user);
        return user;
    }

    @Override
    public User findById(Long id) {
        return userMapper.findById(id);
    }

    @Override
    public User findByEmail(String email) {
        return userMapper.findByEmail(email);
    }

    @Override
    public User update(User user) {
        user.setUpdatedAt(System.currentTimeMillis());
        userMapper.update(user);
        return user;
    }

    @Override
    public int delete(Long id) {
        return userMapper.delete(id);
    }

    @Override
    public void sendVerificationCode(String email) {
        emailService.sendVerificationCode(email);
    }

    @Override
    public User registerWithCode(User user, String code) {
        if (!emailService.verifyCode(user.getEmail(), code)) {
            throw new RuntimeException("验证码错误或已过期");
        }
        return register(user);
    }

    @Override
    public void sendPasswordResetCode(String email) {
        User user = userMapper.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("该邮箱未注册");
        }
        emailService.sendPasswordResetCode(email);
    }

    @Override
    public void resetPassword(String email, String code, String newPassword) {
        if (!emailService.verifyCode(email, code)) {
            throw new RuntimeException("验证码错误或已过期");
        }
        User user = userMapper.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("该邮箱未注册");
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        user.setUpdatedAt(System.currentTimeMillis());
        userMapper.update(user);
    }

    @Override
    public List<User> findAll() {
        return userMapper.findAll();
    }

    @Override
    public int updateStatus(Long id, Integer status) {
        return userMapper.updateStatus(id, status, System.currentTimeMillis());
    }

    @Override
    public int adminResetPassword(Long id, String newPassword) {
        return userMapper.updatePassword(id, passwordEncoder.encode(newPassword), System.currentTimeMillis());
    }
}
