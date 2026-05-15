package com.disk.controller;

import com.disk.entity.User;
import com.disk.service.UserService;
import com.disk.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/user")
public class UserController {
    @Autowired
    private UserService userService;

    @Autowired
    private StringRedisTemplate redisTemplate;

    private static final String BLACKLIST_PREFIX = "jwt_blacklist:";

    @PostMapping("/login")
    public Object login(@RequestBody User user) {
        try {
            User result = userService.login(user.getUsername(), user.getPassword());
            if (result != null) {
                String token = JwtUtil.generateToken(result.getId(), result.getUsername(), result.getRole());
                Map<String, Object> response = new HashMap<>();
                response.put("token", token);
                response.put("user", result);
                return response;
            }
            Map<String, Object> error = new HashMap<>();
            error.put("code", 401);
            error.put("message", "用户名或密码错误");
            return error;
        } catch (RuntimeException e) {
            Map<String, Object> error = new HashMap<>();
            error.put("code", 403);
            error.put("message", e.getMessage());
            return error;
        }
    }

    @PostMapping("/register")
    public Object register(@RequestBody Map<String, Object> params) {
        try {
            String username = (String) params.get("username");
            String password = (String) params.get("password");
            String email = (String) params.get("email");
            String code = (String) params.get("code");

            User user = new User();
            user.setUsername(username);
            user.setPassword(password);
            user.setEmail(email);

            User result = userService.registerWithCode(user, code);
            String token = JwtUtil.generateToken(result.getId(), result.getUsername(), result.getRole());
            Map<String, Object> response = new HashMap<>();
            response.put("code", 200);
            response.put("token", token);
            response.put("user", result);
            return response;
        } catch (RuntimeException e) {
            Map<String, Object> error = new HashMap<>();
            error.put("code", 400);
            error.put("message", e.getMessage());
            return error;
        }
    }

    @PostMapping("/send-verify-code")
    public Map<String, Object> sendVerifyCode(@RequestBody Map<String, String> params) {
        Map<String, Object> result = new HashMap<>();
        try {
            String email = params.get("email");
            if (email == null || email.isEmpty()) {
                result.put("code", 400);
                result.put("message", "邮箱不能为空");
                return result;
            }
            userService.sendVerificationCode(email);
            result.put("code", 200);
            result.put("message", "验证码已发送");
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", e.getMessage());
        }
        return result;
    }

    @PostMapping("/send-reset-code")
    public Map<String, Object> sendResetCode(@RequestBody Map<String, String> params) {
        Map<String, Object> result = new HashMap<>();
        try {
            String email = params.get("email");
            if (email == null || email.isEmpty()) {
                result.put("code", 400);
                result.put("message", "邮箱不能为空");
                return result;
            }
            userService.sendPasswordResetCode(email);
            result.put("code", 200);
            result.put("message", "验证码已发送");
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", e.getMessage());
        }
        return result;
    }

    @PostMapping("/logout")
    public Map<String, Object> logout(HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        String token = request.getHeader("Authorization");
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
            try {
                Date expiration = JwtUtil.getExpirationFromToken(token);
                long ttl = expiration.getTime() - System.currentTimeMillis();
                if (ttl > 0) {
                    redisTemplate.opsForValue().set(
                        BLACKLIST_PREFIX + token, "1", Duration.ofMillis(ttl));
                }
            } catch (Exception ignored) {
                // token already invalid, no need to blacklist
            }
        }
        result.put("code", 200);
        result.put("message", "已退出登录");
        return result;
    }

    @PostMapping("/reset-password")
    public Map<String, Object> resetPassword(@RequestBody Map<String, String> params) {
        Map<String, Object> result = new HashMap<>();
        try {
            String email = params.get("email");
            String code = params.get("code");
            String password = params.get("password");
            userService.resetPassword(email, code, password);
            result.put("code", 200);
            result.put("message", "密码重置成功");
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", e.getMessage());
        }
        return result;
    }

    @GetMapping("/{id}")
    public User getById(@PathVariable Long id) {
        return userService.findById(id);
    }

    @PutMapping
    public User update(@RequestBody User user) {
        return userService.update(user);
    }

    @DeleteMapping("/{id}")
    public int delete(@PathVariable Long id) {
        return userService.delete(id);
    }
}
