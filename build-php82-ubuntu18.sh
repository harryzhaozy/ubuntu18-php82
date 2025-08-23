#!/bin/bash
set -e

# 默认 PHP 版本
DEFAULT_PHP_VERSION="8.2.23"
OPENSSL_VERSION="1.1.1w"
INSTALL_DIR="/usr/local/php8.2"
KEEP_SOURCE=false

# 解析参数
PHP_VERSION="$DEFAULT_PHP_VERSION"
for arg in "$@"; do
    case $arg in
        --keep)
            KEEP_SOURCE=true
            ;;
        *)
            PHP_VERSION="$arg"
            ;;
    esac
done

echo ">>> 将要安装 PHP ${PHP_VERSION} (OpenSSL ${OPENSSL_VERSION})"
if [ "$KEEP_SOURCE" = true ]; then
    echo ">>> 启用 --keep 参数，将保留源码"
else
    echo ">>> 安装完成后会清理源码和压缩包"
fi

echo ">>> 更新系统 ..."
sudo apt update -y
sudo apt upgrade -y

echo ">>> 安装依赖 ..."
sudo apt install -y build-essential pkg-config \
    libxml2-dev libsqlite3-dev libonig-dev libcurl4-openssl-dev \
    libssl-dev libzip-dev libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev \
    libicu-dev libxslt1-dev libreadline-dev libargon2-0-dev libsodium-dev \
    libtidy-dev libxslt-dev zlib1g-dev wget tar

# ----------------------------
# 自动判断内存并创建 Swap
# ----------------------------
MEM_TOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_TOTAL_MB=$((MEM_TOTAL_KB/1024))
echo ">>> 系统总内存: ${MEM_TOTAL_MB} MB"

# 如果内存小于 4GB，启用 Swap
if [ "$MEM_TOTAL_MB" -lt 4096 ]; then
    echo ">>> 内存 <4GB，创建 4GB Swap ..."
    if [ ! -f /swapfile ]; then
        sudo fallocate -l 4G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    else
        echo ">>> Swap 文件已存在，跳过创建"
    fi
fi

# 根据内存大小选择 make -j
# 简单策略：每 1GB 内存使用 1 个并行
MAKE_J=$(( MEM_TOTAL_MB / 1024 ))
if [ "$MAKE_J" -lt 1 ]; then
    MAKE_J=1
fi
echo ">>> make 并行数: -j$MAKE_J"

cd /usr/local/src

echo ">>> 安装 OpenSSL ${OPENSSL_VERSION} ..."
wget -nc https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
tar -xzf openssl-${OPENSSL_VERSION}.tar.gz
cd openssl-${OPENSSL_VERSION}
./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared zlib
make -j$MAKE_J
sudo make install
cd ..
export PKG_CONFIG_PATH=/usr/local/openssl/lib/pkgconfig:$PKG_CONFIG_PATH

echo ">>> 下载 PHP ${PHP_VERSION} ..."
wget -nc https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz
tar -xzf php-${PHP_VERSION}.tar.gz
cd php-${PHP_VERSION}

echo ">>> 配置编译参数 ..."
./configure \
    --prefix=${INSTALL_DIR} \
    --with-config-file-path=${INSTALL_DIR}/etc \
    --enable-fpm \
    --with-fpm-user=www-data \
    --with-fpm-group=www-data \
    --enable-mbstring \
    --with-curl \
    --with-openssl=/usr/local/openssl \
    --with-zlib \
    --with-zip \
    --with-mysqli \
    --with-pdo-mysql \
    --enable-intl \
    --with-xsl \
    --with-readline \
    --enable-sockets \
    --enable-bcmath \
    --enable-soap \
    --with-gettext \
    --with-freetype \
    --with-jpeg \
    --with-webp

echo ">>> 编译并安装 PHP ${PHP_VERSION} ..."
make -j$MAKE_J
sudo make install

echo ">>> 配置 PHP ..."
sudo mkdir -p ${INSTALL_DIR}/etc
sudo cp php.ini-production ${INSTALL_DIR}/etc/php.ini

echo ">>> 配置 PHP-FPM ..."
sudo cp sapi/fpm/php-fpm.service /etc/systemd/system/php8.2-fpm.service
sudo systemctl daemon-reload
sudo systemctl enable php8.2-fpm
sudo systemctl start php8.2-fpm

echo ">>> 配置环境变量 ..."
echo "export PATH=${INSTALL_DIR}/bin:\$PATH" | sudo tee /etc/profile.d/php82.sh
source /etc/profile.d/php82.sh

echo ">>> 检查版本 ..."
php -v

# ----------------------------
# 清理源码
# ----------------------------
if [ "$KEEP_SOURCE" = false ]; then
    echo ">>> 清理临时文件 ..."
    cd /usr/local/src
    rm -rf php-${PHP_VERSION} php-${PHP_VERSION}.tar.gz
    rm -rf openssl-${OPENSSL_VERSION} openssl-${OPENSSL_VERSION}.tar.gz
    #删除swapfile
    sudo swapoff /swapfile
    sudo rm /swapfile
else
    echo ">>> 保留源码和压缩包 ..."
fi

echo ">>> 安装完成！"

