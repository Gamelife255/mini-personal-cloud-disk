# mini-personal-cloud-disk

# 简易个人网盘系统

基于 **Spring Boot + Vue3** 开发的轻量级个人网盘，实现文件云端存储、文件夹管理、在线预览等核心功能，仿百度网盘基础版体验。

## 🛠️ 技术栈

### 后端
- **Spring Boot 3.2.0** - 后端框架
- **MySQL 8.0+** - 数据库
- **Redis 7+** - 缓存 / JWT 黑名单
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
| 3 | JWT 黑名单（Redis）— 退出登录后 Token 失效 |
| 4 | 上传文件类型白名单 + 重命名 |
| 5 | 文件真实类型校验（魔数检测） |
| 6 | 每个文件绑定 userId，接口权限校验 |
| 7 | 过滤路径遍历字符 |

## 🚀 快速开始

### 环境要求
- **Java 17+**
- **Node.js 18+**
- **MySQL 8.0+**
- **Redis 7+**
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

### 一键启动（Windows 本地开发）
```bash
# 使用一键启动脚本
script/start.bat
```

---

## 🖥️ Linux 服务器部署

项目提供了一套完整的部署脚本，支持**低配服务器**通过本地构建 + 上传的方式完成部署。适用于 **Ubuntu 20.04 / 22.04 / 24.04**。

### 脚本概览

| 脚本 | 用途 | 运行位置 |
|------|------|----------|
| `setup-env.sh` | 安装所有运行依赖 | 服务器（仅一次） |
| `deploy.sh` | 一键部署（构建 + Nginx + 启动） | 服务器 |
| `build-local.sh` | 本地构建前后端并上传 | 本地 (Linux/Mac) |
| `build-local.bat` | 本地构建前后端并上传 | 本地 (Windows) |
| `start-backend.sh` | 后端服务启停管理 | 服务器 |
| `service-control.sh` | 交互式前端+后端服务管理 | 服务器 |

### 推荐方式：本地构建 + 上传（低配服务器首选）

服务器编译慢、内存不足时，在本机构建然后上传，服务器端零编译。

#### 第一步：安装服务器环境（仅一次）

```bash
cd mini-personal-cloud-disk
bash deploy/setup-env.sh    # 安装 JDK/MySQL/Redis/Nginx
```

#### 第二步：本地构建并上传

Windows：
```bat
deploy\build-local.bat 你的服务器IP
```

Linux/Mac：
```bash
bash deploy/build-local.sh 你的服务器IP
```

#### 第三步：服务器部署

```bash
cd ~/mini-personal-cloud-disk
bash deploy/deploy.sh --use-local-build
```

### 服务器直接构建（高配服务器）

如果服务器性能足够，也可以直接在服务器上编译：

```bash
# 仅首次
bash deploy/setup-env.sh

# 每次部署
bash deploy/deploy.sh

# 跳过前端构建（前端已提前上传）
bash deploy/deploy.sh --skip-frontend-build

# 跳过后端构建（JAR 已提前上传）
bash deploy/deploy.sh --skip-backend-build
```

### 部署流程说明

| 阶段 | 操作 |
|------|------|
| 1. 环境检查 | 验证 JDK、Node.js、Maven、MySQL、Nginx 是否就绪 |
| 2. 数据库初始化 | 执行建表 SQL，创建数据库表结构 |
| 3. 创建部署目录 | 建立 `/opt/cloud-disk/` 下的前端、后端目录 |
| 4. 构建后端 | Maven 编译打包（`--skip-backend-build` 则跳过） |
| 5. 部署前端 | npm + Vite 构建（`--skip-frontend-build` 则跳过） |
| 6. 配置 Nginx | 生成站点配置、反向代理 `/api/` 到后端 8080 端口，启动全部服务 |

### 日常运维命令

```bash
# 查看后端服务状态（含内存占用、运行时长、最新日志）
bash deploy/start-backend.sh status

# 重启 / 停止 / 启动后端服务
bash deploy/start-backend.sh restart
bash deploy/start-backend.sh stop
bash deploy/start-backend.sh start

# 交互式管理菜单（可同时管理后端 + Nginx）
bash deploy/service-control.sh

# 查看后端实时日志
tail -f /opt/cloud-disk/backend/app.log
```

### 部署后目录结构

