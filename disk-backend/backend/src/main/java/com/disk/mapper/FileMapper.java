package com.disk.mapper;

import com.disk.entity.File;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface FileMapper {
    File findById(Long id);
    List<File> findByIds(List<Long> ids);
    List<File> findByUserId(Long userId);
    List<File> findByUserIdAndParentId(@Param("userId") Long userId, @Param("parentId") Long parentId,
                                       @Param("sortBy") String sortBy, @Param("sortOrder") String sortOrder);
    int insert(File file);
    int update(File file);
    int delete(Long id);
    Long sumFileSizeByUserId(Long userId);
    List<File> findAll();
    List<File> findByUserIdAndParentIdIgnoreOwnership(@Param("userId") Long userId, @Param("parentId") Long parentId,
                                                       @Param("sortBy") String sortBy, @Param("sortOrder") String sortOrder);
}
