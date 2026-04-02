---
date: "2026-02-07T12:14:43+08:00"
draft: false
tags:
    - R
    - blog
title: R语言 renv环境配置
---


项目环境配置步骤（本地执行，无需在文档中运行）
```r
# 1. 安装 renv 包（使用清华镜像源，国内下载更快）
install.packages("renv", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")

# 2. 加载 renv 包
library(renv)

# 3. 初始化项目独立环境（确保当前工作目录是项目根目录）
renv::init()  

# 4. 安装 Quarto 所需的核心 R 包
install.packages(c("rmarkdown", "tidyverse"), repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")

# 5. 同步依赖到版本锁定文件
renv::snapshot() 

# 6.修改安装镜像

options(repos = c(CRAN = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/"))


# 中国区域镜像
中国
https://mirrors.tuna.tsinghua.edu.cn/CRAN/	TUNA 团队，清华大学
https://mirrors.bfsu.edu.cn/CRAN/	北京外国语大学
https://mirrors.pku.edu.cn/CRAN/	北京大学
https://mirrors.ustc.edu.cn/CRAN/	中国科学技术大学
https://mirrors.zju.edu.cn/CRAN/	浙江大学
https://mirror-hk.koddos.net/CRAN/	香港 KoDDoS
https://mirrors.e-ducation.cn/CRAN/	精英教育
https://mirrors.qlu.edu.cn/CRAN/	齐鲁工业大学
https://mirror.lzu.edu.cn/CRAN/	兰州大学开源社区
https://mirrors.nju.edu.cn/CRAN/	南京大学e科学中心
https://mirrors.sjtug.sjtu.edu.cn/cran/	上海交通大学
https://mirrors.sustech.edu.cn/CRAN/	南方科技大学 (SUSTech)
https://mirrors.nwafu.edu.cn/cran/	西北农林科技大学 (NWAFU)


在 Windows 环境中使用 Positron 或原生 R 时，可以通过以下两种主要方法将 R 软件包（Library）的安装路径从 C 盘更改到其他盘符（如 D 盘）。

方法一：修改环境变量（推荐，最彻底）
通过设置 Windows 系统的环境变量 R_LIBS_USER，可以强制 R 以后都将包安装到指定目录。
	1.	创建目标文件夹：在 D 盘（或其他盘）创建一个文件夹，例如 D:\R\library。
	2.	打开环境变量设置：
	•	按下 Win + S，搜索“编辑系统环境变量”并打开。
	•	点击右下角的 “环境变量”。
	3.	新建用户变量：
	•	在“用户变量”栏点击 “新建”。
	•	变量名输入：R_LIBS_USER
	•	变量值输入：D:\R\library（即你刚才创建的路径）。
	4.	重启 Positron：重新启动 Positron 并在 R 控制台中输入 .libPaths()。如果输出的第一条路径是你设置的 D 盘路径，说明设置成功。



# quarto render Hugo网页时
为了保证qmd文件不会放入public文件夹，需要在hugo.toml或者config.toml 或者后缀为yaml的配置中，进行描述

Toml文件：

ignoreFiles = [".Rmd$", ".R$", ".py$",".qmd$",".ipynb$"]

Yaml 文件

ignoreFiles:
    - ".qmd$"
    - ".ipynb$"
    - ".py$"
    - ".Rmd$"




#R语言学习本
```

#R语言学习本 #blog 


