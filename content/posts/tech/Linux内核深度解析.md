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

1. 函数el2_setup
> a.如果异常级别是1，那么在异常级别1执行内核。   \
b.如果异常级别是2，那么根据处理器是否支持虚拟化宿主扩展（Virtualization Host Extensions，VHE），决定是否需要降级到异常级别1。    \
   1）如果处理器支持虚拟化宿主扩展，那么在异常级别2执行内核。    \  
   2）如果处理器不支持虚拟化宿主扩展，那么降级到异常级别1，在异常级别1执行内核      \

&emsp;基于内核的虚拟机（Kernel-based Virtual Machine，KVM），KVM的主要特点是直接在处理器上执行客户操作系统，因此虚拟机的执行速度很快。KVM是内核的一个模块，把内核变成虚拟机监控程序。       \
&emsp;开源虚拟机管理软件是QEMU，QEMU支持KVM虚拟机。QEMU创建一个KVM虚拟机，和KVM的交互过程           \
```c
// 打开KVM字符设备文件。
fd = open("/dev/kvm", O_RDWR);
// 创建一个虚拟机，QEMU进程得到一个关联到虚拟机的文件描述符。
vmfd = ioctl(fd, KVM_CREATE_VM, 0);
// KVM为每个虚拟处理器创建一个kvm_vcpu结构体，QEMU进程得到一个关联到虚拟处理器的文件描述符
vcpu_fd = ioctl(vmfd, KVM_CREATE_VCPU, 0);
```

&emsp;从QEMU切换到客户操作系统的过程如下。      \
&emsp;（1）QEMU进程调用“ioctl(vcpu_fd, KVM_RUN, 0)”，陷入到内核。     \
&emsp;（2）KVM执行命令KVM_RUN，从异常级别1切换到异常级别2。           \
&emsp;（3）KVM首先把调用进程的所有寄存器保存在kvm_vcpu结构体中，然后把所有寄存器设置为客户操作系统的寄存器值，最后从异常级别2返回到异常级别1，执行客户操作系统。           \
&emsp;为了提高切换速度，ARM64架构引入了虚拟化宿主扩展，在异常级别2执行宿主操作系统的内核，从QEMU切换到客户操作系统的时候，KVM不再需要先从异常级别1切换到异常级别2      \

<br>

2. 函数__create_page_tables
> 1）创建恒等映射，虚拟地址=物理地址`__enable_mmu`开启内存管理单元        \
> 2）为内核镜像创建映射             \

&emsp;映射代码节`.idmap.text`,恒等映射代码节的起始地址存放在全局变量__idmap_text_start中，结束地址存放在全局变量__idmap_text_end中。恒等映射是为恒等映射代码节创建的映射，idmap_pg_dir是恒等映射的页全局目录（即第一级页表）的起始地址。内核的页表中为内核镜像创建映射，内核镜像的起始地址是_text，结束地址是_end，swapper_pg_dir是内核的页全局目录的起始地址

<br>

3. 函数__primary_switch
> 1）__enable_mmu开启内存管理单元            \
> 2）__primary_switched   \
&ensp;__enable_mmu执行流程  \
&emsp;1）把转换表基准寄存器0(TTBR0_EL1)设置为恒等映射的页全局目录的起始物理地址     \
&emsp;2）把转换表基准寄存器1(TTBR1_EL1)设置为内核的页全局目录的起始物理地址        \
&emsp;3）设置系统控制寄存器(SCTLR_EL1)，开启内存管理单元，后MMU把虚拟地址转换成物理地址    \
&ensp;__primary_switch执行流程      \
&emsp;1）把当前异常级别的栈指针寄存器设置为0号线程内核栈的顶部(init_thread_union + THREAD_SIZE)           \
&emsp;2）把异常级别0的栈指针寄存器(SP_EL0)设置为0号线程的结构体`thread_info`的地址(init_task.thread_info)        \
&emsp;3）把向量基准地址寄存器(VBAR_EL1)设置为异常向量表的起始地址(vectors)     \
&emsp;4）计算内核镜像的起始虚拟地址(kimage_vaddr)和物理地址的差值，保存在全局变量kimage_voffset中     \
&emsp;5）用0初始化内核的未初始化数据段      \
&emsp;6）调用C语言函数`start_kernel`      \

