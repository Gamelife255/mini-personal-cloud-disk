package com.disk.controller;

import com.disk.entity.File;
import com.disk.service.FileService;
import com.disk.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/file")
public class FileController {
    @Autowired
    private FileService fileService;

    @Value("${disk.upload.path}")
    private String uploadPath;

    @PostMapping("/upload")
    public Map<String, Object> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam("parentId") Long parentId,
            HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            String token = request.getHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
            }
            Long userId = JwtUtil.getUserIdFromToken(token);
            
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "未登录");
                return result;
            }
            
            if (file.isEmpty()) {
                result.put("code", 400);
                result.put("message", "文件不能为空");
                return result;
            }
            
            String originalFilename = file.getOriginalFilename();
            String fileExtension = originalFilename.substring(originalFilename.lastIndexOf("."));
            String newFileName = UUID.randomUUID().toString() + fileExtension;
            
            Path uploadDir = Paths.get(uploadPath);
            if (!Files.exists(uploadDir)) {
                Files.createDirectories(uploadDir);
            }
            
            Path filePath = uploadDir.resolve(newFileName);
            Files.copy(file.getInputStream(), filePath);
            
            com.disk.entity.File fileInfo = new com.disk.entity.File();
            fileInfo.setUserId(userId);
            fileInfo.setFileName(originalFilename);
            fileInfo.setFileType(file.getContentType());
            fileInfo.setFilePath(filePath.toString());
            fileInfo.setFileSize(file.getSize());
            fileInfo.setParentId(parentId);
            fileInfo.setIsFolder(0);
            
            com.disk.entity.File uploadedFile = fileService.upload(fileInfo);
            
            result.put("code", 200);
            result.put("message", "上传成功");
            result.put("data", uploadedFile);
        } catch (IOException e) {
            result.put("code", 500);
            result.put("message", "上传失败: " + e.getMessage());
        }
        
        return result;
    }

    @PostMapping("/folder")
    public Map<String, Object> createFolder(
            @RequestParam("folderName") String folderName,
            @RequestParam("parentId") Long parentId,
            HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            String token = request.getHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
            }
            Long userId = JwtUtil.getUserIdFromToken(token);
            
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "未登录");
                return result;
            }
            
            com.disk.entity.File folder = new com.disk.entity.File();
            folder.setUserId(userId);
            folder.setFileName(folderName);
            folder.setFileType("folder");
            folder.setFilePath("");
            folder.setFileSize(0L);
            folder.setParentId(parentId);
            folder.setIsFolder(1);
            
            com.disk.entity.File createdFolder = fileService.upload(folder);
            
            result.put("code", 200);
            result.put("message", "创建成功");
            result.put("data", createdFolder);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "创建失败: " + e.getMessage());
        }
        
        return result;
    }

    @GetMapping("/download/{id}")
    public ResponseEntity<byte[]> download(@PathVariable Long id) {
        try {
            com.disk.entity.File fileInfo = fileService.download(id);
            if (fileInfo == null) {
                return ResponseEntity.notFound().build();
            }
            
            Path filePath = Paths.get(fileInfo.getFilePath());
            if (!Files.exists(filePath)) {
                return ResponseEntity.notFound().build();
            }
            
            byte[] fileContent = Files.readAllBytes(filePath);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType(fileInfo.getFileType()));
            headers.setContentDispositionFormData("attachment", fileInfo.getFileName());
            headers.setContentLength(fileContent.length);
            
            return ResponseEntity.ok()
                    .headers(headers)
                    .body(fileContent);
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/list")
    public Map<String, Object> list(
            @RequestParam(required = false) Long parentId,
            HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            String token = request.getHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
            }
            Long userId = JwtUtil.getUserIdFromToken(token);
            
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "未登录");
                return result;
            }
            
            if (parentId == null) {
                parentId = 0L;
            }
            
            List<File> files = fileService.list(userId, parentId);
            
            result.put("code", 200);
            result.put("message", "查询成功");
            result.put("data", files);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "查询失败: " + e.getMessage());
        }
        
        return result;
    }

    @DeleteMapping("/{id}")
    public Map<String, Object> delete(@PathVariable Long id, HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            String token = request.getHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
            }
            Long userId = JwtUtil.getUserIdFromToken(token);
            
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "未登录");
                return result;
            }
            
            com.disk.entity.File fileInfo = fileService.download(id);
            if (fileInfo == null) {
                result.put("code", 404);
                result.put("message", "文件不存在");
                return result;
            }
            
            if (!fileInfo.getUserId().equals(userId)) {
                result.put("code", 403);
                result.put("message", "无权限删除");
                return result;
            }
            
            if (!fileInfo.getIsFolder().equals(1)) {
                Path filePath = Paths.get(fileInfo.getFilePath());
                if (Files.exists(filePath)) {
                    Files.delete(filePath);
                }
            }
            
            fileService.delete(id);
            
            result.put("code", 200);
            result.put("message", "删除成功");
        } catch (IOException e) {
            result.put("code", 500);
            result.put("message", "删除失败: " + e.getMessage());
        }
        
        return result;
    }

    @GetMapping("/space")
    public Map<String, Object> getSpaceUsage(HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            String token = request.getHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
            }
            Long userId = JwtUtil.getUserIdFromToken(token);
            
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "未登录");
                return result;
            }
            
            Long usedSpace = fileService.getUsedSpace(userId);
            Long totalSpace = 1024L * 1024L * 1024L * 10L; // 10GB
            
            result.put("code", 200);
            result.put("message", "查询成功");
            result.put("data", Map.of(
                "usedSpace", usedSpace,
                "totalSpace", totalSpace
            ));
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "查询失败: " + e.getMessage());
        }
        
        return result;
    }
}
