package com.disk.controller;

import com.disk.entity.File;
import com.disk.entity.User;
import com.disk.service.FileService;
import com.disk.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/admin")
public class AdminController {
    @Autowired
    private UserService userService;

    @Autowired
    private FileService fileService;

    private boolean isAdmin(HttpServletRequest request) {
        return "admin".equals(request.getAttribute("role"));
    }

    @GetMapping("/users")
    public Map<String, Object> listUsers(HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        if (!isAdmin(request)) {
            result.put("code", 403);
            result.put("message", "无权限");
            return result;
        }
        List<User> users = userService.findAll();
        users.forEach(u -> u.setPassword(null));
        result.put("code", 200);
        result.put("data", users);
        return result;
    }

    @PutMapping("/user/{id}/status")
    public Map<String, Object> updateStatus(@PathVariable Long id,
                                            @RequestBody Map<String, Integer> params,
                                            HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        if (!isAdmin(request)) {
            result.put("code", 403);
            result.put("message", "无权限");
            return result;
        }
        Long userId = (Long) request.getAttribute("userId");
        if (userId.equals(id)) {
            result.put("code", 400);
            result.put("message", "不能操作自己");
            return result;
        }
        userService.updateStatus(id, params.get("status"));
        result.put("code", 200);
        result.put("message", "操作成功");
        return result;
    }

    @PutMapping("/user/{id}/reset-password")
    public Map<String, Object> resetPassword(@PathVariable Long id,
                                             @RequestBody Map<String, String> params,
                                             HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        if (!isAdmin(request)) {
            result.put("code", 403);
            result.put("message", "无权限");
            return result;
        }
        String newPassword = params.get("password");
        if (newPassword == null || newPassword.length() < 6) {
            result.put("code", 400);
            result.put("message", "密码不能少于6位");
            return result;
        }
        userService.adminResetPassword(id, newPassword);
        result.put("code", 200);
        result.put("message", "密码重置成功");
        return result;
    }

    @GetMapping("/user/{id}/files")
    public Map<String, Object> getUserFiles(@PathVariable Long id,
                                            @RequestParam(defaultValue = "0") Long parentId,
                                            @RequestParam(defaultValue = "updatedAt") String sortBy,
                                            @RequestParam(defaultValue = "DESC") String sortOrder,
                                            HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        if (!isAdmin(request)) {
            result.put("code", 403);
            result.put("message", "无权限");
            return result;
        }
        // Whitelist sort parameters to prevent SQL injection
        if (!Set.of("fileName", "fileSize", "fileType", "updatedAt").contains(sortBy)) {
            sortBy = "updatedAt";
        }
        if (!Set.of("ASC", "DESC").contains(sortOrder.toUpperCase())) {
            sortOrder = "DESC";
        }
        List<File> files = fileService.list(id, parentId, sortBy, sortOrder);
        result.put("code", 200);
        result.put("data", files);
        return result;
    }
}
