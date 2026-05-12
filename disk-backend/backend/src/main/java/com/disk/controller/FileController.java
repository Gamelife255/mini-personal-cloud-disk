package com.disk.controller;

import com.disk.entity.File;
import com.disk.service.FileService;
import com.disk.util.JwtUtil;
import com.disk.util.PsdUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletRequest;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import javax.imageio.ImageIO;

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

            // 确定文件保存目录：有父文件夹则存入对应目录，否则存根目录
            Path saveDir = Paths.get(uploadPath);
            if (parentId != null && parentId != 0) {
                com.disk.entity.File parentFolder = fileService.download(parentId);
                if (parentFolder != null && parentFolder.getIsFolder() == 1
                        && parentFolder.getFilePath() != null && !parentFolder.getFilePath().isEmpty()) {
                    saveDir = Paths.get(parentFolder.getFilePath());
                }
            }
            if (!Files.exists(saveDir)) {
                Files.createDirectories(saveDir);
            }

            Path filePath = saveDir.resolve(newFileName);
            Files.copy(file.getInputStream(), filePath);
            
            // 处理PSD文件，生成预览图
            String previewPath = null;
            if (PsdUtil.isPsdFile(originalFilename)) {
                try {
                    String previewFileName = UUID.randomUUID().toString() + ".png";
                    Path previewFilePath = saveDir.resolve(previewFileName);
                    BufferedImage previewImage = PsdUtil.psdToImage(filePath.toFile());
                    ImageIO.write(previewImage, "png", previewFilePath.toFile());
                    previewPath = previewFilePath.toString();
                } catch (Exception e) {
                    // PSD解析失败，继续上传但不生成预览
                }
            }
            
            com.disk.entity.File fileInfo = new com.disk.entity.File();
            fileInfo.setUserId(userId);
            fileInfo.setFileName(originalFilename);
            fileInfo.setFileType(file.getContentType());
            fileInfo.setFilePath(filePath.toString());
            fileInfo.setFileSize(file.getSize());
            fileInfo.setParentId(parentId);
            fileInfo.setIsFolder(0);
            
            // 存储预览图路径（如果是PSD文件）
            if (previewPath != null) {
                fileInfo.setFileHash(previewPath); // 使用fileHash字段存储预览图路径
            }
            
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
            
            // 创建文件夹对应的实体目录
            Path uploadDir = Paths.get(uploadPath);
            if (!Files.exists(uploadDir)) {
                Files.createDirectories(uploadDir);
            }
            String folderDirName = UUID.randomUUID().toString();
            Path folderPath = uploadDir.resolve(folderDirName);
            Files.createDirectories(folderPath);

            com.disk.entity.File folder = new com.disk.entity.File();
            folder.setUserId(userId);
            folder.setFileName(folderName);
            folder.setFileType("folder");
            folder.setFilePath(folderPath.toString());
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
    public ResponseEntity<byte[]> download(@PathVariable Long id, HttpServletRequest request) {
        try {
            String token = request.getHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
            }
            Long userId = JwtUtil.getUserIdFromToken(token);
            
            if (userId == null) {
                return ResponseEntity.status(401).build();
            }
            
            com.disk.entity.File fileInfo = fileService.download(id);
            if (fileInfo == null) {
                return ResponseEntity.notFound().build();
            }
            
            // 验证用户权限
            if (!fileInfo.getUserId().equals(userId)) {
                return ResponseEntity.status(403).build();
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

    @GetMapping("/preview/{id}")
    public ResponseEntity<byte[]> preview(@PathVariable Long id, HttpServletRequest request) {
        try {
            String token = request.getHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
            }
            Long userId = JwtUtil.getUserIdFromToken(token);

            if (userId == null) {
                return ResponseEntity.status(401).build();
            }

            com.disk.entity.File fileInfo = fileService.download(id);
            if (fileInfo == null) {
                return ResponseEntity.notFound().build();
            }

            if (!fileInfo.getUserId().equals(userId)) {
                return ResponseEntity.status(403).build();
            }

            String fileName = fileInfo.getFileName();
            HttpHeaders headers = new HttpHeaders();
            byte[] fileContent;

            if (PsdUtil.isPsdFile(fileName)) {
                // 优先使用上传时生成的预览图
                String previewPath = fileInfo.getFileHash();
                Path previewFile = null;
                if (previewPath != null && !previewPath.isEmpty()) {
                    previewFile = Paths.get(previewPath);
                    if (!Files.exists(previewFile)) {
                        previewFile = null;
                    }
                }

                if (previewFile != null) {
                    fileContent = Files.readAllBytes(previewFile);
                } else {
                    // 预览图不存在，实时转换为PNG
                    Path psdPath = Paths.get(fileInfo.getFilePath());
                    if (!Files.exists(psdPath)) {
                        return ResponseEntity.notFound().build();
                    }
                    BufferedImage image = PsdUtil.psdToImage(psdPath.toFile());
                    ByteArrayOutputStream baos = new ByteArrayOutputStream();
                    ImageIO.write(image, "png", baos);
                    fileContent = baos.toByteArray();
                }
                headers.setContentType(MediaType.IMAGE_PNG);
            } else {
                Path filePath = Paths.get(fileInfo.getFilePath());
                if (!Files.exists(filePath)) {
                    return ResponseEntity.notFound().build();
                }
                fileContent = Files.readAllBytes(filePath);
                headers.setContentType(MediaType.parseMediaType(fileInfo.getFileType()));
            }

            headers.setContentLength(fileContent.length);
            return ResponseEntity.ok()
                    .headers(headers)
                    .body(fileContent);
        } catch (Exception e) {
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

    @PostMapping("/batch-delete")
    public Map<String, Object> batchDelete(@RequestBody Map<String, List<Long>> params, HttpServletRequest request) {
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

            List<Long> ids = params.get("ids");
            if (ids == null || ids.isEmpty()) {
                result.put("code", 400);
                result.put("message", "请选择要删除的文件");
                return result;
            }

            List<com.disk.entity.File> files = fileService.findByIds(ids);
            int deleted = 0;
            for (com.disk.entity.File fileInfo : files) {
                if (!fileInfo.getUserId().equals(userId)) {
                    continue;
                }
                if (!fileInfo.getIsFolder().equals(1)) {
                    Path filePath = Paths.get(fileInfo.getFilePath());
                    Files.deleteIfExists(filePath);
                    // 同时删除预览图
                    if (fileInfo.getFileHash() != null && !fileInfo.getFileHash().isEmpty()) {
                        Files.deleteIfExists(Paths.get(fileInfo.getFileHash()));
                    }
                }
                fileService.delete(fileInfo.getId());
                deleted++;
            }

            result.put("code", 200);
            result.put("message", "成功删除 " + deleted + " 个文件");
            result.put("data", Map.of("deleted", deleted, "total", ids.size()));
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "批量删除失败: " + e.getMessage());
        }
        return result;
    }

    @GetMapping("/batch-download")
    public ResponseEntity<byte[]> batchDownload(@RequestParam List<Long> ids, HttpServletRequest request) {
        try {
            String token = request.getHeader("Authorization");
            if (token != null && token.startsWith("Bearer ")) {
                token = token.substring(7);
            }
            Long userId = JwtUtil.getUserIdFromToken(token);

            if (userId == null) {
                return ResponseEntity.status(401).build();
            }

            List<com.disk.entity.File> files = fileService.findByIds(ids);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            try (ZipOutputStream zos = new ZipOutputStream(baos)) {
                for (com.disk.entity.File fileInfo : files) {
                    if (!fileInfo.getUserId().equals(userId) || fileInfo.getIsFolder().equals(1)) {
                        continue;
                    }
                    Path filePath = Paths.get(fileInfo.getFilePath());
                    if (!Files.exists(filePath)) {
                        continue;
                    }
                    zos.putNextEntry(new ZipEntry(fileInfo.getFileName()));
                    Files.copy(filePath, zos);
                    zos.closeEntry();
                }
            }

            byte[] zipContent = baos.toByteArray();
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
            headers.setContentDispositionFormData("attachment", "files.zip");
            headers.setContentLength(zipContent.length);

            return ResponseEntity.ok().headers(headers).body(zipContent);
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping("/batch-move")
    public Map<String, Object> batchMove(@RequestBody Map<String, Object> params, HttpServletRequest request) {
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

            @SuppressWarnings("unchecked")
            List<Integer> rawIds = (List<Integer>) params.get("ids");
            List<Long> ids = new ArrayList<>();
            for (Integer id : rawIds) {
                ids.add(id.longValue());
            }
            Long targetParentId = ((Number) params.get("targetParentId")).longValue();

            if (ids.isEmpty()) {
                result.put("code", 400);
                result.put("message", "请选择要移动的文件");
                return result;
            }

            List<com.disk.entity.File> files = fileService.findByIds(ids);
            int moved = 0;
            for (com.disk.entity.File fileInfo : files) {
                if (!fileInfo.getUserId().equals(userId)) {
                    continue;
                }
                fileInfo.setParentId(targetParentId);
                fileInfo.setUpdatedAt(System.currentTimeMillis());
                fileService.update(fileInfo);
                moved++;
            }

            result.put("code", 200);
            result.put("message", "成功移动 " + moved + " 个文件");
            result.put("data", Map.of("moved", moved, "total", ids.size()));
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "批量移动失败: " + e.getMessage());
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
