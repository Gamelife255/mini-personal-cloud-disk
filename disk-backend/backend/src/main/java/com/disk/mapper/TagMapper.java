package com.disk.mapper;

import com.disk.entity.Tag;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface TagMapper {
    List<Tag> findAll();
    Tag findById(Long id);
    Tag findByName(String name);
    int insert(Tag tag);
    List<Tag> findByTopicId(Long topicId);
}
