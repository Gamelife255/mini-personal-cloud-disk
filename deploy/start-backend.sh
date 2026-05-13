#!/bin/bash
# Cloud Disk — 后端启动脚本
# 用法: bash start-backend.sh [start|stop|restart|status]

JAR_NAME="backend-1.0-SNAPSHOT.jar"
JAR_DIR="/opt/cloud-disk/backend"
LOG_FILE="/opt/cloud-disk/backend/app.log"
PID_FILE="/opt/cloud-disk/backend/app.pid"

# JVM 参数，根据服务器内存调整
JAVA_OPTS="-Xms128m -Xmx256m -Dfile.encoding=UTF-8"

mkdir -p "$JAR_DIR"

# 获取进程 PID
get_pid() {
    if [ -f "$PID_FILE" ]; then
        cat "$PID_FILE"
    else
        pgrep -f "$JAR_NAME" | head -1
    fi
}

start() {
    PID=$(get_pid)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "后端已在运行中 (PID: $PID)"
        return 1
    fi

    echo "正在启动后端..."
    cd "$JAR_DIR"

    if [ ! -f "$JAR_NAME" ]; then
        echo "错误: 找不到 $JAR_DIR/$JAR_NAME，请先构建并复制 jar 包"
        return 1
    fi

    nohup java $JAVA_OPTS -jar "$JAR_NAME" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    sleep 3

    PID=$(get_pid)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "后端启动成功 (PID: $PID)"
    else
        echo "后端启动失败，查看日志: tail -f $LOG_FILE"
        return 1
    fi
}

stop() {
    PID=$(get_pid)
    if [ -z "$PID" ]; then
        echo "后端未在运行"
        return 0
    fi

    echo "正在停止后端 (PID: $PID)..."
    kill "$PID"
    sleep 3

    if kill -0 "$PID" 2>/dev/null; then
        echo "强制终止..."
        kill -9 "$PID"
    fi

    rm -f "$PID_FILE"
    echo "后端已停止"
}

status() {
    PID=$(get_pid)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "后端运行中 (PID: $PID)"
    else
        echo "后端未运行"
    fi
}

case "$1" in
    start)   start ;;
    stop)    stop ;;
    restart) stop; sleep 1; start ;;
    status)  status ;;
    *)
        echo "用法: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
