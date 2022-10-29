---
title: "Linux Read Tool"
date: 2022-05-05T00:17:58+08:00
lastmod: 2022-05-05T00:17:58+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- tech
- linux
- kbuild
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


## Linux Kernel阅读工具



[需要多久才能看完linux内核源码？](https://mp.weixin.qq.com/s/K_Ix6C9d_03cb1Hfpz461g)




## Linux内核代码下载

Linux kernel官网
https://www.kernel.org/

解压 linux-5.19.10.tar.xz
```sh
tar -xvf linux-5.19.10.tar.xz
```


https://blog.csdn.net/m0_49328056/article/details/121669035



## linux内核线上阅读

- linux、u-boot、qemu、glibc、llvm、grub
https://elixir.bootlin.com/

<br>

## U-boot

```sh
# 下载源代码
git clone https://source.denx.de/u-boot/u-boot.git
# 或
git clone https://github.com/u-boot/u-boot
# 切换分支
git checkout v2020.10
```

- 官网 https://www.denx.de/wiki/U-Boot/  
- 代码网站 https://source.denx.de/u-boot
- 什么是U-Boot以及如何下载U-Boot源码
https://blog.csdn.net/zhuguanlin121/article/details/119008893


<br>

- gdb
[《100个gdb小技巧》](https://wizardforcel.gitbooks.io/100-gdb-tips/content/)

https://leetcode-cn.com/circle/article/7mxorv



- kbuild
[Kbuild: the Linux Kernel Build System](https://www.linuxjournal.com/content/kbuild-linux-kernel-build-system)        \
[Kernel Build System¶](https://www.kernel.org/doc/html/latest/kbuild/index.html)








https://www.zhihu.com/question/47039391/answer/2287806626









## ELF

开源库
lief

参考链接：
https://blog.csdn.net/GrayOnDream/article/details/124564129