```
/opt/cloud-disk/
├── backend/                   # 后端 JAR + 日志 + 上传文件
│   ├── backend.jar            # Spring Boot 可执行 JAR
│   ├── app.log                # 应用运行日志
│   ├── app.pid                # 进程 PID 文件
│   └── upload/                # 用户上传文件（相对路径 ./upload/）
├── frontend/                  # 前端静态文件（Nginx 根目录）
│   ├── index.html
│   └── assets/
```

### 常见问题

**Q: 部署后无法访问？**
1. 确认云服务商安全组已放行 **80 (TCP)** 端口
2. 检查服务状态：`bash deploy/service-control.sh` 选择"查看服务状态"
3. 查看后端日志：`tail -f /opt/cloud-disk/backend/app.log`

**Q: 更新代码后如何重新部署？**
```bash
git pull
# 低配服务器：本地构建 + 上传
# 高配服务器：bash deploy/deploy.sh
```

**Q: Maven 构建卡住？**
服务器性能不够时建议本地构建后上传：
```bash
# 本地
bash deploy/build-local.sh 服务器IP
# 服务器
bash deploy/deploy.sh --use-local-build
```

**Q: 数据库中文乱码？**
确认 `application.yml` 中 `spring.sql.init.encoding` 设为 `UTF-8`

**Q: MySQL 连接失败？**
- 确认密码正确：`mysql -u root -p`
- `application.yml` 中的密码需要与 MySQL root 密码一致

**Q: 上传文件报 500 错误？**
检查 Redis 是否启动：`redis-cli ping`，返回 `PONG` 即正常

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
├── deploy/                    # 部署脚本
│   ├── setup-env.sh           # 服务器环境一键安装
│   ├── deploy.sh              # 服务器端一键部署
│   ├── build-local.sh         # 本地构建（Linux/Mac）
│   ├── build-local.bat        # 本地构建（Windows）
│   ├── start-backend.sh       # 后端服务管理
│   ├── service-control.sh     # 交互式服务管理
│   ├── deploy.bat             # Windows 本地部署
│   └── update.bat             # Windows 本地更新
├── sql/                       # 数据库脚本
│   └── schema.sql             # 建表 + 初始数据
├── script/                    # 快捷脚本
│   └── start.bat              # 一键启动前端开发
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
    path: ./upload/             # 文件存储路径（相对路径，Windows/Linux通用）
  sql:
    init:
      mode: always
      encoding: UTF-8           # 确保SQL中文不会乱码
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
| `/api/file/preview/{id}` | GET | 文件预览（图片/视频/PSD/PDF等） |
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

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. **Fork 项目**
2. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **提交更改**
   ```bash
   git commit -m "Add: your feature description"
   ```
4. **推送到分支**
   ```bash
   git push origin feature/your-feature-name
   ```
5. **创建 Pull Request**

### 代码规范

- **后端**：遵循 Java 编码规范，使用 Lombok 简化代码
- **前端**：使用 Vue 3 Composition API，遵循 ESLint 规则
- **提交信息**：使用语义化提交格式（Add、Fix、Update、Refactor、Docs）

## 💡 使用技巧

### 1. 快速启动开发环境

```bash
# 方式一：使用一键启动脚本（Windows）
script/start.bat

# 方式二：手动启动
# 后端
cd disk-backend/backend
mvn spring-boot:run

# 前端
cd disk-frontend
npm run dev
```

### 2. 构建生产版本

```bash
# 推荐：使用本地构建脚本（一次构建前后端 + 打包）
deploy\build-local.bat          # Windows
bash deploy/build-local.sh      # Linux/Mac

# 或手动分别构建
cd disk-frontend && npm run build
cd disk-backend/backend && mvn clean package -DskipTests
```

### 3. 部署到服务器

```bash
# 全新服务器（仅一次）
bash deploy/setup-env.sh

# 方案A：低配服务器 — 本地构建 + 上传
# 本地:  bash deploy/build-local.sh 服务器IP
# 服务器: bash deploy/deploy.sh --use-local-build

# 方案B：高配服务器 — 服务器直接构建
bash deploy/deploy.sh
```

## 📧 联系方式

如有问题或建议，欢迎提交 Issue 或 Pull Request！

---

⭐ 如果这个项目对你有帮助，请给个 Star 支持一下！

## 📊 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Gamelife255/mini-personal-cloud-disk&type=Date)](https://star-history.com/#你的用户名/mini-personal-cloud-disk&Date)

