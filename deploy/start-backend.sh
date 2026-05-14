#!/bin/bash
# ============================================
#  Cloud Disk — 后端服务管理脚本
#  用法: bash start-backend.sh [start|stop|restart|status]
# ============================================

# ---- 配置 ----
JAR_NAME="backend.jar"
JAR_DIR="/opt/cloud-disk/backend"
LOG_FILE="$JAR_DIR/app.log"
PID_FILE="$JAR_DIR/app.pid"

# JVM 参数 (可根据服务器内存调整)
JAVA_OPTS="-Xms128m -Xmx256m -Dfile.encoding=UTF-8"

# ---- 颜色定义 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ---- 函数定义 ----

# 获取进程 PID
get_pid() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "$pid"
            return
        fi
    fi
    # 备用方案: 通过进程名查找
    pgrep -f "$JAR_NAME" 2>/dev/null | head -1
}

# 检查 JAR 文件是否存在
check_jar() {
    if [ ! -f "$JAR_DIR/$JAR_NAME" ]; then
        echo -e "  ${RED}[✗]${NC} 找不到 JAR 文件: $JAR_DIR/$JAR_NAME"
        echo "  请先执行部署脚本: bash deploy/deploy.sh"
        return 1
    fi
    return 0
}

# 启动服务
start() {
    echo -e "${GREEN}━━━ 启动后端服务 ━━━${NC}"

    check_jar || return 1

    PID=$(get_pid)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo -e "  ${YELLOW}[!]${NC} 后端已在运行中"
        echo "  PID: $PID"
        echo "  如需重启请执行: bash $0 restart"
        return 0
    fi

    # 清理残留的 PID 文件
    rm -f "$PID_FILE"

    echo "  正在启动后端服务..."
    echo "  JAR:  $JAR_DIR/$JAR_NAME"
    echo "  日志: $LOG_FILE"

    mkdir -p "$JAR_DIR"
    cd "$JAR_DIR"

    nohup java $JAVA_OPTS -jar "$JAR_NAME" >> "$LOG_FILE" 2>&1 &
    NEW_PID=$!
    echo "$NEW_PID" > "$PID_FILE"

    # 等待启动 (最多 30 秒)
    echo -n "  等待服务启动"
    for i in $(seq 1 30); do
        sleep 1
        echo -n "."
        if [ -n "$NEW_PID" ] && ! kill -0 "$NEW_PID" 2>/dev/null; then
            echo ""
            echo -e "  ${RED}[✗]${NC} 后端进程异常退出"
            echo "  请查看日志: tail -50 $LOG_FILE"
            rm -f "$PID_FILE"
            return 1
        fi
        # 检查端口是否已监听
        if ss -tlnp 2>/dev/null | grep -q ":8080" || netstat -tlnp 2>/dev/null | grep -q ":8080"; then
            echo ""
            echo -e "  ${GREEN}[✓]${NC} 后端启动成功"
            echo "  PID: $NEW_PID"
            echo "  端口: 8080"
            echo "  日志: $LOG_FILE"
            return 0
        fi
    done

    # 超时后仍检查进程是否存活
    echo ""
    if [ -n "$NEW_PID" ] && kill -0 "$NEW_PID" 2>/dev/null; then
        echo -e "  ${YELLOW}[!]${NC} 后端进程已启动但端口尚未监听"
        echo "  PID: $NEW_PID"
        echo "  可能仍在初始化中，请稍后检查: bash $0 status"
        return 0
    else
        echo -e "  ${RED}[✗]${NC} 后端启动失败"
        echo "  请查看日志: tail -50 $LOG_FILE"
        rm -f "$PID_FILE"
        return 1
    fi
}

# 停止服务
stop() {
    echo -e "${YELLOW}━━━ 停止后端服务 ━━━${NC}"

    PID=$(get_pid)
    if [ -z "$PID" ]; then
        echo "  后端未在运行"
        rm -f "$PID_FILE"
        return 0
    fi

    echo "  正在停止后端服务 (PID: $PID)..."

    # 优雅关闭
    kill "$PID" 2>/dev/null || true

    # 等待进程退出 (最多 15 秒)
    echo -n "  等待进程退出"
    for i in $(seq 1 15); do
        if ! kill -0 "$PID" 2>/dev/null; then
            echo ""
            echo -e "  ${GREEN}[✓]${NC} 后端已停止"
            rm -f "$PID_FILE"
            return 0
        fi
        sleep 1
        echo -n "."
    done

    # 强制终止
    echo ""
    echo -e "  ${YELLOW}[!]${NC} 进程未响应，正在强制终止..."
    kill -9 "$PID" 2>/dev/null || true
    sleep 1

    if kill -0 "$PID" 2>/dev/null; then
        echo -e "  ${RED}[✗]${NC} 无法终止进程 $PID"
        return 1
    else
        echo -e "  ${GREEN}[✓]${NC} 后端已强制停止"
        rm -f "$PID_FILE"
        return 0
    fi
}

# 查看状态
status() {
    echo -e "${BLUE}━━━ 后端服务状态 ━━━${NC}"

    PID=$(get_pid)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo -e "  状态: ${GREEN}运行中${NC}"
        echo "  PID:  $PID"

        # 运行时长
        if command -v ps &>/dev/null; then
            local elapsed
            elapsed=$(ps -o etime= -p "$PID" 2>/dev/null | xargs)
            [ -n "$elapsed" ] && echo "  运行: $elapsed"
        fi

        # 内存使用
        if command -v ps &>/dev/null; then
            local mem
            mem=$(ps -o rss= -p "$PID" 2>/dev/null | awk '{printf "%.1f MB", $1/1024}')
            [ -n "$mem" ] && echo "  内存: $mem"
        fi

        # 端口监听
        if ss -tlnp 2>/dev/null | grep -q ":8080" || netstat -tlnp 2>/dev/null | grep -q ":8080"; then
            echo "  端口: 8080 (已监听)"
        fi

        echo "  日志: $LOG_FILE"
    else
        echo -e "  状态: ${RED}未运行${NC}"
        rm -f "$PID_FILE"
    fi

    # 显示最近的日志条目
    if [ -f "$LOG_FILE" ]; then
        local log_size
        log_size=$(du -h "$LOG_FILE" 2>/dev/null | cut -f1)
        echo ""
        echo "  ┌─ 最近日志 (文件大小: $log_size) ──────────┐"
        tail -5 "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
            echo "  │ $line"
        done
        echo "  └────────────────────────────────────────────┘"
    fi
}

# ---- 主入口 ----

# 确保目录存在
mkdir -p "$JAR_DIR"

case "${1:-}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        echo -e "${BLUE}━━━ 重启后端服务 ━━━${NC}"
        stop
        echo ""
        sleep 2
        start
        ;;
    status)
        status
        ;;
    *)
        echo ""
        echo "Cloud Disk — 后端服务管理"
        echo ""
        echo "用法: bash start-backend.sh {start|stop|restart|status}"
        echo ""
        echo "  start   — 启动后端服务"
        echo "  stop    — 停止后端服务"
        echo "  restart — 重启后端服务"
        echo "  status  — 查看服务状态与最新日志"
        echo ""
        exit 1
        ;;
esac
