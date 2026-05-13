#!/bin/bash
# Cloud Disk — 一键部署脚本
# 用法: bash deploy.sh
# 自动完成: 环境检查 → 配置密码 → 数据库初始化 → 构建前后端 → 配置Nginx → 启动服务

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
# 0. 收集信息
# ==========================================
echo "请先确认以下信息："
PUBLIC_IP=$(curl -s --connect-timeout 3 ifconfig.me 2>/dev/null || echo "")

# 域名
if [ -n "$PUBLIC_IP" ]; then
    read -p "  域名或 IP [$PUBLIC_IP]: " DOMAIN
    DOMAIN=${DOMAIN:-$PUBLIC_IP}
else
    read -p "  域名或 IP (必填): " DOMAIN
    [ -z "$DOMAIN" ] && error "请输入域名或 IP"
fi

# MySQL 密码
read -sp "  MySQL root 密码: " MYSQL_PASS
echo ""

# 应用配置密码
APP_CONF="$PROJECT_DIR/disk-backend/backend/src/main/resources/application.yml"
if [ -f "$APP_CONF" ] && [ -n "$MYSQL_PASS" ]; then
    CURRENT_PASS=$(grep -oP 'password:\s*\K.*' "$APP_CONF" | head -1)
    if [ "$CURRENT_PASS" != "$MYSQL_PASS" ] && [ -n "$CURRENT_PASS" ]; then
        sed -i "s/password: $CURRENT_PASS/password: $MYSQL_PASS/" "$APP_CONF"
        info "已更新 application.yml 中的数据库密码"
    fi
fi

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
    warn "未找到 MySQL，将跳过数据库初始化"
fi

# Nginx: 如果未安装，自动安装
if ! command -v nginx &>/dev/null; then
    warn "未安装 Nginx，正在安装..."
    sudo apt update -qq && sudo apt install nginx -y -qq
fi
info "Nginx: $(nginx -v 2>&1)"

echo ""

# ==========================================
# 2. 数据库初始化
# ==========================================
echo "[2/6] 初始化数据库..."

SQL_FILE="$PROJECT_DIR/sql/schema.sql"

if [ -f "$SQL_FILE" ] && command -v mysql &>/dev/null && [ -n "$MYSQL_PASS" ]; then
    if mysql -u root -p"$MYSQL_PASS" -e "SELECT 1" 2>/dev/null; then
        mysql -u root -p"$MYSQL_PASS" < "$SQL_FILE"
        info "数据库初始化完成"
    else
        warn "MySQL 连接失败，请手动执行: mysql -u root -p < sql/schema.sql"
    fi
else
    warn "跳过数据库初始化"
fi
echo ""

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

# 修正 Windows 路径
if grep -q "E:/disk/upload/" src/main/resources/application.yml 2>/dev/null; then
    sed -i 's|E:/disk/upload/|/opt/cloud-disk/upload/|g' src/main/resources/application.yml
    info "已自动修正上传路径"
fi

info "编译后端（首次需下载依赖，请耐心等待）..."
mvn clean package -DskipTests

JAR_FILE=$(find target -name "*.jar" -not -name "*sources*" | head -1)
[ -z "$JAR_FILE" ] && error "后端构建失败"
cp "$JAR_FILE" "$BACKEND_DIR/backend.jar"
info "后端构建完成"

# ==========================================
# 5. 部署前端
# ==========================================
echo "[5/6] 部署前端..."

if [ -d "$PROJECT_DIR/disk-frontend/dist" ] && [ -f "$PROJECT_DIR/disk-frontend/dist/index.html" ]; then
    warn "检测到已有 dist，跳过构建（如需重建请先删除 disk-frontend/dist）"
else
    cd "$PROJECT_DIR/disk-frontend"
    npm install
    chmod +x node_modules/.bin/* 2>/dev/null || true
    NODE_OPTIONS="--max-old-space-size=2048" npx vite build
fi

sudo rm -rf "$FRONTEND_DIR"/*
sudo cp -r "$PROJECT_DIR/disk-frontend/dist"/* "$FRONTEND_DIR/"
info "前端部署完成"

# ==========================================
# 6. 配置 Nginx + 启动服务
# ==========================================
echo "[6/6] 配置 Nginx 并启动服务..."

# 生成 nginx 配置
sudo tee /etc/nginx/sites-available/cloud-disk > /dev/null << NGINX_EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $FRONTEND_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        client_max_body_size 500m;
    }
}
NGINX_EOF

# 清理冲突的站点
sudo rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/cloud

# 启用
sudo ln -sf /etc/nginx/sites-available/cloud-disk /etc/nginx/sites-enabled/

# 测试并启动
if sudo nginx -t 2>/dev/null; then
    if sudo systemctl is-active --quiet nginx 2>/dev/null; then
        sudo systemctl reload nginx
    else
        sudo systemctl start nginx
    fi
    info "Nginx 配置完成"
else
    warn "Nginx 测试失败，请检查配置"
fi

# 更新启动脚本中的 jar 名称
sed -i 's/backend-1.0-SNAPSHOT.jar/backend.jar/' "$PROJECT_DIR/deploy/start-backend.sh"

# 启动后端
bash "$PROJECT_DIR/deploy/start-backend.sh" restart

echo ""
echo "=========================================="
echo "  部署完成！"
echo "=========================================="
echo ""
echo "  访问地址:  http://$DOMAIN"
[ -n "$PUBLIC_IP" ] && echo "  公网 IP:   http://$PUBLIC_IP"
echo "  前端目录:  $FRONTEND_DIR"
echo "  上传目录:  $UPLOAD_DIR"
echo "  后端日志:  $BACKEND_DIR/app.log"
echo ""
echo "  管理命令:"
echo "    状态:   bash deploy/start-backend.sh status"
echo "    重启:   bash deploy/start-backend.sh restart"
echo "    日志:   tail -f $BACKEND_DIR/app.log"
echo ""
echo "  ⚠ 确保云服务商安全组已放行 80 端口"
echo "=========================================="