<br>


### 1.2.2 C语言部分

&emsp;内核初始化的C语言部分入口是函数`start_kernel`，函数start_kernel首先初始化基础设施，即初始化内核的各个子系统，然后调用函数`rest_init`。函数rest_init的执行流程如下。   \
&ensp;（1）创建1号线程，即init线程，线程函数是kernel_init。     \
&ensp;（2）创建2号线程，即kthreadd线程，负责创建内核线程。     \
&ensp;（3）0号线程最终变成空闲线程。    \

init线程继续初始化，执行的主要操作如下。    \
&ensp;（1）smp_prepare_cpus()：在启动从处理器以前执行准备工作。   \
&ensp;（2）do_pre_smp_initcalls()：执行必须在初始化SMP系统以前执行的早期初始化，即使用宏early_initcall注册的初始化函数。   \
&ensp;（3）smp_init()：初始化SMP系统，启动所有从处理器。   \
&ensp;（4）do_initcalls()：执行级别0～7的初始化。 \
&ensp;（5）打开控制台的字符设备文件“/dev/console”，文件描述符0、1和2分别是标准输入、标准输出和标准错误，都是控制台的字符设备文件。   \
&emsp;（6）prepare_namespace()：挂载根文件系统，后面装载init程序时需要从存储设备上的文件系统中读文件。   \
&emsp;（7）free_initmem()：释放初始化代码和数据占用的内存。   \
&emsp;（8）装载init程序（U-Boot程序可以传递内核参数“init=”以指定init程序），从内核线程转换成用户空间的init进程。  \

&ensp;级别0～7的初始化，是指使用以下宏注册的初始化函数：
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


### 1.2.3 SMP系统的引导
&ensp;对称多处理器(Symmetirc Multi-Processor SMP)       \
&emsp;3种引导从处理器方法      \
- 自旋表
- 电源状态协调接口
- ACPI停车协议

