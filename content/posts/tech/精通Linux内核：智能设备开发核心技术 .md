---
title: "精通Linux内核：智能设备开发核心技术 "
date: 2023-06-05T00:21:58+08:00
lastmod: 2023-06-06T00:21:58+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- arm
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

&ensp;知识储备篇介绍了Linux的数据结构、中断处理、内核同步和时间计算等  \
&ensp;内存管理篇、文件系统篇、进程管理篇、介绍Linux的三大核心模块   \
&ensp;Linux内核开发在操作系统、智能设备、驱动、通信、芯片以及人工智能等 \

&ensp;书分为以下五个部分:  \
&emsp;知识储备篇： 数据结构、时间、中断处理和内核同步 \
&emsp;内存管理篇： 内存寻址、物理内存和线性内存空间的管理及缺页异常  \
&emsp;文件系统篇： VFS流程，sysfs、proc和devtmpfs文件系统实现，ext4文件系统  \
&emsp;进程管理篇： 进程原理、进程调度、信号处理、进程通信和程序执行。掌握进程间的关系、进程调度的过程、进程通信原理、信号处理过程  \
&emsp;升华篇： I/O多路复用、input子系统、V4L2架构、Linux设备驱动模型、Binder通信和驱动实现 \


# 第1章 基于Linux内核的操作系统

## 1.1 处理器、平台和操作系统

&ensp;基于Linux内核的操作系统，一般包括： \
&emsp;(1)BootLoader: 如GRUB和SYSLINUX，负责加载内核到内存，在系统上电或BIOS初始化完成后执行加载 \
&emsp;(2)init程序：负责启动系统的服务和操作系统的核心程序  \
&emsp;(3)软件库：如加载elf文件的ld-linux-so、支持C程序的库、如GUN C Library(glibc)、Android的Bionic \
&emsp;(4)命令和工具：如Shell命令和GNU coreutils   \


## 1.2 以安卓为例剖析操作系统
### 1.2.1 安卓的整体架构

![20230613004743](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230613004743.png)
&ensp;Android操作系统架构图 \
&ensp;Linux内核是整个架构的基础，它负责管理内存、电源、文件系统和进程等核心模块，提供系统的设备驱动
 

![20230613005710](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230613005710.png)

&ensp;三个进程，APP1、APP2和Service，APP和Service之间传递控制和数据都需要通过进程通信实现，Service将控制传递至HAL，最终到设备驱动，HAL得到驱动产生的数据，报告至Service，由Service分发给APP1和APP2  \

&ensp;操作系统的核心功能看Android与内核的关系 \
&emsp;进程管理： 进程这个概念本身是由内核实现的，还包括进程调度、进程通信。\
&ensp;&emsp;Android利用Pthread等实现了它的进程、线程，是对内核系统调用的封装。Android引入Binder通信，Binder不仅需要用户空间，还需要驱动  \
&ensp;内存管理： 内存、内存映射和内存分配、回收等内核都已实现 \
&ensp;&emsp;Android实现了特有的ION内存管理机制，使用它在用户空间申请大段连续的物理内存  \
&ensp;文件系统： 内核实现了文件系统的框架和常用的文件系统  \
&ensp;&emsp;文件系统不仅关乎数据存储，进程、内存和设备，Linux一切皆文件  \
&ensp;用户界面： Android开发了一套控件（View）,一套完整的显示架构，用户界面： Android开发了一套控件（View） \
&ensp;设备驱动： 设备驱动由内核提供,随系统启动而运行的设备驱动，一般在内核启动过程中加载，某些在特定情况下才会使用的设备驱动

### 1.2.2 Linux内核的核心作用

&ensp;开机后，内核由bootloader加载进入内存执行，它是创建系统的第一个进程，初始化时钟、内存、中断等核心功能，然后执行init程序。init程序是基于Linux内核的操作系统，在用户空间的起点，它启动核心服务，挂载文件系统，更改文件权限，由后续的服务一步步初始化整个操作系统

&ensp;内核实现了内存管理、文件系统、进程管理和网络管理等核心模块，将用户空间封装内核提供的系统调用作为类库，供其他部分使用


## 1.3 内核整体架构

### 1.3.1 内核代码目录结构

 &ensp;内核代码一级目录： \
 &ensp;&emsp;Documentation目录：存放说明文档 \
 &ensp;&emsp;arch目录：arch是architecture，体系结构相关代码，体系结构相关，如内存页表和进程上下文等 \
 &ensp;&emsp;kernel目录：内核核心部分，包括进程调度、中断处理和时钟等模块的核心代码，与体系结构相关代码存在arch/xx/kernel下  \
 &ensp;&emsp;drivers目录：设备驱动代码  \
 &ensp;&emsp;mm目录：mm是memory managemnt缩写，包括内存管理相关代码 \
 &ensp;&emsp;fs目录：fs是file system文件系统代码，文件系统架构(VFS)和系统支持各种文件系统，一个子目录至少对应一种文件系统  \
 &ensp;&emsp;ipc目录：inter process communication，包括消息队列、共享内存和信号量等进程通信方式 \
 &ensp;&emsp;block目录：块设备管理的代码，块设备与字符设备。块设备支持随机访问，SD卡和硬盘是块设备；字符设备只能顺序访问，键盘和串口是字符设备  \
 &ensp;&emsp;lib目录：公用的库函数，比如红黑树和字符串操作，内核处在C语言库(glibc等)下一层，glibc是由封装内核的系统调用实现的  \
 &ensp;&emsp;init目录：内核初始化代码，main.c定义内核启动的入口start_kernel函数 \
 &ensp;&emsp;firmware目录：包括运行在芯片内的固件  \
 &ensp;&emsp;scripts目录：辅助内核配置脚本，如make menuconfig命令配置  \
 &ensp;&emsp;net：网络、crypto：加密、certs：证书、security：安全、tools：工具、virt：虚拟化  \


### 1.3.2 内核的核心模块及关联

















