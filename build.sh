#!/bin/bash

# 本地开发
if [ "$1" = "dev" ]; then
    hugo server --config config-dev.yaml --cleanDestinationDir --disableFastRender
# 构建线上版本
elif [ "$1" = "build" ]; then
    hugo --config config.yaml --gc --minify
else
    echo "用法:"
    echo "  ./build.sh dev   # 本地开发模式"
    echo "  ./build.sh build # 构建线上版本"
fi