# 🔒 用户文件隔离实现说明

## 一、核心设计思想

系统通过 **用户ID关联 + 权限校验** 实现文件隔离，确保每个用户只能访问和操作自己的文件。

---

## 二、数据层隔离

### 1. 文件表结构设计

```java
public class File {
    private Long id;
    private Long userId;      // ✅ 核心字段：关联所属用户
    private String fileName;
    private String filePath;
    // ... 其他字段
}
```

**数据库层面**：所有文件记录都绑定到特定用户，`userId` 作为外键关联 `user` 表。

### 2. 查询时强制过滤

```java
// FileServiceImpl.java
public List<File> list(Long userId, Long parentId, String sortBy, String sortOrder) {
    return fileMapper.findByUserIdAndParentId(userId, parentId, sortBy, sortOrder);
}
```

```xml
<!-- FileMapper.xml -->
<select id="findByUserIdAndParentId" resultType="File">
    SELECT * FROM files 
    WHERE user_id = #{userId} 
      AND parent_id = #{parentId}
    ORDER BY ${sortBy} ${sortOrder}
</select>
```

---

## 三、业务层权限校验

### 1. 获取当前用户ID（从JWT Token中解析）

```java
// FileController.java
String token = request.getHeader("Authorization").replace("Bearer ", "");
Long userId = JwtUtil.getUserIdFromToken(token);
```

### 2. 文件操作前的权限验证

**下载文件时：**
```java
// FileController.java:199
File fileInfo = fileService.getById(id);
if (!fileInfo.getUserId().equals(userId)) {
    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("无权访问该文件");
}
```

**删除文件时：**
```java
// FileController.java:459
if (!fileInfo.getUserId().equals(userId) || fileInfo.getIsFolder().equals(1)) {
    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("无权删除该文件");
}
```

---

## 四、完整的隔离流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    用户请求文件操作                              │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. JwtInterceptor 拦截请求，从 Token 解析 userId               │
│     request.setAttribute("userId", userId)                     │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. Controller 获取 userId，作为查询/操作条件                    │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. Service → Mapper 查询时强制带上 userId 条件                  │
│     SELECT * FROM files WHERE user_id = #{userId} ...          │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. 敏感操作（下载/删除）前二次校验                              │
│     if (!file.getUserId().equals(currentUserId))               │
│         return 403 Forbidden                                   │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    返回用户自己的文件列表                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 五、隔离机制的安全保障

| 层级 | 保障措施 |
|------|----------|
| **认证层** | JWT Token 验证，确保用户身份真实 |
| **查询层** | SQL 查询强制带 `user_id` 条件，防止越权查询 |
| **操作层** | 敏感操作前二次校验文件归属 |
| **存储层** | 数据库记录与用户强绑定 |
| **传输层** | Token 通过请求头传递，避免 URL 泄露 |

---

## 六、关键代码位置

| 文件 | 作用 |
|------|------|
| `entity/File.java` | 文件实体，包含 `userId` 字段 |
| `controller/FileController.java` | 所有文件操作都校验 userId |
| `service/impl/FileServiceImpl.java` | 业务逻辑层，传递 userId 参数 |
| `mapper/FileMapper.java` | SQL 查询强制带 userId 过滤 |
| `util/JwtUtil.java` | 从 Token 解析用户身份 |
| `config/JwtInterceptor.java` | 全局拦截，提取用户信息 |

---

## 七、总结

**核心原理**：每个文件记录都存储了所属用户的 `userId`，在查询时强制按 `userId` 过滤，在操作时校验文件归属。这种设计确保了：

1. **数据隔离**：每个用户只能看到自己的文件
2. **权限控制**：无法访问或操作他人文件
3. **安全性**：即使知道文件ID也无法越权访问
