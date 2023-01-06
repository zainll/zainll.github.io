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
 

![2023-01-06_21-47](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/2023-01-06_21-47.png)

&ensp;init 进程是系统所有进程的起点，init 程序首先是需要读取配置文件 /etc/inittab。    \
&ensp;许多程序需要开机启动。它们在Windows叫做"服务"（service），在Linux就叫做"守护进程"（daemon）  \
&ensp;init进程的一大任务，就是去运行这些开机启动的程序。  \
&ensp;不同的场合需要启动不同的程序，比如用作服务器时，需要启动Apache，  \
&ensp;Linux允许为不同的场合，分配不同的开机启动程序，这就叫做"运行级别"（runlevel）。也就是说，启动时根据"运行级别"，确定要运行哪些程序  \

![2023-01-06_21-51](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/2023-01-06_21-51.png)

&ensp;Linux系统有7个运行级别(runlevel)： \
&emsp;运行级别0：系统停机状态，系统默认运行级别不能设为0，否则不能正常启动  \
&emsp;运行级别1：单用户工作状态，root权限，用于系统维护，禁止远程登陆  \
&emsp;运行级别2：多用户状态(没有NFS)  \
&emsp;运行级别3：完全的多用户状态(有NFS)，登陆后进入控制台命令行模式
 \
&emsp;运行级别4：系统未使用，保留 \
&emsp;运行级别5：X11控制台，登陆后进入图形GUI模式  \
&emsp;运行级别6：系统正常关闭并重启，默认运行级别不能设为6，否则不能正常启动 \

# 2.系统初始化

&ensp;在init的配置文件中有这么一行：si::sysinit:/etc/rc.d/rc.sysinit　它调用执行了/etc/rc.d/rc.sysinit，而rc.sysinit是一个bash shell的脚本，它主要是完成一些系统初始化的工作，rc.sysinit是每一个运行级别都要首先运行的重要脚本  \
&ensp;它主要完成的工作有：激活交换分区，检查磁盘，加载硬件模块以及其它一些需要优先执行任务。  \
```sh
15:5wait:/etc/rc.d/rc 5
```
&ensp;这一行表示以5为参数运行/etc/rc.d/rc，/etc/rc.d/rc是一个Shell脚本，它接受5作为参数，去执行/etc/rc.d/rc5.d/目录下的所有的rc启动脚本，/etc/rc.d/rc5.d/目录中的这些启动脚本实际上都是一些连接文件，而不是真正的rc启动脚本，真正的rc启动脚本实际上都是放在/etc/rc.d/init.d/目录下  \
&ensp;而这些rc启动脚本有着类似的用法，它们一般能接受start、stop、restart、status等参数  \
&ensp;/etc/rc.d/rc5.d/中的rc启动脚本通常是K或S开头的连接文件，对于以 S 开头的启动脚本，将以start参数来运行  \
&ensp;而如果发现存在相应的脚本也存在K打头的连接，而且已经处于运行态了(以/var/lock/subsys/下的文件作为标志)，则将首先以stop为参数停止这些已经启动了的守护进程，然后再重新运行  \
&ensp;这样做是为了保证是当init改变运行级别时，所有相关的守护进程都将重启。 \
&ensp;至于在每个运行级中将运行哪些守护进程，用户可以通过chkconfig或setup中的"System Services"来自行设定  \

![2023-01-06_21-56](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/2023-01-06_21-56.png)

&ensp;rc执行完毕后，返回init。这时基本系统环境已经设置好了，各种守护进程也已经启动了。 \
&ensp;init接下来会打开6个终端，以便用户登录系统。在inittab中的以下6行就是定义了6个终端： \


![2023-01-06_21-57](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/2023-01-06_21-57.png)


&ensp;从上面可以看出在2、3、4、5的运行级别中都将以respawn方式运行mingetty程序，mingetty程序能打开终端、设置模式。  \
&ensp;同时它会显示一个文本登录界面，这个界面就是我们经常看到的登录界面，在这个登录界面中会提示用户输入用户名，而用户输入的用户将作为参数传给login程序来验证用户的身份  \

# 3.用户登录系统

&ensp;一般来说，用户的登录方式有三种： \
&emsp;（1）命令行登录  \
&emsp;（2）ssh登录  \
&emsp;（3）图形界面登录  \

![2023-01-06_22-00](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/2023-01-06_22-00.png)

&ensp;对于运行级别为5的图形方式用户来说，他们的登录是通过一个图形化的登录界面。登录成功后可以直接进入 KDE、Gnome 等窗口管理器。  \
&ensp;而本文主要讲的还是文本方式登录的情况：当我们看到mingetty的登录界面时，我们就可以输入用户名和密码来登录系统了。  \
&ensp;Linux 的账号验证程序是 login，login 会接收 mingetty 传来的用户名作为用户名参数。  \
&ensp;然后 login 会对用户名进行分析：如果用户名不是 root，且存在 /etc/nologin 文件，login 将输出 nologin 文件的内容，然后退出。  \
&ensp;这通常用来系统维护时防止非root用户登录。只有/etc/securetty中登记了的终端才允许 root 用户登录，如果不存在这个文件，则 root 用户可以在任何终端上登录。  \
&ensp;/etc/usertty文件用于对用户作出附加访问限制，如果不存在这个文件，则没有其他限制  \



- 参考链接
https://mp.weixin.qq.com/s?__biz=Mzg4OTgyNzQwMQ==&mid=2247484052&idx=1&sn=4b74f1134fcd2e9341173653d271bbd6&chksm=cfe4bbb2f89332a491e774cbcce98f8b7e9075d837bfa58dd0a9d5b151f72647dac8f0cae5e0&mpshare=1&scene=1&srcid=1231tifch9Iyv8wFwiPLT39I&sharer_sharetime=1672481021630&sharer_shareid=813a8c319563d8c50feefd77b191f183#rd









