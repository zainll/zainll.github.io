---
title: "WindowsSoftware"
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



## CMD命令

```sh
# 查询本机IP
ipconfig
# 向对方电脑发送消息
msg /server 192.168.1.100 * 消息
# 查看本机用户信息
net user
# 查看共享资源
net share
# 查看网站IP
nsloopup www.baidu.com
# 查看WiFi配置文件
netsh wlan show
# 管道符，输出到文件
| 1.txt
# 



```


## windows 工具软件



### Snipaste  
> 截图软件   支持自定义设置快捷键       \
[Download](https://www.snipaste.com/download.html)

<br>

### ZoomIt  
> 屏幕缩放、标记、录制 展示小工具     \
whois  居然可以在Windows使用      \
[Download](https://learn.microsoft.com/en-us/sysinternals/downloads/zoomit)

<br>

### Sysinternals 
> 工具集   \
[Download](https://learn.microsoft.com/en-us/sysinternals/)

<br>

### everyting 
>快速查找文件    \
[Download](https://www.voidtools.com/downloads/)

<br>

### 7zip 
> 开源压缩软件   \
[Download](https://www.7-zip.org/)

<br>

### Wiztree  
>磁盘文件占用     \
[Download](https://www.diskanalyzer.com/)

<br>

### Windows Terminal        
>取代传统cmd显示，可集成PowerShell， 登录wsl，  未来Windows将设置为默认终端   \
[微软商店](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=en-us&gl=us)

<br>

### cmder
> 同事推荐，值得探索，Windows命令行工具    \ 
[Download](https://cmder.app/)   \
[github](https://github.com/cmderdev/cmder)    \
[配置](https://juejin.cn/post/6844903817851453453)   \

<br>


### PowerShell  
>一款shell，支持Windows、linux、mac，推荐Windows结合 Windows Terminal使用, 使Windows像Linux终端一样爽   \
[Download](https://github.com/PowerShell/PowerShell)

```sh
winget search Microsoft.PowerShell
winget install Microsoft.PowerShell
```
参考链接：
- [Windows Powershell和Windows Terminal的区别](https://blog.csdn.net/The_Time_Runner/article/details/106038222)


- [安装和设置 Windows 终端](https://docs.microsoft.com/zh-cn/windows/terminal/get-started)
- [wsl+windows terminal 美化教程](https://www.jianshu.com/p/aac4c5e87a3a)


<br>

<br>
### WindTerm

[WindTerm 源码](https://github.com/kingToolbox/WindTerm)




<br>

### Q-Dir  
>多窗口资源管理器                   \
[Download](http://www.q-dir.com/)


<br>

### FileZilla 
>多协议文件传送，支持FTP、SFTP，包含Client和Server，支持Windows、Linux、mac             \
[Download](https://filezilla-project.org/)


<br>

### 终端连接程序
>secureCRT 需要破解    \
https://blog.csdn.net/qq_39052513/article/details/104692026


<br>

### geek 
> windows卸载工具，清理注册表，删除缓存文件，开箱即用    \
[Download](https://geekuninstaller.com/)

<br>






<br>


## Windows包管理


### Scoop

> Scoop 是 Windows 的命令行安装程序，是一个强大的包管理工具

[项目地址](https://github.com/ScoopInstaller/Scoop)

[使用教程](https://www.mobaijun.com/posts/908521329.html)


<br>

### Chocolatey 

```sh

choro

```

[Windows软件管理工具Chocolatey的安装和使用](https://blog.csdn.net/weixin_43288999/article/details/125660445)


<br>


### winget 官方推出

> 谁用Windows 终端安装程序？   <br>  我！

```sh
# 使用 WinGet 安装一遍
winget install postman
winget search postman

# 卸载，再用 Scoop 安装一遍
scoop install postman
```

<br>

###  vcpkg 
> C/C++ 库管理工具，跨平台       \
[Get started with vcpkg](https://vcpkg.io/en/getting-started.html)



<br>

### cget
https://cget.readthedocs.io/en/latest/#         \

[开源库集成器Vcpkg全教程](https://blog.csdn.net/cjmqas/article/details/79282847)


<br>








## WSL

### 安装ubuntu20.04

安装到非系统盘目录，下载离线安装包，复制到想要安装的目录下，解压，以管理员身份运行ubuntu2004.exe

### 卸载wsl

```sh
wslconfig /l
# 从列表中选择要卸载的发行版（例如Ubuntu）并键入命令
wslconfig /u Ubuntu
```
参考链接：[WSL系列操作：安装，卸载](https://blog.csdn.net/zhangpeterx/article/details/97616268
)

### 设置wsl
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



## l

### rustdesk  
> 远程开源软件，跨平台          \
https://github.com/rustdesk/rustdesk

<br>

### ditto 粘贴板工具
https://ditto-cp.sourceforge.io/           \
https://github.com/sabrogden/Ditto

<br>

### bleachbit
https://github.com/bleachbit/bleachbit         \
https://www.bleachbit.org/

<br>

### qbittorrent
https://github.com/qbittorrent/qBittorrent

<br>


### imagine gui   
> 跨平台PNG和JPEG优化GUI工具          \
https://github.com/meowtec/Imagine

<br>

### creentogif  
>动图捕获软件 录制屏幕上的指定区域              \
https://www.screentogif.com/

<br>


### grammarly
https://www.grammarly.com/

<br>

### PowerToys
功能多样工具集
https://github.com/microsoft/PowerToys

<br>

### Wox
http://www.wox.one/
https://github.com/Wox-launcher/Wox
[WOX 软件高效使用](https://zhuanlan.zhihu.com/p/60477847)

<br>

### Zetero
https://www.zotero.org/
https://github.com/zotero/zotero
[Zotero 简明介绍](https://zhuanlan.zhihu.com/p/445621222)
[Zotero+TeraCloud同步应用](https://blog.csdn.net/qq_40301351/article/details/126968367)




<br>


### potplayer 
https://iptv-org.github.io/iptv/index.m3u

### maya  三维建模软件


### sscom

https://www.51xiazai.cn/soft/637125.htm



### IDA
7.6
http://www.ddooo.com/softdown/215615.htm
7.0
http://www.ddooo.com/softdown/183917.htm

https://www.wangan.com/p/7fy7f6eefd60ebc3

### OllyDbg
http://www.ollydbg.de/
https://gitee.com/geekneo/A64Dbg



<br>
<br>


## Online 


### 线上思维导图
https://gitmind.cn/app/template

<br>

### 在线文档转换
https://www.aconvert.com/cn/

<br>

### 开源软件下载网站
https://www.fosshub.com/#








、


剪切板win10自带的有很多剪切记录的快捷键Windows键➕V键




### chrome插件

油猴

## windows输入英文中间有间隙
进入了全角模式，选择半角即可

## React Router


http://react-guide.github.io/react-router-cn/index.html


## youtube 下载
https://www.ganbey.com/youtube-download-3774







