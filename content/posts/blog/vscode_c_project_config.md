---
title: "vscode c/c++一键创建工程插件"
date: 2022-10-23T00:00:08+08:00
lastmod: 2022-10-23T00:00:52+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- tech
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

> 说明：插件基于C/C++ Project Generator，原始项目未更新，联系到作者沟通是否合入 

<br>

## 本项目地址:
https://github.com/zhuangll/vscode_c_project_config

> 支持gtest

## 安装
1. 在vscode中安装C/C++ Project Generator插件       
2. 下载代码，将代码替换到C/C++ Project Generator插件所在目录，windows环境vscode插件目录,将功能代码复制替换如下目录中 `C:\Users\<用户名>\.vscode\extensions\danielpinto8zz6.c-cpp-project-generator-1.2.4`
3. mingw安装，选择如下链接下载一个即可，添加到环境变量path中
- 各版本gcc  mingw  clang
https://winlibs.com/
https://github.com/brechtsanders/winlibs_mingw
- MinGW-w64
https://www.mingw-w64.org/changelog/

## 使用方法

> wingows环境需要安装mingw，并添加到环境变量    \
linux环境适配中，已经部分适配，存在小bug，暂无适配动力
