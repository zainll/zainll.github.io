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
参考链接：[ubuntu20.04更改国内镜像源](https://blog.csdn.net/qq_33706673/article/details/106869016)
https://blog.csdn.net/qq_48490728/article/details/124944114


## ubuntu 显示

https://ubuntuqa.com/article/8837.html

https://www.csdn.net/tags/MtTaAgzsNjg5MTk4LWJsb2cO0O0O.html




```sh
# 查看当前目录大小
du -h --max-depth=1
```




## flameshot截图工具


```sh
# 快捷方式
flameshot gui


```

- https://www.cnblogs.com/kendoziyu/p/how_to_screenshot_in_ubuntu2004.html






