---
title: "linuxTool"
date: 2022-05-05T00:18:23+08:00
lastmod: 2022-05-05T00:18:23+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- blog
- tool
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




## ubuntu 换源

```sh
# 备份
cp /etc/apt/sources.list /etc/apt/sources.list.20211013
lsb_release -c
lsb_release -a
# 

sudo apt-get update
sudo apt-get upgrade

```
参考链接：
[ubuntu20.04更改国内镜像源](https://blog.csdn.net/qq_33706673/article/details/106869016)           \
https://blog.csdn.net/qq_48490728/article/details/124944114              \
https://blog.csdn.net/weixin_44916154/article/details/124581334


## 安装搜狗输入法
https://blog.csdn.net/Mr_Sudo/article/details/124874239

## ubuntu 显示

https://ubuntuqa.com/article/8837.html

https://www.csdn.net/tags/MtTaAgzsNjg5MTk4LWJsb2cO0O0O.html

## Ubunut 22.04 LTS 版本

**GNU/Linux核心**

* GCC 11.2.0
* binutils 2.38
* glibc 2.35

**编译工具链**

* Python 3.10.4
* Perl 5.34.0
* LLVM 14
* golang 1.18
* rustc 1.58
* OpenJDK
* Ruby 3.0
* systemd 249.11
* OpenSSL 3.0

**虚拟化**

* qemu 6.2.0
* libvirt 8.0.0
* virt-manager 4.0.0




## Linux包管理

### snap



## flameshot截图工具


```sh
# 快捷方式 
# 个人习惯设置为 alt + AQ
# -c 保存到粘贴板， -p 保存到路径 
flameshot gui -c -p <path>
```

- https://www.cnblogs.com/kendoziyu/p/how_to_screenshot_in_ubuntu2004.html


## free

```sh
get -O clash.gz https://github.com/Dreamacro/clash/releases/download/v1.11.8/clash-linux-amd64-v1.11.8.gz
gzip -f clash.gz -d 
sudo chmod +x clash 
./clash
wget -U "Mozilla/6.0" -O ~/.config/clash/config.yaml   https://to.runba.cyou/link/HR6FLUV7z8k7lNyx?clash=1
```





