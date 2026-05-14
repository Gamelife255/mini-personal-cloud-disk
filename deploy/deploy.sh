#!/bin/bash
# ============================================
#  Cloud Disk — 一键部署脚本
#  用法: bash deploy.sh
#  自动完成: 环境检查 → 数据库初始化 → 构建前后端 → Nginx 配置 → 启动服务
# ============================================

set -e

# ---- 路径定义 ----
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY_DIR="/opt/cloud-disk"
FRONTEND_DIR="$DEPLOY_DIR/frontend"
BACKEND_DIR="$DEPLOY_DIR/backend"
UPLOAD_DIR="$DEPLOY_DIR/upload"

# ---- 颜色定义 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "  ${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "  ${YELLOW}[!]${NC} $1"; }
error() { echo -e "\n${RED}═══ 部署失败 ═══${NC}\n  ${RED}[✗]${NC} $1\n"; exit 1; }
step()  { echo ""; echo -e "${BLUE}┌──────────────────────────────────────────┐${NC}"; echo -e "${BLUE}│${NC}  [$1/6] $2"; echo -e "${BLUE}└──────────────────────────────────────────┘${NC}"; }

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       Cloud Disk — 一键部署              ║"
echo "║       前后端构建 + Nginx 配置 + 启动      ║"
echo "╚══════════════════════════════════════════╝"
echo ""

DEPLOY_START=$(date +%s)

# ============================================
# 0. 收集部署信息
# ============================================
echo -e "${BLUE}━━━ 部署前信息确认 ━━━${NC}"
echo ""

# 获取公网 IP
echo "  正在检测公网 IP..."
PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "")

# 域名或 IP
if [ -n "$PUBLIC_IP" ]; then
    echo "  检测到公网 IP: ${GREEN}$PUBLIC_IP${NC}"
    read -p "  → 请输入域名或 IP (直接回车使用公网 IP): " DOMAIN
    DOMAIN=${DOMAIN:-$PUBLIC_IP}
else
    echo "  未能检测到公网 IP"
    read -p "  → 请输入域名或 IP (必填): " DOMAIN
    [ -z "$DOMAIN" ] && error "域名或 IP 不能为空"
fi

# MySQL 密码
echo ""
read -sp "  → 请输入 MySQL root 密码: " MYSQL_PASS
echo ""

# 同步应用配置中的密码
APP_CONF="$PROJECT_DIR/disk-backend/backend/src/main/resources/application.yml"
if [ -f "$APP_CONF" ] && [ -n "$MYSQL_PASS" ]; then
    CURRENT_PASS=$(grep -oP 'password:\s*\K.*' "$APP_CONF" | head -1)
    if [ "$CURRENT_PASS" != "$MYSQL_PASS" ] && [ -n "$CURRENT_PASS" ]; then
        sed -i "s/password: $CURRENT_PASS/password: $MYSQL_PASS/" "$APP_CONF"
        info "已同步 application.yml 中的数据库密码"
    fi
fi

echo ""
echo "  部署目标: ${GREEN}$DOMAIN${NC}"
echo ""

# ============================================
# 1. 环境检查
# ============================================
step "1" "检查服务器运行环境"

check_tool() {
    local name="$1"
    local check_cmd="$2"
    local install_hint="$3"
    local min_ver="$4"

    if command -v "$check_cmd" &>/dev/null; then
        if [ -n "$min_ver" ]; then
            local ver
            ver=$("$check_cmd" -version 2>&1 | head -1 | grep -oP '\d+' | head -1)
            if [ "$ver" -ge "$min_ver" ] 2>/dev/null; then
                info "$name: 已安装 ✓"
            else
                error "$name 版本过低 (需要 ≥${min_ver})，请执行: $install_hint"
            fi
        else
            info "$name: 已安装 ✓"
        fi
    else
        error "未检测到 $name，请执行: $install_hint"
    fi
}

check_tool "JDK 17"     "java"  "sudo apt install openjdk-17-jdk"  17
check_tool "Node.js 18" "node"  "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt install nodejs" 18
check_tool "Maven"      "mvn"   "sudo apt install maven"
check_tool "MySQL"      "mysql" "sudo apt install mysql-server"

# Nginx: 未安装则自动安装
if ! command -v nginx &>/dev/null; then
    warn "未检测到 Nginx，正在自动安装..."
    sudo apt update -qq && sudo apt install nginx -y -qq
    info "Nginx 安装完成"
else
    info "Nginx: $(nginx -v 2>&1)"
