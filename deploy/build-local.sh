#!/bin/bash
# ============================================
#  Cloud Disk — 本地构建 + 打包上传脚本
#  用法: bash build-local.sh [选项] [服务器IP]
#
#  在本地高性能机器上构建前端和后端，打包上传到低配服务器
# ============================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND_DIR="$PROJECT_DIR/disk-frontend"
BACKEND_DIR="$PROJECT_DIR/disk-backend/backend"
PACKAGE_NAME="deploy-package.tar.gz"
PACKAGE_PATH="$PROJECT_DIR/$PACKAGE_NAME"
BUILD_DIR="$PROJECT_DIR/deploy-package"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "  ${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "  ${YELLOW}[!]${NC} $1"; }
error() { echo -e "\n  ${RED}[✗]${NC} $1\n"; exit 1; }

SERVER_IP=""
SERVER_PATH="/opt/cloud-disk"
SKIP_FRONTEND=false
SKIP_BACKEND=false

for arg in "$@"; do
    case "$arg" in
        --skip-frontend) SKIP_FRONTEND=true ;;
        --skip-backend)  SKIP_BACKEND=true ;;
        -h|--help)
            echo "用法: bash build-local.sh [选项] [服务器IP]"
            echo ""
            echo "选项:"
            echo "  --skip-frontend  只构建后端，跳过前端"
            echo "  --skip-backend   只构建前端，跳过后端"
            echo "  -h, --help       显示帮助"
            echo ""
            echo "示例:"
            echo "  bash build-local.sh                    # 本地构建全部"
            echo "  bash build-local.sh 12.34.56.78       # 构建并上传"
            echo "  bash build-local.sh --skip-frontend    # 只构建后端"
            exit 0
            ;;
        *)
            if [ -z "$SERVER_IP" ]; then
                SERVER_IP="$arg"
            fi
            ;;
    esac
done

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     Cloud Disk — 本地构建打包            ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ---- 清理旧打包目录 ----
rm -rf "$BUILD_DIR" "$PACKAGE_PATH"
mkdir -p "$BUILD_DIR"

# ============================================
# 1. 构建后端
# ============================================
if [ "$SKIP_BACKEND" = false ]; then
    echo -e "${BLUE}── 构建后端 ──${NC}"
    echo ""

    if ! command -v java &>/dev/null; then
        error "未检测到 JDK，请安装 JDK 17+"
    fi
    if ! command -v mvn &>/dev/null; then
        error "未检测到 Maven，请先安装 Maven"
    fi
    info "JDK: $(java -version 2>&1 | head -1)"
    info "Maven: $(mvn -v 2>&1 | head -1)"

    cd "$BACKEND_DIR"

    echo "  正在编译后端 (首次需下载依赖)..."
    mvn clean package -DskipTests -q

    JAR_FILE=$(find target -name "*.jar" -not -name "*sources*" | head -1)
    if [ -z "$JAR_FILE" ]; then
        error "后端构建失败: 未找到 JAR 文件"
    fi
    cp "$JAR_FILE" "$BUILD_DIR/backend.jar"
    info "后端构建完成 → backend.jar"

    cd "$PROJECT_DIR"
else
    echo -e "${BLUE}── 跳过后端构建 ──${NC}"
fi

# ============================================
# 2. 构建前端
# ============================================
if [ "$SKIP_FRONTEND" = false ]; then
    echo ""
    echo -e "${BLUE}── 构建前端 ──${NC}"
    echo ""

    if ! command -v node &>/dev/null; then
        error "未检测到 Node.js，请安装 Node.js 18+"
    fi
    if ! command -v npm &>/dev/null; then
        error "未检测到 npm"
    fi
    info "Node.js: $(node -v)"
    info "npm: $(npm -v)"

    cd "$FRONTEND_DIR"

    if [ ! -d "node_modules" ]; then
        echo "  正在安装前端依赖..."
        npm install
        info "依赖安装完成"
    else
        info "node_modules 已存在，跳过 npm install"
    fi

    if [ -d "dist" ]; then
        rm -rf dist
    fi

    echo "  正在构建..."
    NODE_OPTIONS="--max-old-space-size=2048" npx vite build

    if [ ! -f "dist/index.html" ]; then
        error "前端构建失败: 未生成 dist/index.html"
    fi
    info "前端构建完成"

    mkdir -p "$BUILD_DIR/frontend-dist"
    cp -r dist/* "$BUILD_DIR/frontend-dist/"
    info "前端已复制到打包目录"

    cd "$PROJECT_DIR"
else
    echo -e "${BLUE}── 跳过前端构建 ──${NC}"
fi

# ============================================
# 3. 打包
# ============================================
echo ""
echo -e "${BLUE}── 打包 ──${NC}"

cd "$PROJECT_DIR"
tar -czf "$PACKAGE_PATH" -C "$BUILD_DIR" .
rm -rf "$BUILD_DIR"

PACKAGE_SIZE=$(du -h "$PACKAGE_PATH" | cut -f1)
info "已打包: $PACKAGE_PATH ($PACKAGE_SIZE)"

# ============================================
# 4. 上传
# ============================================
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║         构建完成！                        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if [ -n "$SERVER_IP" ]; then
    echo "  正在上传到 $SERVER_IP ..."
    ssh "$SERVER_IP" "mkdir -p $SERVER_PATH/deploy-upload"
    scp "$PACKAGE_PATH" "$SERVER_IP:$SERVER_PATH/deploy-upload/"
    ssh "$SERVER_IP" "cd $SERVER_PATH/deploy-upload && tar -xzf $PACKAGE_NAME && rm -f $PACKAGE_NAME"
    info "已上传并解压到 $SERVER_IP:$SERVER_PATH/deploy-upload/"

    echo ""
    echo "  文件清单:"
    ssh "$SERVER_IP" "ls -lh $SERVER_PATH/deploy-upload/"
    echo ""
    echo "  在服务器上运行:"
    echo "    bash deploy/deploy.sh --use-local-build"
else
    echo "  ┌──── 上传到服务器 ──────────────────────┐"
    echo "  │                                        │"
    echo "  │  scp $PACKAGE_PATH 你的服务器:$SERVER_PATH/"
    echo "  │"
    echo "  │  或一键（指定 IP）:"
    echo "  │  bash deploy/build-local.sh 你的服务器IP"
    echo "  │"
    echo "  │  上传后在服务器解压:"
    echo "  │  cd $SERVER_PATH"
    echo "  │  tar -xzf $PACKAGE_NAME"
    echo "  │"
    echo "  │  然后运行部署:"
    echo "  │  bash deploy/deploy.sh --use-local-build"
    echo "  │                                        │"
    echo "  └────────────────────────────────────────┘"
fi

echo ""
