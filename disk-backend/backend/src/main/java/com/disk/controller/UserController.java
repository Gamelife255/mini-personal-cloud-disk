package com.disk.controller;

import com.disk.entity.User;
import com.disk.service.UserService;
import com.disk.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/user")
public class UserController {
    @Autowired
    private UserService userService;

    @PostMapping("/login")
    public Object login(@RequestBody User user) {
        User result = userService.login(user.getUsername(), user.getPassword());
        if (result != null) {
            String token = JwtUtil.generateToken(result.getId(), result.getUsername());
            Map<String, Object> response = new HashMap<>();
            response.put("token", token);
            response.put("user", result);
            return response;
        }
        Map<String, Object> error = new HashMap<>();
        error.put("code", 401);
        error.put("message", "登录失败");
        return error;
    }

    @PostMapping("/register")
    public Object register(@RequestBody User user) {
        try {
            User result = userService.register(user);
            String token = JwtUtil.generateToken(result.getId(), result.getUsername());
            Map<String, Object> response = new HashMap<>();
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
