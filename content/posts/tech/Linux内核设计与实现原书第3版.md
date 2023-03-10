---
title: "Linux内核设计与实现原书第3版)"
date: 2023-01-05T00:18:23+08:00
lastmod: 2023-01-05T00:18:23+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- linux
description: ""  #描述
weight:  # 输入1可以顶置文章，用来给文章展示排序，不填就默认按时间排序
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


# Linux内核设计与实现

&ensp;基于Linux 2.6.34, 主要内容：进程管理、进程调度、时间管理好定时器、系统调用接口、内存寻址、内存管理和页缓存、VFS、内核同步及调试技术。Linux 2.6内核特色内容：CFS调度程序、抢占式内核、块I/O层及I/O调度程序 <br>
&ensp;《Understanding the Linux kernel》、《Linux Devices Drivers》 <br>
&ensp;www.kerneltravel.net



# 第1章 Linux内核
&ensp;BSD：伯克利Unix系统 <br>
&ensp;Unix特点：
- 1）系统调用少且明确
- 2）抽象为文件，统一文件系统调用函数
- 3）C语言
- 4）进程创建fork系统调用
- 5）进程间通信

&ensp;操作系统应该包括的部分：内核、设备驱动程序、启动引导程序、明后shell或其他用户界面、基本文件管理工具和系统工具 <br>
&ensp;内核负责：响应中断的中断服务程序、管理过高接触分享处理器时间的调度程序、管理检查地址空间的内存管理程序和网络、进程间通信等系统服务程序 <br>
&ensp;内核空间和用户空间 <br>
&ensp;应用程序通过系统调用与内核通信，应用程序->库函数->系统调用，应用程序通过系统调用陷入内核，内核运行于进程上下文中 <br>
&ensp;内核管理硬件，中断机制，硬件设备通过中断信号与系统通信，中断号对应存在中断服务程序，响应和处理中断，中断不在进程上下文中执行，在中断上下文中运行 <br>


![2023-03-04_19-31](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/2023-03-04_19-31.png
&ensp;单内核与微内核：
- 单内核：内核在同一地址空间，直接系统调用，Unix、Linux
- 微内核：系统服务独立运行各自地址空间，消息传递处理内核通信，系统采用进程间通信(IPC)系统，Windows、Mac
&ensp;Linux与传统Unix差异：
- Linux支持动态加载内核模块
- Linux支持多处理(SMP)机制
- Linux内核可抢占
- LInux内核不区分线程和其他一般进程
- Linux提供设备类的面向对象设备模型


# 第2章 从内核出发

&ensp;Linux内核官网：http://www.kernel.org
```sh
# git下载代码
git clone 
# 解压
tar xvjf linux.....tar.bz2
tar xvzf linux.....tar.gz
# 使用补丁
patch -p1 < ../patch-x.y.z

```
## 内核源码树
|目录|描述|
|---|---|
|arch|体系结构源码|
|block|块设备I/O层|
|crypto|加密API|
|Documentation|内核源码文档|
|drivers|设备驱动程序|
|firmaware|模型驱动需要的设备固件|
|fs|VFS和各种文件系统|
|include|内核头文件|
|init|内核引导和初始化|
|ipc|进程间通信代码|
|kernel|调度程序等核心子系统|
|lib|通用内核函数|
|mm|内存管理子系统和VM|
|net|网络子系统|
|samples|示例代码|
|scripts|编译内核脚本|
|security|安全模块|
|sound|语言子系统|
|usr|用户空间代码|
|tools|开放工具|
|virt|虚拟化结构|



## 编译内核















