package com.disk.entity;

import lombok.Data;

@Data
public class File {
    private Long id;
    private Long userId;
    private String fileName;
    private String fileType;
    private String filePath;
    private Long fileSize;
    private String fileHash;
    private Long parentId;
    private Integer isFolder;
    private Long createdAt;
    private Long updatedAt;
}
