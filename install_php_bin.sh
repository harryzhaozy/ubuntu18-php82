#!/bin/bash
# ================================
# 一键安装 PHP 二进制包（开箱即用）
# 支持自定义安装路径、版本号、自动启动 FPM
# Author: ChatGPT
# ================================

# ---------- 参数设置 ----------
PHP_TAR="${1:-php8.2-linux.tar.gz}"      # 二进制包文件，默认 php8.2-linux.tar.gz
INSTALL_DIR="${2:-/usr/local/php8.2}"   # 安装目录，默认 /usr/local/php8.2
START_FPM="${3:-false}"                  # 是否自动启动 FPM，默认 false
# -------------------------------

# 检查包是否存在
if [ ! -f "$PHP_TAR" ]; then
    echo "ERROR: PHP 二进制包 $PHP_TAR 不存在！"
    exit 1
fi

echo ">>> 安装信息："
echo "包文件：$PHP_TAR"
echo "安装目录：$INSTALL_DIR"
echo "是否启动 FPM：$START_FPM"
echo "-----------------------------------"

# 创建安装目录
sudo mkdir -p "$INSTALL_DIR"

# 解压二进制包
echo ">>> 解压 PHP 二进制包到 $INSTALL_DIR ..."
sudo tar -xzf "$PHP_TAR" -C /usr/local/

# 检测依赖库
echo ">>> 检测依赖库 ..."
MISSING_LIBS=()
for bin in "$INSTALL_DIR/bin/php" "$INSTALL_DIR/sbin/php-fpm"; do
    if [ -f "$bin" ]; then
        for lib in $(ldd $bin | grep "not found" | awk '{print $1}'); do
            MISSING_LIBS+=($lib)
        done
    fi
done

if [ ${#MISSING_LIBS[@]} -gt 0 ]; then
    echo ">>> 以下依赖库缺失，将自动安装（Ubuntu/Debian 系统）:"
    for lib in "${MISSING_LIBS[@]}"; do
        echo "  $lib"
    done

    sudo apt update
    for lib in "${MISSING_LIBS[@]}"; do
        case $lib in
            libssl.so*) sudo apt install -y libssl-dev ;;
            libcurl.so*) sudo apt install -y libcurl4-openssl-dev ;;
            libxml2.so*) sudo apt install -y libxml2-dev ;;
            libsqlite3.so*) sudo apt install -y libsqlite3-dev ;;
            libonig.so*) sudo apt install -y libonig-dev ;;
            libzip.so*) sudo apt install -y libzip-dev ;;
            libpcre.so*) sudo apt install -y libpcre3-dev ;;
            libreadline.so*) sudo apt install -y libreadline-dev ;;
            *) echo "请手动安装 $lib" ;;
        esac
    done
else
    echo "所有依赖库都已满足。"
fi

# 添加 PATH
echo ">>> 配置 PATH ..."
if ! grep -q "$INSTALL_DIR/bin" ~/.bashrc; then
    echo "export PATH=$INSTALL_DIR/bin:\$PATH" >> ~/.bashrc
    source ~/.bashrc
fi

echo ">>> PHP 命令已可直接使用：php -v"
php -v 2>/dev/null || echo "请使用 $INSTALL_DIR/bin/php -v 查看版本"

# 启动 PHP-FPM
if [ "$START_FPM" = true ]; then
    FPM_CONF="$INSTALL_DIR/etc/php-fpm.conf"
    if [ ! -f "$FPM_CONF" ]; then
        echo "ERROR: PHP-FPM 配置文件 $FPM_CONF 不存在，请手动复制示例配置文件。"
    else
        echo ">>> 启动 PHP-FPM ..."
        sudo "$INSTALL_DIR/sbin/php-fpm" --nodaemonize --fpm-config "$FPM_CONF"
    fi
fi

echo ">>> PHP 安装完成！"
