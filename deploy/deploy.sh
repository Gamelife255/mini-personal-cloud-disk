#!/bin/bash
# Cloud Disk — 一键部署脚本
# 用法: bash deploy.sh
# 自动完成: 环境检查 → 数据库初始化 → 构建前后端 → 配置Nginx → 启动服务

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY_DIR="/opt/cloud-disk"
FRONTEND_DIR="$DEPLOY_DIR/frontend"
BACKEND_DIR="$DEPLOY_DIR/backend"
UPLOAD_DIR="$DEPLOY_DIR/upload"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo "=========================================="
echo "  Cloud Disk 一键部署"
echo "=========================================="
echo ""

# ==========================================
# 1. 环境检查
# ==========================================
echo "[1/6] 检查运行环境..."

# Java 17+
if command -v java &>/dev/null; then
    JAVA_VER=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$JAVA_VER" -ge 17 ] 2>/dev/null; then
        info "Java: $(java -version 2>&1 | head -1)"
    else
        error "需要 JDK 17+，当前版本: $JAVA_VER。请运行: sudo apt install openjdk-17-jdk"
    fi
else
    error "未找到 Java，请安装: sudo apt install openjdk-17-jdk"
fi

# Node.js
if command -v node &>/dev/null; then
    NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VER" -ge 18 ] 2>/dev/null; then
        info "Node.js: $(node -v)"
    else
        error "需要 Node.js 18+，当前版本: $(node -v)"
    fi
else
    error "未找到 Node.js，请安装: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt install nodejs"
fi

# Maven
if command -v mvn &>/dev/null; then
    info "Maven: $(mvn -v 2>&1 | head -1)"
else
    error "未找到 Maven，请安装: sudo apt install maven"
fi

# MySQL
if command -v mysql &>/dev/null; then
    info "MySQL: 已安装"
else
    warn "未找到 MySQL 客户端，将跳过数据库初始化"
fi

# Nginx
if command -v nginx &>/dev/null; then
    info "Nginx: $(nginx -v 2>&1)"
else
    warn "未安装 Nginx，正在安装..."
    sudo apt update && sudo apt install nginx -y
fi

echo ""

# ==========================================
# 2. 数据库初始化
# ==========================================
echo "[2/6] 初始化数据库..."

SQL_FILE="$PROJECT_DIR/sql/schema.sql"

if [ -f "$SQL_FILE" ] && command -v mysql &>/dev/null; then
    echo "请输入 MySQL root 密码:"
    read -s MYSQL_PASS

    if mysql -u root -p"$MYSQL_PASS" -e "SELECT 1" 2>/dev/null; then
        mysql -u root -p"$MYSQL_PASS" < "$SQL_FILE"
        info "数据库初始化完成"
    else
        warn "MySQL 连接失败，请手动执行: mysql -u root -p < sql/schema.sql"
        MYSQL_PASS=""
    fi
    echo ""
else
    warn "跳过数据库初始化（sql/schema.sql 不存在或 mysql 未安装）"
fi

# ==========================================
# 3. 创建部署目录
# ==========================================
echo "[3/6] 创建部署目录..."
sudo mkdir -p "$FRONTEND_DIR" "$BACKEND_DIR" "$UPLOAD_DIR"
sudo chown -R "$USER:$USER" "$DEPLOY_DIR" 2>/dev/null || true
sudo chmod 755 "$UPLOAD_DIR"
info "目录已创建: $DEPLOY_DIR"

# ==========================================
# 4. 构建后端
# ==========================================
echo "[4/6] 构建后端..."
cd "$PROJECT_DIR/disk-backend/backend"

# 如果存在 application.yml，更新上传路径为 Linux 路径
if grep -q "E:/disk/upload/" src/main/resources/application.yml 2>/dev/null; then
    sed -i 's|E:/disk/upload/|/opt/cloud-disk/upload/|g' src/main/resources/application.yml
    info "已自动修正上传路径为 Linux 路径"
fi

mvn clean package -DskipTests -q

JAR_FILE=$(find target -name "*.jar" -not -name "*sources*" | head -1)
if [ -z "$JAR_FILE" ]; then
    error "后端构建失败"
fi
cp "$JAR_FILE" "$BACKEND_DIR/backend-1.0-SNAPSHOT.jar"
info "后端构建完成"

# ==========================================
# 5. 构建前端
# ==========================================
echo "[5/6] 构建前端..."
cd "$PROJECT_DIR/disk-frontend"
npm install --silent 2>/dev/null || npm install
npm run build

sudo rm -rf "$FRONTEND_DIR"/*
sudo cp -r dist/* "$FRONTEND_DIR/"
info "前端构建完成"

# ==========================================
# 6. 配置 Nginx + 启动服务
# ==========================================
echo "[6/6] 配置 Nginx 并启动服务..."

# 配置 Nginx
NGINX_CONF="$PROJECT_DIR/deploy/nginx.conf"
if [ -f "$NGINX_CONF" ]; then
    sudo cp "$NGINX_CONF" /etc/nginx/sites-available/cloud-disk

    # 启用站点（如果尚未启用）
    if [ ! -f /etc/nginx/sites-enabled/cloud-disk ]; then
        sudo ln -sf /etc/nginx/sites-available/cloud-disk /etc/nginx/sites-enabled/
    fi

    # 删除默认站点（避免冲突）
    sudo rm -f /etc/nginx/sites-enabled/default

    # 测试并重载 Nginx
    if sudo nginx -t 2>/dev/null; then
        sudo systemctl reload nginx
        info "Nginx 配置完成"
    else
        warn "Nginx 配置测试失败，请检查 /etc/nginx/sites-available/cloud-disk"
    fi
else
    warn "未找到 nginx.conf 模板，跳过 Nginx 配置"
fi

# 启动后端
bash "$PROJECT_DIR/deploy/start-backend.sh" restart

echo ""
echo "=========================================="
echo "  部署完成！"
echo "=========================================="
echo ""
echo "  访问地址:  http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo '你的服务器IP')"
echo "  前端目录:  $FRONTEND_DIR"
echo "  上传目录:  $UPLOAD_DIR"
echo "  后端日志:  $BACKEND_DIR/app.log"
echo ""
echo "  管理命令:"
echo "    查看状态: bash deploy/start-backend.sh status"
echo "    重启后端: bash deploy/start-backend.sh restart"
echo "    查看日志: tail -f $BACKEND_DIR/app.log"
echo "=========================================="
