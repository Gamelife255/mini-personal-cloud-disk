# mini-personal-cloud-disk

# 简易个人网盘系统

基于 **Spring Boot + Vue3** 开发的轻量级个人网盘，实现文件云端存储、文件夹管理、在线预览等核心功能，仿百度网盘基础版体验。

## 🛠️ 技术栈

### 后端
- **Spring Boot 3.2.0** - 后端框架
- **MySQL 8.0+** - 数据库
- **MyBatis-Plus 3.5.5** - ORM框架
- **JWT** - 用户认证
- **TwelveMonkeys ImageIO** - PSD文件解析
- **Maven** - 依赖管理

### 前端
- **Vue 3** - 前端框架
- **Vite 5** - 构建工具
- **Element Plus** - UI组件库
- **Vue Router** - 路由管理
- **Axios** - HTTP请求

### 其他
- **本地文件存储** - 文件实际存储
- **JWT Token** - 身份认证
- **Git** - 版本管理

## ✨ 核心功能

| 功能 | 描述 |
|------|------|
| 🔐 用户管理 | 用户注册、登录、邮箱验证码 |
| 📤 文件上传 | 支持多文件上传、PSD文件解析 |
| 📥 文件下载 | 支持自定义下载路径 |
| 🗑️ 文件管理 | 删除、重命名、移动文件 |
| 📁 文件夹管理 | 新建文件夹、目录层级管理 |
| 👁️ 在线预览 | 图片、视频、PSD文件预览 |
| 🔒 用户隔离 | 每个用户只能访问自己的文件 |
| 📊 分页搜索 | 文件列表分页、按名称搜索 |
| 📈 数据统计 | 文件数量、文件夹数量、已用空间、文件类型分布、上传趋势 |

## 🌟 项目亮点

1. **前后端分离架构** - 接口规范清晰，便于团队协作
2. **文件元数据管理** - 数据库只存储文件信息，真实文件存本地
3. **PSD文件预览** - 使用 TwelveMonkeys 库实现PSD在线解析
4. **组件化开发** - 前端组件复用性高
5. **完整目录层级** - 模拟真实网盘目录结构

## 🔒 安全特性

| 优先级 | 安全措施 |
|--------|----------|
| 1 | 密码 BCrypt 加密存储 |
| 2 | JWT 登录鉴权 |
| 3 | 上传文件类型白名单 + 重命名 |
| 4 | 文件真实类型校验（魔数检测） |
| 5 | 每个文件绑定 userId，接口权限校验 |
| 6 | 过滤路径遍历字符 |

## 🚀 快速开始

### 环境要求
- **Java 17+**
- **Node.js 18+**
- **MySQL 8.0+**
- **Maven 3.8+**

### 运行步骤

1. **克隆项目**
```bash
git clone https://github.com/你的用户名/mini-personal-cloud-disk.git
cd mini-personal-cloud-disk
```

2. **数据库配置**
```sql
-- 创建数据库
CREATE DATABASE cloud_disk CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

3. **后端启动**
```bash
cd disk-backend/backend
# 修改 src/main/resources/application.yml 中的数据库配置
mvn clean spring-boot:run
```

4. **前端启动**
```bash
cd disk-frontend
npm install
npm run dev
```

5. **访问应用**
- 前端地址：http://localhost:5173
- 后端地址：http://localhost:8080

### 一键启动（Windows）
```bash
# 使用一键启动脚本
script/start.bat
```

## 📁 项目结构

```
mini-personal-cloud-disk/
├── disk-backend/              # 后端代码
│   └── backend/
│       ├── src/main/java/     # Java源代码
│       ├── src/main/resources/# 配置文件
│       └── pom.xml            # Maven配置
├── disk-frontend/             # 前端代码
│   ├── src/                   # Vue源代码
│   ├── package.json           # npm依赖
│   └── vite.config.js         # Vite配置
├── script/                    # 脚本文件
│   └── start.bat              # 一键启动脚本
├── study.md                   # 学习笔记
└── README.md                  # 项目说明
```

## 🔧 配置说明

### 后端配置（application.yml）
```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/cloud_disk
    username: root
    password: your_password
  mail:                        # 邮箱配置（用于发送验证码）
    host: smtp.qq.com
    port: 465
    username: your_email@qq.com
    password: your_auth_code

disk:
  upload:
    path: E:/disk/upload/      # 文件存储路径
```

### 前端配置（.env）
```env
VITE_API_URL=http://localhost:8080
```

## 📝 API 接口

| 接口 | 方法 | 描述 |
|------|------|------|
| `/api/user/register` | POST | 用户注册 |
| `/api/user/login` | POST | 用户登录 |
| `/api/file/upload` | POST | 文件上传 |
| `/api/file/list` | GET | 文件列表 |
| `/api/file/download/{id}` | GET | 文件下载 |
| `/api/file/delete/{id}` | DELETE | 文件删除 |
| `/api/file/preview/{id}` | GET | PSD预览 |
| `/api/statistics/summary` | GET | 获取统计概览（文件数、文件夹数、已用空间） |
| `/api/statistics/type-distribution` | GET | 获取文件类型分布统计 |
| `/api/statistics/upload-trend` | GET | 获取文件上传趋势（按日期统计） |

## 📊 数据统计功能

### 统计概览
返回用户的文件统计信息：
- **totalFiles**: 总文件数
- **totalFolders**: 总文件夹数  
- **usedSpace**: 已用存储空间（字节）

### 文件类型分布
按文件类型分类统计：
- 图片（jpg, png, gif, bmp, svg等）
- 视频（mp4, avi, mov, mkv等）
- 音频（mp3, wav, flac等）
- 文档（doc, pdf, txt, xlsx等）
- 压缩包（zip, rar, 7z等）
- 其他

### 上传趋势
统计指定时间范围内每天的文件上传数量，支持按天、周、月查看上传趋势。

## 📄 许可证

MIT License

## 📧 联系方式

如有问题或建议，欢迎提交 Issue 或 Pull Request！

---

⭐ 如果这个项目对你有帮助，请给个 Star 支持一下！
## Star History

