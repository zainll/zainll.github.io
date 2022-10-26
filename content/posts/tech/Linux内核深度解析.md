---
title: "Linux内核深度解析"
date: 2022-10-05T00:17:58+08:00
lastmod: 2022-10-05T00:17:58+08:00
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

# 内容提纲

- 内核的引导过程U-Boot
- 内核管理和调度进程
- 内核管理虚拟内存和物理内存
- 内核处理异常和中断的技术原理，以及系统调用的实现方式
- 保护临界区的互斥
- 虚拟文件系统

# 第1章 内核引导和初始化

&ensp;处理器上电->执行引导程序->加载内核到内存->执行内核->内核初始化->启动用户空间第一个进程
&emsp;ARM64处理器到物理地址0取第一条指令

## 1.1 引导程序
### 1.1.1 入口_start

&emsp;ARM64处理器U-Boot程序执行过程，入口[`u-boot/arch/arm/cpu/armv8/start.S`](https://elixir.bootlin.com/u-boot/latest/source/arch/arm/cpu/armv8/start.S#L20)标识`_start`
```c
.globl	_start
_start:
#if defined(CONFIG_LINUX_KERNEL_IMAGE_HEADER)
#include <asm/boot0-linux-kernel-header.h>
#elif defined(CONFIG_ENABLE_ARM_SOC_BOOT0_HOOK)
#include <asm/arch/boot0.h>
#else
	b	reset
#endif
```

### 1.1.2 `reset`

```c
reset:
	/* Allow the board to save important registers */
    /* 允许板卡保存重要的寄存器*/
	b	save_boot_params
.globl	save_boot_params_ret
save_boot_params_ret:
  
#ifdef CONFIG_SYS_RESET_SCTRL
    bl reset_sctrl   // 初始化系统控制寄存器
#endif
 /*
 * 异常级别可能是3、2或者1，初始状态：
 * 小端字节序，禁止MMU，禁止指令/数据缓存
 */
    adr  x0, vectors
    witch_el x1, 3f, 2f, 1f
3:  msr  vbar_el3, x0    // 异常级别3，向量基准地址寄存器VBAR_EL3设置位异常向量的起始地址
    mrs  x0, scr_el3   // 设置安全配置寄存器SCR_EL3
    orr  x0, x0, #0xf         /* 设置寄存器SCR_EL3的NS、IRQ、FIQ和EA四个位 */
    msr  scr_el3, x0
    msr  cptr_el3, xzr           /* 启用浮点和SIMD功能*/
#ifdef COUNTER_FREQUENCY
    ldr  x0, =COUNTER_FREQUENCY
    msr  cntfrq_el0, x0          /* 初始化寄存器CNTFRQ */
#endif
    b    0f
2:  msr   vbar_el2, x0   // 异常级别2
    mov  x0, #0x33ff
    msr  cptr_el2, x0            /* 启用浮点和SIMD功能 */
    b    0f
1:  msr    vbar_el1, x0
    mov  x0, #3 << 20
    msr  cpacr_el1, x0           /* 启用浮点和SIMD功能 */
0:
 …
 
/* 应用ARM处理器特定的勘误表*/
bl   apply_core_errata
 
 /* 处理器特定的初始化*/
bl   lowlevel_init    // 执行board_init_f()所需最小初始化
 
#if defined(CONFIG_ARMV8_SPIN_TABLE) && !defined(CONFIG_SPL_BUILD)
    branch_if_master x0, x1, master_cpu
    b    spin_table_secondary_jump    // arch/arm/cpu/armv8/spin_tabli.c
    /* 绝对不会返回*/
#elif defined(CONFIG_ARMV8_MULTIENTRY)
branch_if_master x0, x1, master_cpu

/*
* 从处理器
*/
slave_cpu:
    wfe
    ldr  x1, =CPU_RELEASE_ADDR  // 从处理器进入低功耗状态，它被唤醒的时候，从地址CPU_RELEASE_ADDR读取函数
    ldr  x0, [x1]
    cbz  x0, slave_cpu
    br   x0               /* 跳转到指定地址*/
#endif /* CONFIG_ARMV8_MULTIENTRY */
master_cpu:
    bl   _main  // 主处理器执行函数
```

&emsp;U-Boot分为SPL和正常的U-Boot程序两个部分，如果想要编译为SPL，需要开启配置宏CONFIG_SPL_BUILD。SPL是“Secondary Program Loader”的简称，即第二阶段程序加载器，第二阶段是相对于处理器里面的只读存储器中的固化程序来说的，处理器启动时最先执行的是只读存储器中的固化程序

### 1.1.3 函数_main

```c
// arch/arm/lib/crt0_64.S
ENTRY(_main)

/*
 * 设置初始的C语言运行环境，并且调用board_init_f(0)。
 */
#if defined(CONFIG_SPL_BUILD) && defined(CONFIG_SPL_STACK 
    ldr  x0, =(CONFIG_SPL_STACK)
#else
    ldr  x0, =(CONFIG_SYS_INIT_SP_ADDR)
#endif
    bic  sp, x0, #0xf    /* 为了符合应用二进制接口规范，对齐到16字节*/
    mov  x0, sp
    bl   board_init_f_alloc_reserve // 在栈的顶部为结构体global_data分配空间
    mov  sp, x0
    /* 设置gd */
    mov  x18, x0
    bl   board_init_f_init_reserve  // 函数board_init_f_init_reserve，初始化结构体global_data
    
    mov  x0, #0
    bl   board_init_f  // common/board_f.c   执行数组init_sequence_f中的每个函数
    
#if !defined(CONFIG_SPL_BUILD)
/*
 * 设置中间环境（新的栈指针和gd），然后调用函数
 * relocate_code(addr_moni)。
 *
 */
    ldr  x0, [x18, #GD_START_ADDR_SP]    /* 把寄存器x0设置为gd->start_addr_sp */
    bic  sp, x0, #0xf             /* 为了符合应用二进制接口规范，对齐到16字节 */
    ldr  x18, [x18, #GD_BD]       /* 把寄存器x18设置为gd->bd */
    sub  x18, x18, #GD_SIZE       /* 新的gd在bd的下面 */

    adr  lr, relocation_return
    ldr  x9, [x18, #GD_RELOC_OFF]    /* 把寄存器x9设置为gd->reloc_off */
    add  lr, lr, x9    /* 在重定位后新的返回地址 */
    ldr  x0, [x18, #GD_RELOCADDR]    /* 把寄存器x0设置为gd->relocaddr */
    b    relocate_code
    
relocation_return:
 
/*
 * 设置最终的完整环境
 */
    bl   c_runtime_cpu_setup      /* 仍然调用旧的例程 把向量基准地址寄存器设置为异常向量表的起始地址*/
#endif /* !CONFIG_SPL_BUILD */
#if defined(CONFIG_SPL_BUILD)
    bl   spl_relocate_stack_gd    /* 可能返回空指针 重新定位栈*/
    /*
     * 执行“sp = (x0 != NULL) ? x0 : sp”，
     * 规避这个约束：
     * 带条件的mov指令不能把栈指针寄存器作为操作数
     */
    mov  x1, sp
    cmp  x0, #0
    csel x0, x0, x1, ne
    mov  sp, x0
#endif
  
/*
 * 用0初始化未初始化数据段
 */
    ldr  x0, =__bss_start      /* 这是自动重定位*/
    ldr  x1, =__bss_end        /* 这是自动重定位*/
clear_loop:
    str  xzr, [x0], #8
    cmp  x0, x1
    b.lo clear_loop
    
    /* 调用函数board_init_r(gd_t *id, ulong dest_addr) */
    mov  x0, x18                     /* gd_t */
    ldr  x1, [x18, #GD_RELOCADDR]    /* dest_addr */
    b    board_init_r                /* 相对程序计数器的跳转 common/board_r.c 执行数组init_sequence_r中的每个函数，最后一个函数是run_main_loop */
    
 /* 不会运行到这里，因为函数board_init_r()不会返回*/

ENDPROC(_main)
```

### 1.1.4 函数run_main_loop

&emsp;数组`init_sequence_r`最后一个函数`run_main_loop`，函数执行流程；

```sh
run_main_loop
    main_loop
        bootdely_process # 读取环境变量bootdelay(延迟时间)和bootcmd(环境变量)
        autoboot_command
            abortboot    # 等待用户按键
            run_command_list  # 未等待到按键，自动执行环境变量bootcmd
```

&emsp;`bootm`命令处理函数`do_bootm`
```sh
do_bootm
    do_bootm_states
        bootm_start   # 初始化全局变量bootm_header_timages
        bootm_find_os    # 把内核镜像从存储设备读到内存
        bootm_find_other    # ARM64 扁平设备树(Flattended Device Tree FDT)二进制文件
        bootm_load_os  # 解压病加载内核到正确位置
        bootm_os_get_boot_func  # 在操作系统类型数组boot_os中查找引导函数，linux内核引导函数do_bootm_linux
        do_bootm_linux(flag=BOOTM_STATE_OS_PREP)  # 调用boot_prep_linux
            boot_prep_linux  # 1.分配一块内存，把设备数二进制文件复制 2.修改扁平设备树二进制文件
        boot_selected_os  # 
            do_bootm_linux(flag=BOOTM_STATE_OS_GO)
                boot_jump_linux  # 负责跳转到Linux内核
```

```sh
boot_jum_linux
    do_nonsec_virt_switch
        smp_kick_all_cpus  # CONFIG_GICV2或CONFIG_GICV3，中断控制器版本2，3
        dcache_disable  # 禁用处理器的缓存和内存管理单元
    # 在异常级别1执行内核 # 开启配置宏 CONFIG_ARMV8_SWITCH_TO_EL1
    armv8_switch_to_el2
        switch_to_el1
            armv8_switch_to_el1
                内核入口
    # 在异常级别2执行内核
    armv8_switch_to_el2
        内核入口
```

## 1.2 内核初始化
&emsp;内核初始化分为汇编语言部分和C语言部分
### 1.2.1 汇编语言部分
&emsp;ARM64架构内核入口`_head`，直接跳转到标号`stext`
```c
// linux-4.14.295/arch/arm64/kernel/head.S
_head:
#ifdef CONFIG_EFI   // 提供UEFI运行时支持UEFI（Unified Extensible Firmware Interface）是统一的可扩展固件接口，用于取代BIOS
    add  x13, x18, #0x16
    b    stext
#else
    b    stext       // 跳转到内核起始位置
    .long0           // 保留
#endif
```
&ensp;`stext`
```c
// linux-4.14.295/arch/arm64/kernel/head.S
ENTRY(stext)
    bl   preserve_boot_args  // 把引导程序传递的4个参数保存在全局数组boot_args中
    bl   el2_setup        // 降级到异常级别1, 寄存器w0存放cpu_boot_mode
    adrp x23, __PHYS_OFFSET
    and  x23, x23, MIN_KIMG_ALIGN - 1    // KASLR偏移，默认值是0
    bl   set_cpu_boot_mode_flag  // __boot_cpu_mode[2] 数组
    bl   __create_page_tables  // 创建页表映射
    /*
     * 下面调用设置处理器的代码，请看文件“arch/arm64/mm/proc.S”
     * 了解细节。
     * 返回的时候，处理器已经为开启内存管理单元做好准备，
     * 转换控制寄存器已经设置好。
     */
    bl    __cpu_setup        // 初始化处理器
    b    __primary_switch  // 主处理器开启内存管理单元，进入C语言部分入口函数start_kernel
ENDPROC(stext)

```

* 函数el2_setup
> 1.如果异常级别是1，那么在异常级别1执行内核。
2.如果异常级别是2，那么根据处理器是否支持虚拟化宿主扩展（Virtualization Host Extensions，VHE），决定是否需要降级到异常级别1。
   1）如果处理器支持虚拟化宿主扩展，那么在异常级别2执行内核。  
   2）如果处理器不支持虚拟化宿主扩展，那么降级到异常级别1，在异常级别1执行内核

&emsp;基于内核的虚拟机（Kernel-based Virtual Machine，KVM），KVM的主要特点是直接在处理器上执行客户操作系统，因此虚拟机的执行速度很快。KVM是内核的一个模块，把内核变成虚拟机监控程序。
&emsp;开源虚拟机管理软件是QEMU，QEMU支持KVM虚拟机。QEMU创建一个KVM虚拟机，和KVM的交互过程
```c
// 打开KVM字符设备文件。
fd = open("/dev/kvm", O_RDWR);
// 创建一个虚拟机，QEMU进程得到一个关联到虚拟机的文件描述符。
vmfd = ioctl(fd, KVM_CREATE_VM, 0);
// KVM为每个虚拟处理器创建一个kvm_vcpu结构体，QEMU进程得到一个关联到虚拟处理器的文件描述符
vcpu_fd = ioctl(vmfd, KVM_CREATE_VCPU, 0);
```

&emsp;从QEMU切换到客户操作系统的过程如下。
&emsp;（1）QEMU进程调用“ioctl(vcpu_fd, KVM_RUN, 0)”，陷入到内核。
&emsp;（2）KVM执行命令KVM_RUN，从异常级别1切换到异常级别2。
&emsp;（3）KVM首先把调用进程的所有寄存器保存在kvm_vcpu结构体中，然后把所有寄存器设置为客户操作系统的寄存器值，最后从异常级别2返回到异常级别1，执行客户操作系统。
&emsp;为了提高切换速度，ARM64架构引入了虚拟化宿主扩展，在异常级别2执行宿主操作系统的内核，从QEMU切换到客户操作系统的时候，KVM不再需要先从异常级别1切换到异常级别2

<br>

* 函数__create_page_tables


<br>

* 函数__primary_switch

<br>


### 1.2.2 C语言部分

&emsp;内核初始化的C语言部分入口是函数start_kernel，函数start_kernel首先初始化基础设施，即初始化内核的各个子系统，然后调用函数rest_init。函数rest_init的执行流程如下。

（1）创建1号线程，即init线程，线程函数是kernel_init。

（2）创建2号线程，即kthreadd线程，负责创建内核线程。

（3）0号线程最终变成空闲线程。

init线程继续初始化，执行的主要操作如下。

（1）smp_prepare_cpus()：在启动从处理器以前执行准备工作。

（2）do_pre_smp_initcalls()：执行必须在初始化SMP系统以前执行的早期初始化，即使用宏early_initcall注册的初始化函数。

（3）smp_init()：初始化SMP系统，启动所有从处理器。

（4）do_initcalls()：执行级别0～7的初始化。
保存在全局变量kimage_voffset中。

（5）用0初始化内核的未初始化数据段。

（6）调用C语言函数start_kernel。

1.3.2　C语言部分
内核初始化的C语言部分入口是函数start_kernel，函数start_kernel首先初始化基础设施，即初始化内核的各个子系统，然后调用函数rest_init。函数rest_init的执行流程如下。

（1）创建1号线程，即init线程，线程函数是kernel_init。

（2）创建2号线程，即kthreadd线程，负责创建内核线程。

（3）0号线程最终变成空闲线程。

init线程继续初始化，执行的主要操作如下。

（1）smp_prepare_cpus()：在启动从处理器以前执行准备工作。

（2）do_pre_smp_initcalls()：执行必须在初始化SMP系统以前执行的早期初始化，即使用宏early_initcall注册的初始化函数。

（3）smp_init()：初始化SMP系统，启动所有从处理器。

（4）do_initcalls()：执行级别0～7的初始化。

（5）打开控制台的字符设备文件“/dev/console”，文件描述符0、1和2分别是标准输入、标准输出和标准错误，都是控制台的字符设备文件。

（6）prepare_namespace()：挂载根文件系统，后面装载init程序时需要从存储设备上的文件系统中读文件。

（7）free_initmem()：释放初始化代码和数据占用的内存。

（8）装载init程序（U-Boot程序可以传递内核参数“init=”以指定init程序），从内核线程转换成用户空间的init进程。

级别0～7的初始化，是指使用以下宏注册的初始化函数：
```c
// include/linux/init.h
#define pure_initcall(fn)           __define_initcall(fn, 0)

#define core_initcall(fn)           __define_initcall(fn, 1)
#define core_initcall_sync(fn)      __define_initcall(fn, 1s)
#define postcore_initcall(fn)       __define_initcall(fn, 2)
#define postcore_initcall_sync(fn)  __define_initcall(fn, 2s)
#define arch_initcall(fn)           __define_initcall(fn, 3)
#define arch_initcall_sync(fn)      __define_initcall(fn, 3s)
#define subsys_initcall(fn)         __define_initcall(fn, 4)
#define subsys_initcall_sync(fn)    __define_initcall(fn, 4s)
#define fs_initcall(fn)             __define_initcall(fn, 5)
#define fs_initcall_sync(fn)        __define_initcall(fn, 5s)
#define rootfs_initcall(fn)         __define_initcall(fn, rootfs)
#define device_initcall(fn)         __define_initcall(fn, 6)
#define device_initcall_sync(fn)    __define_initcall(fn, 6s)
#define late_initcall(fn)           __define_initcall(fn, 7)
#define late_initcall_sync(fn)      __define_initcall(fn, 7s)
```







