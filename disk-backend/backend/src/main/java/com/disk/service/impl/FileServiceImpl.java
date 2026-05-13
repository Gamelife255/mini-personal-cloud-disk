package com.disk.service.impl;

import com.disk.entity.File;
import com.disk.mapper.FileMapper;
import com.disk.service.FileService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class FileServiceImpl implements FileService {
    @Autowired
    private FileMapper fileMapper;

    @Override
    public File upload(File file) {
        file.setCreatedAt(System.currentTimeMillis());
        file.setUpdatedAt(System.currentTimeMillis());
        fileMapper.insert(file);
        return file;
    }

    @Override
    public File download(Long id) {
        return fileMapper.findById(id);
    }

    @Override
    public List<File> list(Long userId, Long parentId, String sortBy, String sortOrder) {
        return fileMapper.findByUserIdAndParentId(userId, parentId, sortBy, sortOrder);
    }

    @Override
    public List<File> findByIds(List<Long> ids) {
        return fileMapper.findByIds(ids);
    }

    @Override
    public File rename(Long id, String newName) {
        File file = fileMapper.findById(id);
        if (file != null) {
            file.setFileName(newName);
            file.setUpdatedAt(System.currentTimeMillis());
            fileMapper.update(file);
        }
        return file;
    }

    @Override
    public int update(File file) {
        return fileMapper.update(file);
    }

    @Override
    public int delete(Long id) {
        return fileMapper.delete(id);
    }

    @Override
    public List<File> findByUserId(Long userId) {
        return fileMapper.findByUserId(userId);
    }

    @Override
    public Long getUsedSpace(Long userId) {
        return fileMapper.sumFileSizeByUserId(userId);
    }

    @Override
    public int countFiles(Long userId) {
        List<File> all = fileMapper.findByUserId(userId);
        return (int) all.stream().filter(f -> f.getIsFolder() != 1).count();
    }

    @Override
    public int countFolders(Long userId) {
        List<File> all = fileMapper.findByUserId(userId);
        return (int) all.stream().filter(f -> f.getIsFolder() == 1).count();
    }

    @Override
    public java.util.List<java.util.Map<String, Object>> getUploadHistory(Long userId, int days) {
        long since = System.currentTimeMillis() - (long) days * 24 * 3600 * 1000;
        return fileMapper.countFilesByUploadDate(userId, since);
    }
}
