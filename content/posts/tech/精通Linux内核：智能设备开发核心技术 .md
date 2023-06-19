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


![20230615000241](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230615000241.png)

&ensp;中断模块不仅在设备驱动中频繁使用，内存管理和进程调度等也需要它的支持，内存管理需要缺页中断，进程调度则需要时钟中断和处理器间中断 \
&ensp;内核同步模块贯穿整个内核，如果没有同步机制，错综复杂的执行流访问临界区域就会失去保护，系统瞬间瘫痪 \
&ensp;内存管理、文件管理和进程管理 \
&ensp;&emsp;内存管理模块涉及内存寻址、映射、虚拟内存和物理内存空间的管理、缓存和异常 \
&ensp;&emsp;文件系统的重要性从“一切皆文件”，硬件的控制、数据的传递和存储，几乎都与文件有关 \
&ensp;&emsp;进程管理模块涉及进程的实现、创建、退出和进程通信等，进程本身是管理资源的载体，管理的资源包括内存、文件、I/O设备等 \
&ensp;&emsp;设备驱动模块,每一个设备驱动都是一个小型的系统，电源管理、内存申请、释放、控制、数据，复杂一些的还会涉及进程调度 \

## 1.4 实例分析

&ensp;由芯片开始，经过操作系统的传递，数据到达应用，然后计算并刷新屏幕


# 第 2 章 数据结构使用

## 2.1 关系型数据结构



&ensp;程序=数据结构+算法，数据结构指的是数据与数据之间的逻辑关系，算法指的是解决特定问题的步骤和方法 

### 2.1.1 一对一关系

&ensp;两个结构体之间的一对一关系有指针和内嵌（包含）两种表达方式
&ensp;内嵌，通过container_of宏（内核定义好的）可以由b计算出a的位置 \
```c
// 指针
struct entity_a {
    struct entity_b *b;
};
struct entity_b {
    (struct entity_a *;)
};
// 内嵌(包含)
struct entity_a {
    struct entity_b b;
}
```

### 2.1.2 一对多关系
&ensp;一对多关系在内核中一般由链表或树实现，链表实现有多种常用方式，包括list_head、hlist_head/hlist_node、rb_root/rb_node（红黑树）等数据结构  \

```c
// 单链表
struct branch {
    // others
    struct leaf *head;
};
struct leaf {
    // others
    struct leaf *next;
};

```


```c
// 双链表
struct branch {
    // others
    struct list_head head;
};
struct leaf {
    // others
    struct list_head node;
};
struct list_head {
    struct list_head *next, *prev;
}

```

![20230615002624](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230615002624.png)



&ensp;hlist_head表示链表头，hlist_node表示链表元素 
```c
struct hlist_head {
    struct hlist_node *first;
}；
struct hlist_node {
    struct hlist_node *next, **pprev;
}

```
![20230615003851](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230615003851.png)


### 2.1.3 多对多关系

&ensp;input子系统的三个关键结构体input_dev、input_handler、input_handle是多对多几个


## 2.2 位操作数据结构
&ensp;位图(bitmap)，以每一位(bit)来存放或表示某种状态，一个字节(byte)就可以表示8个元素的状态，节省内存 \
![20230615004359](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230615004359.png)

&ensp;find_first_zero_bit和find_first_bit的第二个参数size是以位(bit)为单位的，find_next_zero_bit和find_next_bit从第offset位(包含offset)开始查找为0和为1的位置，找不到则返回size

## 2.3 模块和内核参数传递


### 2.3.1 内嵌通用数据结构
&ensp;inode是一个典型的例子，内核使用inode对象
```c
struct my_inode {
    struct inode inode;
    // others
}

```

&ensp;传递参数给内核的时候，传递my_inode的inode的地址ptr；从内核获得的inode地址，通过container_of(ptr, my_inode, inode)宏就可以获得my_inode对象


### 2.3.2 通用结构的私有变量

&ensp;内核中很多数据结构都定义了类型为void*的私有数据字段，模块可以将它特有的数据赋值给该字段，通过引用该字段就可以获取它的数据。file结构体的private_data、device结构体的driver_data都是这种用法


## 2.4 实例分析

### 2.4.1 模块的封装

&ensp;以inode结构体为例，它主要适用VFS和具体文件系统的实现两种场景。其他模块，比如一个设备驱动一般是不会直接访问它的，而是访问file结构体

### 2.4.2 火眼金睛：看破数据结构

&ensp;首先要理清模块内的数据结构，数据结构是灵魂，函数是表现


# 第 3 章 时间的衡量和计算

&ensp;&emsp;内核时间以滴答(jiffy)来计算


## 3.1 数据结构

&ensp;gettimeofday系统调用获取当前时间，结果以timeval和timezone(时区)结构体形式返回 \
&ensp;内核先通过ktime_get_real_ts64获得timespec表示当前时间，然后转化为timeval形式，timespec64的tv_sec以秒为单位，tv_nsec以纳秒为单位

