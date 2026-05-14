#!/bin/bash
# ============================================
#  Cloud Disk — 服务器环境一键安装脚本
#  用法: bash setup-env.sh
#  适用: Ubuntu 20.04 / 22.04 / 24.04
#  功能: 安装 JDK17 / Node.js 18 / Maven / MySQL / Nginx / Git
# ============================================

set -e

# ---- 颜色定义 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "  ${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "  ${YELLOW}[!]${NC} $1"; }
error() { echo -e "  ${RED}[✗]${NC} $1"; exit 1; }
step()  { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# ---- 权限检查 ----
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}请不要用 root 用户直接运行此脚本${NC}"
    echo "请使用具有 sudo 权限的普通用户执行"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     Cloud Disk — 服务器环境安装          ║"
echo "║     将安装: JDK 17 | Node.js 18 | Maven  ║"
echo "║     MySQL | Nginx | Git                  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 记录开始时间
START_TIME=$(date +%s)

# ============================================
# 1. 系统更新
# ============================================
step "第一步：更新系统软件包列表"
echo "  正在执行 apt update..."
sudo apt update -qq && info "软件包列表已更新" || warn "apt update 有部分错误，继续安装"

# ============================================
# 2. JDK 17
# ============================================
step "第二步：安装 JDK 17"
echo "  检测现有 Java 环境..."
if command -v java &>/dev/null; then
    EXISTING_JAVA=$(java -version 2>&1 | head -1)
    echo "  已安装: $EXISTING_JAVA"
    JAVA_VER=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$JAVA_VER" -ge 17 ] 2>/dev/null; then
        info "当前 Java 版本满足要求 (≥17)，跳过安装"
    else
        warn "当前 Java 版本过低，正在升级到 JDK 17..."
        sudo apt install openjdk-17-jdk -y
        info "JDK 17 安装完成: $(java -version 2>&1 | head -1)"
    fi
else
    echo "  未检测到 Java，开始安装 JDK 17..."
    sudo apt install openjdk-17-jdk -y
    info "JDK 17 安装完成: $(java -version 2>&1 | head -1)"
fi

# ============================================
# 3. Node.js 18
# ============================================
step "第三步：安装 Node.js 18"
echo "  检测现有 Node.js 环境..."
if command -v node &>/dev/null; then
    EXISTING_NODE=$(node -v)
    echo "  已安装: $EXISTING_NODE"
    NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VER" -ge 18 ] 2>/dev/null; then
        info "当前 Node.js 版本满足要求 (≥18)，跳过安装"
    else
        warn "当前 Node.js 版本过低，正在升级到 Node.js 18..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt install nodejs -y
        info "Node.js 18 安装完成: $(node -v)"
    fi
else
    echo "  未检测到 Node.js，开始安装 Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install nodejs -y
    info "Node.js 18 安装完成: $(node -v)"
fi

# ============================================
# 4. Maven
# ============================================
step "第四步：安装 Maven"
echo "  检测现有 Maven 环境..."
if command -v mvn &>/dev/null; then
    info "Maven 已安装: $(mvn -v 2>&1 | head -1)"
else
    echo "  未检测到 Maven，开始安装..."
    sudo apt install maven -y
    info "Maven 安装完成: $(mvn -v 2>&1 | head -1)"
fi

# ============================================
# 5. MySQL
# ============================================
step "第五步：安装并配置 MySQL"
echo "  检测现有 MySQL 环境..."

MYSQL_NEEDS_CONFIG=false
if command -v mysql &>/dev/null; then
    info "MySQL 客户端已安装"
else
    echo "  未检测到 MySQL，开始安装 MySQL Server..."
    sudo apt install mysql-server -y
    info "MySQL Server 安装完成"
    MYSQL_NEEDS_CONFIG=true
fi

# 确保 MySQL 已启动
if sudo systemctl is-active --quiet mysql 2>/dev/null; then
    info "MySQL 服务已在运行中"
else
    echo "  正在启动 MySQL 服务..."
    sudo systemctl enable mysql
    sudo systemctl start mysql
    info "MySQL 服务已启动并设为开机自启"
fi

# 设置 root 密码
if [ "$MYSQL_NEEDS_CONFIG" = true ] || ! mysql -u root -e "SELECT 1" &>/dev/null 2>&1; then
    echo ""
    echo "  ┌─────────────────────────────────────┐"
    echo "  │  请设置 MySQL root 密码              │"
    echo "  │  (直接回车则跳过密码设置)            │"
    echo "  └─────────────────────────────────────┘"
    read -sp "  → 新密码: " ROOT_PASS
    echo ""

    if [ -n "$ROOT_PASS" ]; then
        echo "  正在设置 MySQL root 密码..."
        sudo mysql << SQL 2>/dev/null
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$ROOT_PASS';
FLUSH PRIVILEGES;
SQL
        if [ $? -eq 0 ]; then
            info "MySQL root 密码已设置成功"
        else
            warn "MySQL 密码设置可能失败，请手动执行: sudo mysql"
        fi
    else
        warn "已跳过 MySQL root 密码设置"
    fi
