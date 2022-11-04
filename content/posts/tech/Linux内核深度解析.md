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
2:  msr   vbar_el2, x0   		// 异常级别2
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
	// 从处理器进入低功耗状态，它被唤醒的时候，从地址CPU_RELEASE_ADDR读取函数
    ldr  x1, =CPU_RELEASE_ADDR 
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

// 设置初始的C语言运行环境，并且调用board_init_f(0)。
#if defined(CONFIG_SPL_BUILD) && defined(CONFIG_SPL_STACK 
    ldr  x0, =(CONFIG_SPL_STACK)
#else
    ldr  x0, =(CONFIG_SYS_INIT_SP_ADDR)
#endif
    bic  sp, x0, #0xf   /* 为了符合应用二进制接口规范，对齐到16字节*/
    mov  x0, sp
    bl   board_init_f_alloc_reserve // 在栈的顶部为结构体global_data分配空间
    mov  sp, x0
    mov  x18, x0  /* 设置gd */
	// 函数board_init_f_init_reserve，初始化结构体global_data
    bl   board_init_f_init_reserve  
    
    mov  x0, #0
    bl   board_init_f // common/board_f.c 执行数组init_sequence_f中的每个函数
    
#if !defined(CONFIG_SPL_BUILD)
 // 设置中间环境（新的栈指针和gd），然后调用函数
 // relocate_code(addr_moni)
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

// 设置最终的完整环境
   /* 仍然调用旧的例程 把向量基准地址寄存器设置为异常向量表的起始地址*/
    bl   c_runtime_cpu_setup  
#endif /* !CONFIG_SPL_BUILD */
#if defined(CONFIG_SPL_BUILD)
    bl   spl_relocate_stack_gd    /* 可能返回空指针 重新定位栈*/
    // 执行“sp = (x0 != NULL) ? x0 : sp”，
    // 规避这个约束：
    // 带条件的mov指令不能把栈指针寄存器作为操作数
    mov  x1, sp
    cmp  x0, #0
    csel x0, x0, x1, ne
    mov  sp, x0
#endif
  
// 用0初始化未初始化数据段
    ldr  x0, =__bss_start      /* 这是自动重定位*/
    ldr  x1, =__bss_end        /* 这是自动重定位*/
