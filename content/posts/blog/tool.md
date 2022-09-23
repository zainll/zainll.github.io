---
title: "tool"
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


# WSL

## 安装ubuntu20.04

安装到非系统盘目录，下载离线安装包，复制到想要安装的目录下，解压，以管理员身份运行ubuntu2004.exe

## 卸载wsl

```sh
wslconfig /l
# 从列表中选择要卸载的发行版（例如Ubuntu）并键入命令
wslconfig /u Ubuntu
```
参考链接：[WSL系列操作：安装，卸载](https://blog.csdn.net/zhangpeterx/article/details/97616268
)

## 设置wsl
```sh
# 更改默认root用户登录
ubuntu1804.exe config --default-user root
# 更改默认登陆目录
# list 中 Ubuntu-20.04 条目中添加
"startingDirectory": "//wsl$/Ubuntu-20.04"

# 以管理员权限运行cmd
# 停止
net stop LxssManager  
# 启动
net start LxssManager 
```

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

## ubuntu 显示

https://ubuntuqa.com/article/8837.html

https://www.csdn.net/tags/MtTaAgzsNjg5MTk4LWJsb2cO0O0O.html




# PowerShell

```sh
winget search Microsoft.PowerShell
winget install Microsoft.PowerShell
```
参考链接：
- [Windows Powershell和Windows Terminal的区别](https://blog.csdn.net/The_Time_Runner/article/details/106038222)


- [安装和设置 Windows 终端](https://docs.microsoft.com/zh-cn/windows/terminal/get-started)


# windows 包管理工具

## winget 官方推出

```sh
# 使用 WinGet 安装一遍
winget install postman
winget search postman

# 卸载，再用 Scoop 安装一遍
scoop install postman
```

## choro


##  vcpkg
[Get started with vcpkg](https://vcpkg.io/en/getting-started.html)

## cget
https://cget.readthedocs.io/en/latest/#

[开源库集成器Vcpkg全教程](https://blog.csdn.net/cjmqas/article/details/79282847)

##  Scoop 


#  图床


 https://blog.csdn.net/qq_44314954/article/details/122951033


# Vim

## vim快捷方式

```sh
# 退出ESC 返回命令模式
# 保存退出
wq
# 放弃退出
!q
# 回到文件首部
gg
# 到文件尾部
GG
# i 进入编辑模式

;n              # 打开文件目录树显示在屏幕左侧
;m              # 打开当前函数和变量目录树显示在屏幕右侧
;w              # 保存文件
;u              # 向上翻半屏
;d              # 向下翻半屏
;1              # 光标快速移动到行首
;2              # 光标快速移动到行末
;a              # 快速切换.h和cpp文件，写C++的时候很方便
;e              # 打开一个新文件
;z              # 切回shell交互命令，输入fg在切回vim，非常实用
;s              # 水平分屏，并打开文件目录选取想打开的文件，如果想新建文件，;e 就好
;v              # 竖直分屏，并打开文件目录选取想打开的文件，如果想新建文件，;e 就好
;fw            # 查找项目内关键字
;ff            # 查找项目内文件名
;gt            # 跳转到变量或者函数定义的地方，前提是安装ctags，并且在在PowerVim输入 ;tg命令 Jump to the definition of the keyword where the cursor is located, but make sure you have make ctags
;gr            # 跳回，对应着;gt
;tg            # 对当前目录打ctag
;y              # 保存当前选中的目录到系统剪切板，前提是vim支持系统剪切板的寄存器
dsfa;w
;h/l/k/j        # 光标向左右上下窗口移动，特别是打开多个窗口。使用这个快捷键组合非常实用
;gg            # 按顺序光标跳转各个窗口
# Shortcuts without ;

e              # 快速删除光标所在的词
tabc            # 关闭当前tab，可以用:tabnew来打开一个新的tab Close tab, of course you should :tabnew a file first.
F1              # 编译C++代码，自己写的C++例子的时候一键编译。前提手动在当前目录建一个bin文件夹，这是用来存放编译产生的执行文件
gc              # 快速注释选中的块（是visual模式下选中的块）
gcc            # 快速当前行
{              # 光标向上移动一个代码块s
}              # 光标向下移动一个代码块


```

## PowerVim

[【VIM】PowerVim安装及使用](https://blog.csdn.net/weixin_44583590/article/details/120896928)

[PowerVim - 使Vim更加强大易用](https://www.jianshu.com/p/c2641958b30f?utm_campaign=maleskine&utm_content=note&utm_medium=seo_notes&utm_source=recommendation)


# vscode

## vscode 上传图片

```sh
# 上传剪贴板中的图片到服务器。
ctrl + alt + u
# 打开文件浏览器选择图片上传。
ctrl + alt + e

```
- https://www.jianshu.com/p/868b3a2028f8
https://zhuanlan.zhihu.com/p/131584831