else
    info "MySQL 已配置过密码，跳过设置"
fi

# ============================================
# 6. Nginx
# ============================================
step "第六步：安装 Nginx"
echo "  检测现有 Nginx 环境..."
if command -v nginx &>/dev/null; then
    info "Nginx 已安装: $(nginx -v 2>&1)"
else
    echo "  未检测到 Nginx，开始安装..."
    sudo apt install nginx -y
    info "Nginx 安装完成: $(nginx -v 2>&1)"
fi

if sudo systemctl is-enabled nginx &>/dev/null 2>&1; then
    info "Nginx 已设为开机自启"
else
    sudo systemctl enable nginx
    info "Nginx 已设为开机自启"
fi

# ============================================
# 7. Git
# ============================================
step "第七步：安装 Git"
if command -v git &>/dev/null; then
    info "Git 已安装: $(git --version)"
else
    echo "  未检测到 Git，开始安装..."
    sudo apt install git -y
    info "Git 安装完成: $(git --version)"
fi

# ============================================
# 8. 防火墙配置
# ============================================
step "第八步：检查防火墙规则"
if command -v ufw &>/dev/null; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null)
    if echo "$UFW_STATUS" | grep -q "Status: active"; then
        echo "  检测到 ufw 防火墙已启用，正在配置规则..."

        if sudo ufw status | grep -q "80/tcp"; then
            info "端口 80 (HTTP) 已放行"
        else
            echo "  放行端口 80 (HTTP)..."
            sudo ufw allow 80/tcp
            info "端口 80 已放行"
        fi

        if sudo ufw status | grep -q "22/tcp"; then
            info "端口 22 (SSH) 已放行"
        else
            echo "  放行端口 22 (SSH)..."
            sudo ufw allow 22/tcp
            info "端口 22 已放行"
        fi
    else
        echo "  ufw 防火墙未启用，无需配置"
    fi
else
    echo "  未安装 ufw，跳过防火墙配置"
fi

# ============================================
# 9. 验证安装
# ============================================
step "第九步：验证安装结果"

echo ""
echo "  ┌──── 环境检查结果 ────┐"
echo "  │"

check_item() {
    local name="$1"
    shift
    if "$@" &>/dev/null; then
        echo -e "  │  ${GREEN}✓${NC}  $name"
    else
        echo -e "  │  ${RED}✗${NC}  $name — 请手动安装"
    fi
}

check_item "JDK 17       $(java -version 2>&1 | head -1 | cut -d' ' -f1-3)" java -version
check_item "Node.js      $(node -v 2>/dev/null || echo '未安装')" node -v
check_item "Maven        $(mvn -v 2>/dev/null | head -1 | cut -d' ' -f1-3 || echo '未安装')" mvn -v
check_item "MySQL        $(mysql --version 2>/dev/null | cut -d' ' -f1-3 || echo '未安装')" mysql --version
check_item "Nginx        $(nginx -v 2>&1 | cut -d' ' -f2- || echo '未安装')" nginx -v
check_item "Git          $(git --version 2>/dev/null | cut -d' ' -f1-3 || echo '未安装')" git --version

echo "  │"
echo "  └────────────────────────┘"
echo ""

# 计算耗时
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo "╔══════════════════════════════════════════╗"
echo "║         环境安装完成！                    ║"
if [ $MINUTES -gt 0 ]; then
    echo "║         耗时: ${MINUTES} 分 ${SECONDS} 秒                    ║"
else
    echo "║         耗时: ${SECONDS} 秒                          ║"
fi
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  ⚠  重要提醒: 请确保已在云服务商控制台的安全组中放行以下端口:"
echo "     • 80  (TCP) — HTTP 访问"
echo "     • 22  (TCP) — SSH 远程连接（通常已默认放行）"
echo ""
echo "  ┌─ 下一步操作 ─────────────────────────┐"
echo "  │                                        │"
echo "  │  git clone <你的仓库地址>               │"
echo "  │  cd mini-personal-cloud-disk           │"
echo "  │  bash deploy/deploy.sh                 │"
echo "  │                                        │"
echo "  └────────────────────────────────────────┘"
echo ""