clear_loop:
    str  xzr, [x0], #8
    cmp  x0, x1
    b.lo clear_loop
    
    /* 调用函数board_init_r(gd_t *id, ulong dest_addr) */
    mov  x0, x18                     /* gd_t */
    ldr  x1, [x18, #GD_RELOCADDR]    /* dest_addr */
	/* 相对程序计数器的跳转 common/board_r.c 执行数组init_sequence_r中的每个函数，最后一个函数是run_main_loop */
    b    board_init_r   
    
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
    
    /* 下面调用设置处理器的代码，请看文件“arch/arm64/mm/proc.S” 了解细节。
     * 返回的时候，处理器已经为开启内存管理单元做好准备，
     * 转换控制寄存器已经设置好。*/
    bl    __cpu_setup        // 初始化处理器
    b    __primary_switch  // 主处理器开启内存管理单元，进入C语言部分入口函数start_kernel
ENDPROC(stext)

```

<br>

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
&emsp;为了提高切换速度，`ARM64架构引入了虚拟化宿主扩展，在异常级别2执行宿主操作系统的内核`，从QEMU切换到客户操作系统的时候，KVM不再需要先从异常级别1切换到异常级别2      \

<br>

2. 函数__create_page_tables
> 1）创建恒等映射，虚拟地址=物理地址`__enable_mmu`开启内存管理单元        \
> 2）为内核镜像创建映射             \

&emsp;映射代码节`.idmap.text`,恒等映射代码节的起始地址存放在全局变量__idmap_text_start中，结束地址存放在全局变量__idmap_text_end中。恒等映射是为恒等映射代码节创建的映射，idmap_pg_dir是恒等映射的页全局目录（即第一级页表）的起始地址。内核的页表中为内核镜像创建映射，内核镜像的起始地址是_text，结束地址是_end，swapper_pg_dir是内核的页全局目录的起始地址

<br>

3. 函数__primary_switch
> 1）__enable_mmu开启内存管理单元            \
> 2）__primary_switched      \
&ensp;__enable_mmu执行流程     \
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



## 2.5 启动程序

```c
ret = fork();
if (ret > 0) {
   /* 父进程继续执行 */
} else if (ret == 0) {
    /* 子进程装载程序 */
    ret = execve(filename, argv, envp);
} else {
   /* 创建子进程失败 */
}
```

### 2.5.1　创建新进程

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

#### 1. _do_fork函数

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


#### 2. copy_process函数
![20221030190536](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221030190536.png)


- **（1）标志组合**

|||
:-: | :-: | :-: 
|CLONE_NEWNS & CLONE_FS|新进程属于新挂载命名空间<br>共享文件系统信息|
|CLONE_NEWUSER & CLONE_FS|新进程属于新用户命名空间<br>共享文件系统信息|
|CLONE_THREAD <br> 未设置CLONE_SIGHAND|新进程和当前进程同属一个线程组，<br>但不共享信号处理程序|
|CLONE_SIGHAND <br> 未设置CLONE_VM|新进程和当前进程共享信号处理程序，<br>但不共享虚拟内存|

  
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


&emsp;1）UNIX系统5信号量，同属一个线程组的线程才共享UNIX系统的5信号量，copy_semundo函数
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

&ensp;2）打开文件夹，同属一个线程组的线程直接共享打开文件表，函数copy_files复制或共享打开文件表
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

&emsp;3）文件系统信息。进程文件系统信号包括：根目录、当前工作目录和文件模式创建掩码。同属一个线程组的线程之间才会共享文件系统信息     \
&ensp;&emsp;函数copy_fs复制或共享文件系统信息
```c
// linux-5.10.102/kernel/fork.c
static int copy_fs(unsigned long clone_flags, struct task_struct *tsk)
{
	struct fs_struct *fs = current->fs;
	if (clone_flags & CLONE_FS) {  // CLONE_FS共享文件系统信息
		/* tsk->fs is already what we want */
		spin_lock(&fs->lock);
		if (fs->in_exec) {
			spin_unlock(&fs->lock);
			return -EAGAIN;
		}
		fs->users++;  // fs_struct共享文件系统信息结构体 加1
		spin_unlock(&fs->lock);
		return 0;
	}
	tsk->fs = copy_fs_struct(fs);  // 新进程复制当前进程文件系统信息
	if (!tsk->fs)
		return -ENOMEM;
	return 0;
}
```
&emsp;4）信号处理程序，同属一个线程组线程之间才会共享信号处理程序 \
&ensp;&emsp;函数copy_sighand复制或共享信号处理程序
```c
// 
static int copy_sighand(unsigned long clone_flags, struct task_struct *tsk)
{
	struct sighand_struct *sig;

	if (clone_flags & CLONE_SIGHAND) {  // CLONE_SIGHAND 表示共享信号处理程序
		refcount_inc(&current->sighand->count); // 引用计数加1
		return 0;
	}
    // 新进程复制当前进程信号处理程序
	sig = kmem_cache_alloc(sighand_cachep, GFP_KERNEL);
	RCU_INIT_POINTER(tsk->sighand, sig);
	if (!sig)
		return -ENOMEM;

	refcount_set(&sig->count, 1);
	spin_lock_irq(&current->sighand->siglock);
	memcpy(sig->action, current->sighand->action, sizeof(sig->action));
	spin_unlock_irq(&current->sighand->siglock);

	/* Reset all signal handler not set to SIG_IGN to SIG_DFL. */
	if (clone_flags & CLONE_CLEAR_SIGHAND)
		flush_signal_handlers(tsk, 0);

	return 0;
}

```

&emsp;5）信号结构体，同属一个线程组的线程才会共享信号结构体   \
&ensp;&emsp;函数copy_signal复制或共享信号结构体
```c
// linux-5.10.102/kernel/fork.c
static int copy_signal(unsigned long clone_flags, struct task_struct *tsk)
{
	struct signal_struct *sig;

	if (clone_flags & CLONE_THREAD)  // CLONE_THREAD表示创建线程，新进程和当前进程共享信号结构体signal_struct
		return 0;
    // 为新进程分配结构体，初始化，继承当前进程资源限制
	sig = kmem_cache_zalloc(signal_cachep, GFP_KERNEL);
	tsk->signal = sig;
	if (!sig)
		return -ENOMEM;

	sig->nr_threads = 1;
	atomic_set(&sig->live, 1);
	refcount_set(&sig->sigcnt, 1);

	/* list_add(thread_node, thread_head) without INIT_LIST_HEAD() */
	sig->thread_head = (struct list_head)LIST_HEAD_INIT(tsk->thread_node);
	tsk->thread_node = (struct list_head)LIST_HEAD_INIT(sig->thread_head);

	init_waitqueue_head(&sig->wait_chldexit);
	sig->curr_target = tsk;
	init_sigpending(&sig->shared_pending);
	INIT_HLIST_HEAD(&sig->multiprocess);
	seqlock_init(&sig->stats_lock);
	prev_cputime_init(&sig->prev_cputime);

#ifdef CONFIG_POSIX_TIMERS
	INIT_LIST_HEAD(&sig->posix_timers);
	hrtimer_init(&sig->real_timer, CLOCK_MONOTONIC, HRTIMER_MODE_REL);
	sig->real_timer.function = it_real_fn;
#endif

	task_lock(current->group_leader);
	memcpy(sig->rlim, current->signal->rlim, sizeof sig->rlim);
	task_unlock(current->group_leader);

	posix_cpu_timers_init_group(sig);

	tty_audit_fork(sig);
	sched_autogroup_fork(sig);

	sig->oom_score_adj = current->signal->oom_score_adj;
	sig->oom_score_adj_min = current->signal->oom_score_adj_min;

	mutex_init(&sig->cred_guard_mutex);
	init_rwsem(&sig->exec_update_lock);

	return 0;
}
```

&emsp;6）虚拟内存，同属一个线程组的线程才会共享虚拟内存  \ 
&ensp;&emsp;函数copy_mm复制或共享虚拟内存
```c
// linux-5.10.102/kernel/freezer.c
static int copy_mm(unsigned long clone_flags, struct task_struct *tsk)
{
	struct mm_struct *mm, *oldmm;
	int retval;

	tsk->min_flt = tsk->maj_flt = 0;
	tsk->nvcsw = tsk->nivcsw = 0;
#ifdef CONFIG_DETECT_HUNG_TASK
	tsk->last_switch_count = tsk->nvcsw + tsk->nivcsw;
	tsk->last_switch_time = 0;
#endif

	tsk->mm = NULL;
	tsk->active_mm = NULL;

	/*
	 * Are we cloning a kernel thread?
	 *
	 * We need to steal a active VM for that..
	 */
	oldmm = current->mm;
	if (!oldmm)
		return 0;

	/* initialize the new vmacache entries */
	vmacache_flush(tsk);

	if (clone_flags & CLONE_VM) {  // CLONE_VM表示共享虚拟内存，新进程和当前进程共享内存描述符mm_struct
		mmget(oldmm);
		mm = oldmm;
		goto good_mm;
	}

	retval = -ENOMEM;
    // 新进程复制当前进程的虚拟内存
	mm = dup_mm(tsk, current->mm);
	if (!mm)
		goto fail_nomem;

good_mm:
	tsk->mm = mm;
	tsk->active_mm = mm;
	return 0;

fail_nomem:
	return retval;
}
```
&emsp;7）命名空间    \
&ensp;&emsp;函数copy_namespace创建或共享命名空间
```c
// linux-5.10.102/kernel/nsproxy.c
int copy_namespaces(unsigned long flags, struct task_struct *tsk)
{
	struct nsproxy *old_ns = tsk->nsproxy;
	struct user_namespace *user_ns = task_cred_xxx(tsk, user_ns);
	struct nsproxy *new_ns;
	int ret;
    // 如果共享除了用户以外的所有其他命名空间，
	// 那么新进程和当前进程共享命名空间代理结构体nsproxy，把计数加1
	if (likely(!(flags & (CLONE_NEWNS | CLONE_NEWUTS | CLONE_NEWIPC |
			      CLONE_NEWPID | CLONE_NEWNET |
			      CLONE_NEWCGROUP | CLONE_NEWTIME)))) {
		if (likely(old_ns->time_ns_for_children == old_ns->time_ns)) {
			get_nsproxy(old_ns);
			return 0;
		}
	} else if (!ns_capable(user_ns, CAP_SYS_ADMIN)) 
	// 进程没有系统管理权限，那么不允许创建新的命名空间
		return -EPERM;

	
	/* CLONE_NEWIPC must detach from the undolist: after switching
	 * to a new ipc namespace, the semaphore arrays from the old
	 * namespace are unreachable.  In clone parlance, CLONE_SYSVSEM
	 * means share undolist with parent, so we must forbid using
	 * it along with CLONE_NEWIPC. */
    // 既要求创建新的进程间通信命名空间，又要求共享UNIX系统5信号量，那么这种要求是不合理的
	if ((flags & (CLONE_NEWIPC | CLONE_SYSVSEM)) ==
		(CLONE_NEWIPC | CLONE_SYSVSEM)) 
		return -EINVAL;
    // 创建新的命名空间代理，然后创建或者共享命名空间
	new_ns = create_new_namespaces(flags, tsk, user_ns, tsk->fs);
	if (IS_ERR(new_ns))
		return  PTR_ERR(new_ns);

	ret = timens_on_fork(new_ns, tsk);
	if (ret) {
		free_nsproxy(new_ns);
		return ret;
	}

	tsk->nsproxy = new_ns;
	return 0;
}
```

&emsp;8）I/O上下文    \
&ensp;&emsp;函数copy_io创建或共享I/O上下文
```c
// linux-5.10.102/kernel/fork.c
static int copy_io(unsigned long clone_flags, struct task_struct *tsk)
{
#ifdef CONFIG_BLOCK
	struct io_context *ioc = current->io_context;
	struct io_context *new_ioc;

	if (!ioc)
		return 0;
	
	/* Share io context with parent, if CLONE_IO is set */
	if (clone_flags & CLONE_IO) {  // CLONE_IO 共享I/O上小文
		ioc_task_link(ioc);  // 计数nr_tasks加1
		tsk->io_context = ioc;  // 共享I/O上下文结构体io_context
	} else if (ioprio_valid(ioc->ioprio)) {
        // 创建新的I/O上下文，初始化，继承当前进程的I/O优先级
		new_ioc = get_task_io_context(tsk, GFP_KERNEL, NUMA_NO_NODE);
		if (unlikely(!new_ioc))
			return -ENOMEM;

		new_ioc->ioprio = ioc->ioprio;
		put_io_context(new_ioc);
	}
#endif
	return 0;
}
```

&emsp;9）复制寄存器值   \
&ensp;&emsp;函数copy_thread_tls复制当前进程的寄存器值，并修改一部分寄存器值。进程有两处用来保存寄存器值：从用户模式切换到内核模式时，把用户模式的各种寄存器保存在内核栈底部的结构体pt_regs中；进程调度器调度进程时，切换出去的进程把寄存器值保存在进程描述符的成员thread中。因为不同处理器架构的寄存器不同，所以各种处理器架构需要自己定义结构体pt_regs和thread_struct

![20221030211811](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221030211811.png)

&ensp;&emsp;ARM64架构copy_thread_tls->copy_thread
```c
// linux-5.10.102/arch/arm64/kernel/process.c
int copy_thread(unsigned long clone_flags, unsigned long stack_start,
		unsigned long stk_sz, struct task_struct *p, unsigned long tls)
{
	struct pt_regs *childregs = task_pt_regs(p);
    // 新进程的进程描述符的成员thread.cpu_context清零，在调度进程时切换出去的进程使用这个成员保存通用寄存器的值
	memset(&p->thread.cpu_context, 0, sizeof(struct cpu_context));

	
	/* In case p was allocated the same task_struct pointer as some
	 * other recently-exited task, make sure p is disassociated from
	 * any cpu that may have run that now-exited task recently.
	 * Otherwise we could erroneously skip reloading the FPSIMD
	 * registers for p. */
	fpsimd_flush_task_state(p);

	ptrauth_thread_init_kernel(p);

	if (likely(!(p->flags & PF_KTHREAD))) {  // 用户进程
		*childregs = *current_pt_regs();
		childregs->regs[0] = 0;

		
		/* Read the current TLS pointer from tpidr_el0 as it may be
		 * out-of-sync with the saved value.
         * 从寄存器tpidr_el0读取当前线程的线程本地存储的地址，
         * 因为它可能和保存的值不一致 */
		*task_user_tls(p) = read_sysreg(tpidr_el0);

		if (stack_start) {
			if (is_compat_thread(task_thread_info(p)))
				childregs->compat_sp = stack_start;
			else
				childregs->sp = stack_start;
		}

		
		/* If a TLS pointer was passed to clone, use it for the new thread. 
		 * 如果把线程本地存储的地址传给系统调用clone的第4个参数，那么新线程将使用它*/
		if (clone_flags & CLONE_SETTLS)
			p->thread.uw.tp_value = tls;
	} else {  // 内核线程
		memset(childregs, 0, sizeof(struct pt_regs));
		childregs->pstate = PSR_MODE_EL1h;
		if (IS_ENABLED(CONFIG_ARM64_UAO) &&
		    cpus_have_const_cap(ARM64_HAS_UAO))
			childregs->pstate |= PSR_UAO_BIT;

		spectre_v4_enable_task_mitigation(p);

		if (system_uses_irq_prio_masking())
			childregs->pmr_save = GIC_PRIO_IRQON;

		p->thread.cpu_context.x19 = stack_start;
		p->thread.cpu_context.x20 = stk_sz;
	}
	p->thread.cpu_context.pc = (unsigned long)ret_from_fork;
	p->thread.cpu_context.sp = (unsigned long)childregs;

	ptrace_hw_copy_thread(p);

	return 0;
}
```

- **（7）设置进程号和进程关系**

```c
static __latent_entropy struct task_struct *copy_process(
					struct pid *pid,
					int trace,
					int node,
					struct kernel_clone_args *args)
{
    // 为新进程分配进程号
    // pid等于init_struct_pid的地址，内核初始化时，引导处理器为每个从处理器分叉生成一个空闲线程（参考函数idle_threads_init），所有处理器的空闲线程使用进程号0，全局变量init_struct_pid存放空闲线程的进程号
    if (pid != &init_struct_pid) {
        pid = alloc_pid(p->nsproxy->pid_ns_for_children);
        if (IS_ERR(pid)) {
            retval = PTR_ERR(pid);
            goto bad_fork_cleanup_thread;
        }
    }
    
    …
    // 设置新进程退出时发送给父进程的信号
    p->pid = pid_nr(pid);
    if (clone_flags & CLONE_THREAD) {
        p->exit_signal = -1; // 新线程退出时不需要发送信号给父进程
        p->group_leader = current->group_leader;  // group_leader指向同一个组长
        p->tgid = current->tgid;  // tgid存放组长的进程号
    } else {
        if (clone_flags & CLONE_PARENT) // CLONE_PARENT 新进程和当前进程是兄弟关系
            p->exit_signal = current->group_leader->exit_signal;  // 新进程的成员exit_signal等于当前进程所属线程组的组长的成员exit_signal
        else // 父子关系
            p->exit_signal = (clone_flags & CSIGNAL); // 新进程的成员exit_signal是调用者指定的信号
        p->group_leader = p;
        p->tgid = p->pid;
    }
    
    // 控制组的进程数控制器检查是否允许创建新进程：
	// 从当前进程所属的控制组一直到控制组层级的根，
	// 如果其中一个控制组的进程数量大于或等于限制，
	// 那么不允许使用fork和clone创建新进程
    cgroup_threadgroup_change_begin(current);
    retval = cgroup_can_fork(p);
    if (retval)
        goto bad_fork_free_pid;
    
    write_lock_irq(&tasklist_lock);
    // 为新进程设置父进程
    if (clone_flags & (CLONE_PARENT|CLONE_THREAD)) {
		// 新进程和当前进程拥有相同的父进程
        p->real_parent = current->real_parent;  
        p->parent_exec_id = current->parent_exec_id;
    } else {
        p->real_parent = current;  // 新进程的父进程是当前进程
        p->parent_exec_id = current->self_exec_id;
    }
    
    …
    spin_lock(&current->sighand->siglock);
    …
    if (likely(p->pid)) {
        …
        init_task_pid(p, PIDTYPE_PID, pid);
        if (thread_group_leader(p)) {  // true 新进程和当前进程属于同一个进程组
            init_task_pid(p, PIDTYPE_PGID, task_pgrp(current));  // 指向同一个进程组的组长的进程号结构体
            init_task_pid(p, PIDTYPE_SID, task_session(current));  // 指向同一个会话的控制进程的进程号结构体

            if (is_child_reaper(pid)) {  
                ns_of_pid(pid)->child_reaper = p;
                p->signal->flags |= SIGNAL_UNKILLABLE;  // 1号进程是不能杀死的
            }

            p->signal->leader_pid = pid;
            p->signal->tty = tty_kref_get(current->signal->tty);
            p->signal->has_child_subreaper = p->real_parent->signal-> has_child_subreaper ||
                                p->real_parent->signal->is_child_subreaper;
            list_add_tail(&p->sibling, &p->real_parent->children);  // 新进程添加到父进程的子进程链表
			// 新进程添加到进程链表中，链表节点是成员tasks，
			// 头节点是空闲线程的成员tasks（init_task.tasks）
            list_add_tail_rcu(&p->tasks, &init_task.tasks);  
            attach_pid(p, PIDTYPE_PGID);  // 新进程添加到进程组的进程链表
            attach_pid(p, PIDTYPE_SID);  // 新进程添加到会话的进程链表
            __this_cpu_inc(process_counts);
        } else {  // 创建线程
            current->signal->nr_threads++;  // 线程组的线程计数值加1
            atomic_inc(&current->signal->live);  // 原子变量线程组的第2个线程计数值加1
            atomic_inc(&current->signal->sigcnt);  // 信号结构体的引用计数加1
            list_add_tail_rcu(&p->thread_group,    
                        &p->group_leader->thread_group);  // 线程加入线程组的线程链表
            list_add_tail_rcu(&p->thread_node,
                        &p->signal->thread_head);  // 线程加入线程组的第二条线程链表
        }
        attach_pid(p, PIDTYPE_PID);  // 新进程添加到进程号结构体的进程链表
        nr_threads++;  // 新进程添加到进程号结构体的进程链表
    }
    
    total_forks++;
    spin_unlock(&current->sighand->siglock);
    …
    write_unlock_irq(&tasklist_lock);
    
    proc_fork_connector(p);
    cgroup_post_fork(p);
    cgroup_threadgroup_change_end(current);
    …
    return p;
}
```

#### 3.唤醒新进程

&emsp;wake_up_new_task函数唤醒新进程
```c
// linux-5.10.102/kernel/sched/core.c
void wake_up_new_task(struct task_struct *p)
{
	struct rq_flags rf;
	struct rq *rq;

	raw_spin_lock_irqsave(&p->pi_lock, rf.flags);
	p->state = TASK_RUNNING;  // 切换TASK_RUNNING
#ifdef CONFIG_SMP
	
	/* Fork balancing, do it here and not earlier because:
	 *  - cpus_ptr can change in the fork path
	 *  - any previously selected CPU might disappear through hotplug
	 * Use __set_task_cpu() to avoid calling sched_class::migrate_task_rq,
	 * as we're not fully set-up yet.*/
	p->recent_used_cpu = task_cpu(p);
	rseq_migrate(p);
	__set_task_cpu(p, select_task_rq(p, task_cpu(p), SD_BALANCE_FORK, 0));  // 在SMP系统上，创建新进程是执行负载均衡的绝佳时机，为新进程选择一个负载最轻的处理器
#endif
	rq = __task_rq_lock(p, &rf);  // 锁住运行队列
	update_rq_clock(rq);  // 更新运行队列的时钟
	post_init_entity_util_avg(p);  // 根据公平运行队列的平均负载统计值，推算新进程的平均负载统计值

	activate_task(rq, p, ENQUEUE_NOCLOCK); // 把新进程插入运行队列
	trace_sched_wakeup_new(p);
	check_preempt_curr(rq, p, WF_FORK);  // 检查新进程是否可以抢占当前进程
#ifdef CONFIG_SMP
	if (p->sched_class->task_woken) {  // 在SMP系统上，调用调度类的task_woken方法
		
		/* Nothing relies on rq->lock after this, so its fine to
		 * drop it.*/
		rq_unpin_lock(rq, &rf);
		p->sched_class->task_woken(rq, p);
		rq_repin_lock(rq, &rf);
	}
#endif
	task_rq_unlock(rq, p, &rf);  // 释放运行队列的锁
}
```


#### 4.新进程第一次运行

&emsp;新进程第一次运行，是从函数ret_from_fork开始执行，ARM64的ret_from_fork函数
```c
// linux-5.10.102/arch/arm64/kernel/entry.S
    tsk   .req   x28      //当前进程的thread_info结构体的地址
SYM_CODE_START(ret_from_fork)
	bl	schedule_tail  // 为上一个进程执行清理操作
	cbz	x19, 1f  // not a kernel thread 如果寄存器x19的值是0，说明当前进程是用户进程，那么跳转到标号1
	mov	x0, x20  // 内核线程：x19存放线程函数的地址，x20存放线程函数的参数
	blr	x19  // 调用线程函数
1:	get_current_task tsk  // 用户进程：x28 = sp_el0 = 当前进程的thread_info结构体的地址
	b	ret_to_user  // 返回用户模式
SYM_CODE_END(ret_from_fork)
NOKPROBE(ret_from_fork)
```
&ensp;&emsp;copy_thread函数中，新进程是内核线程，寄存器x19存放线程函数的地址，寄存器x20存放线程函数的参数，如果新进程是用户进程，寄存器x19值是0   \
&ensp;&emsp;

```c
// linux-5.10.102/kernel/sched/core.c
asmlinkage __visible void schedule_tail(struct task_struct *prev)
	__releases(rq->lock)
{
	struct rq *rq;
	/* New tasks start with FORK_PREEMPT_COUNT, see there and
	 * finish_task_switch() for details.
	 *
	 * finish_task_switch() will drop rq->lock() and lower preempt_count
	 * and the preempt_enable() will end up enabling preemption (on
	 * PREEMPT_COUNT kernels).*/
	rq = finish_task_switch(prev);  // 为上一个进程执行清理操作2.8.6
	balance_callback(rq);  // 执行运行队列的所有负载均衡回调函数
	preempt_enable();  // 开启内核抢占

	if (current->set_child_tid)  // pthread库在调用clone()创建线程时设置了标志位CLONE_CHILD_SETTID，那么新进程把自己的进程标识符写到指定位置
		put_user(task_pid_vnr(current), current->set_child_tid);

	calculate_sigpending();
}
```


### 2.5.2 装载程序

&ensp;调度器调度新进程，新进程从函数`ret_from_fork`开始，从系统调用`fork`返回用户空间，返回值0。然后新进程使用系统调用`execve`装载程序。Linux内核练个装载程序系统调用：    \
```c
// 路径名是相对时execve解释为相对调用进程的当前工作目录
int execve(const char *filename, char *const argv[], char *const envp[]);
// 路径名是相对的，execveat解释为相对文件描述符dirfd指向的目录
// 路径名时绝对的，execveat忽略参数dirfd
int execveat(int dirfd, const char *pathname, char *const argv[], char *const envp[], int flags);
```
&ensp;&emsp;参数argv是传给新程序的参数指针数组，数组的每个元素存放一个参数字符串的地址，argv[0]应该指向要装载的程序的名称。参数envp是传给新程序的环境指针数组，数组的每个元素存放一个环境字符串的地址，环境字符串的形式是“键=值


&emsp;两个系统调用最终都调用函数do_execveat_common
![20221102001015](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221102001015.png)

&ensp;&emsp;函数do_open_execat打开可执行文件。   \
&ensp;&emsp;函数sched_exec。装载程序是实现处理器负载均衡的机会，此时进程在内存和缓存中的数据是最少的。选择负载最轻的处理器，然后唤醒当前处理器上的迁移线程，当前进程睡眠等待迁移线程把自己迁移到目标处理器      \
&ensp;&emsp;函数bprm_mm_init创建新的内存描述符，分配长度为一页的临时的用户栈，虚拟地址范围是[STACK_TOP_MAX−页长度，STACK_TOP_MAX]，bprm->p指向在栈底保留一个字长（指针长度）后的位置           \
&ensp;&emsp;函数prepare_binprm设置进程证书，然后读文件的前面128字节到缓冲区。128字节是什么？      \ 
&ensp;&emsp;依次把文件名称、环境字符串和参数字符串压到用户栈         \
![20221102001840](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221102001840.png)
&ensp;&emsp;函数exec_binprm调用函数search_binary_handler，尝试注册过的每种二进制格式的处理程序，直到某个处理程序识别正在装载的程序为止

#### 1.二进制格式
&ensp;Linux二进制格式
```c
// linux-5.10.102/include/linux/binfmts.h
struct linux_binfmt {
	struct list_head lh;
	struct module *module;
	int (*load_binary)(struct linux_binprm *);
	int (*load_shlib)(struct file *);
	int (*core_dump)(struct coredump_params *cprm);
	unsigned long min_coredump;	/* minimal dump size */
} __randomize_layout;
```
&emsp;二进制格式提供3个函数        \
&ensp;&emsp;(1)load_binary 加载普通程序       \
&ensp;&emsp;(2)load_shlib 加载共享库     \
&ensp;&emsp;(3)core_dump 在进程异常退出时生成核心转储文件，min_coredump指定核心转储文件的最小长度     \
&ensp;二进制格式使用`register_binfmt`向内核注册

#### 2.装载ELF程序
&ensp;ELF文件,ELF(Executable and Linkable Format)可执行与可链接格式 `linux-5.10.102/include/uapi/linux/elf.h`
- 目标文件(可重定位文件)，`.o`，多个模板文件链接生成可执行文件或共享库
- 可执行文件
- 共享库 `.so`
- 核心转储文件(core dump file)

&emsp;ELF文件分成4部分：`ELF首部、程序首部表(programe header table)、节(section)和节首部表(section header table)`，ELF只有首部的位置是固定的。

![20221103105503](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221103105503.png)

&ensp;&emsp;程序首部表就是段表(segment table)，`段(segment)是从运行角度描述`，`节(section)是从链接角度描述`。    \
&emsp;64位ELF文件格式


参考链接：
ELF 格式详解 https://blog.csdn.net/shanandqiu/article/details/115206426     \
ELF文件格式简介  https://blog.csdn.net/GrayOnDream/article/details/124564129


```sh
# 查看ELF首部
readelf -h <ELF文件>
# 查看程序首部表
readelf -l <ELF文件>
# 查看节首部表
readelf -S <ELF文件>
```

&emsp;ELF解析程序  \
&ensp;&emsp;`linux-5.10.102/fs/binfmt_elf.c` 解析64位ELF程序，和处理器架构无关 \
&ensp;&emsp;`linux-5.10.102/fs/compat_binfmt_elf.c`  在64位内核中解析32位ELF程序，和处理器架构无   \

&emsp;装载ELF程序函数`load_elf_binary`

![20221103112822](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221103112822.png)

&ensp;&emsp;1）检查ELF首部，检查是不是可执行文件或共享库，检查处理器架构
&ensp;&emsp;2）读取程序首部表
&ensp;&emsp;3）程序首部表中查找解释器段，如程序需要链接动态库，存在解释器段，从解释器段读取解释器的文件名称，打开文件，读取ELF首部。
&ensp;&emsp;4）检查解释器的ELF首部，读取解释器的程序首部表
&ensp;&emsp;5）flush_old_exec函数终止线程组中其他线程，释放旧的用户虚拟地址空间
&ensp;&emsp;6）setup_new_exec函数调用arch_pick_mmap_layout设置内存映射的布局，在堆和栈直接有一个内存映射区域
&ensp;&emsp;7）之前调用bprm_mm_init函数创建临时用户栈，调用set_arg_pages函数把用户栈定下来，更新用户栈标志位和访问权限，把用户栈移动到最终位置，并扩大用户栈
&ensp;&emsp;8）把可加载段映射到进程的虚拟地址空间
&ensp;&emsp;9）setbrk函数把初始化数据段映射到进程的用户虚拟地址空间，并设置堆的起始虚拟地址，调用padzero函数用零填充未初始化数据段
&ensp;&emsp;10）得到程序入口。程序有解释器段，加载段映射到进程的用户虚拟地址空间，程序入口切换为解释器程序入口
&ensp;&emsp;11）调用create_elf_tables依次把传递ELF解释器信息的辅助向量、环境指针数组envp、参数指针数组argv和参数个数argc压到进程的用户栈
&ensp;&emsp;12）调用函数start_thread设置结构体pt_regs中程序计数器和栈指针寄存器，ARM64架构定义的函数start_thread
```c
// linux-5.10.102/arch/arm64/include/asm/processor.h
static inline void start_thread_common(struct pt_regs *regs, unsigned long pc)
{
	memset(regs, 0, sizeof(*regs));
	forget_syscall(regs);
	regs->pc = pc; /* 把程序计数器设置为程序的入口 */
}

static inline void start_thread(struct pt_regs *regs, unsigned long pc,
				unsigned long sp)
{
	start_thread_common(regs, pc);
	regs->pstate = PSR_MODE_EL0t;  /* 把处理器状态设置为0，其中异常级别是0 */
	spectre_v4_enable_task_mitigation(current);
	regs->sp = sp;   /*设置用户栈指针 */
}
```

#### 3.装载脚本程序

&ensp;脚本程序前两个字节是`#!`，后面是解释器程序的名称和参数。解释器用来执行脚本程序
&emsp;`linux-5.10.102/fs/binfmt_script.c`函数`load_script`负责装载脚本程序

![20221103141127](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221103141127.png)

&ensp;&emsp;1）检查前两个字节是不是脚本程序的标识符    \
&ensp;&emsp;2）解析处解释程序的名称和参数      \
&ensp;&emsp;3）从用户栈删除第一个参数，依次把脚本程序的文件名称、传给解释程序的参数和解释程序的名称压到用户栈      \
&ensp;&emsp;4）调用opens_exec打开解释程序文件       \
&ensp;&emsp;5）调用函数prepare_binprm设置进程证书，然后读取解释程序文件的前128字节到缓冲区        \
&ensp;&emsp;6）调用函数search_binary_handler，尝试注册过的每种二进制格式的处理程序，直到某个处理程序识别解释程序为止     \



## 2.6 进程退出

&ensp;进程退出两种情况：进程主动退出和终止进程    \
&ensp;Linux内核两个主动退出的系统调用       \
```c
// 线程退出
void exit(int status);
// 一个线程组所有线程退出
void exit_group(int status);
```
&emsp;glibc库函数exit、_exit和_Exit用来使进程退出，库函数调用系统调用exit_group。库函数exit会执行进程使用的atexit和os_exit注册的函数        \
&ensp;&emsp;终止进程是退出给进程发送信号实现的，Linux讷河发送信号的系统调用
```c
//
// 发送信号给进程或进程组
int kill(pid_t pid, int sig);
// 发送信号给线程  已废弃
int tkill(int tid, int sig);
// 发送信号给线程
int tgkill(int tgid, int tid, int sig);
```
&emsp;父进程是否关注子进程退出事假，
&ensp;&emsp;1）父进程关注子进程退出事件，子进程退出时释放各种资源，留空进程描述符的僵尸进程，发送信号SIGCHLD(CHILD是child)通知父进程，父进程查询进程终止原因从子进程收回进程描述符。进程默认关注子进程退出事件，通过系统调用sigaction对信号SIGHLD设置标志SA_NOCLDWAIT(CLD是child)，子进程退出时不变成僵尸进程或设置忽略信号SIGCHLD    \
&ensp;&emsp;2）父进程不关注子进程退出事件，进程退出是释放各种资源，释放进程描述符 \
&emsp;Linux内核3个系统调用等待子进程状态改变：子进程终止、信号SIGSTOP使子进程停止执行或信号SIGCONT使子进程继续执行
```c
pid_t waitpid(pid_t pid, int *wstatus, int options);
int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options);
pit_t wiat4(pit_t pid, int *wstatus, int options, staruct usage *rusage);  // 废弃
```

&emsp;父进程退出时，给子进程寻找领养者
&ensp;&emsp;1）进程属于一个线程组，且还有其他线程，选择任意其他线程   \
&ensp;&emsp;2）选择最亲近的充当"替补领养者"的祖先进程，进程使用系统调用prtctl(PR_SET_CHILD_SUBREAPER)设置为替换领养者     \
&ensp;&emsp;3）选择所属进程号命名空间的1号进程      \
&ensp;&emsp;

### 2.6.1 线程组退出 exit_group
&emsp; 系统调用exit_group执行流程

![20221103145928](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221103145928.png)


&emsp;一个线程组的两个线程，线程1和线程2，线程1调用exit_group使线程组退出，线程1执行流程：
&emsp;1）把退出码保存在结构体成员group_exit_code中，传递给线程2    \
&emsp;2）给线程组设置正在退出标志     \
&emsp;3）向线程2发送杀死信号，唤醒线程2，线程2处理杀死信号    \
&emsp;4）线程1调用函数do_exit以退出    \
&emsp;线程2退出的执行流程，函数do_group_exit执行流程

 

![20221103151545](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221103151545.png)

&emsp;线程2可能发挥用户模式3种情况
&emsp;（1）执行完系统调用      \
&emsp;（2）被中断抢占，中断处理程序执行完    \
&emsp;（3）执行指令是生成异常，异常处理程序执行完     \

&emsp;do_exit函数执行流程
&emsp;（1）释放各种资源，把资源引用计数减一，如果引用计数变为0，则释放数据结构   \
&emsp;（2）调用函数exit_notify，为子进程选择领养者，然后把自己死讯通知父进程   \
&emsp;（3）把进程状态设置为死亡(TASK_DEAD)     \
&emsp;（4）最后一次调用函数__schedule以调度进程    \
&emsp;死亡进程调用__schedule时进程调度器处理流程
```c
// linux-5.10.102/kernel/sched/core.c
__schedule() --> context_switch() --> finish_task_switch()
static struct rq *finish_task_switch(struct task_struct *prev)
 __releases(rq->lock)
{
	…
	prev_state = prev->state;
	…
	if (unlikely(prev_state == TASK_DEAD)) {
		if (prev->sched_class->task_dead)
			prev->sched_class->task_dead(prev);  // 执行调度类task_dead
		…
		// 如果结构体thread_info放在进程描述符里面，
		// 而不是放在内核栈的顶部，那么释放进程的内核栈
		put_task_stack(prev);
		// 进程描述符的引用计数减1，如果引用计数变为0，那么释放进程描述符
		put_task_struct(prev);
	}
	…
}
```

### 2.6.2 终止进程
&emsp;系统调用kill向线程组或进程组发送信号linux-5.10.102/kernel/signal.c，执行流程
![20221103154752](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221103154752.png)

&emsp;函数__send_signal主要代码
```c
// linux-5.10.102/kernel/signal.c
static int __send_signal(int sig, struct siginfo *info, struct task_struct *t,
           int group, int from_ancestor_ns)
{
	struct sigpending *pending;
	struct sigqueue *q;
	int override_rlimit;
	int ret = 0, result;

	…
	result = TRACE_SIGNAL_IGNORED;
	// 目标线程忽略信号,不发送信号
	if (!prepare_signal(sig, t,
			from_ancestor_ns || (info == SEND_SIG_FORCED)))
		goto ret;
	// 确定把信号添加到哪个信号队列和集合
	pending = group ? &t->signal->shared_pending : &t->pending;

	result = TRACE_SIGNAL_ALREADY_PENDING;
	// 传统信号，并且信号集合已经包含同一个信号,不发送
	if (legacy_queue(pending, sig))
		goto ret;

	…
	// 判断分配信号队列节点时是否可以忽略信号队列长度的限制
	if (sig < SIGRTMIN)
		override_rlimit = (is_si_special(info) || info->si_code >= 0);
	else
		override_rlimit = 0;
	// 分配一个信号队列节点
	q = __sigqueue_alloc(sig, t, GFP_ATOMIC | __GFP_NOTRACK_FALSE_POSITIVE,
		override_rlimit);
	if (q) {
		list_add_tail(&q->list, &pending->list); // 添加到信号队列中
		…
	} else if (!is_si_special(info)) {
		…
	}

out_set:
	signalfd_notify(t, sig);
	sigaddset(&pending->signal, sig);  // 信号添加到信号集合中
	// 在线程组中查找一个没有屏蔽信号的线程，唤醒它，让它处理信号
	complete_signal(sig, t, group); 
ret:
	…
	return ret;
}
```


### 2.6.3 查询子进程终止原因

&ensp;系统调用waitid
```c
int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options);
pid_t waitpid(pid_t pid, int *wstatus, int options);
```
<table>
	<tr>
	    <th>参数</th>
	    <th>参数值</th>
	    <th>含义</th>  
	</tr >
	<tr >
	    <td rowspan="3">idtype</td>
	    <td>P_ALL</td>
	    <td>等待任意子进程，忽略参数id</td>
	</tr>
	<tr>
	    <td>P_PID</td>
	    <td>等待进程号为id的子进程</td>
	</tr>
	<tr>
	    <td>P_PGID</td>
	    <td>等待进程组标识符是id的任意子进程</td>
	</tr>
	<tr >
	    <td rowspan="5">options</td>
	    <td>WEXITED</td>
	    <td>等待退出的子进程</td>
	</tr>
	<tr>
	    <td >WSTOPPED</td>
	    <td>等待收到信号SIGSTOP并停止执行的子进程</td>
	</tr>
	<tr>
	    <td >WCONTINUED</td>
	    <td >等待收到信号SIGCONT并继续执行的子进程</td>
	</tr>
	<tr>
	    <td >WNOHANG</td>
	    <td >如果没有子进程退出，立即返回</td>
	</tr>
	<tr>
	    <td >WNOWAIT</td>
	    <td >让子进程处于僵尸状态，以后可以再次查询状态信息</td>
	</tr>
</table>

&emsp;do_wait函数执行流程

![20221103162302](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221103162302.png)




## 2.7 进程状态



<table>
	<tr>
	    <th>状态</th>
	    <th>state</th>
	    <th>含义</th>  
	</tr >
	<tr >
	    <td>就绪状态</td>
	    <td>TASK_RUNNING</td>
	    <td>正在运行队列中等待调度器调度</td>
	</tr>
	<tr>
	    <td>运行状态</td>
	    <td>TASK_RUNNING</td>
	    <td>被调度器选中，正在处理器上运行</td>
	</tr>
	<tr>
	    <td>轻度睡眠</td>
	    <td>TASK_INTERRUPTIBLE</td>
	    <td>可信号打断的睡眠状态</td>
	</tr>
	<tr >
	    <td>中度睡眠</td>
	    <td>TASK_KILLABLE</td>
	    <td>只能被致命的信号打断</td>
	</tr>
	<tr>
	    <td>深度睡眠</td>
	    <td>TASK_UNINTERRUPTIBLE</td>
	    <td>不可打断的睡眠状态</td>
	</tr>
	<tr>
	    <td>僵尸状态</td>
	    <td>TASK_DEAD</td>
	    <td>被调度器选中，正在处理器上运行</td>
	</tr>
	<tr>
	    <td>死亡状态</td>
	    <td>TASK_DEAD</td>
	    <td>如果父进程不关注子进程退出事件，那么子进程退出时自动消亡</td>
	</tr>
</table>


&emsp;进程状态变迁
![20221103163416](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221103163416.png)



## 2.8 进程调度

### 2.8.1 调度策略
&ensp;Linux内核支持的调度策略
&emsp;（1）限制进程使用限期调度策略(SCHED_DEADLINE)，3个参数：运行时间runtime，截止期限deadline和周期period    \
&emsp;（2）实时进程支持两种调度策略：先进先出调度(SCHED_FIFO)和轮流调度(SCHED_RR)   \
&emsp;（3）普通进程两种调度策略：标准轮流分时(SCHED_NORMAL)和空闲(SCHED_BATCH)，Linux内核引入完全公平调度算法后，批量调度策略废弃。     \

### 2.8.2 进程优先级

&ensp;限期进程的优先级比实时进程高，实时进程的优先级比普通进程高。  \
&ensp;限期进程的优先级是−1。        \
&ensp;实时进程的实时优先级是1～99，优先级数值越大，表示优先级越高。    \
&ensp;普通进程的静态优先级是100～139，优先级数值越小，表示优先级越高，可通过修改nice值（即相对优先级，取值范围是−20～19）改变普通进程的优先级，优先级等于120加上nice值   \
&emsp;task_struct中，4个成员和优先级有关   \
```c
include/linux/sched.h
struct task_struct {
	…
	int                  prio;
	int                  static_prio;
	int                  normal_prio;
	unsigned int         rt_priority;
	…
};
```



<table>
	<tr>
	    <th>优先级</th>
	    <th>限期进程</th>
	    <th>实时进程</th>  
	    <th>普通进程</th>  
	</tr >
	<tr >
	    <td>prio<br>调度优先级(数值越小，表示优先级越高)</td>
	    <td colspan="3">大多数prio等于normal_prio</td>
	</tr>
	<tr>
	    <td>static_prio<br>静态优先级</td>
	    <td>总是0</td>
	    <td>总是0</td>
	    <td>120 + nice值数值越小，<br>表示优先级越高</td>
	</tr>
	<tr>
	    <td>normal_prio<br>正常优先级(数值越小，表示优先级越高)</td>
	    <td>-1</td>
	    <td>99 − rt_priority</td>
	    <td>static_prio</td>
	</tr>
		<tr>
	    <td>实时优先级</td>
	    <td>总是0</td>
	    <td>值越大，优先级越高</td>
	    <td> </td>
	</tr>
</table>















