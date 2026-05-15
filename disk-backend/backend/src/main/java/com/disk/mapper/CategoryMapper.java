package com.disk.mapper;

import com.disk.entity.Category;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CategoryMapper {
    List<Category> findAll();
    Category findById(Long id);
    int insert(Category category);
    int update(Category category);
    int updateTopicCount(@Param("id") Long id, @Param("delta") int delta);
}
