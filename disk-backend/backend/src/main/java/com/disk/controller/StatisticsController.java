package com.disk.controller;

import com.disk.entity.File;
import com.disk.service.FileService;
import com.disk.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.*;

@RestController
@RequestMapping("/api/statistics")
public class StatisticsController {

    @Autowired
    private FileService fileService;

    private Long getUserId(HttpServletRequest request) {
        String token = request.getHeader("Authorization").replace("Bearer ", "");
        Long userId = JwtUtil.getUserIdFromToken(token);
        if (userId == null) throw new RuntimeException("未登录");
        return userId;
    }

    @GetMapping("/overview")
    public Map<String, Object> overview(HttpServletRequest request) {
        Long userId = getUserId(request);
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);

        Map<String, Object> data = new HashMap<>();
        data.put("totalFiles", fileService.countFiles(userId));
        data.put("totalFolders", fileService.countFolders(userId));
        data.put("usedSpace", fileService.getUsedSpace(userId));
        result.put("data", data);
        result.put("message", "查询成功");
        return result;
    }

    @GetMapping("/file-types")
    public Map<String, Object> fileTypes(HttpServletRequest request) {
        Long userId = getUserId(request);
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);

        List<File> allFiles = fileService.findByUserId(userId);
        Map<String, Integer> typeCount = new LinkedHashMap<>();
        typeCount.put("图片", 0);
        typeCount.put("视频", 0);
        typeCount.put("文档", 0);
        typeCount.put("音频", 0);
        typeCount.put("压缩包", 0);
        typeCount.put("其他", 0);

        for (File f : allFiles) {
            if (f.getIsFolder() == 1) continue;
            String type = f.getFileType();
            if (type == null) {
                typeCount.merge("其他", 1, Integer::sum);
                continue;
            }
            String fileName = f.getFileName() != null ? f.getFileName().toLowerCase() : "";

            if (type.startsWith("image/")) {
                typeCount.merge("图片", 1, Integer::sum);
            } else if (type.startsWith("video/")) {
                typeCount.merge("视频", 1, Integer::sum);
            } else if (type.startsWith("audio/")) {
                typeCount.merge("音频", 1, Integer::sum);
            } else if (type.equals("application/pdf") || type.contains("word") || type.contains("excel")
                    || type.contains("powerpoint") || type.contains("text/") || type.contains("document")
                    || fileName.endsWith(".txt") || fileName.endsWith(".md")) {
                typeCount.merge("文档", 1, Integer::sum);
            } else if (type.equals("application/zip") || type.equals("application/x-rar-compressed")
                    || type.equals("application/x-7z-compressed") || type.equals("application/gzip")
                    || type.equals("application/x-tar") || fileName.endsWith(".zip") || fileName.endsWith(".rar")
                    || fileName.endsWith(".7z")) {
                typeCount.merge("压缩包", 1, Integer::sum);
            } else {
                typeCount.merge("其他", 1, Integer::sum);
            }
        }

        List<Map<String, Object>> data = new ArrayList<>();
        for (Map.Entry<String, Integer> entry : typeCount.entrySet()) {
            Map<String, Object> item = new HashMap<>();
            item.put("name", entry.getKey());
            item.put("value", entry.getValue());
            data.add(item);
        }

        result.put("data", data);
        result.put("message", "查询成功");
        return result;
    }

    @GetMapping("/upload-history")
    public Map<String, Object> uploadHistory(HttpServletRequest request) {
        Long userId = getUserId(request);
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("data", fileService.getUploadHistory(userId, 30));
        result.put("message", "查询成功");
        return result;
    }
}
