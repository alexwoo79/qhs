#!/bin/bash

# 本地开发 - 生成页面
if [ "$1" = "dev" ]; then
    hugo --config config-dev.yaml --destination public
    
    # 询问是否同步到 miniserver
    echo
    read -p "是否同步构建结果到 miniserver (10.10.10.115)? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "public" ]; then
            echo "正在同步 public 文件夹到 10.10.10.115:/root/web/html/public ..."
            rsync -avz --delete -e "ssh -p 5522" public/ root@10.10.10.115:/root/web/html/public/
            if [ $? -eq 0 ]; then
                echo "同步成功完成！"
            else
                echo "同步过程中出现错误，请检查连接。"
            fi
        else
            echo "错误: public 目录不存在。请先运行构建命令。"
        fi
    else
        echo "跳过同步步骤。"
    fi
# 构建线上版本
elif [ "$1" = "build" ]; then
    hugo --config config.yaml --gc --minify
    
    # 询问是否同步到 miniserver
    echo
    read -p "是否同步构建结果到 miniserver (10.10.10.115)? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "public" ]; then
            echo "正在同步 public 文件夹到 10.10.10.115:/root/web/html/public ..."
            rsync -avz --delete -e "ssh -p 5522" public/ root@10.10.10.115:/root/web/html/public/
            if [ $? -eq 0 ]; then
                echo "同步成功完成！"
            else
                echo "同步过程中出现错误，请检查连接。"
            fi
        else
            echo "错误: public 目录不存在。请先运行构建命令。"
        fi
    else
        echo "跳过同步步骤。"
    fi
else
    echo "用法:"
    echo "  ./build.sh dev   # 本地开发模式"
    echo "  ./build.sh build # 构建线上版本"
fi