---
title: "ARM64体系结构编程与实践"
date: 2022-07-12T00:21:58+08:00
lastmod: 2022-07-12T00:21:58+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- ARM
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



# 第1章 ARM64体系结构基础

- ARMv8体系结构处理器包含`31`个通用寄存器
- AArch64执行状态包含·`4`个异常等级，EL0~EL3，用户态、内核态、虚拟机、安全态
- PSTATE寄存器中NZCV标志：负零进溢
- PSTATE寄存器DAIF异常掩码标志位

## 1.1 ARM简介
&ensp;ARM体系结构是一种硬件规范，主要约定指令集、芯片内部体系结构  <br>
&ensp;ARMv8体系结构处理器IP Cortex-A53、Cortex-A55、Cortex-A72、Cortex-A77  <br>

## 1.2 ARMv8体系结构基础知识

### 1.2.1 ARMv8体系结构
&ensp;ARMv8是64位处理器指令集和体系结构  <br>
- 64位虚拟地址空间，32位仅支持4GB
- 31个64位宽通用寄存器
- 支持16KB和64Kb页面，降低TLB命中率
- 异常处理模型EL0~EL3
- 加载-获取指令(Load-Acquire Instruction)，存储-释放指令(Store-Release Instruction)

### 1.2.2 ARMv8处理器内核
- Cortex-A53
- Cortex-A57
- Cortex-A72


### 1.2.3 ARMv8体系结构基本概念

&ensp;ARMv8体系结构基本概念和定义  <br>
- 处理机PE(Processing Element):处理器处理事务过程抽象
- 执行状态(execution state):处理器运行时环境，包括寄存器位宽、支持指令集、异常模型、内存管理以及编程模型  <br>
> ARMv8两个执行状态
>> AArch64：64位执行状态
>>> 31个通用寄存器
>>> 64位程序计数(PC)指针寄存器、栈指针(Stack Pointer SP)寄存器及异常链接寄存器(Exception Link Register ELR)
>>> A64指令集
>>> ARMv8异常模型，4个异常等级，即EL0~EL3
>>> 64位内存模型
>>> 一组处理器状态(PSTATE)保存PE状态
>> AArch32: 32位执行状态

&ensp;AArch64状态，部分系统寄存器在不同异常等级提供不同变种寄存器
```c
<register_name>_ELx  // x: 0 1 2 3
```

### 1.2.4 A64指令集
&ensp;ARMv8体系结构64位指令集：处理64位宽寄存器和数据并使用64位指针访问内存

### 1.2.5 ARMv8处理器执行状态
&ensp;AArch64状态异常等级(exception level)确定处理器当前运行的特权级别
- EL0:用户特权
- EL1：系统特权，操作系统内核，系统使能虚拟化扩展，运行虚拟操作系统内核
- EL2：运行虚拟化扩展的虚拟监控程序(hypervisor)
- EL3：运行安全世界中安全监控器(secure monitor)

![20221204150429](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221204150429.png)


### 1.2.6 ARMv8数据宽度
- 字节(byte)：8位
- 半字(halfword)：16位
- 字(word)：32位
- 双字(doubleword)：64位
- 四字(quadword)：128位

## 1.3 ARMv8寄存器

### 1.3.1 通用寄存器

&ensp;AArch64执行状态支持31个64位通用寄存器，X0~X30寄存器，AArch32状态支持16个32位通用寄存器  <br>
&ensp;AArch64状态下，X表示64位通用寄存器，W表示低32位的数据

![20221204151151](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221204151151.png)

### 1.3.2 处理器状态

&ensp;AArch64体系结构使用PSTATE寄存器表示当前处理器状态


<table>
	<tr>
	    <th>分　　类</th>
	    <th>字　　段</th>
	    <th>描　　述</th>  
	    <th>描　　述</th>  
	</tr >
	<tr >
	    <td rowspan="4">条件标志位</td>
	    <td>N</td>
	    <td>负数标志位。