fi

info "环境检查全部通过"

# ============================================
# 2. 数据库初始化
# ============================================
step "2" "初始化数据库"

SQL_FILE="$PROJECT_DIR/sql/schema.sql"

if [ ! -f "$SQL_FILE" ]; then
    warn "未找到 SQL 文件: $SQL_FILE，跳过数据库初始化"
elif ! command -v mysql &>/dev/null; then
    warn "MySQL 未安装，跳过数据库初始化"
elif [ -z "$MYSQL_PASS" ]; then
    warn "未提供 MySQL 密码，跳过数据库初始化"
else
    echo "  正在连接 MySQL 并执行建表脚本..."
    if mysql -u root -p"$MYSQL_PASS" -e "SELECT 1" &>/dev/null; then
        mysql -u root -p"$MYSQL_PASS" < "$SQL_FILE"
        info "数据库表结构已初始化"
    else
        warn "MySQL 连接失败，请检查密码是否正确"
        warn "跳过数据库初始化，请稍后手动执行: mysql -u root -p < sql/schema.sql"
    fi
fi

# ============================================
# 3. 创建部署目录
# ============================================
step "3" "创建部署目录"

echo "  目标目录: $DEPLOY_DIR"

if [ ! -d "$DEPLOY_DIR" ]; then
    echo "  正在创建部署目录结构..."
fi

sudo mkdir -p "$FRONTEND_DIR" "$BACKEND_DIR" "$UPLOAD_DIR"
sudo chown -R "$USER:$USER" "$DEPLOY_DIR" 2>/dev/null || true
sudo chmod 755 "$UPLOAD_DIR"

info "前端目录: $FRONTEND_DIR"
info "后端目录: $BACKEND_DIR"
info "上传目录: $UPLOAD_DIR"

# ============================================
# 4. 构建后端
# ============================================
step "4" "构建后端项目"

cd "$PROJECT_DIR/disk-backend/backend"

# 修正 Windows 上传路径为 Linux 路径
if grep -q "E:/disk/upload/" src/main/resources/application.yml 2>/dev/null; then
    sed -i 's|E:/disk/upload/|/opt/cloud-disk/upload/|g' src/main/resources/application.yml
    info "已自动将上传路径从 Windows 格式修正为 /opt/cloud-disk/upload/"
fi

echo "  正在编译后端项目 (Maven)..."
echo "  首次构建需下载依赖，可能需要几分钟，请耐心等待..."
echo ""

if mvn clean package -DskipTests; then
    JAR_FILE=$(find target -name "*.jar" -not -name "*sources*" | head -1)
    if [ -z "$JAR_FILE" ]; then
        error "未找到构建产物 JAR 文件，请检查 Maven 构建输出"
    fi
    cp "$JAR_FILE" "$BACKEND_DIR/backend.jar"
    info "后端编译完成 → $BACKEND_DIR/backend.jar"
else
    error "后端 Maven 构建失败，请检查错误信息并重试"
fi

# ============================================
# 5. 部署前端
# ============================================
step "5" "部署前端项目"

cd "$PROJECT_DIR/disk-frontend"

if [ -d "dist" ] && [ -f "dist/index.html" ]; then
    warn "检测到已有前端构建产物 (dist/)"
    read -p "  → 是否重新构建？(y/N): " REBUILD_FRONTEND
    if [ "$REBUILD_FRONTEND" = "y" ] || [ "$REBUILD_FRONTEND" = "Y" ]; then
        echo "  正在删除旧的前端构建产物..."
        rm -rf dist node_modules/.vite 2>/dev/null || true
        FORCE_REBUILD=true
    else
        echo "  跳过前端构建，使用已有产物"
        FORCE_REBUILD=false
    fi
else
    FORCE_REBUILD=true
fi

