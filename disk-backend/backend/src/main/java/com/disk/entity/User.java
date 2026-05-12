package com.disk.entity;

import lombok.Data;

@Data
public class User {
    private Long id;
    private String username;
    private String password;
    private String email;
    private String role;
    private String phone;
    private String avatar;
    private Integer status;
    private Long createdAt;
    private Long updatedAt;
}
