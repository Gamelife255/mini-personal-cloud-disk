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
    public List<File> list(Long userId, Long parentId) {
        return fileMapper.findByParentId(parentId);
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
    public Long getUsedSpace(Long userId) {
        return fileMapper.sumFileSizeByUserId(userId);
    }
}
