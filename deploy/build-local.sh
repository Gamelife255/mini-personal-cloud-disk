#!/bin/bash
# ============================================
#  Cloud Disk — 本地前端构建 + 打包脚本
#  用法: bash build-local.sh [服务器IP] [服务器路径]
#  在本地高性能机器上构建前端，打包上传到服务器
# ============================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND_DIR="$PROJECT_DIR/disk-frontend"
PACKAGE_NAME="frontend-dist.tar.gz"
PACKAGE_PATH="$PROJECT_DIR/$PACKAGE_NAME"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "  ${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "  ${YELLOW}[!]${NC} $1"; }
error() { echo -e "\n  ${RED}[✗]${NC} $1\n"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     Cloud Disk — 本地前端构建            ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ---- 检查 Node.js ----
if ! command -v node &>/dev/null; then
    error "未检测到 Node.js，请先安装 Node.js 18+"
fi
info "Node.js: $(node -v)"

# ---- 检查 npm ----
if ! command -v npm &>/dev/null; then
    error "未检测到 npm"
fi
info "npm: $(npm -v)"

# ---- 进入前端目录 ----
cd "$FRONTEND_DIR"

# ---- 安装依赖 ----
echo ""
echo "  ── 检查依赖 ──"
if [ ! -d "node_modules" ]; then
    echo "  正在安装前端依赖..."
    npm install
    info "依赖安装完成"
else
    info "node_modules 已存在，跳过 npm install"
    echo "  (如需强制重装，请先删除 node_modules 目录)"
fi

# ---- 清理旧构建 ----
echo ""
echo "  ── 构建前端 ──"
if [ -d "dist" ]; then
    warn "清理旧构建产物..."
    rm -rf dist
fi

# ---- 构建 ----
echo "  正在构建..."
NODE_OPTIONS="--max-old-space-size=2048" npx vite build

if [ ! -f "dist/index.html" ]; then
    error "前端构建失败: 未生成 dist/index.html"
fi
info "前端构建完成"

# ---- 打包 ----
echo ""
echo "  ── 打包 ──"
cd "$PROJECT_DIR"
rm -f "$PACKAGE_PATH"
tar -czf "$PACKAGE_PATH" -C "$FRONTEND_DIR" dist/
info "已打包: $PACKAGE_PATH"
PACKAGE_SIZE=$(du -h "$PACKAGE_PATH" | cut -f1)
echo "  文件大小: $PACKAGE_SIZE"

# ---- 上传提示 ----
SERVER_IP="${1:-}"
SERVER_PATH="${2:-/opt/cloud-disk}"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║         构建完成！                        ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  ┌──── 上传到服务器 ──────────────────────┐"
echo "  │                                        │"

if [ -n "$SERVER_IP" ]; then
    echo "  │  正在上传到 $SERVER_IP ..."
    echo ""
    ssh "$SERVER_IP" "mkdir -p $SERVER_PATH/frontend-upload"
    scp "$PACKAGE_PATH" "$SERVER_IP:$SERVER_PATH/frontend-upload/"
    ssh "$SERVER_IP" "cd $SERVER_PATH/frontend-upload && tar -xzf $PACKAGE_NAME && rm -f $PACKAGE_NAME"
    info "已上传并解压到 $SERVER_IP:$SERVER_PATH/frontend-upload/"
    echo ""
    echo "  │  在服务器上运行:"
    echo "  │    bash deploy/deploy.sh --skip-frontend-build"
else
    echo "  │  手动上传:"
    echo "  │    scp $PACKAGE_PATH 你的服务器:$SERVER_PATH/"
    echo "  │"
    echo "  │  或一键上传（提供服务器IP）:"
    echo "  │    bash deploy/build-local.sh 你的服务器IP"
    echo "  │"
    echo "  │  然后在服务器解压:"
    echo "  │    cd $SERVER_PATH"
    echo "  │    tar -xzf $PACKAGE_NAME"
    echo "  │"
    echo "  │  最后运行部署（跳过前端构建）:"
    echo "  │    bash deploy/deploy.sh --skip-frontend-build"
fi

echo "  │                                        │"
echo "  └────────────────────────────────────────┘"
echo ""