if [ "$FORCE_REBUILD" = true ]; then
    echo "  正在安装前端依赖..."
    npm install

    echo "  正在构建前端项目..."
    chmod +x node_modules/.bin/* 2>/dev/null || true
    NODE_OPTIONS="--max-old-space-size=2048" npx vite build

    if [ ! -f "dist/index.html" ]; then
        error "前端构建失败: 未生成 dist/index.html"
    fi
    info "前端构建完成"
fi

echo "  正在部署前端文件到 Nginx 目录..."
sudo rm -rf "$FRONTEND_DIR"/*
sudo cp -r dist/* "$FRONTEND_DIR/"
info "前端部署完成 → $FRONTEND_DIR"

# ============================================
# 6. 配置 Nginx + 启动服务
# ============================================
step "6" "配置 Nginx 并启动全部服务"

# 生成 Nginx 配置
echo "  正在生成 Nginx 站点配置..."
sudo tee /etc/nginx/sites-available/cloud-disk > /dev/null << NGINX_EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $FRONTEND_DIR;
    index index.html;

    # 前端静态文件
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # API 反向代理到后端
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        client_max_body_size 500m;
    }

    # 上传文件的直接访问
    location /upload/ {
        alias $UPLOAD_DIR/;
    }
}
NGINX_EOF

# 清理可能冲突的默认站点
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "  移除 Nginx 默认站点配置..."
    sudo rm -f /etc/nginx/sites-enabled/default
fi
if [ -f /etc/nginx/sites-enabled/cloud ]; then
    echo "  移除旧的 cloud 站点配置..."
    sudo rm -f /etc/nginx/sites-enabled/cloud
fi

# 启用站点
sudo ln -sf /etc/nginx/sites-available/cloud-disk /etc/nginx/sites-enabled/

# 测试 Nginx 配置
echo "  正在验证 Nginx 配置..."
if sudo nginx -t 2>/dev/null; then
    info "Nginx 配置语法检查通过"
else
    warn "Nginx 配置测试未通过，请手动检查: sudo nginx -t"
fi

# 启动/重载 Nginx
if sudo systemctl is-active --quiet nginx 2>/dev/null; then
    echo "  正在重载 Nginx..."
    sudo systemctl reload nginx
    info "Nginx 已重载"
else
    echo "  正在启动 Nginx..."
    sudo systemctl start nginx
    info "Nginx 已启动"
fi

# 修正启动脚本中的 JAR 名称 (兼容旧版本)
START_SCRIPT="$PROJECT_DIR/deploy/start-backend.sh"
if grep -q "backend-1.0-SNAPSHOT.jar" "$START_SCRIPT" 2>/dev/null; then
    sed -i 's/backend-1.0-SNAPSHOT.jar/backend.jar/' "$START_SCRIPT"
    info "已更新启动脚本中的 JAR 包名"
fi

# 启动后端
echo "  正在启动后端服务..."
bash "$START_SCRIPT" restart

# ============================================
# 部署完成
# ============================================
DEPLOY_END=$(date +%s)
DEPLOY_ELAPSED=$((DEPLOY_END - DEPLOY_START))
DEPLOY_MIN=$((DEPLOY_ELAPSED / 60))
DEPLOY_SEC=$((DEPLOY_ELAPSED % 60))

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║                                          ║"
echo "║         🎉  部署全部完成！                ║"
echo "║                                          ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  ┌──── 部署信息 ────────────────────────┐"
echo "  │                                        │"
echo "  │  访问地址:  http://$DOMAIN"
if [ -n "$PUBLIC_IP" ] && [ "$DOMAIN" != "$PUBLIC_IP" ]; then
    echo "  │  公网 IP:   http://$PUBLIC_IP"
fi
echo "  │  前端目录:  $FRONTEND_DIR"
echo "  │  后端目录:  $BACKEND_DIR"
echo "  │  上传目录:  $UPLOAD_DIR"
echo "  │  后端日志:  $BACKEND_DIR/app.log"
if [ $DEPLOY_MIN -gt 0 ]; then
    echo "  │  总耗时:    ${DEPLOY_MIN} 分 ${DEPLOY_SEC} 秒"
else
    echo "  │  总耗时:    ${DEPLOY_SEC} 秒"
fi
echo "  │                                        │"
echo "  └────────────────────────────────────────┘"
echo ""
echo "  ┌──── 常用管理命令 ────────────────────┐"
echo "  │                                        │"
echo "  │  查看后端状态:                          │"
echo "  │    bash deploy/start-backend.sh status  │"
echo "  │                                        │"
echo "  │  重启后端:                              │"
echo "  │    bash deploy/start-backend.sh restart │"
echo "  │                                        │"
echo "  │  查看实时日志:                          │"
echo "  │    tail -f $BACKEND_DIR/app.log         │"
echo "  │                                        │"
echo "  │  交互式服务管理:                        │"
echo "  │    bash deploy/service-control.sh       │"
echo "  │                                        │"
echo "  └────────────────────────────────────────┘"
echo ""
echo "  ⚠  重要: 请确保云服务商安全组已放行 80 (TCP) 端口"
echo "     否则外网将无法访问！"
echo ""
