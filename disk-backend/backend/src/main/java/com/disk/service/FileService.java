package com.disk.service;

import com.disk.entity.File;

import java.util.List;

public interface FileService {
    File upload(File file);
    File download(Long id);
    List<File> list(Long userId, Long parentId, String sortBy, String sortOrder);
    List<File> findByIds(List<Long> ids);
    File rename(Long id, String newName);
    int update(File file);
    int delete(Long id);
    Long getUsedSpace(Long userId);
}
