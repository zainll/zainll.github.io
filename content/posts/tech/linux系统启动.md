---
title: "linux系统启动"
date: 2022-08-17T00:17:58+08:00
lastmod: 2022-08-18T00:17:58+08:00
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


&ensp;LInux系统启动5个阶段： \
&emsp;内核引导 -> 运行init -> 系统初始化 -> 建立终端 -> 用户登录系统

# 1.内核引导

&ensp;机器上电后，BIOS开机自检，根据BIOS中设置的启动设备(通常为硬盘)启动 \
&ensp;操作系统阶段硬件，首先读入`/boot`目录下内核文件 \ 
 