![ARM64架构下SMP系统的自旋表引导过程](https://liuz0123.gitee.io/zain/img/ARM64_SMP_spin_table.png)


## 1.3 init进程
&emsp;init进程是用户空间第一个进程，负责启动用户程序。Linux系统init程序有`sysvinit`、busybox init、upstart、`systemd`和procd。sysvinit是Unix系统5(System V)init程序，启动配置文件`/etc/initab`


<br>

# 第2章 进程管理

## 2.1 进程

&emsp;Linux内核把进程称为task，进程虚拟地址空间分为用户虚拟地址空间和内核地址空间，所有进程共享内核虚拟地址空间，每个进程有独立用户虚拟地址空间       \
&emsp;进程有两种特殊形式：没有用户虚拟地址空间的进程称为内核线程，共享用户虚拟地址空间的进程称为用户线程。     \
&emsp;task_struct结构体是进程描述符，主要成员

```c
volatile long state;    // 进程状态
void *stack;            // 指向内核栈
pid_t pid;              // 全局进程号
pid_t tgid              // 全局的线程组标识符
struct pid_link pid[PIDTYPE_MAX];   // 进程号，进程组标识符和会话标识符
struct task_struct _rcu *real_parent;   // real_parent指向真实的父进程
struct task_struct _rcu *parent;        // parent指向父进程
struct task_struct *group_leader;   // 指向进村组的组长
const struct cred _rcu *real_cred;  // real_cred指向主题和真实客体证书
const struct cred _rcu *cred;       // cred指向客体证书
char comm[TASK_COMM_LEN];           // 进程名
int prio, static_prio, nornal_prio; // 调度策略
unsigned int rt_priority,prolicy；  // 优先级
cpumask_t cpus_allowed;             // 允许进程在哪些处理器上运行
struct mm_struct *mm, *active_mm;   // 指向内存描述符，进程mm，和active_mm指向同一个内存描述符，内核线程mm是指针，当内核线程运行时active_mm指向从进程借用的内存描述符
struct file_struct *files;          // 打开文件表
struct nsproxy *nsproxy;            // 命名空间
struct signal_struct *signal;       // 信号处理
struct sigband_struct *sighand;
sigset_t blocked, real_blocked;
sigset_t saved_sigmask;
struct sigpending pending;
struct sysv_sem sysvsem;            // UNIx系统5信号量和共享内存
struct sysv_shm sysvshm;
```



## 2.2 命名空间
&emsp;和虚拟机相比，容器是一种轻量级的虚拟化技术，直接使用宿主机的内核，使用命名空间隔离资源,虚拟机仅仅是通过命名空间隔离？  \


|命名空间|隔离资源|
-|-|-
|控制组cgroup|控制组根目录|
|进程间通信IPC|UNIX系统5进程间通信和POSIx消息队列|
|network|网络协议|
|挂载mount|挂载点|
|PID|进程号|
|user|用户标识符和组标识符|
|UNIX分时系统(UTS)|主机名和网络信息服务NIS域名|

&ensp;创建新的命名空间方法：   \
&emsp;调用clone创建子进程时，使用标志位控制子进程是共享父进程的命名空间还是创建新命名空间   \
&emsp;调用unshare创建新的命名空间    \
&ensp;进程使用系统调用setns，绑定一个已经存在的命名空间

![进程的命名空间](https://liuz0123.gitee.io/zain/img/process_namespace.png)

&emsp;进程号命名空间用来隔离进程号，对应的结构体是pid_namespace,进程号命名空间用来隔离进程号，对应的结构体是pid_namespace。


## 2.3 进程标识符

|标识符||
-|-|-
|进程标识符|命名空间给进程分配标识符|
|线程组标识符|线程组中的主进程称为组长，线程组标识符就是组长的进程标识符<br>系统调用clone传入标志CLONE_THREAD以创建新进程时，新进程和当前进程属于一个线程组|
|进程组标识符|进程组标识符是组长的进程标识符。<br>进程可以使用系统调用setpgid创建或者加入一个进程组|
|会话标识符|进程调用系统调用setsid的时候，创建一个新的会话|


![进程的命名空间](https://liuz0123.gitee.io/zain/img/pid_mark.png)

&emsp;pid存储全局进程号，pids[PIDTYPE_PID].pid指向结构体pid，pids[PIDTYPE_PGID].pid指向进程组组长的结构体pid，pids[PIDTYPE_SIG].pid指向会话进程的结构体pid    \

&emsp;进程标识符结构体pid的成员，count是引用计数，level进程号命名空间的层次，numbers元素个数是level的值加1，



## 2.4 进程关系

&emsp;如果子进程被某个进程（通常是调试器）使用系统调用ptrace跟踪，那么成员parent指向跟踪者的进程描述符，否则成员parent也指向父进程的进程描述符。

![进程的命名空间](https://liuz0123.gitee.io/zain/img/process_relative.png)

![进程和线程链表](https://liuz0123.gitee.io/zain/img/tasks_table.png)



## 2.4 启动程序

&emsp;内核使用静态数据构造出0号内核线程，0号内核线程分叉生成1号内核线程和2号内核线程（kthreadd线程）。1号内核线程完成初始化以后装载用户程序，变成1号进程，其他进程都是1号进程或者它的子孙进程分叉生成的；其他内核线程是kthreadd线程分叉生成的
&emsp;两个个系统调用创建进程：    \
- fork：子进程是父进程的副本，用写时复制
- clone：可控制子进程和父进程共享哪些资源
- vfork：创建子进程，子进程用execve装载程序(已废弃)

```c
// 数字表示参数个数
SYSCALL_DEFINE0(fork)
// 宏展开 asmlinkage表示C语言函数看被汇编代码调用
asmlinkage long sys_fork(void)
```

&emsp;创建进程的进程p和被创建进程c三种关系
- 新进程是进程p的子进程
- clone传入CLONE_PARENT，兄弟关系
- clone传入CLONE_THREAD，同属一个线程组

1. _do_fork函数

```c
// kernel/fork.c
long _do_fork(unsigned long clone_flags,
           unsigned long stack_start,
           unsigned long stack_size,
           int __user *parent_tidptr,
           int __user *child_tidptr,
           unsigned long tls);  // tls 创建线程，clone_flags为CLONE_SETTLS时，tlstls指定新线程的线程本地存储的地址

```

![函数_do_fork的执行流程](https://liuz0123.gitee.io/zain/img/_do_fork.png)

&emsp;调用copy_process创建新进程  \
&emsp;clone_flags设置CLONE_PARENT_SETTID，新线程的进程标识符写到参数parent_tidptr指定的位置   \
&emsp;wake_up_new_task唤醒新进程


2. copy_process函数
![20221030190536](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221030190536.png)


- **（1）标志组合**

|||
- | :-: | :-: 
|CLONE_NEWNS & CLONE_FS|新进程属于新挂载命名空间<br>共享文件系统信息|
|CLONE_NEWUSER & CLONE_FS|新进程属于新用户命名空间<br>共享文件系统信息|
|CLONE_THREAD 未设置CLONE_SIGHAND|新进程和当前进程同属一个线程组，但不共享信号处理程序|
|CLONE_SIGHAND 未设置CLONE_VM|新进程和当前进程共享信号处理程序，但不共享虚拟内存|

  
- **（2）dup_task_struct函数**
&emsp;未新进程的进程描述符分配内存，复制当前进程描述符，为新进程分配内核栈

![20221030192206](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221030192206.png "进程的内核栈")

```c
// include/linux/sched.h
union thread_union {
#ifndef CONFIG_ARCH_TASK_STRUCT_ON_STACK
	struct task_struct task;
#endif
#ifndef CONFIG_THREAD_INFO_IN_TASK
	struct thread_info thread_info;
#endif
	unsigned long stack[THREAD_SIZE/sizeof(long)];
};
```

&ensp;内核栈两种布局
- 1. thread_info在内核栈顶部，成员task指向进程描述符
- 2. thread_info未占用内核栈
&emsp;第二种布局需打开CONFIG_THREAD_INFO_IN_TASK，ARM64使用第二种内核栈布局，thread_info结构体地址与进程描述符地址相同。进程在内核模式时，ARM64架构的内核使用用户栈指针寄存器SP_EL0存放当前进程的thread_info结构体地址，可同时得到thread_info地址和进程描述符地址
&emsp;内核栈的长度时`THREAD_SIZE`，**ARM64架构内核栈长度为16KB**
&ensp;thread_info存放汇编代码直接访问的底层数据，ARM64架构定义结构体
```c
// arch/arm64/include/asm/thread_info.h
struct thread_info {
	unsigned long		flags;		/* low level flags 底层标志位 */
	mm_segment_t		addr_limit;	/* address limit 地址限制 */
#ifdef CONFIG_ARM64_SW_TTBR0_PAN
	u64			ttbr0;		/* saved TTBR0_EL1 保存的寄存器TTBR0_EL1 */
#endif
    u64		preempt_count;	/* 抢占计数器 0 => preemptible 可抢占, <0 => bug缺陷 */
};
```


- **（3）copy_creds函数**
&emsp;负责复制或共享证书，证书存放进程的用户标识符、组标识符和访问权限。设置标志CLONE_THREAD，同属一个线程组。CLONE_NEWUSER，需要为新进程创建新的用户命名空间。进程计数器加1

- **（4）检查线程数量限制**
&emsp;全局变量nr_threads存放当前线程数量，max_threads存放允许创建的线程最大数量，默认值MAX_THREADS

- **（5）sched_fork函数**

&emsp;为新进程设置调度器相关的参数
```c
// linux-5.10.102/kernel/sched/core.c  书中为4.x版本
int sched_fork(unsigned long clone_flags, struct task_struct *p)
{
	__sched_fork(clone_flags, p);   // 执行基本设置
	/*
	 * We mark the process as NEW here. This guarantees that
	 * nobody will actually run it, and a signal or other external
	 * event cannot wake it up and insert it on the runqueue either.
	 */
	p->state = TASK_NEW;    // 新进程状态设置为TASK_NEW

	/*
	 * Make sure we do not leak PI boosting priority to the child.
	 */
	p->prio = current->normal_prio;  // 新进程调度优先级设置为当前进程正常优先级

	uclamp_fork(p);

	/*
	 * Revert to default priority/policy on fork if requested.
	 */
	if (unlikely(p->sched_reset_on_fork)) {
		if (task_has_dl_policy(p) || task_has_rt_policy(p)) { // 限期进程或实时进程
			p->policy = SCHED_NORMAL;  // 调度策略
			p->static_prio = NICE_TO_PRIO(0); // nice值默认值0，静态优先级120
			p->rt_priority = 0;  
		} else if (PRIO_TO_NICE(p->static_prio) < 0) // 普通进程
			p->static_prio = NICE_TO_PRIO(0); // nice值默认值0，静态优先级120

		p->prio = p->normal_prio = p->static_prio;
		set_load_weight(p, false);

		/*
		 * We don't need the reset flag anymore after the fork. It has
		 * fulfilled its duty:
		 */
		p->sched_reset_on_fork = 0;
	}

	if (dl_prio(p->prio)) // 调度优先级是限期调度累的优先级
		return -EAGAIN;  // 不允许限期进程分叉生成新的限期进程
	else if (rt_prio(p->prio))  // 调度优先级是实时调度类优先级
		p->sched_class = &rt_sched_class; // 调度类设置为实时调度类
	else
		p->sched_class = &fair_sched_class;  // 调度优先级是公平调度类的优先级，调度类设置为公平调度类

	init_entity_runnable_average(&p->se);

#ifdef CONFIG_SCHED_INFO
	if (likely(sched_info_on()))
		memset(&p->sched_info, 0, sizeof(p->sched_info));
#endif
#if defined(CONFIG_SMP)
	p->on_cpu = 0;
#endif
	init_task_preempt_count(p);
#ifdef CONFIG_SMP
	plist_node_init(&p->pushable_tasks, MAX_PRIO);
	RB_CLEAR_NODE(&p->pushable_dl_tasks);
#endif
	return 0;
}
```


- **（6）复制或共享资源**
&emsp;UNIX系统5信号量，同属一个线程组的线程才共享UNIX系统的5信号量，copy_semundo函数
```c
// linux-4.14.295/ipc/sem.c
int copy_semundo(unsigned long clone_flags, struct task_struct *tsk)
{
	struct sem_undo_list *undo_list;
	int error;

	if (clone_flags & CLONE_SYSVSEM) {  // CLONE_SYSTEM表示UNIX系统5信号量
		error = get_undo_list(&undo_list);
		if (error)
			return error;
		refcount_inc(&undo_list->refcnt); // 5信号量的撤销请求链表，sem_undo_list 计数+1
		tsk->sysvsem.undo_list = undo_list;
	} else
		tsk->sysvsem.undo_list = NULL; // 新进程5信号量撤销请求链表为空

	return 0;
}
```

&ensp;打开文件夹，同属一个线程组的线程直接共享打开文件表，函数copy_files复制或共享打开文件表
```c
// linux-5.10.102/kernel/fork.c
static int copy_files(unsigned long clone_flags, struct task_struct *tsk)
{
	struct files_struct *oldf, *newf;
	int error = 0;

	/*
	 * A background process may not have any files ...
	 */
	oldf = current->files;
	if (!oldf)
		goto out;

	if (clone_flags & CLONE_FILES) { // CLONE_FIELS共享打开文件表
		atomic_inc(&oldf->count);  // files_struct 计数加1
		goto out;
	}

	newf = dup_fd(oldf, NR_OPEN_MAX, &error);  // 新进程把当前进程的打开文件表复制一份
	if (!newf)
		goto out;

	tsk->files = newf;
	error = 0;
out:
	return error;
}
```




