package com.disk.mapper;

import com.disk.entity.File;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface FileMapper {
    File findById(Long id);
    List<File> findByUserId(Long userId);
    List<File> findByParentId(Long parentId);
    int insert(File file);
    int update(File file);
    int delete(Long id);
}
