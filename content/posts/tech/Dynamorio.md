---
title: "Linux内核深度解析"
date: 2022-10-05T00:17:58+08:00
lastmod: 2022-10-05T00:17:58+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- tech
- linux
description: ""
weight:
slug: ""
draft: false # 是否为草稿
comments: true
reward: true # 打赏
mermaid: true #是否开启mermaid
showToc: true # 显示目录
TocOpen: true # 自动展开目录
hidemeta: false # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: true # 底部不显示分享栏
showbreadcrumbs: true #顶部显示路径
cover:
    image: "" #图片路径例如：posts/tech/123/123.png
    caption: "" #图片底部描述
    alt: ""
    relative: false
---




## 编译
- 注意wsl中需要root用户编译
https://dynamorio.org/page_building.html
```sh
cmake \
-DCMAKE_TOOLCHAIN_FILE=/mnt/e/code/dynamorio/make/toolchain-android=arm64.cmake \
-DANDROID_TOOLCHAIN=/android_toolchain_using \
-DDR_COPY_TO_DEVICE=OFF \
-DCMAKE_BUILD_TYPE=Debug \
-DBUILD_TESTS=OFF \
-DBUILD_SAMPLES=ON \
-DBUILD_CLIENTS=ON \
../dynamorio



cmake \
-DDR_COPY_TO_DEVICE=OFF \
-DCMAKE_BUILD_TYPE=Debug \
-DBUILD_TESTS=OFF \
-DBUILD_SAMPLES=ON \
-DBUILD_CLIENTS=ON \
../dynamorio
```


<!--more-->


- 学习链接
DynamoRIO进阶指南
https://blog.csdn.net/oShuangYue12/article/details/109780166





