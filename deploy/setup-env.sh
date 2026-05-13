#!/bin/bash
# Cloud Disk — 服务器环境安装
# 用法: bash setup-env.sh
# 适用于 Ubuntu 20.04/22.04/24.04

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
info() { echo -e "${GREEN}[OK]${NC} $1"; }
step() { echo -e "\n${GREEN}>>${NC} $1"; }

if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}请不要用 root 运行此脚本，使用 sudo 用户${NC}"
    exit 1
fi

echo "=========================================="
echo "  Cloud Disk — 环境安装"
echo "=========================================="

# 基础更新
step "更新系统包..."
sudo apt update -qq

# JDK 17
step "安装 JDK 17..."
sudo apt install openjdk-17-jdk -y
info "Java: $(java -version 2>&1 | head -1)"

# Node.js 18
step "安装 Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y
info "Node.js: $(node -v)"

# Maven
step "安装 Maven..."
sudo apt install maven -y
info "Maven: $(mvn -v 2>&1 | head -1)"

# MySQL
step "安装 MySQL..."
sudo apt install mysql-server -y
sudo systemctl enable mysql
sudo systemctl start mysql
info "MySQL 已安装并启动"

# 设置 MySQL root 密码
echo ""
echo "请设置 MySQL root 密码:"
read -sp "  新密码: " ROOT_PASS
echo ""

if [ -n "$ROOT_PASS" ]; then
    sudo mysql << SQL
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$ROOT_PASS';
FLUSH PRIVILEGES;
SQL
    info "MySQL 密码已设置"
fi

# Nginx
step "安装 Nginx..."
sudo apt install nginx -y
sudo systemctl enable nginx
info "Nginx: $(nginx -v 2>&1)"

# Git
step "安装 Git..."
sudo apt install git -y

# 防火墙（如果启用）
step "检查防火墙..."
if command -v ufw &>/dev/null && sudo ufw status | grep -q "Status: active"; then
    echo "检测到 ufw 防火墙，放行 80 端口..."
    sudo ufw allow 80/tcp
    sudo ufw allow 22/tcp
else
    echo "ufw 未启用，无需操作"
fi

echo ""
echo "=========================================="
echo "  环境安装完成！"
echo "=========================================="
echo ""
echo "  ⚠ 还需要去云服务商安全组放行: 80 (TCP)"
echo ""
echo "  接下来:"
echo "    git clone <你的仓库>"
echo "    cd mini-personal-cloud-disk"
echo "    bash deploy/deploy.sh"
echo "=========================================="
