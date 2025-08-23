
🚀 build-php82-ubuntu18.sh使用方法

一、默认安装 PHP 8.2.23 并清理源码：

chmod +x build-php82-ubuntu18.sh
./build-php82-ubuntu18.sh


指定版本安装 PHP 8.2.24 并清理源码：

./build-php82-ubuntu18.sh 8.2.24


指定版本安装并保留源码：

./build-php82-ubuntu18.sh 8.2.24 --keep


脚本会自动检测内存大小，低内存时创建 4GB Swap，并自动选择合适的 make -j 并行数，避免 OOM 编译失败。
