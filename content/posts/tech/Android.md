---
title: "Android"
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



官方文档
https://source.android.com/docs/core/architecture?hl=zh-cn

https://source.android.com/docs/setup/contribute/code-search?hl=zh-cn

aosp代码
https://cs.android.com/



[Android APP应用工程师转Android Framework系统工程师(仅此一篇够了)](https://blog.51cto.com/u_15455614/5997341)

[Android Tech And Perf](https://androidperformance.com/)
systrace,


# ptrace


[ptrace使用简介](https://www.jianshu.com/p/b1f9d6911c90)
[android的ptrace详细分析](https://blog.csdn.net/c_kongfei/article/details/113242082)
[【Android 逆向】ptrace 函数 ( C 标准库 ptrace 函数简介 | ptrace 函数真实作用 )](https://blog.csdn.net/shulianghan/article/details/121032501)




android PackageManager和PackageInstall
https://blog.csdn.net/u013673422/article/details/46655589

# Termux
Android手机命令行中断

https://termux.dev/en/
https://github.com/termux/termux-app


IDA

010 Editor


speedscope


# LineageOS

&ensp;第三方开源Android

https://6xyun.cn/article/169

[树梅派烧录Lineage OS](https://blog.csdn.net/xsh_fu/article/details/125862825)
[树莓派4 安装Android系统(lineage os) 体验](https://zhuanlan.zhihu.com/p/358637971)


[xda社区](https://forum.xda-developers.com/)

[小米手机刷 LineageOS 系统操作指南](https://miuiver.com/install-lineageos-on-xiaomi/)

[miui删除内置不卡米教程_LineageOS V17 安装刷入教程](https://blog.csdn.net/weixin_30965253/article/details/112205240)



[App逆向 | 安卓环境搭建-LineageOS刷机指南](https://zhuanlan.zhihu.com/p/147299441?utm_id=0)


lineageos20 树莓派4串口



[Raspberry Pi OS上如何使用串口](https://yangpaopao.space/2023/04/25/raspberrypi_os%E4%B8%8A%E5%A6%82%E4%BD%95%E4%BD%BF%E7%94%A8%E4%B8%B2%E5%8F%A3/)
[minicom的使用](http://www.pczh.cn/news/22131.html)
[Ubuntu串口驱动以及串口调试工具使用详解](https://blog.csdn.net/flowerspring/article/details/128957910)





```sh

adb connect 192.168.18.128
adb root
adb remount


```

# Android APK

https://apkcombo.com/zh/youtube/com.google.android.youtube/



https://www.gdaily.org/14895/youtube-vanced


https://www.gdaily.org/30590/youtube-revanced-apk


https://developer.android.com/ndk/guides/application_mk?hl=zh-cn




# lineageos 代码下载

需要访问google
```sh
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo 



sudo git config --global user.email "xxx@xxx.com"
sudo git config --global user.name "xxx"


sudo ~/bin/repo init -u https://github.com/LineageOS/android.git -b lineage-19.1

sudo ~/bin/repo sync -j12
```




[lineageOS编译aosp源码并刷入小米](https://zhuanlan.zhihu.com/p/570745179)

s



[LineageOS Download](https://download.lineageos.org/)
https://mirrors.tuna.tsinghua.edu.cn/help/git-repo/
https://mirrors.tuna.tsinghua.edu.cn/help/lineageOS/



# APP启动


```sh
# logcat 查看启动 Activity，微博为例
logcat | grep "com.sina.weibo"
# 启动
am start com.sina.weibo/.SplashActivity
# 带参数
am start -W  com.sina.weibo/.SplashActivity
# 停止
am force-stop com.sina.weibo
```



# Android查看进程、线程信息


```sh

top

ps -T -p 10791



```


[无需手机端安装应用，安卓投屏神器scrcpy使用教程](https://zhuanlan.zhihu.com/p/144566954?utm_id=0)