在结果是有符号的二进制补码的情况下，如果结果为负数，则N=1；如果结果为非负数，则N=0</td>
	</tr>
	<tr>
	    <td>Z</td>
	    <td>0标志位。如果结果为0，则Z=1；如果结果不为0，则Z=0</td>
	</tr>
    <tr>
	    <td>C</td>
	    <td>进位标志位。当发生无符号数溢出时，C=1。其他情况下，C=0</td>
	</tr>
    <tr>
	    <td>V</td>
	    <td>有符号数溢出标志位。<br>　对于加/减法指令，在操作数和结果是有符号的整数时，如果发生溢出，则V=1；如果未发生溢出，则V=0。<br>　对于其他指令，V通常不发生变化</td>
	</tr>
    <tr >
	    <td rowspan="3">执行状态控制</td>
	    <td>SS</td>
	    <td>软件单步。该位为1，说明在异常处理中使能了软件单步功能</td>
	</tr>
    <tr>
	    <td>IL</td>
	    <td>不合法的异常状态</td>
	</tr>
    <tr>
	    <td>nRW</td>
	    <td>当前执行状态 <br>　0：处于AArch64状态 <br>　1：处于AArch32状态</td>
	</tr>
    <tr >
	    <td rowspan="2">执行状态控制</td>
	    <td>EL</td>
	    <td>当前异常等级 <br> 　0：表示EL0<br> 　1：表示EL1<br> 　2：表示EL2<br> 　3：表示EL3</td>
	</tr>
    <tr>
	    <td>SP</td>
	    <td>选择SP寄存器。当运行在EL0时，处理器选择EL0的SP寄存器，即SP_EL0；当处理器运行在其他异常等级时，处理器可以选择使用SP_EL0或者对应的SP_ELn寄存器</td>
	</tr>
    <tr >
	    <td rowspan="4">异常掩码标志位</td>
	    <td>D</td>
	    <td>调试位。使能该位可以在异常处理过程中打开调试断点和软件单步等功能</td>
	</tr>
    <tr>
	    <td>A</td>
	    <td>用来屏蔽系统错误（SError）</td>
	</tr>
    <tr>
	    <td>I</td>
	    <td>用来屏蔽IRQ</td>
	</tr>
    <tr>
	    <td>F</td>
	    <td>用来屏蔽FIQ</td>
	</tr>
    <tr >
	    <td rowspan="2">访问权限</td>
	    <td>PAN</td>
	    <td>特权模式禁止访问（Privileged Access Never）位是ARMv8.1的扩展特性 <br> 　1：在EL1或者EL2访问属于EL0的虚拟地址时会触发一个访问权限错误 <br> 　0：不支持该功能，需要软件来模拟</td>
	</tr>
    <tr>
	    <td>UAO</td>
	    <td>用户访问覆盖标志位，是ARMv8.2的扩展特性 <br> 　1：当运行在EL1或者EL2时，没有特权的加载存储指令可以和有特权的加载存储指令一样访问内存，如LDTR指令<br>　0：不支持该功能</td>
	</tr>
</table>



### 1.3.3 特殊寄存器
&ensp;ARMv8体系结构除31个通用寄存器外，还提供多个特殊寄存器

![20221204153018](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221204153018.png)

#### 1.零寄存器
&ensp;ARMv8提供两个零寄存器(zero register)，寄存器内部全是0，WZR是32位零寄存器，XZR是64位零寄存器

#### 2.PC指针寄存器
&ensp;PC指针寄存器用来存储当前运行指令的`下一条指令地址`，控制程序中指令的运行顺序，不可直接访问  <br>

#### 3.SP寄存器

&ensp;ARMv8体系结构支持4个异常等级，每个异常等级有专门SP寄存器：SP_EL0、SP_EL1、SP_EL2、SP_EL3  <br>
&ensp;Linux内核使用SP_EL0存放进程中`task_struct`数据结构指针

#### 4.备份状态寄存器

&ensp;运行异常处理程序时，处理器备份程序会保存备份程序状态寄存器(Savaed Program Status Register SPSR)里。当异常发生时，处理器会把PSTATE寄存器的值暂时保存到SPSR里，当异常处理完成并返回时，再把SPSR值恢复到PSTATE寄存器，SPSR字段：

