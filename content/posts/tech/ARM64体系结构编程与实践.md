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




















































# 参考文档




















