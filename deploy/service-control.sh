#!/bin/bash
# ============================================
#  Cloud Disk — 交互式服务管理
#  用法: bash service-control.sh
#  提供菜单式界面管理后端 + Nginx
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_CTRL="$SCRIPT_DIR/start-backend.sh"

# ---- 颜色定义 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "  ${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "  ${YELLOW}[!]${NC} $1"; }
error() { echo -e "  ${RED}[✗]${NC} $1"; }

# ---- 依赖检查 ----
check_dependencies() {
    local has_error=false

    if [ ! -f "$BACKEND_CTRL" ]; then
        error "找不到后端管理脚本: $BACKEND_CTRL"
        has_error=true
    fi

    if ! command -v nginx &>/dev/null; then
        error "Nginx 未安装"
        has_error=true
    fi

    if $has_error; then
        echo ""
        echo "请先执行环境安装脚本: bash deploy/setup-env.sh"
        exit 1
    fi
}

# ---- 服务操作 ----

start_services() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           启动全部服务                    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""

    # 启动后端
    echo "▶ 正在启动后端服务..."
    bash "$BACKEND_CTRL" start || {
        error "后端启动失败，请检查日志"
        return 1
    }

    # 启动 Nginx
    echo ""
    echo "▶ 正在启动 Nginx..."
    if sudo systemctl is-active --quiet nginx 2>/dev/null; then
        info "Nginx 已在运行中"
    else
        if command -v systemctl >/dev/null 2>&1; then
            sudo systemctl start nginx
        else
            sudo nginx
        fi
        if sudo systemctl is-active --quiet nginx 2>/dev/null || pgrep -x nginx >/dev/null 2>&1; then
            info "Nginx 启动成功"
        else
            error "Nginx 启动失败"
            return 1
        fi
    fi

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  全部服务已启动！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

stop_services() {
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║           关闭全部服务                    ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════╝${NC}"
    echo ""

    # 停止后端
    echo "▶ 正在停止后端服务..."
    bash "$BACKEND_CTRL" stop || warn "后端停止时出现问题"

    # 停止 Nginx
    echo ""
    echo "▶ 正在停止 Nginx..."
    if command -v systemctl >/dev/null 2>&1; then
        if sudo systemctl is-active --quiet nginx 2>/dev/null; then
            sudo systemctl stop nginx
            info "Nginx 已停止"
        else
            info "Nginx 未在运行"
        fi
    else
        if pgrep -x nginx >/dev/null 2>&1; then
            sudo nginx -s stop 2>/dev/null || sudo killall nginx 2>/dev/null || true
            info "Nginx 已停止"
        else
            info "Nginx 未在运行"
        fi
    fi

    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  全部服务已关闭！${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

status_services() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           服务运行状态                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo ""

    # 后端状态
    echo "┌─ 后端服务 ─────────────────────────────┐"
    bash "$BACKEND_CTRL" status
    echo "└─────────────────────────────────────────┘"

    echo ""

    # Nginx 状态
    echo "┌─ Nginx ────────────────────────────────┐"
    if command -v systemctl >/dev/null 2>&1; then
        if sudo systemctl is-active --quiet nginx 2>/dev/null; then
            echo -e "  状态: ${GREEN}运行中${NC}"
            local nginx_pid
            nginx_pid=$(pgrep -x nginx | head -1)
            [ -n "$nginx_pid" ] && echo "  主进程 PID: $nginx_pid"
        else
            echo -e "  状态: ${RED}未运行${NC}"
        fi
    else
        if pgrep -x nginx >/dev/null 2>&1; then
            echo -e "  状态: ${GREEN}运行中${NC}"
            local nginx_pid
            nginx_pid=$(pgrep -x nginx | head -1)
            echo "  主进程 PID: $nginx_pid"
        else
            echo -e "  状态: ${RED}未运行${NC}"
        fi
    fi

    # 检查配置文件是否有效
    if sudo nginx -t &>/dev/null; then
        echo "  配置: 有效 ✓"
    else
        echo -e "  配置: ${RED}有错误${NC}"
    fi
    echo "└─────────────────────────────────────────┘"

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # 磁盘使用情况
    echo ""
    echo "┌─ 磁盘使用 ─────────────────────────────┐"
    df -h /opt/cloud-disk 2>/dev/null | tail -1 | awk '{printf "  磁盘: %s / %s (已用: %s)\n", $3, $2, $5}'
    echo "  日志大小: $(du -sh /opt/cloud-disk/backend/app.log 2>/dev/null | cut -f1 || echo '无')"
    echo "└─────────────────────────────────────────┘"
}

# ---- 主菜单 ----

print_menu() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Cloud Disk — 服务管理              ║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC}                                          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}1${NC}) 启动前后端服务                       ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${BLUE}2${NC}) 查看服务状态                         ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${YELLOW}3${NC}) 关闭全部服务                         ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${RED}q${NC}) 退出                                ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                          ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
}

# ---- 主循环 ----
check_dependencies

while true; do
    print_menu
    echo ""
    read -rp "  → 请选择操作 [1/2/3/q]: " choice
    case "$choice" in
        1)
            start_services
            echo ""
            read -rp "  按 Enter 返回菜单..."
            ;;
        2)
            status_services
            echo ""
            read -rp "  按 Enter 返回菜单..."
            ;;
        3)
            echo ""
            read -rp "  → 确认关闭全部服务？(y/N): " confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                stop_services
            else
                echo "  已取消"
            fi
            echo ""
            read -rp "  按 Enter 返回菜单..."
            ;;
        q|Q)
            echo ""
            echo "  已退出服务管理。再见！"
            echo ""
            exit 0
            ;;
        *)
            warn "无效选项，请输入 1、2、3 或 q"
            sleep 1
            ;;
    esac
done