![20221204172503](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221204172503.png)



<table>
	<tr>
	    <th>字　　段</th>
	    <th>描　　述</th>
	</tr >
	<tr >
	    <td>N</td>
	    <td>负数标志位</td>
	</tr>
    <tr >
	    <td>Z</td>
	    <td>零标志位</td>
	</tr>
    <tr >
	    <td>C</td>
	    <td>进位标志位</td>
	</tr>
    <tr >
	    <td>V</td>
	    <td>有符号数溢出标志位</td>
	</tr>
    <tr >
	    <td>DIT</td>
	    <td>与数据无关的指令时序（Data Independent Timing），ARMv8.4的扩展特性</td>
	</tr>
    <tr >
	    <td>UAO</td>
	    <td>用户访问覆盖标志位，ARMv8.2的扩展特性</td>
	</tr>
     <tr >
	    <td>PAN</td>
	    <td>特权模式禁止访问位，ARMv8.1的扩展特性</td>
	</tr>
     <tr >
	    <td>SS</td>
	    <td>表示是否使能软件单步功能。若该位为1，说明在异常处理中使能了软件单步功能</td>
	</tr>
     <tr >
	    <td>IL</td>
	    <td>不合法的异常状态</td>
	</tr>
     <tr >
	    <td>D</td>
	    <td>调试位。使能该位可以在异常处理过程中打开调试断点和软件单步等功能</td>
	</tr>
     <tr >
	    <td>A</td>
	    <td>用来屏蔽系统错误</td>
	</tr>
     <tr >
	    <td>I</td>
	    <td>用来屏蔽IRQ</td>
	</tr>
     <tr >
	    <td>F</td>
	    <td>用来屏蔽FIQ</td>
	</tr>
     <tr >
	    <td>M[4]</td>
	    <td>用来表示异常处理过程中处于哪个执行状态，若为0，表示AArch64状态</td>
	</tr>
     <tr >
	    <td>M[3:0]</td>
	    <td>异常模式</td>
	</tr>
</table>


#### 5. ELR
&ensp;ELR存放异常返回地址

#### 6.CurrentEL寄存器
&ensp;该寄存器表示PSTATE寄存器中EL字段，保存异常等级，使用MRS指令读取当前异常等级

#### 7.DAIF寄存器
&ensp;该寄存器表示PSTATE寄存器中[D、A、I、F]字段

#### 8.SPSel寄存器
&ensp;寄存器表示PSTATE寄存器中SP字段，用于在SP_EL0和SP_ELn中选择SP寄存器

#### 9.PAN寄存器
&ensp;PAN寄存器表示PSTATE寄存器中PAN字段，通过MSR和MRS指令设置PAN寄存器<br>
&ensp;内核态访问用户态内存，主动调用内核接口，如copy_from_user()或copy_to_user()  <br>

&ensp;PAN寄存器值：0：表示内核态可访问用户态内存； 1：表示内核态访问用户态内存会触发访问权限异常


#### 10.UAO寄存器
&ensp;该寄存器表示PSTATE寄存器中UAO(User Access Override 用户访问覆盖)字段，MSR和MRS设置UAO寄存器，1表示EL1和EL2执行非特权指令效果和特权指令一样

#### 11.NZCV寄存器

&ensp;PSTATE寄存器中{N, Z, C, V}

### 1.3.4 系统寄存器

&ensp;ARMv8体系结构7类系统寄存器  <br>
- 通用系统控制寄存器
- 调试寄存器
- 性能监控寄存器
- 活动监控寄存器
- 统计扩展寄存器
- RAS寄存器
- 通用定时寄存器

&ensp;系统寄存器支持不同的异常等级访问，Reg_ELx  <br>
&ensp;MSR和MRS指令访问系统寄存器  <br>
```c
mrs x0, TTBR0_EL1   // 把TTBR0_EL1值复制到X0寄存器
msr TTBR0_El1, X0   // 把X0寄存器值复制到TTBR0_EL1
```

## 1.4 Cortex-A7处理器介绍