```c
void ktime_get_real_ts64(struct timespec64 *ts)
{
    struct timekeeper *tk = &tk_core.timekeeper;
    u64 nsecs;

    ts->tv_sec = tk->xtime_sec;
    nsecs = timekeeping_get_ns(&tk->mono);
    ts->tv_nesc = 0;
    timespce64 _add_ns(ts, nsecs);
}

u64 timekeeping_get_ns(const struct tk_read_base *tkr)
{
    struct clocksource *clock = READ_ONCE(tkr->clock);
    cycle_now = clock->read(clock);
    cycle_delta = (cycle_now - tkr->cycle_last) &tkr->mask;
    nsec = cycle_delta * tkr->mult + tkr->xtime_nsec;
    nsec >>= tkr->shift;
    return nsec + get_arch_timeoffset();
}

```

&ensp;第一个与时间相关的结构体为timekeeper，主要功能是保持或者记录时间，从timekeeping_get_ns函数可以看到，tk的tkr_mono->clock字段指向clocksource类型的对象，表示当前使用的时钟源  \
&ensp;时钟源以clocksource结构体(简称cs)表示

![20230616233307](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230616233307.png)

![20230616233327](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230616233327.png)

&ensp;rating字段代表cs的等级，内核只会选择一个时钟源作为watchdog(即看门狗)，也只会选择一个时钟源作为系统的时钟源(与全局变量tk_core.timekeeper对应)，同等条件下，等级更高的时钟源拥有更高的优先级 

&ensp;将保持时间的设备称为时钟源，将关注时间事件的设备称为时钟中断设备

![20230616233842](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230616233842.png)

&ensp;set_state_xxx是切换当前设备状态的回调函数，xxx可以有共有periodic、oneshot、oneshot_stopped和shutdown四种。其中，periodic表示周期性地触发时钟中断，oneshot表示单触发。所谓周期性是指触发一次中断之后自动进入下一次中断计时，单触发是指触发一次中断之后停止。rating字段表示设备的等级，等级越高优先级越高。最常用的设备特性（features字段）有PERIODIC、ONESHOT和C3STOP三种，其中C3STOP表示系统处于C3状态的时候设备停止  \
&ensp;时钟中断产生后，内核会调用event_handler字段的回调函数处理中断，该函数完成时钟中断相关的逻辑，还可以回调set_next_event设置下一次时钟中断 \
&ensp;内核使用了几个常见的变量和宏定义
- HZ：一秒内的滴答数
- jiffies：累计的滴答数
- tick_period：ktime_t类型的全局变量，周期性时钟中断的时间间隔
- tick_cpu_device：每cpu变量，类型为tick_device，简称td
- tick_cpu_sched：每cpu变量，类型为tick_sched，简称ts，它与系统调度和更新系统时间有关


## 3.2 时钟芯片

&ensp;x86架构上常见的设备  \
&ensp;&emsp;RTC（Real-timeClock）：实时时钟，兼具时钟源和时钟中断两种功能  \
&ensp;&emsp;PIT（Programmable interval timer）：可编程间隔计时器，时钟中断设备  \
&ensp;&emsp;TSC（Time Stamp Counter）：时间戳计数器，是一个64位的寄存器,TSC记录处理器的时钟周期数，程序可以通过RDTSC指令来读取它的值 \
&ensp;&emsp;HPET（High Precision Event Timer）：俗称高精度定时器，兼具时钟源和时钟中断两种功能  \
&ensp;&emsp;APIC（Advanced Programmable Interrupt Controller）：高级可编程中断控制器，用作时钟中断设备  \


## 3.3 从内核的角度看时间

&ensp;内核维护了多种时间，其中最常用REALTIME、MONOTONIC和BOOTTIME三种 \
&ensp;REALTIME时间：WALLTIME（墙上时间）系统时间  \
&ensp;MONOTONIC时间：表示系统启动到当前所经历的非休眠时间，不计算系统休眠的时间  \
&ensp;BOOTTIME时间：表示系统启动到现在的时间  \
![20230616234554](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230616234554.png)


## 3.4 周期性和单触发的时钟中断

&ensp;包含多种时钟中断设备，它们可以支持周期性和单触发的时钟中断，下文以PIT和APICTimer的组合  \
&ensp;APIC Timer进入工作（setup_APIC_timer）之后，由于它的rating比PIT高，td的evtdev字段被替换成APIC的evt，此时可以尝试切换至nohz模式 \
&ensp;nohz模式（也可称为tickless模式、oneshot模式、动态时钟模式）  \
&ensp;nohz模式又分为两种模式：高精度模式和低精度模式 \


## 3.5 时间相关的系统调用
### 3.5.1 获取时间

&ensp;gettimeofday和settimeofday系统调用外，内核可能还会实现time和stime系统调用，后面二者都是以秒为单位的，兼容POSIX标准的系统调用clock_gettime和clock_settime


### 3.5.2 给程序定个闹钟

&ensp;setitimer，alarm多数情况下会通过调用setitimer实现，后者是一个系统调用，通过它可以设置一个定时器。getitimer与之对应，用来获得定时器的当前时间。setitimer的精度为微秒

## 3.6 实例分析

### 3.6.1 实现智能手机的长按


&ensp;滑动和长按的区别在于手指移动的距离


### 3.6.2 系统的时间并不如你所




# 第 4 章 中断和中断处理

&ensp;广义的中断包括中断（interrupt）和异常（exception）两种类型。处理器在执行完一条指令之后，会检查当前的状态，如果发现有事件到来，在执行下一条语句之前，处理事件，然后返回继续执行下一条指令，这就是中断。中断是被动的，陷阱是处理器主动触发的
![20230620001402](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20230620001402.png)

## 4.1 处理器识别中断








