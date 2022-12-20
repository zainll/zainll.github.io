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
- 支持16KB和64Kb页面，降低TLB未命中率
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
>> AArch64：64位执行状态   <br>
>>> 31个通用寄存器   <br>
>>> 64位程序计数(PC)指针寄存器、栈指针(Stack Pointer SP)寄存器及异常链接寄存器(Exception Link Register ELR)  <br>
>>> A64指令集   <br>
>>> ARMv8异常模型，4个异常等级，即EL0~EL3   <br>
>>> 64位内存模型   <br>
>>> 一组处理器状态(PSTATE)保存PE状态  <br>
>> AArch32: 32位执行状态   <br>

&ensp;AArch64状态，部分系统寄存器在不同异常等级提供不同变种寄存器
```c
<register_name>_ELx  // x: 0 1 2 3
```

### 1.2.4 A64指令集
&ensp;ARMv8体系结构64位指令集：处理64位宽寄存器和数据并使用64位指针访问内存

### 1.2.5 ARMv8处理器执行状态
&ensp;AArch64状态异常等级(exception level)确定处理器当前运行的特权级别
- EL0：用户特权
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
	</tr>
	<tr>
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

&ensp;PAN寄存器值： <br>
&emsp;0：表示内核态可访问用户态内存 <br>
&emsp;1：表示内核态访问用户态内存会触发访问权限异常 <br>


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


## 1.4 Cortex-A72处理器介绍

&ensp;树莓派4B开发板，内置了4个Cortex-A72处理器内核  <br>
&ensp;Cortex-A72处理器支持特性  <br>
- 采用ARMv8体系结构规范来设计，兼容ARMv8.0协议。
- 超标量处理器设计，支持乱序执行的流水线。


- 基于分支目标缓冲区(BTB)和全局..缓冲区(GHB)

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
  
&ensp;TLB支持8位或16位ASID，还支持VMID(虚拟化)


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




<br>

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


<br>



# 第3章 A64指令集I —— 加载与存储指令

&ensp;A64指令特点  <br>


## 3.1 A64指令集介绍

&ensp;ARMv8体系结构，A64指令集64位指令集，处理64位宽寄存器和数据，并使用64位指针访问内存，A64指令集指令宽度为32位  <br>
&ensp;A64指集分类：
- 内存加载和存储指令
- 多字节内存加载和存储指令
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

&ensp;A64指令集指令宽度为32位，第24~28位识别指令分类


&ensp;op0字段值

<table>
	<tr>
	    <th>op0 字段值</th>
	    <th>说    明</th>
	</tr>
	<tr>
	    <td>0000x</td>
	    <td>保留</td>
    </tr>
    <tr>
	    <td>0010x</td>
	    <td>可伸缩矢量扩展(SVE)指令</td>
    </tr>
    <tr>
	    <td>100xx</td>
	    <td>数据处理指令(立即数)</td>
    </tr>
    <tr>
	    <td>101xx</td>
	    <td>分支处理指令、异常处理指令及系统寄存器访问指令</td>
    </tr>
    <tr>
	    <td>x1x0x</td>
	    <td>加载与存储指令</td>
    </tr>
    <tr>
	    <td>x101x</td>
	    <td>数据处理指令(基于寄存器)</td>
    </tr>
    <tr>
	    <td>x111x</td>
	    <td>数据处理指令(浮点数与SIMD)</td>
    </tr>
</table>


&ensp;加载与存储指令分类  <br>

&ensp;为什么指令编码宽度是32位？  <br>
&ensp;A64指令集基于寄存器加载和存储体系结构设计，数据加载、存储及处理在通用寄存器中。ARM64一共31个通用寄存器X0~X30，因此在指令编码中使用5位宽，可索引32个通用寄存器  <br>
- 使用寄存器作为基地址，把SP(栈指针)寄存器当做第31个通用寄存器
- 用作源寄存器操作数时，把XZR当作第31个通用寄存器



## 3.3 加载与存储指令

&ensp;ARMv8体系结构基于指令加载和存储体系结构，所有数据处理都通过通用寄存器完成，不能直接在内存中完成  <br>

&ensp;常见内存加载指令是LDR指令，存储指令STR指令
```c
LDR 目标寄存器,  <存储器地址>  // 把存储地址中的数据加载到目标寄存器中
STR 源寄存器,  <存储器地址>    // 把源寄存器数据存储到存储器中 
```