&ensp;树莓派4B开发板，内置了4个Cortex-A72处理器内核  <br>
&ensp;Cortex-A72处理器支持特性  <br>
- 采用ARMv8体系结构规范来设计，兼容ARMv8.0协议。
- 超标量处理器设计，支持乱序执行的流水线。
- 基于分支目标缓冲区（BTB）和全局历史缓冲区（GHB）的动态分支预测，返回栈缓冲器以及间接预测器。
- 支持48个表项的全相连指令TLB，可以支持4 KB、64 KB以及1 MB大小的页面。
- 支持32个表项的全相连数据TLB，可以支持4 KB、64 KB以及1 MB大小的页面。
- 每个处理器内核支持4路组相连的L2 TLB。
- 48 KB的L1指令高速缓存以及32 KB的L1数据高速缓存。
- 可配置大小的L2高速缓存，可以配置为512 KB、1 MB、2 MB以及4 MB大小。
- 基于AMBA4总线协议的ACE（AXI Coherency Extension）或者CHI（CoherentHubInterface）。
- 支持PMUv3体系结构的性能监视单元。
- 支持多处理器调试的CTI（Cross Trigger Interface）。
- 支持GIC（可选）。
- 支持多电源域（power domain）的电源管理。

![20221204175403](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221204175403.png)

#### 1.指令预取单元
&ensp;指令预取单元从L1指令高速缓存中获取指令，每个周期向译码单元最多发送3条指令。支持动态和静态分支预测，指令预取单元功能：
- L1指令高速缓存是一个48 KB大小、3路组相连的高速缓存，每个缓存行的大小为64字节。
- 支持48个表项的全相连指令TLB，可以支持4 KB、64 KB以及1 MB大小的页面。
- 带有分支目标缓冲器的2级动态预测器，用于快速生成目标。
- 支持静态分支预测。
- 支持间接预测。
- 返回栈缓冲器。

#### 2.指令译码单元
&ensp;指令译码单元对A32、T32、A64指令集进行译码   <br>
&ensp;指令译码单元执行寄存器重命名，消除写后写(WAW)和读后写(WAR)实现乱序执行   <br>

#### 3.指令分派单元

&ensp;指令分派单元控制译码后的指令何时被分派到执行管道及返回的结果何时终止，包括ARM核心通用寄存器、SIMD和浮点寄存器


#### 4.加载/存储单元

&ensp;加载/存储单元(LSU)执行加载和存储指令，包括L1数据存储系统


#### 5.L1内存子系统
&ensp;L1内存子系统包括指令内存系统和数据内存系统  <br>
&ensp;L1指令内存系统包括如下特性  <br>
- 具有48 KB的指令高速缓存，3路组相连映射。
- 缓存行的大小为64字节。
- 支持物理索引物理标记（PIPT）。
- 高速缓存行的替换算法为LRU（Least Recently Used）算法。
L
&ensp;L1数据内存系统包括如下特性  <br>
- 具有32 KB的数据高速缓存，两路组相连映射。
- 缓存行的大小为64字节。
- 支持物理索引物理标记。
- 对于普通内存，支持乱序发射、预测以及非阻塞的加载请求访问；对于设备内存，支持非预测以及非阻塞的加载请求访问。
- 高速缓存行的替换算法为LRU算法。
- 支持硬件预取。


#### 6.MMU
&ensp;MMU实现虚拟地址到物理地址转换，AArch64支持4KB、16KB、64KB页面  <br>
&ensp;MMMU包括：
- 48表项全相连的L1指令TLB
- 32表项全相连的L1数据TLB
- 4路组相连L2 TLB
  
&ensp;TLB支持8位或16位ASId，还支持VMID(虚拟化)


#### 7.L2内存子系统
&ensp;L2内存子系统不仅负责处理每个处理器内核的L1指令和数据高速缓存未命中的情况，还通过ACE或者CHI连接到内存系统。其特性  <br>
- 可配置L2高速缓存的大小，大小可以是512 KB、1 MB、2 MB、4 MB。
- 缓存行大小为64字节。
- 支持物理索引物理标记。
- 具有16路组相连高速缓存。
- 缓存一致性监听控制单元（Snoop Control Unit，SCU）。
- 具有可配置的128位宽的ACE或者CHI。
- 具有可选的128位宽的ACP接口。
- 支持硬件预取。


