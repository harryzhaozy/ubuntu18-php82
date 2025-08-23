
🚀 <span style="font-size:20px">20px 大小</span>build-php82-ubuntu18.sh使用方法

一、默认安装 PHP 8.2.23 并清理源码：

chmod +x build-php82-ubuntu18.sh
./build-php82-ubuntu18.sh


指定版本安装 PHP 8.2.24 并清理源码：

./build-php82-ubuntu18.sh 8.2.24


指定版本安装并保留源码：

./build-php82-ubuntu18.sh 8.2.24 --keep


脚本会自动检测内存大小，低内存时创建 4GB Swap，并自动选择合适的 make -j 并行数，避免 OOM 编译失败。
生成的php82可以安装到其他ubuntu18的机器上，在编译好的机器上打包制作二进制包 (tar.gz)
cd /usr/local
tar -czf php8.2-bin.tar.gz php8.2 openssl
🚀使用install_php_bin.sh还原
使用示例
# 默认安装包和路径，不启动 FPM
./install_php_bin.sh

# 指定二进制包和安装目录，自动启动 FPM
./install_php_bin.sh php8.2-linux.tar.gz /usr/local/php8.2 true
