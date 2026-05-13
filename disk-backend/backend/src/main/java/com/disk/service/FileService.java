package com.disk.service;

import com.disk.entity.File;

import java.util.List;

public interface FileService {
    File upload(File file);
    File download(Long id);
    List<File> list(Long userId, Long parentId, String sortBy, String sortOrder);
    List<File> findByUserId(Long userId);
    List<File> findByIds(List<Long> ids);
    File rename(Long id, String newName);
    int update(File file);
    int delete(Long id);
    Long getUsedSpace(Long userId);
    int countFiles(Long userId);
    int countFolders(Long userId);
    java.util.List<java.util.Map<String, Object>> getUploadHistory(Long userId, int days);
}