<table>
	<tr>
	    <th>寻 址 模 式</th>
	    <th>说   明</th>
	</tr>
	<tr>
	    <td>基地址模式</td>
	    <td>[Xn]</td>
    </tr>
    <tr>
	    <td>基地址加偏移量模式</td>
	    <td>[Xn, #offset]</td>
    </tr>
    <tr>
	    <td>前变基模式</td>
	    <td>[Xn, #offset]!</td>
    </tr>
    <tr>
	    <td>后变基模式</td>
	    <td>[Xn] #offset</td>
    </tr>
    <tr>
	    <td>PC相对地址模式</td>
	    <td> < lable></td>
    </tr>
</table>


### 3.3.1 基于基地址寻址模式

&ensp;基地址模式寄存器值表示地址，基地址加偏移量模式基地址加上可正可负偏移  <br>

#### 1.基地模式
&ensp;指令以Xn寄存器值为内存地址，加载此内存地址内容到Xt寄存器
```c
LDR Xt, [Xn] 
```
&ensp;指令把Xt寄存器中内容存储到Xn寄存器的内存地址中
```c
STR Xt, [Xn]  ?
```

#### 2.基地址加偏移量模式
&ensp;指令把Xn寄存器值加偏移量(offset是8的倍数)，以相加的结果作为内存地址，加载此地址内容到Xt寄存器
```c
// 偏移量从指令编码imm12字段获取 0~32760B
LDR Xt, [Xn, $offset]
// 基地址加偏移量存储指令
STR Xt, [Xn, $offset]
```

#### 3.基地址扩展模式

```c
LDR <Xt>, {<Xn>, (<Xn>){, <extend> {<amount>}}}
STR <Xt>, {<Xn>, (<Xn>){, <extend> {<amount>}}}
```

```c


```

### 3.3.2 变基模式

&ensp;两种变基模式
- 前变基：先更新偏移量地址，后访问内存
- 后变基：先访问内存地址，后更新偏移量地址

```c
// 前变基模式
LDR <Xt>, [<Xn|SP>, #<simm>]!
STR <Xt>, [<Xn|SP>, #<simm>]!

// 后变基模式
LDR <Xt>, [<Xn|SP>], #<simm>
STR <Xt>, [<Xn|SP>], #<simm>
```


### 3.3.3 PC相对寻址模式
```c
// LDR指令访问标签的地址
LDR <Xt>, <label>

```

### 3.3.4 LDR伪指令
```c
// LDR伪指令
LDR Xt, =<label>  // 把label标记的地址加载到Xt寄存器
```
&ensp;Linux内核实现重定位伪代码
```c
// arch/arm64/kernel/head.S
__primary_switch:
	adrp  x1, init_pg_dir
	b1  __enable_mmu  // 打开MMU

	ldr  x8, =__primary_switched  // 跳转 到链接地址，即内核空间虚拟地址
	adrp  x0, __PHYS_OFFSET  // 
	br  x8
ENDPROC(__primary_switch)
```


## 3.4 加载与存储指令变种
### 3.4.1 不同位宽加载与存储指令
&ensp;LDR、LDRSW、LDRB、LDRSB、LDRH、LDRSH、STRB、STRH

### 3.4.2 不可扩展加载与存储指令
```c
LDUR <Xt>, [<Xn|SP>{, #<simm>}]
STUR <Xt>, [<Xn|SP>{, #<simm>}]
```
&ensp;不可扩展LDUR和STUR数据位宽变种

### 3.4.3 多字节内存加载与存储指令

&ensp;A64提供LDP和STP指令

#### 1.基地址偏移量模式
```c
LDP <Xt1>, <Xt2>, [<Xn|SP>{, #<imm>}]

STP <Xt1>, <Xt2>, [<Xn|SP>{, #<imm>}]

```

#### 2.前变基模式
```c
LDP <Xt1>, <Xt2>, [<Xn|SP>, #<imm>]!

STP <Xt1>, <Xt2>, [<Xn|SP>, #<imm>]!

```

#### 3.后变基模式
```c
LDP <Xt1>, <Xt2>, [<Xn|SP>], #<imm>

STP <Xt1>, <Xt2>, [<Xn|SP>], #<imm>

```


### 3.4.4 独占内存访问指令

&ensp;ARMv8体系结构独占内存访问(exclusive memory access)指令，A64指令集LDXR指令尝试在内存总线中申请一个独占访问锁，然后访问一个内存地址。STXR会往LDXR指令申请独占访问内存地址中写入新内容。LDXR和STXR组合实现同步操作，如Linux内核自旋锁  <br>
&ensp;ARMv8多字节多占内存访问指令，LDXP和STXP

### 3.4.5 隐含加-获取/存储-释放内存屏障原语

&ensp;内存屏障原语LDAR和STAR

### 3.4.6 非特权访问级别加载和存储指令


## 3.5 入栈和出栈
&ensp;栈(stack)后进先出数据结构，保存：
- 临时存储数据，如局部变量
- 参数：参数小于等于8个，用X0~X7通用寄存器传递，超过8个使用栈

&ensp;栈从高地址向低地址扩展，栈指针(Stack Pointer SP)指向栈顶  <br>
```c
// 栈向下扩展16字节
stp x29, x30, [sp, #-16]

add sp, sp, #-8
// 释放8字节
add sp, sp, #8

ldp x29, x30, [sp], #16

```


## 3.6 MOV指令

&ensp;MOV指令寄存器直接搬移和立即数搬移
```c
// 寄存器搬移
MOV <Xd|SP>, <Xn|SP>
// 立即数搬移
MOV <Xd>, #<imm>


MOVZ <Xd>, #<imm16>, LSL #<shift>

ORR <Xd|SP>, XZR, #<imm>

```
&ensp;objdump指令查看MOV指令
```c
aarch64-linux-gnu-objdump -s -d  -M no-aliases test.o
```



<br>


# 第4章 A64指令集2 —— 算术与移位指令

- N、Z、C、V 4个条件标志位作用


## 4.1 条件操作码
&ensp;A64指令集在PSTATE寄存器中有4个条件标志位，N 负数、 Z 零、 C 进位、 V 溢出  <br>

## 4.2 加法和减肥指令

### 4.2.1 加法

&ensp;add、adds、adc

### 4.2.2 减法

&ensp;SUB、SUBS


## 4.3 CMP指令

&ensp;A64指令集中 CMP指令内部调用SUBS指令

```c
// 立即数的CMP指令
CMP <Xn|SP>, #<imm>{, <shift>}
// 上述等同于
SUBS XZR, <Xn|SP>, #<imm> {, <shift>}

// 寄存器的CMP指令
CMP <Xn|SP>, <R><m>{, <extend> {#<amount>}}

// 移位操作的CMP指令


// CMP指令于添加操作后缀

```

## 4.4 条件表示位


## 4.5 移位指令
&ensp;常见移位指令：
- LSL：逻辑左移，最高位丢弃，最低位补0
- LSR：逻辑右移，最高位补0，最低位丢弃
- ASR：算术右移，最低位丢弃，最高位按符号位扩展
- ROR：循环右移，最低位移到最高位


## 4.6 位操作指令
&ensp;两种与操作指令
- AND：按位与操作
- ANDS：带条件标志位与操作，影响Z标志位
  
&ensp;或操作指令
- ORR
- EOR 异或

&ensp;位清除操作
- BIC

&ensp;CLZ指令 计算为1的最高位前面有几个零

## 4.7 位段操作指令

&ensp;1.位段插入操作指令 BFI  
```c

```

&ensp;2.位段提取操作指令 UBFX
```c

```



<br>


# 第5章 A64指令集3 —— 比较指令与跳转指令

- RET与ERET

## 5.1 比较指令

&ensp;比较指令
- CMP  CMN
- CSEL：条件选择指令
- CSET：条件置位指令
- CSINC：条件选择并增加指令

### 5.1.1 CMN指令
&ensp;CMN指令将一个数与另一个数相反数进行比较
```c
CMN <Xn|SP>, #<imm>{, <shift>}
CMN <XN|SP>, <R><m>{, <extend> {#<amount>}}

```

### 5.1.2 CSEL指令
```c
// cond为真，返回Xn，为假，返回Xm
CSEL <Xd>, <Xn>, <Xm>, <cond>
```

### 5.1.3 CSET指令
```c
// cond为真，Xd寄存器为1，否则为0
CSET <Xd>, <cond>
```

### 5.1.4 CSINC指令
```c
// cond为真，返回Xn寄存器值，否则返回Xm寄存器值
CSINC <Xd>, <Xn>, <Xm>, <cond>
```

## 5.2 跳转与返回指令

### 5.2.1 跳转指令

<table>
	<tr>
	    <th>指   令</th>
	    <th>描　 述</th>
	</tr>
	<tr>
	    <td>B</td>
	    <td>跳转指令<br> B Lable</td>
	</tr>
	<tr>
	    <td>B.cond</td>
	    <td>有条件跳转指令<br> B.cond Lable</td>
	</tr>
	<tr>
	    <td>BL</td>
	    <td>带返回值跳转指令<br> BL Lable</td>
	</tr>
	<tr>
	    <td>BR</td>
	    <td>跳转到寄存器指定地址<br> BR Xn</td>
	</tr>
	<tr>
	    <td>BLR</td>
	    <td>跳转到寄存器指定地址<br> BLR Xn</td>
	</tr>
</table>


### 5.2.2 返回指令
&ensp;A64两条返回指令： <br>
- RET：用于子函数返回，返回地址保存在LR
- ERET：从当前的异常模式返回，把SPSR内容恢复到PSTATE寄存器中，从ELR中获取跳转地址并返回到该地址，ERET可实现处理器模式切换，如EL1到EL0
  
### 5.2.3 比较跳转指令

<table>
	<tr>
	    <th>指   令</th>
	    <th>描　 述</th>
	</tr>
	<tr>
	    <td>CBZ</td>
	    <td>比较并跳转指令<br> CBZ Xt, Lable</td>
	</tr>
	<tr>
	    <td>CBNZ</td>
	    <td>比较并跳转指令<br> CBNZ Xt, Lable</td>
	</tr>
	<tr>
	    <td>TBZ</td>
	    <td>测试位并跳转指令<br> TBZ R< t>, #imm, lable</td>
	</tr>
	<tr>
	    <td>TBNZ</td>
	    <td>测试并跳转指令<br> TBNZ R< t>， #imm, lable</td>
	</tr>
</table>


<br>


# 第6章 A64指令集 —— 其他重要指令

- ADR/ADRP与伪指令LDR
- ADRP指令获取的是与 4KB 对齐的地址
  
## 6.1 PC相对地址加载指令

&ensp;A64指令集PC相对地址加载指令——ADR和ADRP指令
```c
// ADR 加载当前PC值+-1MB范围内label地址到Xd寄存器
ADR <Xd>, <label>

// ADRP 加载当前PC值一段范围内的label地址到Xd寄存器，与label地址按4Kb对齐
// 即偏移量位 -4Gb~4GB
ADRP <Xd>, <label>
```

## 6.2 LDR与ADRP指令区别
&ensp;树莓派上电复位后，固件(BOOTROM)把很想加载到`0x80000`地址处  <br>
&ensp;LDR伪指令加载的是绝对地址，即程序编译是的链接地址。ADR/ADRP指令加载的是当前PC的相对地址(PC relative-address)，即当前PC值加上label的偏移量，理解位当前运行是label的物理地址  <br>

## 6.3 独占内存访问指令
&ensp;ARMv8体系结构，A64指令集，LDXR指令尝试在内存总线中申请一个独占访问的锁，然后访问一个内存地址。STXR指令会往LDXR指令已经申请的独占访问内存地址宏写入新内容。  <br>


## 6.4 异常处理指令

<table>
	<tr>
	    <th>指   令</th>
	    <th>描　 述</th>
	</tr>
	<tr>
	    <td>SVC</td>
	    <td>系统调用指令<br> SVC #imm</td>
	</tr>
	<tr>
	    <td>HVC</td>
	    <td>虚拟化系统调用指令<br> HVC #imm</td>
	</tr>
	<tr>
	    <td>SMC</td>
	    <td>安全监控系统调用指令<br> SMC #imm</td>
	</tr>
</table>


## 6.5 系统寄存器访问指令
&ensp;ARMv8体系结构MRS和MSR指令直接访问寄存器  <br>

<table>
	<tr>
	    <th>指   令</th>
	    <th>描　 述</th>
	</tr>
	<tr>
	    <td>MRS</td>
	    <td>读取系统寄存器的值到通用寄存器</td>
	</tr>
	<tr>
	    <td>MSR</td>
	    <td>更新系统寄存器的值</td>
	</tr>
</table>

&ensp;ARMv8体系结构7类系统寄存器  <br>
- 通用系统控制寄存器(System Control Register SCTLR)
- 调试寄存器
- 性能监控寄存器
- 活动监控寄存器
- 统计扩展寄存器
- RAS寄存器
- 通用定时寄存器


<table>
	<tr>
	    <th>特殊系统寄存器</th>
	    <th>描　 述</th>
	</tr>
	<tr>
	    <td>CurrentEL</td>
	    <td>获取当前系统的异常等级</td>
	</tr>
	<tr>
	    <td>DAIF</td>
	    <td>获取和设置PSTATE寄存器中的DAIF掩码</td>
	</tr>
	<tr>
	    <td>NZCV</td>
	    <td>获取和设置PSTATE寄存器中的条件掩码</td>
	</tr>
	<tr>
	    <td>PAN</td>
	    <td>获取和设置PSTATE寄存器中的PAN掩码</td>
	</tr>
	<tr>
	    <td>SPSel</td>
	    <td>获取和设置当前寄存器的SP寄存器</td>
	</tr>
	<tr>
	    <td>UAO</td>
	    <td>获取和设置PSTATE寄存器中的UAO掩码</td>
	</tr>
</table>


## 6.6 内存屏障指令
&ensp;ARMv8体系结构是弱一致性内存模型，内存访问次序可能和程序预取顺序不一样

<table>
	<tr>
	    <th>指   令</th>
	    <th>描　 述</th>
	</tr>
	<tr>
	    <td>DMB</td>
	    <td>数据存储屏障，确保在执行新的存储访问前所有存储器访问都已完成</td>
	</tr>
	<tr>
	    <td>DSB</td>
	    <td>数据同步屏障，确保在下一个指令执行前所有存储器访问都已完成</td>
	</tr>
<tr>
	    <td>ISB</td>
	    <td>指令同步屏障，清空流水线，确保在执行新的指令前，之前所有指令都已完成</td>
	</tr>

</table>




&ensp;新的加载和存储指令

<table>
	<tr>
	    <th>指   令</th>
	    <th>描　 述</th>
	</tr>
	<tr>
	    <td>LDAR</td>
	    <td>加载-获取(laod-acquire)指令 <br> LDAR指令后面的读写内存指令必须在LDAR指令之前执行</td>
	</tr>
	<tr>
	    <td>STLR</td>
	    <td>存储-释放(store-release)指令 <br> 所有的加载和存储指令必须在STLR指令之前完成</td>
	</tr>
</table>



<br>


# 第7章 A64指令集的陷阱

## 7.1 加载宏标签
&ensp;ARMv8体系结构，在没有使能MMU情况下，访问内存地址变成访问设备类型的内存(device memory)。内存类型分为普通类型内存和设备类型内存  <br>
&ensp;对设备类型内服访问发起不对齐访问，会触发对齐异常 <br>
&ensp;系统MMU使能后，访问内存变成了访问普通类型内存，对普通类型内存发起一个不对齐访问，分为两种情况
- 当SCTLR_ELx寄存器的A字段为1时，触发一个对齐异常
- 当SCTLR_ELx寄存器的A字段为0时，系统自动完成不对齐访问

## 7.2 加载字符串


## 7.3 读写寄存器导致树莓派死机

## 7.4 LDXR指令导致水平4B死机


## 7.5 在汇编中实现串口输出功能


## 7.6 纷享Linux5.0的启动汇编代码

&ensp;Linux内核入口函数`stext`，在`arch/arm64/kernel/haed.S`汇编文件中实现。系统上电复位后，启动引导程序(bootloader)或BIOS初始化，最终跳转到Linux内核入口函数`stext`汇编函数，启动引导程序必要初始化，如内存设备初始化、磁盘设备初始化以及将内核镜像加载到运行地址，然后跳转到Linux内核入口。  <br>
&ensp;内核汇编入口到C语言入口`start_kernel()`函数之间的汇编代码


<br>


# 第8章 GNU汇编器

- 汇编器
- 符号
- 伪指令
- kernel_ventry宏

&ensp;汇编代码同汇编器生成目标代码，然后由连接器链接成可执行二进制程序  <br>
&ensp;ARM64汇编器：1）ARM公司汇编器，2）GNU项目AS汇编器  <br>
&ensp;aarch64-linux-gnu，级汇编后文件Wieaarch64体系结构   <br>


## 8.1 编译流程与ELF文件

&ensp;GCC编译流程：   <br>
&emsp;1）预处理(pre-process)，GCC预处理器(cpp)，生成 *.i 文件  <br>
&emsp;2）编译(compile)，C语言编译器(ccl)，对预处理文件进行词法、语法分析及语义分析    <br>
&emsp;3）汇编(assemble)，汇编器(as)把汇编代码翻译成机器语言，并生成可重定位目标文件     <br>
&emsp;4）链接(link)，连接器(ld)把所有生成可重定位目标文件以及用到的库文件综合成可执行二进制文件   <br>
```sh
gcc -E text.c -o text.i

gcc -S text.i -o text.s

as test.s -o test.o

ld -o test test.o -lc
```

&ensp;ELF格式，待补充链接  <br>

```sh
ld --version

```
&ensp;链接器在链接过程中对所有输入可重定位目标文件的符号表进行符号解析和重定位，每个符号在输出文件的相应段中得到一个确定的地址，最终生成一个符号表(symbol table)  <br>


## 8.2 汇编程序


```sh
# -o 输出二进制  -Map 输出符号表  -lc 链接libc库
ld test.o -o test -Map test.map -lc
# 获取程序符号表 -s 显示符号表内容
readelf -s test 
```


## 8.3 汇编语法

&ensp;汇编代码注释 单行 `#` 或 `//` ，多行 `/* */`  <br>
&ensp;符号可表示地址、变量或函数   <br>
&ensp;全局符号：使用global声明   <br>
&ensp;本地符号：在本地汇编代码中引用   <br>
&ensp;本地标签：供汇编器和程序员临时使用   <br>

## 8.4 常用伪指令

&ensp;伪指令仅在汇编器编译期间起作用   <br>

&ensp; .align 对齐伪指令   <br>

&ensp;数据定义伪指令   <br>

&ensp;函数相关伪指令    <br>

&ensp;段相关伪指令  <br>

&ensp; .section 伪指令 <br>


&ensp;宏相关伪指令  <br>



## 8.5 AArch64依赖特性

&ensp;AArch64特有命令行选项  <br>



<br>



# 第9章 链接器与链接脚本

- 链接器LD
- 链接脚本
- 加载地址、虚拟地址和链接地址
- 位置无关代码
- 重定位、Uboot重定位、打开MMU后重定位


## 9.1 链接器

&ensp;链接器把目标文件(包括标准库函数目标文件)的代码段、数据段及符号表等内容按照某种格式(ELF)组合成一个可执行二进制文件  <br>
&ensp;链接器使用链接脚本(Linker Script LS)语言，链接脚本把二进制文件.o，综合成可执行二进制文件 <br>
```sh
ld -o mytest test1.o test2.o -lc
```

&ensp;ld命令选项  <br>

## 9.3 链接脚本

&ensp;链接器使用`-T`参数指定链接脚本，不指定使用内置链接脚本  <br>

### 9.2.1 链接程序

&ensp;可执行程序由代码段、数据段、未初始化数据段。  <br>
&ensp;Linux内置链接脚本是vmlinux.lds.S文件  <br>

```sh
SECTIONS
{
	. = 0X10000;
	.text : { *{.text} }
	. = 0x8000000;
	.data : { *{.data} }
	.bss : { *{.bss} }
}
```

### 9.2.2 设置入口点

```sh

ENTRY(symbol)
```


### 9.2.3 

&ensp;输出段和输入段包括段的名字、大小、可加载属性及可分配属性。可加载属性用于在运行是加载这些段内容到内存中，可分配属性用于在内存中预留一个区域，并不会加载这个区域内容  <br>
&ensp;链接脚本关于段地址：加载地址和虚拟地址，加载地址是加载时段所在的地址，运行地址是虚拟地址是运行是所在的地址。通常两个地址相同的，不同情况是代码段被加载到ROM中，在程序启动是被复制到RAM中，即 ROM地址是加载地址，RAM地址是虚拟地址 <br>



### 9.2.7 常用内建函数

&ensp;链接脚本语言包含内建函数  <br>

#### 1.ABSOLUTE(exp)


#### 2.ADDR(section)


#### 3.ALIGN(align) 



#### 4.SIZEOF(section)


## 9.3 重定位

&ensp;**加载地址**：存储代码的物理地址，GNU链接脚本里为LMA  <br>
&ensp;**运行地址**：程序运行时地址，GNU链接脚本里为VMA   <br>
&ensp;**链接地址**：在编译、链接时指定的地址，使用`aarch64-linux-gnu-objdump`工具进行反汇编时查看的就是链接地址  <br>

### 9.3.1 BenOS重定位


### 9.3.2 UBoot和Linux内核重定位



```c
// linux5.0/arch/arm64/kernel/head.S
	__primary_switch;
	adrp	x1, init_pg_dir
	bl		__enable_mmu

	ldr 	x8, =__primary_switched
	adrp	x0, __PHY_OFFSET
	br		x8
```




<br>


# 第10章 GCC内嵌汇编代码


- 内嵌汇编代码关键字asm、volatile、inline及goto
- 内嵌汇编代码输出部分 = 和 + 
- 内嵌汇编代码输出部分和输入部分的参数
- 内嵌汇编代码 # 和 ## 
  
## 10.1 内嵌汇编代码基本用法

&ensp;内嵌汇编代码两种形式：  <br>
&emsp;基础内嵌汇编代码，不带参数   <br>
&emsp;扩展内嵌汇编代码，可带输入/输出参数  <br>

### 10.1.1 基础内嵌汇编代码
```c
asm { "汇编指令" }
```

### 10.1.2 扩展内嵌汇编代码

```c
asm 修饰词(
		指令部分
		: 输出部分
		: 输入部分
		: 损坏部分)

```

&ensp;常用修饰符: <br>
&emsp;volatile：关闭GCC优化  <br>
&emsp;inline：内联，GCC把汇编代码编译为尽可能短的代码  <br>
&emsp;goto：跳转到C语言标签   <br>




### 10.1.3 内嵌汇编代码的修饰符和约束符



### 10.1.4 使用汇编符号名



### 10.1.5 内嵌汇编函数与宏结合



### 10.1.6 使用goto修饰符




<br>

# 第11章 异常处理

- ARM64处理器，异常类型
- ARM64处理器异常等级
- 同步异常和异步异常
- ARM64处理器异常发生后CPU处理
- LR和ELR返回地址

## 11.1 异常处理基本概念

&ensp;ARMv8体系结构中，异常和中断都属于异常处理
### 11.1.1 异常类型

#### 1.中断
&ensp;ARM64处理器中，中断请求分成普通中断请求(Interrupt Request IRQ)和快速中断请求(Fast Interrupt Request FIQ)


#### 2.中止
&ensp;中止主要有指令中止(Instruction abort)和数据中止(data abort)两种，指访问内存地址发生错误(如缺页)，处理器内部的MMU捕获这些错误并且报告给处理器，指令中止是指当前处理器尝试执行某条指令时发生错误，数据中止指使用加载或存储指令读写外部存储单元发生错误  <br>

#### 3.复位
&ensp;复位(reset)，由CPU复位引脚产生复位信号，让CPU进入复位状态，并重新启动  <br>

#### 4.系统调用
&ensp;ARMv8体系结构提供3中软件尝试的异常和3种系统调用
- SVC指令：用户态程序请求操作系统内核的服务
- HVC指令：客户操作系统(guest OS)请求虚拟机监控器(hypervisor)的服务 
- SMC指令：普通世界中的程序请求安全监控器(secure monitor)


### 11.1.2 异常等级
&ensp;处理器两种运行模式：一种是特权模式，另一种是非特权模式，操作系统内核运行在特权模式  <br>
&ensp;ARM64处理器支持4种特权模式，异常等级(Exception Level EL)：
- EL0 非特权模式，运行应用程序
- EL1 特权模式，运行操作系统内核
- EL2 运行虚拟化管理程序
- EL3 运行安全世界的管理程序


### 11.1.3 同步异常和异步异常
&ensp;异常分成同步异常和异步异常两种，同步异常是处理器执行某条指令而直接导致的异常，指令异常和数据异常为同步异常  <br>
&ensp;中断称为异步异常  <br>
&ensp;异步异常包括物理中断和虚拟中断：
- 物理中断分为3种：SError、IRQ、FIQ
- 虚拟中断分为3种：VSError、vIRQ、vFIQ


## 11.2 异常处理与返回

### 11.2.1 异常入口

&ensp;CPU内核感知异常发生，生成一个目标异常等级，CPU会做： <br>
&emsp;1）把PSTATE寄存器的值保存到对应目标异常等级的SPSR_ELx中 <br>
&emsp;2）把返回地址保存到对应目标异常等级的ELR_ELx中  <br>
&emsp;3）把PSTATE寄存器中D、A、I、F标志位置为1，禁止中断 <br>
&emsp;4）对于同步异常，分析异常原因，写入ESR_ELx  <br>
&emsp;5）切换SP寄存器为目标异常等级的SP_ELx寄存器 <br>
&emsp;6）从异常现场的异常等级切换到对应的目标异常等级，然后跳转到异常向量表 <br>

### 11.2.2 异常返回
&ensp;操作系统系统处理完后，执行一条ERET指令从异常返回，指令执行如下操作： <bt>
&emsp;1）从ELR_ELx中恢复PC指针  <br>
&emsp;2）从SPSR_ELx中恢复PSTATE寄存器的状态  <br>

### 11.2.3 异常返回地址


&ensp;两个寄存器存放不同返回地址： <br>
&emsp;1）X30寄存器(LR)，存放子函数的返回地址，函数完成调用RET指令返回父函数 <br>
&emsp;2）ELR_ELx，存放异常返回地址，执行ERET指令返回异常现场  <br>


### 11.2.4 异常处理路由

&ensp;异常处理路由指的是当异常发生时应该在哪个异常等级处理


### 11.2.5 栈选择
&ensp;ARMv8体系结构，每个异常等级都有对应的栈指针(SP)寄存器，通过SPSel寄存器配置SP，SPSel寄存器SP字段0，EL使用SP_EL0作为栈指针，1表示SP_ELx作为栈指针寄存器 <br>
&emsp;栈必须16字节对齐


### 11.2.6 异常处理的执行状态


### 11.2.7 异常返回的执行状态

&ensp;SPSR决定ERET指令返回是不是切换执行模式 




## 11.3 异常向量表

### 11.3.1 ARMv8异常向量表

&ensp;异常相关处理指令存储在内存中，存储位置为异常向量，ARM体系结构中，异常向量存储到一个异常向量表中<br>




<table>
	<tr>
	    <th>地  址</th>
	    <th>异 常 类 型</th>
	    <th>描　　述</th>  
	</tr >
	<tr>
	    <td>+ 0x000 </td>
	    <td>同步</td>
	    <td  rowspan="4">使用SP_EL0执行状态的当前异常等级</td>
	</tr>
	<tr>
	    <td>+ 0x080 </td>
	    <td>IRQ/vIRQ</td>
	</tr>
	<tr>
	    <td>+ 0x100 </td>
	    <td>FIQ/vFIQ</td>
	</tr>
	<tr>
	    <td>+ 0x180 </td>
	    <td>SError/vSError</td>
	</tr>
	<tr>
	    <td>+ 0x400 </td>
	    <td>同步</td>
	    <td  rowspan="4">在AArch64执行状态下的低异常等级</td>
	</tr>
	<tr>
	    <td>+ 0x480 </td>
	    <td>IRQ/vIRQ</td>
	</tr>
	<tr>
	    <td>+ 0x500 </td>
	    <td>FIQ/vFIQ</td>
	</tr>
	<tr>
	    <td>+ 0x580 </td>
	    <td>SError/vSError</td>
	</tr>
	<tr>
	    <td>+ 0x600 </td>
	    <td>同步</td>
	    <td  rowspan="4">在AArch32执行状态下的低异常等级</td>
	</tr>
	<tr>
	    <td>+ 0x680 </td>
	    <td>IRQ/vIRQ</td>
	</tr>
	<tr>
	    <td>+ 0x700 </td>
	    <td>FIQ/vFIQ</td>
	</tr>
	<tr>
	    <td>+ 0x780 </td>
	    <td>SError/vSError</td>
	</tr>
</table>


### 11.3.2 Linux5.0 内核的异常向量表
&ensp;Linux5.0 内核异常向量表在`arch/arm64/kernel/entry.S`
```c
<arch/arm64/kernel/entry.S>

```


### 11.3.3 VBAR_ELx

&ensp;ARMv8体系结构中VBAR_ELx寄存器来设置异常向量表地址 <br>
&ensp;ARMv8体系结构异常向量表特点： <br>
&emsp;1）除EL0外，每个EL都有自己的异常向量表 <br>
&emsp;2）异常向量表基地址设置到VBAR_ELx中 <br>
&emsp;3）异常向量表起始地址必须以2KB字节对齐  <br>
&emsp;4）每个表项存放32条指令，共128字节  <br>


## 11.4 异常现场

&ensp;ARM64处理器异常现场，需要在栈空间保存： <br>
&emsp;1）PSTATE寄存器的值 <br>
&ensp;2）PC值  <br>
&emsp;3）SP值  <br>
&emsp;4）X0~X30寄存器的值  <br>
&ensp;这个栈空间指发生异常时进程的内核态的栈空间 <br>

## 11.5 同步异常

&ensp;ARMv8体系结构中一个访问失效相关寄存器--异常综合信息寄存器(Exception Syndrome Register ESR)


### 11.5.1 异常类型


### 11.5.2 数据异常



<br>


# 第 12 章 中断处理

- 中断处理一般过程
- 中断现场

## 12.1 中断知识

### 12.1.1 中断引脚

&ensp;ARM64处理器有两个中断相关引脚：nIRQ和nFIQ，ARM处理中断请求分为普通中断IRQ(Interrupt Request)和FIQ(Fast Interrupt Request) <br>
&ensp;PSTATE寄存器两位中断相关，CPU内核的中断总开关： <br>
&emsp; I： 屏蔽和打开IRQ <br>
&emsp; F： 屏蔽和打开FIQ  <br>

### 12.1.2 中断控制器

&ensp;ARM中断控制器GIC




### 12.1.3 中断处理过程


&ensp;中断处理过程： <br>
&emsp;1）CPU操作，把当前PC值保存到ELR中，把PSTATE寄存器值保存到SPSR中，然后跳转到异常向量表  <br>
&emsp;2）在异常向量表中，CPU跳转到对应汇编处理函数，IRQ，中断发生在内核态，跳转到el1_irq，用户态，跳转到el0_irq汇编函数  <br>
&emsp;3）汇编函数中保存中断现场  <br>
&emsp;4）跳转到中断处理函数，如GIC驱动驱动读取中断号，跳转到设备中断处理程序 <br>
&emsp;5）在设备中断处理程序里，处理中断 <br>
&emsp;6）返回el1_irq或el0_irq汇编函数，恢复中断上下文  <br>
&emsp;7）调用ERET指令完成中断返回，CPU把ELR值恢复到PC寄存器，把SPSR寄存器值恢复到PSTATE寄存器 <br>
&emsp;8）CPU继续值中断现场下一条指令  <br>

## 12.2 树莓派4B中断控制器

&ensp;树莓派4B支持两种中断控制器:  <br>
&emsp;1）传统中断控制器，基于寄存器管理中断  <br>
&emsp;2）GIC-400  <br>


## 12.3 ARM内核上通用定时器

&ensp;Cortex-A72内核内置4个通用定时器：PS、PNS、HP、V

## 12.4 中断现场

&ensp;保存中断发生中断前现场，ARM64处理器在栈空间保存： <br>
&emsp;1）PSTATE寄存器的值  <br>
&emsp;2）PC值  <br>
&emsp;3）SP值  <br>
&emsp;4）X0~X30寄存器的值  <br>

&ensp;栈框数据结构(结构体ps_regs)来保存中断现场  <br>

### 12.4.1 保存中断现场

&ensp;中断现场保存到当前进程的内核栈里:  <br>
&emsp;1）栈框里的PSTATE保存发生中断时SPSR_EL1内容  <br>
&emsp;2）栈框里的PC保存ELR_EL1  <br>
&emsp;3）栈框里的SP保存栈定的位置  <br>
&emsp;4）栈框里的regs[30]保存LR的值    <br>
&emsp;5）栈框里的regs[0]~regs[29]分别保存X0~X30寄存器的值  <br>

### 12.4.2 恢复中断现场

&ensp;中断返回时，从进程内核栈恢复中断现场到CPU


<br>


# 第 13 章 GIC-V2

- GIC-V2的SGI、PPI和SPI
- GIC-V2中断号分配
- GIC-V2的SPI外设中断


## 12.1 GIC


## 12.2 中断状态、中断触发方式和硬件中断号


&ensp;中断4种状态： <br>
&emsp;1）不活跃(inactive)状态：中断处于无效状态  <br>
&emsp;2）等待(pending)状态：中断处于有效状态，但等待CPU响应该中断  <br>
&emsp;3）活跃(active)状态：CPU已响应中断  <br>
&emsp;4）活跃并等待(active and pending)状态：CPU正在响应中断，但该中断源又发送中断  <br>

&ensp;中断触发方式：边沿触发与电平触发  <br>


<table>
	<tr>
	    <th>中 断 类 型</th>
	    <th>中 断 号 范 围</th>
	</tr>
	<tr>
	    <td>软件触发中断 SGI</td>
	    <td>0~15</td>
	</tr>
	<tr>
	    <td>私有外设中断 PPI</td>
	    <td>16~31</td>
	</tr>
	<tr>
	    <td>共享外设中断 SPI</td>
	    <td>32~1019</td>
	</tr>
</table>



## 13.3 GIC-V2




## 13.4 树莓派4B的GIC-400

 
<br>

# 第 14 章 内存管理

- 分段和分页机制
- 多级页表
- 内存管理单元(Memory Management Unit MMU)
- ARM64中TTBR0和TTBR1 两个转换页表基地址寄存器
- ARM64处理器4级页表转换过程
- ARMv8体系结构处理器两种内存属性：普通类型内存(normal memory)和设备类型内存(device memory)
- 打开MMU时需建立恒等映射


## 14.1 内存管理基础

&ensp;内存分配三个问题： <br>
&emsp;1）进程地址空间保护   &emsp;&emsp; 虚拟内存  <br>
&emsp;2）内存使用率低    &emsp;&emsp;&emsp;&emsp;分页机制<br>
&emsp;3）程序运行重定位   <br>


## 14.1.2 地址空间抽象

&ensp;进程使用内存的3个地方：  <br>
&emsp;1）进程本身，代码段、数据段存储程序数据  <br>
&emsp;2）栈空间，程序运行时分配内存空间，保存函数调用关系、局部变量、函数参数及函数返回值   <br>
&emsp;3）堆空间，程序运行时动态分配     <br>


&ensp;地址转换：把进程请求的虚拟地址转换成物理地址  <br>
&ensp;进程地址空间是对内存的抽象，使得虚拟化得到实现。进程地址空间、进程的CPU虚拟化及文件存储地址空间抽象，共同组成操作系统3个元素   <br>


## 14.1.3 分段机制

&ensp;分段机制(segmentation)：把程序所需的内存空间的虚拟地址映射到某个物理空间  <br>



## 14.1.4 分页机制


&ensp; 分页机制引入虚拟存储器概念，分页机制核心思想：程序中一部分不使用的内存可以存放到交换磁盘，而程序正在使用的内存继续保留在物理内存中。   <br>
&ensp;虚拟地址VA[31:0]分成两部分：一部分是虚拟页面内的偏移量，以4KB页为例，VA[11:0]是虚拟页面偏移量；另一部分用来寻找属于那个页，称为虚拟页帧号(Virtual Page Number VPN)  &ensp;物理地址PA[11:0]表示物理页帧的偏移量，剩余部分表示物理页帧号(Physical Frame Number PFN)。MMU把虚拟页帧号转换成物理页帧号。处理器使用一张存储VPN到PFN映射关系，称为页表(Page Table PT)，页表每一项称为页表项(Page Table Entry PTE) <br>
&ensp;多级页表来减少页表占用的内存空间  <br>


&ensp;TLB未命中时，处理器的MMU中的页表查询过程：  <br>
&emsp;1）处理器根据虚拟地址判断使用TTBR0还是TTBR1，TTBR存放一级页表的基地址  <br>
&emsp;2）处理器以虚拟地址Bit[31:20]作为索引，在一级页表中查找页表项，一级页表一共有4096个表项  <br>
&emsp;3）一级页表的页表项存放二级页表的物理基地址  <br>



## 14.2 ARM64内存管理

&ensp;ARM64处理器内核的MMU包括TLB和页表遍历单元(Table Waik Unit TWU)两个部件。TLB是高速缓存，缓存页表转换结果  <br>

&ensp;进程地址空间分为内核空间(kernel space)和用户空间(user space)  <br>

&ensp;在SMP系统中，每个处理器内置MMU和TLB硬件单元，CPU0和CPU1共享物理内存，页表存储在物理内存中。CPU1和CPU1的MMU和TLB共享一份页表，当一个CPU修改页表项时，使用BBM(Break-Before-Make)机制来保存其他CPU能访问正确和有效的TLB  <br>

### 14.2.1 页表

&ensp;AArch64执行状态MMU支持一阶段页表转换，也支持虚拟化扩展中两阶段页表转换 <br>
&ensp;一阶段页表转换指把虚拟地址(VA)翻译成物理地址(PA)  <br>
&ensp;两阶段页表转换：阶段1，把虚拟地址翻译成中间物理地址(Intermdeiate Physical Address IPA)，阶段2，把IPA翻译成最终PA  <br>

### 14.2.2 页表映射
&ensp;AArch64体系结构中，以48位地址总线位宽，VA划分位两个空间，每个256TB <br>
&emsp;1）低位虚拟地址空间高16位为0，使用TTBR0_ELx存储页表基地址，用户地址空间 <br>
&emsp;2）高位虚拟地址空间高16位为1，使用TTBR1_ELx存放页表基地址，内核地址空间 <br>


&ensp;TLB未命中时，处理器查询页表的过程 <br>


### 14.2.3 页表粒度

&ensp;4KB、16KB、64KB


### 14.2.4 两套页表

&ensp;AArch64执行状态采用两套页表，整个虚拟地址空间分成3部分，下面是用户空间，中间非规范区域，上面是内核空间。 <br>
&emsp;1）CPU访问用户空间地址(虚拟地址高16位为0)，MMU选择TTBR0_EL0指向页表，
&emsp;2）CPU访问内核空间地址(虚拟地址高16位为1)，MMU选择TTBR1_EL1寄存器指向的页表 

### 14.2.5 页表项描述符


### 14.2.6 页表属性

#### 1.共享性和缓存性


<table>
	<tr>
	    <th>SH[1:0]字段</th>
	    <th>说 明</th>
	</tr>
	<tr>
	    <td>00</td>
	    <td>没有共享性</td>
	</tr>
	<tr>
	    <td>01</td>
	    <td>保留</td>
	</tr>
	<tr>
	    <td>10</td>
	    <td>外部共享</td>
	</tr>
	<tr>
	    <td>11</td>
	    <td>内部共享</td>
	</tr>
</table>



#### 2.访问权限

<table>
	<tr>
	    <th>AP[1:0]字段</th>
	    <th>非特权模式(EL0)</th>
		<th>特权模式(EL1、EL2及EL3)</th>
	</tr>
	<tr>
	    <td>00</td>
	    <td>不可读/不可写</td>
		<td>可读/可写</td>
	</tr>
	<tr>
	    <td>01</td>
	    <td>可读/可写</td>
		<td>可读/可写</td>
	</tr>
	<tr>
	    <td>10</td>
	    <td>不可读/不可写</td>
		<td>只读</td>
	</tr>
	<<tr>
	    <td>11</td>
	    <td>只读</td>
		<td>只读</td>
	</tr>
</table>


#### 3.执行权限



#### 4.访问标志位


#### 5.全局和进程持有TLB

&ensp;TLB表项分成全局和进程特有的 <br>


### 14.2.7 连续块表项


## 14.3 硬件管理访问位和脏位


&ensp;ARMv8体系结构新增TTHM，支持由硬件管理访问位(Access Flag AF)和脏状态(dirty state)  <br>

## 14.4 地址转黄相关寄存器
&ensp;地址转黄相关控制寄存器： <br>
&emsp;1）转黄控制寄存器(Translation Control Register TCR)  <br>
&emsp;2）系统控制寄存器(Sytem Control Register SCTLR)  <br>
&emsp;3）转换页表基地址寄存器(Translation Table Base Register TTBR)  <br>

### 14.4.1 TCR


### 14.4.2 SCTLR

### 14.4.3 TTBR

&ensp;TTBR存储页表的基地址，系统使用两段虚拟地址区域时，TTBR0_EL1指向低端虚拟地址区域，TTBR1_EL1指向高端虚拟地址区域。 <br>
&ensp;ASID字段用来存储硬件ASID，BADDR字段存储页表基地址  <br>

## 14.5 内存属性

&ensp;ARMv8体系结构处理器两个内存属性：普通类型内存和设备类型内存  <br>

### 14.5.1 普通类型内存


### 14.5.2 设备类型内存


## 14.6 BenOS里实现恒等映射


<br>
 
# 第 15 章 高速缓存

- 查询高速缓存过程
- 直接映射、全相连映射及组相连映射高速缓存
- 高速缓存组、路、高速缓存行，标记域
- 重名、同名问题
- ARM64处理器 PoU和PoC


&ensp;高速缓存工作原理、映射方式、虚拟高速缓存与物理高速缓存、重名和别名问题、高速缓存访问延时、高速缓存访问策略、共享属性、高速缓存维护指令

## 15.1 高速缓存

&ensp;数据在高速缓存中，称为高速缓存名字(cache bit)，数据不在高速缓存里，称为高速缓存未命中(cache miss)  <br>
&ensp;高速缓存集成在处理内部的SRAM(Static Random Access Memory)  <br>

&ensp;经典高速缓存系统方案 图

## 15.2 高速缓存的访问延时

&ensp;内存两种体系结构：一种是统一内存访问(Uniform Memroy Access UMA)体系结构，另一种是非统一内存访问(Non-Uniform Memory Access NUMA)体系结构  <br>

## 15.3 高速缓存工作原理

&ensp;经典高速缓存体系结构(VIPT) <br>

&ensp;处理器访问存储器时会把虚拟地址同时传递给TLB和高速缓存，TLB存储虚拟地址到物理地址转换的小缓存，处理器先使用有效帧号(EPN)在TLB中查找最终实际页帧号(RPN)  <br>


&ensp;高速缓存的基本结构  <br>


&emsp;1）地址：处理器访问高速缓存时的地址编码，分成3部分：偏移量(offset)域、索引域和标记(tag)域   <br>
&emsp;2）高速缓存行：高速缓存中最小访问单元，包含一小段主存储器中的数据 <br>
&emsp;3）索引(index)：高速缓存地址编码部分，用于索引和查找地址在高速缓存的哪一组中  <br>
&emsp;4）组(set)：由相同索引的高速缓存行组成  <br>
&emsp;5）路(way)：在组相连的高速缓存中，高速缓存分成大小相同的几块  <br>
&emsp;6）标记(tag)：判断高速缓存行缓存的数据的地址是否和处理器寻找的地址一致 <br>
&emsp;7）偏移量(offset)：高速缓存行中的偏移量  <br>


## 15.4 高速缓存的映射方式

&ensp;高速缓存映射方式：
- 直接映射
- 全相连映射
- 组相连映射


### 15.4.1 直接映射

&ensp;每个组只有一个高速缓存行时，高速缓存称为直接映射高速缓存

### 15.4.2 全相连映射
&ensp;主内存中只有一个地址与n个高速缓存行对应，称为全相连映射  <br>


### 15.4.3 组相连映射

&ensp;


## 15.5 虚拟高速缓存与物理高速缓存

### 15.5.1 物理虚拟缓存
&ensp;处理器查询MMU和TLB并得到物理地址之后，使用物理地址查询高速缓存，称为物理高速缓存

### 15.5.2 虚拟高速缓存

&ensp;虚拟高速缓存：处理器使用虚拟地址寻找高速缓存 


### 15.5.3 VIPT和PIPT
&ensp;VIVT(Virtual Index Virtual Tag)：使用虚拟索引域和虚拟地址的标记域，虚拟高速缓存  <br>
&ensp;PIPT(Physical Index Physical Tag)：使用物理索引域和物理地址标识域，物理高速缓存  <br>
&ensp;VIPT(Virtual Index Physical Tag)：使用虚拟地址索引域和物理地址标记域 <br>


&ensp;VIPT高速缓存工作方式




## 15.6 重名和同名问题

### 15.6.1 重名问题

&ensp;不同虚拟地址对应不同高速缓存行，但对应相同物理地址为重名问题  <br>

&ensp;

### 15.6.2 同名问题

&ensp;同名问题：相同虚拟地址对应不同物理地址，出现在进程切换场景  <br>
&ensp;解决方法在进程切换是先使用clean命令把脏的缓存行数据写回到内存，然后是所有高速缓存行失效，同事需要使TLB无效  <br>


&ensp;重名问题是多个虚拟地址映射到同一个物理地址引发问题，同名问题是一个虚拟地址在进程切换等情况下映射不同物理地址引发问题  <br>


### 15.6.3 VIPT重名问题

&ensp;VIPT中，使用虚拟地址索引域查找高速缓存组，可导致多个高速缓存组映射到同一物理地址



## 15.7 高速缓存策略
&ensp;处理器内核中，一套存储读写指令经过取值、译码、发射和执行等操作后，首先到达LSU(Load Store Unit)。LSU包括加载队列(load queue)和存储队列(store queue)。LSU是指令流水线中的一个执行部件，是处理器存储子系统顶层，是连续指令流水线和高速缓存一个支点  &ensp;存储读写指令通过LSU后，到达一级缓存控制器，一级缓存控制器最先发起探测(probe)操作，对读操作，发起高速缓存读探测操作并带回数据，对写操作，发起写探测操作之前，准备号代谢高速缓存行。探测操作写返回是，将会带回数据。存储器写指令获得最终数据并进行提交操作之后，将整个数据写入。写入可采用直写(write throught)模式或回写(write back)模式 <br>

&ensp;探测过程中，写操作没有找到对应高速缓存行，出现未命中(write miss)，否则为写命中(write hit)。对于写未命中处理器策略是写分配(write-allocate) <br>

&ensp;写命中时，真正写入两种模式：
- 直写模式
- 回写模式

&ensp;写未命中，两种策略：
- 写分配(write-allocate)策略
- 不写分配(no write-allocate)策略


&ensp;读操作，命中高速缓存，直接从高速缓存获取数据 <br>
&ensp;读操作，未命中高速缓存两种策略
- 读分配(read-allocate)策略
- 读直通(read-through)策略

&ensp;高速缓存替换策略：随机法(random-policy)、先进先出(First in First out FIFO)法和最近最少使用(Least Recently Used LRU)法



## 15.8 高速缓存的共享属性

### 15.8.1 共享属性
&ensp;ARMv8体系结构下，普通内存为高速缓存设置可缓存的(shareability)和不可缓存的(non-shareability)两种属性。可设置高速缓存为内部共享(inner share)和外部共享(outer share)高速缓存  <br>

&ensp;高速缓存4个共享域(share domain)：不可共享域、内部共享域、外部共享域及系统共享域

### 15.8.2 PoU和PoC区别

&ensp;ARMv8体系结构观察内存：  <br>
- 全局缓存一致性角度(Ponit of Coherency PoC)：系统中所有可发起内存访问的硬件单元都保证观察到某一个地址上的数据是一致的或相同的副本
- 处理器缓存一致性角度(Point of Unification PoU)：表示站在处理器角度看高速缓存的一致性问题。如指令高速缓存、数据高速缓存、TLB、MMU
&emsp;PoU两个观察点： <br>
- 站在处理器角度
- 站在内部共享属性范围看



## 15.9 高速缓存的维护指令


&ensp;ARM64指令集高速缓存管理指令，包括管理无效缓存和清理高速缓存指令  <br>
&ensp;高速缓存管理三种情况：
- 失效操作
- 清理操作
- 清零操作



## 15.10 高速缓存枚举




<br>



# 第 16 章 缓存一致性

- 缓存一致性
- MESI协议
- DMA和高速缓存一致性问题
- 自修改代码


## 16.1 缓存一致性

&ensp;MESI协议对软件透明，是硬件实现的，但下列场景需要软件手工干预   <br>
- 驱动程序中使用DMA缓冲区造成数据高速缓存和内存中的数据不一致
- 自修改代码(Self-Modifying Code SMC)导致数据高速缓存和指令高速缓存不一致
- 修改页表到时不一致(TLB里保存的数据可能过时)



## 16.2 缓存一致性分类

### 16.2.1 ARM处理器缓存一致性

&ensp;Cortex-15引入大小＆体系结构，大小核体系结构里两个CPU簇(cluster)，每个簇里有多个处理器，MESI协议保证多个处理器内核缓存一致性。CPU簇与簇之间一致性通过AMBA缓存一致性扩展协议控制器  <br>


### 16.2.2 缓存一致性分类

&ensp;缓存一致性系统分成两大类：
- 多喝间的缓存一致性
- 系统间缓存一致性
  
&ensp;硬件实现MESI协议，在ARM芯片手册里，实现MESI协议的硬件单元为侦听控制单元(Snoop Control Unit SCU)，SCU保证CPU内核之间的缓存一致性  <br>


### 16.2.3 系统缓存一致性

&ensp;在一个CPU簇里，每个CPU各自独立L1高速缓存，共享一个L2高速缓存，通过一个ACE硬件单元链接到缓存一致性控制器里。ACE(AXI Coherent Extension)是AMBA 4协议中定义  <br>


## 16.3 缓存一致性解决方案

&ensp;解决缓存一致性问题，3种方案：
- 关闭高速缓存
- 软件维护缓存一致性
- 硬件维护缓存一致性
  

### 16.3.1 关闭高速缓存


### 16.3.2 软件维护缓存一致性

&ensp;软件在合适是清楚脏缓存行或使缓存行失效

### 16.3.3 硬件维护缓存一致性

&ensp;多核里失效一个MESI协议，失效一种总线侦听控制单元



## 16.4 MESI协议



## 16.5 高速缓存伪共享


## 16.6 CCI和CCN缓存一致性控制器

&ensp;处理器中通过高速缓存一致性协议失效，维护一个有限状态机(Finite State Machine FSM)，根据存储器读写的指令或总线上的传输内容，进行状态迁移和响应的高速缓存操作来维护高速缓存一致性，不需要软件   <br>
&ensp;高速缓存一致性协议两达类别：一类监听协议(snooping protocol)，每个高速缓存都要被监听或监听其他高速缓存总线活动；另一类目录协议(directory protocol)用于全局统一管理高速缓存状态  <br>

&ensp;MESI协议：修改(Modified M)、独占(Exclusive E)、共享(Shared S)和无效(Invalid I) 4个状态


### 16.6.1 MESI协议

&ensp;高速缓存行两个标志位——脏(dirty)和有效(valid)


<br>




# 第 17 章 TLB管理

- TLB
- TLB查询过程
- TLB重名、同名问题
- ASID机制
- TLB维护指令后DSB内存屏障指令
- BBM机制
- 操作系统切换页表是刷新TLB

&ensp;把MMu的地址转换结果缓存到缓冲区TLB(Translation Lookaside Buffer)，称为快表  <br>



## 17.1 TLB基础知识


&ensp;MMU内部，TLB项(TLB entry)数量较少，没项包含虚拟页帧号(VPN)、物理页帧号(PFN)及一些属性。  <br>

&ensp;TLB类似高速缓存，支持直接映射方式、全相连映射方式及组相连映射方式。TLB大多采用组相连映射方式  <br>
&ensp;组相连映射TLB，虚拟地址分成三部分，分别是标记域、索引域及页内偏移量  <br>
&ensp;L1 TLB包括指令TLB和数据TLB，而L2 TLB是统一的TLB体系结构  <br>
&ensp;全相连L1指令TLB包括48个表项，全相连L1数据TLb包括32个表项。4路组相连的L2 TLB包括1024个表项  <br>


## 17.2 TLB重名与同名问题


### 17.2.1 重名问题


### 17.2.2 同名问题





## 17.2 ASID



## 17.4 TLB管理命令












































































































































































<br>



<br>
<br>







# 参考文档





















[ARM Architecture Reference Manual Supplement®ARMv8.1, for ARMv8-A architecture profile](https://developer.arm.com/documentation/ddi0557/ab?lang=en)


[ARM Cortex -A Series®®Version: 1.0 Programmer’s Guide for ARMv8-A](https://developer.arm.com/documentation/den0024/a/?lang=en)



[ARM® Cortex®-A72 MPCore Processor Revision: r0p3 Technical Reference Manual](https://developer.arm.com/documentation/100095/0003/?lang=en)


