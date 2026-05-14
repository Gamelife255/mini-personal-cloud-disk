#!/bin/bash
# Cloud Disk — 服务管理脚本
# 用法: bash service-control.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_CTRL="$SCRIPT_DIR/start-backend.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_dependencies() {
    if [ ! -x "$BACKEND_CTRL" ]; then
        error "找不到可执行的后端管理脚本: $BACKEND_CTRL"
    fi
}

start_services() {
    info "启动后端服务..."
    bash "$BACKEND_CTRL" start || error "后端启动失败"

    info "启动 Nginx..."
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl start nginx
    else
        sudo nginx
    fi

    info "服务已启动，访问前端请确认 Nginx 已正确配置"
}

status_services() {
    echo "===== 服务状态 ====="

    echo "[后端]"
    bash "$BACKEND_CTRL" status
    echo ""

    echo "[Nginx]"
    if command -v systemctl >/dev/null 2>&1; then
        if sudo systemctl is-active --quiet nginx; then
            echo "Nginx 运行中"
        else
            echo "Nginx 未运行"
        fi
    else
        if pgrep -x nginx >/dev/null 2>&1; then
            echo "Nginx 运行中"
        else
            echo "Nginx 未运行"
        fi
    fi
    echo "====================="
}

stop_services() {
    info "停止后端服务..."
    bash "$BACKEND_CTRL" stop || warn "后端停止时出现问题"

    info "停止 Nginx..."
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl stop nginx
    else
        sudo nginx -s stop || true
    fi

    info "服务已关闭"
}

print_menu() {
    cat <<EOF
Cloud Disk 服务管理
====================
1) 启动前后端
2) 查看服务状态
3) 关闭服务
q) 退出
EOF
}

check_dependencies

while true; do
    print_menu
    read -rp "请选择操作 [1/2/3/q]: " choice
    case "$choice" in
        1)
            start_services
            break
            ;;
        2)
            status_services
            break
            ;;
        3)
            stop_services
            break
            ;;
        q|Q)
            echo "退出"
            exit 0
            ;;
        *)
            warn "无效选项，请重新输入"
            ;;
    esac
done