## 1.5 ARMv9体系结构

&ensp;ARMv9体系结构新加入的特性包括：  <br>
- 全新的可伸缩矢量扩展（Scalable Vector Extension version 2，SVE2）计算；
- 机密计算体系结构（Confidential Compute Architecture，CCA），基于硬件提供的安全环境来保护用户敏感数据；
- 分支记录缓冲区扩展（Branch Record Buffer Extension，BRBE），它以低成本的方式捕获控制路径历史的分支记录缓冲区；
- 内嵌跟踪扩展（Embedded Trace Extension，ETE）以及跟踪缓冲区扩展（Trace Buffer Extension，TRBE），用于增强对ARMv9处理器内核的调试和跟踪功能；
- 事务内存扩展（Transactional Memory Extension，TME）


# 第2章 搭建树莓派环境

## 2.1 树莓派
&ensp;树莓派4B 博通BCM2711芯片  <br>
- CPU内核：4核 A72 1.5GHz
- L1缓存： 32KB数据缓存，48KB指令缓存
- L2缓存： 1MB
- GPU： VideoCoreV1核心，500MHz
- 内存： LPDDR4 
  
&ensp;两种地址模式：
- 低地址模式
- 35位全地址模式


## 2.2 搭建树莓派环境

### 2.2.2 安装树莓派官方OS


&ensp;boot分区包括文件：
- bootcode.bin：引导程序
- start4.elf：树莓派4B的GPU固件
- start.elf： 树莓派3B的GPU固件
- config.txt：配置文件


### 2.2.4 使用GDB和QEMU虚拟机调试BenOS


## 2.3 BenOS代码


## 2.4 QEMU虚拟机与ARM64

&ensp;QEMU虚拟机与ARM64实验平台，书中Ubuntu20.04  <br>
&ensp;1)安装工具
```sh
sudo apt-get install qemu-system-arm libncurses5-dev gcc-aarch64-linux-gnu build-essential git bison flex libssl-dev

# 查看ARM gcc版本
aarch64-linux-gnu-gcc -v
```
&ensp;2)下载仓库
```sh
git clone git@github.com:figozhang/runninglinuxkernel_5.0.git
```
&ensp;3)编译内核及创建文件系统 <br>
&emsp;rootfs_arm64.tar.xz文件基于20.04系统的根文件系统创建
```sh
# 编译内核
cd runninglinuxkernel_5.0
./run_rlk_arm64.sh build_kernel

# 编译文件系统  生成rootfs_arm64.ext4根文件系统
cd runninglinuxkernel_5.0
sudo ./run_rlk_arm64.sh build_rootfs
```

&ensp;4)运行ARM64版本Linux系统
```sh
./run_rlk_arm64.sh run
# root   123
# 或
qemu-system-aarch64 -m 1024 -cpu max,sve=on,sev256=on -M virts
```

&ensp;5)在线安装软件包  <br>

```sh
# 查看网络配置
ifconfig 

```

&ensp;6)主机和QEMU虚拟机共享文件  <br>

```sh
cp test.c runninglinuxkernel_5.0/kmodules/

# qemu
cd /mnt
ls

```


# 第3章 A64指令集I ———— 加载与存储指令

&ensp;A64指令特点  <br>


## 3.1 A64指令集介绍

&ensp;ARMv8体系结构，A64指令集64位指令集，处理64位宽寄存器和数据，并使用64位指针访问内存，A64指令集指令宽度为32位  <br>
&ensp;A64指集分类：
- 内存加载和存在指令
- 多字节内存饺子和存储指令
- 算数和移位指令
- 移位操作指令
- 位操作指令
- 条件操作指令
- 跳转指令
- 独占内存访问
- 内存屏障指令
- 异常处理指令
- 系统寄存器访问指令

## 3.2 A64指令编码

























































































