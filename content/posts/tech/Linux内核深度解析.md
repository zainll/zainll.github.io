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
&emsp;和虚拟机相比，容器是一种轻量级的虚拟化技术，直接使用宿主机的内核，使用命名空间隔离资源,容器仅仅是通过命名空间隔离？  \


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


### 2.8.3 调度类
&ensp;Linux内核抽象一个调度类`sched_class`，目前实现5种调度类，优先级从上到下从高到低：

<table>
	<tr>
	    <th>调度类</th>
	    <th>调度策略</th>
	    <th>调度算法</th>  
	    <th>调度对象</th>  
	</tr >
	<tr >
	    <td>停机调度类<br>stop_sched_class</td>
	    <td>无</td>
	    <td>无</td>
	    <td>停机进程</td>
	</tr>
	<tr>
	    <td>限期调度类<br>dl_sched_class</td>
	    <td>SCHED_DEADLINE</td>
	    <td>最早期限优先</td>
	    <td>限期进程</td>
	</tr>
	<tr>
	    <td>实时调度类<br>rt_sched_class</td>
	    <td>SCHED_FIFO<br>SCHED_RR</td>
	    <td>先进先出<br>轮流调度</td>
	    <td>实时进程</td>
	</tr>
		<tr>
	    <td>公平调度类<br>cfs_sched_class</td>
	    <td>SCHED_NORMAL<br>SCHED_IDIE</td>
	    <td>完全公平调度算法</td>
	    <td>普通进程</td>
	</tr>
	</tr>
		<tr>
	    <td>空闲调度类<br>idle_sched_class</td>
	    <td>无</td>
	    <td>无</td>
	    <td>每个处理器上的空闲线程</td>
	</tr>
</table>


&emsp;详细信息参考书籍      


### 2.8.4 运行队列

&ensp;每个处理器有一个运行队列，结构体rq，定义全局变量
```c
// linux-5.10.102/kernel/sched/cpuacct.c
DEFINE_PER_CPU_SHARED_ALIGNED(struct rq, runqueues);
// linux-5.10.102/kernel/sched/sched.h  
struct rq { // 运行队列
	...
	struct cfs_rq		cfs;  // 公平运行队列
	struct rt_rq		rt;   // 实时运行队列
	struct dl_rq		dl;   // 限期运行队列
	...
	struct task_struct	*idle;  // 空闲线程
	struct task_struct	*stop;  // 迁移线程
};
```

### 2.8.5 任务分组
#### 1.任务分组方式
<table>
	<tr>
	    <th>任务分组方式</th>
	    <th>控制宏</th>
	    <th>配置方式</th>  
	</tr >
	<tr >
	    <td>自动组</td>
	    <td>CONFIG_SCHED_AUTOGROUP</td>
	    <td>/proc/sys/kernel/sched_autogroup_enabled <br>运行过程中开启关闭，默认值1<br>源文件kernel/sched/auto_group.c</td>
	</tr>
	<tr>
	    <td>CPU控制组版本1</td>
	    <td>CONFIG_CGROUPS<br>CONFIG_CGROUP_SCHED</td>
	    <td>mount -t tmpfs cgroup_root /sys/fs/cgroup<br>mkdir /sys/fs/cgroup/cpu<br>mount -t cgroup -o cpu none /sys/fs/cgroup/cpu<br>cd /sys/fs/cgroup/cpu<br>mkdir multimedia  # 创建"multimedia"任务组<br>mkdir browser     # 创建"browser"任务组<br>echo 2048 > multimedia/cpu.shares<br>echo 1024 > browser/cpu.shares<br>echo < pid1> > browser/tasks <br>echo < pid2> > multimedia/tasks<br>echo < pid1> > browser/cgroup.procs<br>echo < pid2> > multimedia/cgroup.procs</td>
	</tr>
	<tr>
	    <td>cgroup版本2</td>
	    <td> </td>
	    <td>mount -t tmpfs cgroup_root /sys/fs/cgroup<br>mount -t cgroup2  none /sys/fs/cgroup<br>cd /sys/fs/cgroup <br>
echo "+cpu" > cgroup.subtree_control<br>mkdir multimedia   # 创建"multimedia"任务组 <br>mkdir browser      # 创建"browser"任务组<br>echo 2048 > multimedia/cpu.weight<br>echo 1024 > browser/cpu.weight<br>echo < pid1> > browser/cgroup.procs<br>echo < pid2> > multimedia/cgroup.procs <br>echo threaded > browser/cgroup.type <br> echo < pid1> > browser/cgroup.threads <br>echo threaded > multimedia/cgroup.type <br>echo < pid2> > multimedia/cgroup.threads
</td>
	</tr>
</table>


#### 2. 数据结构

&ensp;task_group,默认任务组是更任务组(全局变量root_task_group)


<table>
	<tr>
	    <th>成员</th>
	    <th>说明</th>
	</tr >
	<tr >
	    <td>const struct sched_class *sched_class</td>
	    <td>调度类</td>
	</tr>
	<tr >
	    <td>struct sched_entity se</td>
	    <td>公平调度实体</td>
	</tr>
		<tr >
	    <td>struct sched_dl_entity dl</td>
	    <td>限期调度实体</td>
	</tr>
</table>

&emsp;任务组在每个处理器上有公平调度实体、公平运行队列、实时调度实体和实时运行队列，根任务组比较特殊：没有公平调度实体和实时调度实体

![20221104104612](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221104104612.png)


&ensp;每个处理器上，计算任务组的公平调度实体的权重的方法如下（参考源文件“kernel/ sched/fair.c”中的函数update_cfs_shares







### 2.8.6 调度进程

&ensp;调度进程的核心函数是`__schedule()`
```c
kernel/sched/core.c
// preempt是否抢占，true抢占调度，false主动调度
static void __sched notrace __schedule(bool preempt)
{
	1. 调用pick_next_task选择下一个进程
	2. 调用context_switch切换进程
}
```
#### 1.选择下一个进程 函数pick_next_task
```c
// linux-5.10.102/kernel/sched/core.c
static inline struct task_struct *
pick_next_task(struct rq *rq, struct task_struct *prev, struct rq_flags *rf)
{
	const struct sched_class *class;
	struct task_struct *p;

	
	/* Optimization: we know that if all tasks are in the fair class we can
	 * call that function directly, but only if the @prev task wasn't of a
	 * higher scheduling class, because otherwise those loose the
	 * opportunity to pull in more work from other CPUs.*/
	// 优化：如果所有进程属于公平调度类
	// 直接调用公平调度类的pick_next_task方法
	if (likely(prev->sched_class <= &fair_sched_class &&
		   rq->nr_running == rq->cfs.h_nr_running)) {

		p = pick_next_task_fair(rq, prev, rf);
		if (unlikely(p == RETRY_TASK))
			goto restart;

		/* Assumes fair_sched_class->next == idle_sched_class */
		// 假定公平调度类的下一个调度类是空闲调度类
		if (!p) {
			put_prev_task(rq, prev);
			p = pick_next_task_idle(rq);
		}

		return p;
	}

restart:
	put_prev_task_balance(rq, prev, rf);

	for_each_class(class) {
		p = class->pick_next_task(rq);
		if (p)
			return p;
	}

	/* The idle class should always have a runnable task: */
	// 空闲调度类应该总是有一个运行的进程
	BUG();
}
```

> 待补充


#### 2.切换进程 context_switch

> 1）switch_mm_irqs_off负责切换进程的用户虚拟地址空间
> 2）switch_to切换处理器的寄存器

```c
// linux-5.10.102/kernel/sched/core.c
static __always_inline struct rq *
context_switch(struct rq *rq, struct task_struct *prev,
	       struct task_struct *next, struct rq_flags *rf)
{
	prepare_task_switch(rq, prev, next); // 准备工作，调用prepare_arch_switch

	
	/* For paravirt, this is coupled with an exit in switch_to to
	 * combine the page table reload and the switch backend into
	 * one hypercall. */
	// 开始上下文切换
	arch_start_context_switch(prev);

	/*
	 * kernel -> kernel   lazy + transfer active
	 *   user -> kernel   lazy + mmgrab() active
	 *
	 * kernel ->   user   switch + mmdrop() active
	 *   user ->   user   switch
	 */
	if (!next->mm) {                 // to kernel
		// 通知处理器架构不需要切换用户虚拟地址空间，加速进程切换的技术称为惰性TLB
		enter_lazy_tlb(prev->active_mm, next);

		next->active_mm = prev->active_mm;
		if (prev->mm)     // from user 切换进程的用户虚拟地址空间
			mmgrab(prev->active_mm);
		else
			prev->active_mm = NULL;
	} else {                                        // to user
		membarrier_switch_mm(rq, prev->active_mm, next->mm);
		/*
		 * sys_membarrier() requires an smp_mb() between setting
		 * rq->curr / membarrier_switch_mm() and returning to userspace.
		 *
		 * The below provides this either through switch_mm(), or in
		 * case 'prev->active_mm == next->mm' through
		 * finish_task_switch()'s mmdrop().
		 */
		switch_mm_irqs_off(prev->active_mm, next->mm, next);

		if (!prev->mm) {                        // from kernel
			/* will mmdrop() in finish_task_switch(). */
			rq->prev_mm = prev->active_mm;
			prev->active_mm = NULL;
		}
	}

	rq->clock_update_flags &= ~(RQCF_ACT_SKIP|RQCF_REQ_SKIP);

	prepare_lock_switch(rq, next, rf);

	/* Here we just switch the register state and the stack. */
	// 只切换寄存器状态和栈
	switch_to(prev, next, prev);
	barrier();

	return finish_task_switch(prev);
}
```
&ensp;（1）切换用户虚拟地址空间。
```c
// ARM64架构使用switch_mm_irqs_off
include/linux/mmu_context.h
#ifndef switch_mm_irqs_off
#define switch_mm_irqs_off switch_mm
#endif
```
&ensp; switch_mm函数
```c
// linux-5.10.102/arch/arm64/include/asm/mmu_context.h
static inline void
switch_mm(struct mm_struct *prev, struct mm_struct *next,
	  struct task_struct *tsk)
{
	if (prev != next)
		__switch_mm(next);

	/* Update the saved TTBR0_EL1 of the scheduled-in task as the previous
	 * value may have not been initialised yet (activate_mm caller) or the
	 * ASID has changed since the last run (following the context switch
	 * of another thread of the same process).*/
	/* 更新调入进程保存的寄存器TTBR0_EL1值，
    * 因为可能还没有初始化（调用者是函数activate_mm），
    * 或者ASID自从上次运行以来已经改变（在同一个线程组的另一个线程切换上下文以后）
    * 避免把保留的寄存器TTBR0_EL1值设置为swapper_pg_dir（init_mm；例如通过函数idle_task_exit）*/
	update_saved_ttbr0(tsk, next);
}

static inline void __switch_mm(struct mm_struct *next)
{
	/*init_mm.pgd does not contain any user mappings and it is always
	 * active for kernel addresses in TTBR1. Just set the reserved TTBR0.*/
	/*init_mm.pgd没有包含任何用户虚拟地址的映射，对于TTBR1的内核虚拟地址总是有效的。
    * 只设置保留的TTBR0 */
	if (next == &init_mm) {
		cpu_set_reserved_ttbr0();
		return;
	}
	// 为进程分配地址空间标识符
	check_and_switch_context(next);
}
```

> 待补充


&ensp;（2）切换寄存器
```c
// linux-5.10.102/include/asm-generic/switch_to.h
#define switch_to(prev, next, last)					\
	do {								\
		((last) = __switch_to((prev), (next)));			\
	} while (0)

```
&emsp;函数__switch_to
```c
__notrace_funcgraph struct task_struct *__switch_to(struct task_struct *prev,
				struct task_struct *next)
{
	struct task_struct *last;

	fpsimd_thread_switch(next);  // 切换浮点寄存器
	tls_thread_switch(next);  // 切换本地存储相关的寄存器
	hw_breakpoint_thread_switch(next);  // 切换吊事寄存器
	contextidr_thread_switch(next);  // 把上下文标识符寄存器CONTEXTIDR_EL1设置为下一个进程号
	entry_task_switch(next);  // 使用处理器变量__entry_task记录下一个进程描述符的地址
	uao_thread_switch(next);  // 根据下一个进程可访问的虚拟地址空间上限恢复用户访问覆盖（User Access Override，UAO）状态
	ssbs_thread_switch(next);  // 
	erratum_1418040_thread_switch(next);

	
	/* Complete any pending TLB or cache maintenance on this CPU in case
	 * the thread migrates to a different CPU.
	 * This full barrier is also required by the membarrier system
	 * call.*/
	// 在这个处理器上执行完前面的所有页表缓存或者缓存维护操作
	// 以防线程迁移到其他处理器
	// 数据同步屏障，确保屏障前面的缓存维护操作和页表缓存维护操作执行完
	dsb(ish);

	
	/* MTE thread switching must happen after the DSB above to ensure that
	 * any asynchronous tag check faults have been logged in the TFSR*_EL1
	 * registers.*/ 
	mte_thread_switch(next);

	/* the actual thread switch */
	// 实际线程切换  切换通用寄存器
	last = cpu_switch_to(prev, next);

	return last;
}
```


&ensp;1）切换浮点寄存器，函数fpsimd_thread_switch负责切换浮点，内核不允许使用浮点数，只有用户空间可以使用浮点数,切换出去的进程把浮点寄存器的值保存在进程描述符的成员thread.fpsimd_state中。ARM64架构实现的linux-5.10.102/arch/arm64/kernel/fpsimd.c函数fpsimd_thread_switch   \ 
&ensp;2）切换通用寄存器，
- 被调用函数负责保存的寄存器x19～x28
- 寄存器x29，即帧指针（Frame Pointer，FP）寄存器
- 栈指针（Stack Pointer，SP）寄存器
- 寄存器x30，即链接寄存器（Link Register，LR），它存放函数的返回地址
- 用户栈指针寄存器SP_EL0，内核使用它存放当前进程的进程描述符的第一个成员thread_info的地址


&ensp;&emsp;cpu_switch_to有两个参数：寄存器x0存放上一个进程的进程描述符的地址，寄存器x1存放下一个进程的进程描述符的地址
```c
// linux-5.10.102/arch/arm64/kernel/entry.S
SYM_FUNC_START(cpu_switch_to)
	mov	x10, #THREAD_CPU_CONTEXT  // cpu_switch_to有两个参数：寄存器x0存放上一个进程的进程描述符的地址，寄存器x1存放下一个进程的进程描述符的地址
	add	x8, x0, x10  // x8存放上一个进程的进程描述符的成员thread.cpu_context的地址
	mov	x9, sp  // x9保存栈指针
	stp	x19, x20, [x8], #16		// store callee-saved registers
	stp	x21, x22, [x8], #16  // 把上一个进程的寄存器x19～x28、x29、SP和LR
	stp	x23, x24, [x8], #16  // 保存到上一个进程的进程描述符的成员thread.cpu_context中
	stp	x25, x26, [x8], #16  // 
	stp	x27, x28, [x8], #16
	stp	x29, x9, [x8], #16  
	str	lr, [x8]  // LR存放函数的返回地址
	add	x8, x1, x10  // x8存放下一个进程的进程描述符的成员thread.cpu_context的地址
	ldp	x19, x20, [x8], #16		// restore callee-saved registers
	ldp	x21, x22, [x8], #16  // 使用下一个进程的进程描述符的成员thread.cpu_context
	ldp	x23, x24, [x8], #16  // 保存的值恢复下一个进程的寄存器x19～x28、x29、SP和LR
	ldp	x25, x26, [x8], #16
	ldp	x27, x28, [x8], #16
	ldp	x29, x9, [x8], #16
	ldr	lr, [x8]
	mov	sp, x9
	msr	sp_el0, x1  // 用户栈指针寄存器SP_EL0设置为下一个进程的进程描述符的第一个成员thread_info的地址
	ptrauth_keys_install_kernel x1, x8, x9, x10
	scs_save x0, x8  // 函数返回，返回值是寄存器x0的值：上一个进程的进程描述符的地址
	scs_load x1, x8
	ret
SYM_FUNC_END(cpu_switch_to)
NOKPROBE(cpu_switch_to)
```
&ensp;&emsp;cpu_switch_to切换通用寄存器的过程，从进程prev切换到进程next。进程prev把通用寄存器的值保存在进程描述符的成员thread.cpu_context中，然后进程next从进程描述符的成员thread.cpu_context恢复通用寄存器的值，使用用户栈指针寄存器SP_EL0存放进程next的进程描述符的成员thread_info的地址    \


<center>ARM64架构切换通用寄存器</center>

![2022-11-05_21-28](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/2022-11-05_21-28.png)

&emsp;链接寄存器存放函数的返回地址，函数cpu_switch_to把链接寄存器设置为进程描述符的成员thread.cpu_context.pc，进程被调度后从返回地址开始执行   \
进程的返回地址分为以下两种情况:
- 创建的新进程，函数copy_thread把进程描述符的成员thread.cpu_context.pc设置为函数ret_from_fork的地址
- 其他情况，返回地址是函数context_switch中调用函数cpu_switch_to之后的一行代码：“last = 函数cpu_switch_to的返回值”，返回地址记录在进程描述符的成员thread.cpu_context.pc中





&ensp;（3）清理工作
&ensp;&emsp;函数finish_task_switch在从进程prev切换到进程next后为进程prev执行清理工作
```c
// kernel/sched/core.c
static struct rq *finish_task_switch(struct task_struct *prev)
	__releases(rq->lock)
{
	struct rq *rq = this_rq();  // rq是当前处理器的运行队列
	struct mm_struct *mm = rq->prev_mm;
	long prev_state;

	/*  The previous task will have left us with a preempt_count of 2
	 * because it left us after:
	 *	schedule()
	 *	  preempt_disable();			// 1
	 *	  __schedule()
	 *	    raw_spin_lock_irq(&rq->lock)	// 2
	 * Also, see FORK_PREEMPT_COUNT.*/
	if (WARN_ONCE(preempt_count() != 2*PREEMPT_DISABLE_OFFSET,
		      "corrupted preempt_count: %s/%d/0x%x\n",
		      current->comm, current->pid, preempt_count()))
		preempt_count_set(FORK_PREEMPT_COUNT);

	rq->prev_mm = NULL;

	
	/* A task struct has one reference for the use as "current".
	 * If a task dies, then it sets TASK_DEAD in tsk->state and calls
	 * schedule one last time. The schedule call will never return, and
	 * the scheduled task must drop that reference.
	 *
	 * We must observe prev->state before clearing prev->on_cpu (in
	 * finish_task), otherwise a concurrent wakeup can get prev
	 * running on another CPU and we could rave with its RUNNING -> DEAD
	 * transition, resulting in a double drop.*/
	prev_state = prev->state;
	vtime_task_switch(prev);  // 计算进程prev的时间统计
	perf_event_task_sched_in(prev, current);
	finish_task(prev);
	// 把prev->on_cpu设置为0，表示进程prev没有在处理器上运行；然后释放运行队列的锁，开启硬中断
	finish_lock_switch(rq); 
	finish_arch_post_lock_switch(); // 执行处理器架构特定的清理工作,ARM64为空
	kcov_finish_switch(current);

	fire_sched_in_preempt_notifiers(current);
	
	/* When switching through a kernel thread, the loop in
	 * membarrier_{private,global}_expedited() may have observed that
	 * kernel thread and not issued an IPI. It is therefore possible to
	 * schedule between user->kernel->user threads without passing though
	 * switch_mm(). Membarrier requires a barrier after storing to
	 * rq->curr, before returning to userspace, so provide them here:
	 *
	 * - a full memory barrier for {PRIVATE,GLOBAL}_EXPEDITED, implicitly
	 *   provided by mmdrop(),
	 * - a sync_core for SYNC_CORE.*/
	if (mm) {
		membarrier_mm_sync_core_before_usermode(mm);
		mmdrop(mm);
	}
	if (unlikely(prev_state == TASK_DEAD)) { // 进程主动退出或者被终止
		if (prev->sched_class->task_dead)
			prev->sched_class->task_dead(prev); // 所属调度类的task_dead方法

		/* * Remove function-return probe instances associated with this
		 * task and put them back on the free list.*/
		kprobe_flush_task(prev);

		/* Task is done with its stack. */
		/*释放进程的内核栈 */
		put_task_stack(prev);
		// 把进程描述符的引用计数减1，如果引用计数变为0，那么释放进程描述符
		put_task_struct_rcu_user(prev);
	}

	tick_nohz_task_switch();
	return rq;
}
```


### 2.8.7 调度时机

> 调度进程的时机: \
> （1）进程主动调用`schedule()`函数
> （2）周期性地调度，抢占当前进程，强迫当前进程让出处理器
> （3）唤醒进程的时候，被唤醒的进程可能抢占当前进程
> （4）创建新进程的时候，新进程可能抢占当前进程。


#### 1.主动调度
&ensp;内核中3种主动调度方式：
&emsp;（1）直接调用`schedule()`函数来调度进程
&emsp;（2）调用有条件重调度函数cond_resched()。非抢占式内核中，函数cond_resched()判断当前进程是否设置了需要重新调度的标志，如果设置了，就调度进程；抢占式内核中，cond_resched()为空
&emsp;（3）如果需要等待某个资源，例如互斥锁或信号量，那么把进程的状态设置为睡眠状态，然后调用schedule()函数以调度进程



#### 2.周期调度
&emsp;周期调度的函数是scheduler_tick()，它调用当前进程所属调度类的task_tick方法。
&ensp;（1）限期调度类的周期调度   \
&emsp;task_tick --> task_tick_dl --> update_curr_dl
```c
// kernel/sched/deadline.c
static void update_curr_dl(struct rq *rq)
{
	struct task_struct *curr = rq->curr;
	struct sched_dl_entity *dl_se = &curr->dl;
	u64 delta_exec, scaled_delta_exec;
	...
	delta_exec = now - curr->se.exec_start;
	if (unlikely((s64)delta_exec <= 0)) {
		if (unlikely(dl_se->dl_yielded))
			goto throttle;
		return;
	}

	...
	dl_se->runtime -= scaled_delta_exec; // 计算限期进程的剩余运行时间

throttle:
	// // 如果限期进程用完了运行时间或者主动让出处理器
	if (dl_runtime_exceeded(dl_se) || dl_se->dl_yielded) { 
		dl_se->dl_throttled = 1;  // 设置节流标志

		/* If requested, inform the user about runtime overruns. */
		if (dl_runtime_exceeded(dl_se) &&
		    (dl_se->flags & SCHED_FLAG_DL_OVERRUN))
			dl_se->dl_overrun = 1;

		__dequeue_task_dl(rq, curr, 0);
		if (unlikely(is_dl_boosted(dl_se) || !start_dl_timer(curr)))
			enqueue_task_dl(rq, curr, ENQUEUE_REPLENISH);

		if (!is_leftmost(curr, &rq->dl))
			resched_curr(rq);
	}

	...
}
```

&ensp;（2）实时调度类的周期调度   \

&emsp;实时调度类的task_tick方法是函数task_tick_rt
```c
// linux-5.10.102/kernel/sched/rt.c
static void task_tick_rt(struct rq *rq, struct task_struct *p, int queued)
{
	struct sched_rt_entity *rt_se = &p->rt;

	...
	if (p->policy != SCHED_RR) // 调度策略不是轮流调度
		return;
    // 把时间片减一，如果没用完时间片，那么返回
	if (--p->rt.time_slice)
		return;
	// 用完了时间片，那么重新分配时间片
	p->rt.time_slice = sched_rr_timeslice;

	/* Requeue to the end of queue if we (and all of our ancestors) are not
	 * the only element on the queue */
	for_each_sched_rt_entity(rt_se) {
		if (rt_se->run_list.prev != rt_se->run_list.next) {
			requeue_task_rt(rq, p, 0);
			resched_curr(rq);
			return;
		}
	}
}
```






&ensp;（3）公平调度类的周期调度     \
&emsp;公平调度类的task_tick方法是函数task_tick_fair
```c
// kernel/sched/fair.c
static void task_tick_fair(struct rq *rq, struct task_struct *curr, int queued)
{
	struct cfs_rq *cfs_rq;
	struct sched_entity *se = &curr->se;

	for_each_sched_entity(se) {
		cfs_rq = cfs_rq_of(se);
		entity_tick(cfs_rq, se, queued);
	}

	...
}

// kernel/sched/fair.c
static void
entity_tick(struct cfs_rq *cfs_rq, struct sched_entity *curr, int queued)
{
	...
	if (cfs_rq->nr_running > 1) // 公平运行队列的进程数量超过1
		check_preempt_tick(cfs_rq, curr);
}


```


```c
// kernel/sched/fair.c
static void
check_preempt_tick(struct cfs_rq *cfs_rq, struct sched_entity *curr)
{
	unsigned long ideal_runtime, delta_exec;
	struct sched_entity *se;
	s64 delta;

	ideal_runtime = sched_slice(cfs_rq, curr);
	delta_exec = curr->sum_exec_runtime - curr->prev_sum_exec_runtime;
	if (delta_exec > ideal_runtime) {
		resched_curr(rq_of(cfs_rq));
		/* The current task ran long enough, ensure it doesn't get
		 * re-elected due to buddy favours.*/
		clear_buddies(cfs_rq, curr);
		return;
	}

	
	/* Ensure that a task that missed wakeup preemption by a
	 * narrow margin doesn't have to wait for a full slice.
	 * This also mitigates buddy induced latencies under load.*/
	if (delta_exec < sysctl_sched_min_granularity)
		return;

	se = __pick_first_entity(cfs_rq);
	delta = curr->vruntime - se->vruntime;

	if (delta < 0)
		return;

	if (delta > ideal_runtime)
		resched_curr(rq_of(cfs_rq));
}
```



&ensp;（4）中断返回时调度。
&emsp;ARM64架构的中断处理程序的入口是e10_irq，中断处理程序执行完以后，跳转到标号ret_to_user以返回用户模式。标号ret_to_user判断当前进程的进程描述符的成员thread_info.flags有没有设置标志位集合_TIF_WORK_MASK中的任何一个标志位，如果设置了其中一个标志位，那么跳转到标号work_pending，标号work_pending调用函数do_notify_resume

```c
// arch/arm64/kernel/entry.S  5.10.102 代码中没有？
ret_to_user:
     disable_irq                   // 禁止中断
     ldr  x1, [tsk, #TSK_TI_FLAGS]
     and  x2, x1, #_TIF_WORK_MASK
     cbnz x2, work_pending
finish_ret_to_user:
     enable_step_tsk x1, x2
     kernel_exit 0
ENDPROC(ret_to_user)

work_pending:
     mov  x0, sp
     /*
      * 寄存器x0存放第一个参数regs
      * 寄存器x1存放第二个参数task_struct.thread_info.flags
      */
     bl  do_notify_resume
#ifdef CONFIG_TRACE_IRQFLAGS
     bl  trace_hardirqs_on         // 在用户空间执行时开启中断
#endif
     ldr x1, [tsk, #TSK_TI_FLAGS]  // 重新检查单步执行
     b   finish_ret_to_user


```
&emsp;函数do_notify_resume判断当前进程的进程描述符的成员thread_info.flags有没有设置需要重新调度的标志位_TIF_NEED_RESCHED，如果设置了，那么调用函数schedule()以调度进程。


```c
// arch/arm64/kernel/signal.c
asmlinkage void do_notify_resume(struct pt_regs *regs,
                         unsigned int thread_flags)
{
    ...
    do {
        if (thread_flags & _TIF_NEED_RESCHED) {
             schedule();
        } else {
             …
        }

        local_irq_disable();
        thread_flags = READ_ONCE(current_thread_info()->flags);
    } while (thread_flags & _TIF_WORK_MASK);
}

```


#### 3.唤醒进程时抢占

&emsp;唤醒进程的时候，被唤醒的进程可能抢占当前进程
<center>唤醒进程时抢占</center>

![20221106214732](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221106214732.png)

&ensp;（1）如果被唤醒的进程和当前进程属于相同的调度类，那么调用调度类的check_preempt_curr方法以检查是否可以抢占当前进程   \
&ensp;（2）如果被唤醒的进程所属调度类的优先级高于当前进程所属调度类的优先级，那么给当前进程设置需要重新调度的标志


<table>
	<tr>
	    <th>调度类</th>
	    <th>check_preempt_curr方法是函数</th>
	    <th>算法</th>  
	</tr >
	<tr >
	    <td>停机调度类</td>
	    <td>check_preempt_curr_stop</td>
	    <td>空函数</td>
	</tr>
	<tr >
	    <td>限期调度类</td>
	    <td>check_preempt_curr_dl</td>
	    <td>如果被唤醒的进程的绝对截止期限比当前进程的绝对截止期限小，那么给当前进程设置需要重新调度的标志</td>
	</tr>
	<tr >
	    <td>实时调度类</td>
	    <td>check_preempt_curr_rt</td>
	    <td>优先级比当前进程的优先级高，那么给当前进程设置需要重新调度的标志</td>
	</tr>
	<tr >
	    <td>公平调度类</td>
	    <td>check_preempt_wakeup</td>
	    <td></td>
	</tr>
	<tr >
	    <td>空闲调度类</td>
	    <td>check_preempt_curr_idle</td>
	    <td>无条件抢占，给当前进程设置需要重新调度的标志</td>
	</tr>
</table>

&emsp;check_preempt_wakeup函数
```c
// linux-5.10.102/kernel/sched/fair.c
static void check_preempt_wakeup(struct rq *rq, struct task_struct *p, int wake_flags)
{
	// 当前进程的调度策略是SCHED_IDLE，被唤醒的进程的调度策略是SCHED_NORMAL或者SCHED_BATCH，那么允许抢占，给当前进程设置需要重新调度的标志
	struct task_struct *curr = rq->curr;
	struct sched_entity *se = &curr->se, *pse = &p->se;
	...
	if (unlikely(task_has_idle_policy(curr)) &&
	    likely(!task_has_idle_policy(p)))
		goto preempt;

	if (unlikely(p->policy != SCHED_NORMAL) || !sched_feat(WAKEUP_PREEMPTION))
		return;
	// 为当前进程和被唤醒的进程找到两个兄弟调度实体
	find_matching_se(&se, &pse);
	update_curr(cfs_rq_of(se));
	BUG_ON(!pse);
	if (wakeup_preempt_entity(se, pse) == 1) { // 判断是否可以抢占
		// 允许抢占，给当前进程设置需要重新调度的标志
		...
		goto preempt;
	}

	return;

preempt:
	resched_curr(rq);
	...
}

static int
wakeup_preempt_entity(struct sched_entity *curr, struct sched_entity *se)
{
	s64 gran, vdiff = curr->vruntime - se->vruntime;

	if (vdiff <= 0)
		return -1;

	gran = wakeup_gran(se);
	if (vdiff > gran)
		return 1;

	return 0;
}
```


#### 4.创建新进程时抢占
&emsp;使用系统调用fork、clone和 vfork创建新进程使，新进程可抢占当前进程；使用韩式kernel_thread创建新的内核线程是，新内核线程可抢占当前进程
![20221106220629](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221106220629.png)


#### 5.内核抢占
&emsp;内核抢占是指当进程在内核模式下运行的时候可以被其他进程抢占，需要打开配置宏CONFIG_PREEMPT。抢占式内核和非抢占式内核。进程tthread_info结构体一个类型为int的成员preempt_count为抢占计数器。


> 待补充

#### 6.高精度调度时钟

&emsp;高精度时钟的精度是纳秒,需要通过配置宏启用。


### 2.8.8 带宽管理

&emsp;调度类管理进程占用的处理器带宽的方法
#### 1.限期调度类的带框管理
&emsp;每个限期进程有自己的带宽，内核把限期进程的运行时间统计到根实时任务组的运行时间里面了，限期进程共享实时进程的带宽
```c
// kernel/sched/deadline.c
static void update_curr_dl(struct rq *rq)
{
      …
      if (rt_bandwidth_enabled()) {
            struct rt_rq *rt_rq = &rq->rt;

            raw_spin_lock(&rt_rq->rt_runtime_lock);
            if (sched_rt_bandwidth_account(rt_rq))
                  rt_rq->rt_time += delta_exec;
            raw_spin_unlock(&rt_rq->rt_runtime_lock);
      }
}
```

#### 2.实时调度类的带宽管理
&ensp;指定实时进程的带宽有以下两种方式
&ensp;（1）指定全局带宽：带宽包含的两个参数是周期和运行时间，即指定在每个周期内所有实时进程的运行时间总和。   \
&emsp;默认的周期是1秒，默认的运行时间是0.95秒。可以借助文件“/proc/sys/kernel/sched_rt_period_us”设置周期，借助文件“/proc/sys/kernel/sched_rt_runtime_us”设置运行时间        \
&emsp;配置宏CONFIG_RT_GROUP_SCHED，即支持实时任务组，那么全局带宽指定了所有实时任务组的总带宽
&ensp;（2）指定每个实时任务组的带宽：在每个指定的周期，允许一个实时任务组最多执行长时间。当实时任务组在一个周期用完了带宽时，这个任务组将会被节流，不允许继续运行，直到下一个周期。可以使用cgroup设置一个实时任务组的周期和运行时间，cgroup版本1的配置方法如下


<details>
<summary>cgroup版本1的配置方法</summary>
<br>
1）cpu.rt_period_us：周期，默认值是1秒。   <br>
2）cpu.rt_runtime_us：运行时间，默认值是0，把运行时间设置为非零值以后才允许把实时进程加入任务组，设置为−1表示没有带宽限制。
cgroup版本1的配置示例如下。 <br>
1）挂载cgroup文件系统，把CPU控制器关联到控制组层级树。   <br>
mount -t cgroup -o cpu none /sys/fs/cgroup/cpu      <br>
2）创建一个任务组。     <br>
cd /sys/fs/cgroup/cpu      <br>
mkdir browser   # 创建"browser"任务组       <br>
3）把实时运行时间设置为10毫秒。         <br>
echo 10000 > browser/cpu.rt_runtime_us      <br>
4）把一个实时进程加入任务组。         <br>
echo <pid> > browser/cgroup.procs      <br>
</details>

&ensp;cgroup版本2从内核4.15版本开始支持CPU控制器，暂时不支持实时进程。

&emsp;一个处理器用完了实时运行时间，可以从其他处理器借用实时运行时间，称为实时运行时间共享，对应调度特性RT_RUNTIME_SHARE，默认开启。
```c
kernel/sched/features.h
SCHED_FEAT(RT_RUNTIME_SHARE, true)
```
实时任务组的带宽存放在结构体task_group的成员rt_bandwidth中：

```c
// kernel/sched/sched.h
struct task_group {
     …
#ifdef CONFIG_RT_GROUP_SCHED
     …
     struct rt_bandwidth rt_bandwidth;
#endif
     …
};
```
&emsp;节流
> 书中详细解释


#### 3.公平调度类的带宽管理
&emsp;使用周期和限额指定一个公平任务组的带宽    \
&emsp;使用cgroup设置一个公平任务组的周期和限额，cgroup版本1的配置  \
<details>
<summary>cgroup版本1的配置方法</summary>
</details>
&emsp;cgroup版本2的配置示例  \
<details>
<summary>cgroup版本2的配置方法</summary>
</details>

&ensp;（1）节流：在以下两种情况下，调度器会检查公平运行队列是否用完运行时间。
&emsp;1）put_prev_task_fair：调度器把当前正在运行的普通进程放回公平运行队列。
&emsp;2）pick_next_task_fair：当前正在运行的进程属于公平调度类，调度器选择下一个普通进程。

![20221106231743](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221106231743.png)




&ensp;（2）周期定时器：在每个周期的开始，重新填充任务组的带宽，把带宽分配给节流的公平运行队列。周期定时器的处理函数是sched_cfs_period_timer，它把主要工作委托给函数do_sched_cfs_period_timer

![20221106232422](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221106232422.png)

```c
// kernel/sched/fair.c
static int do_sched_cfs_period_timer(struct cfs_bandwidth *cfs_b, int overrun)
{
	…
	throttled = !list_empty(&cfs_b->throttled_cfs_rq);
	…
	__refill_cfs_bandwidth_runtime(cfs_b); // 新填充任务组的带宽

	if (!throttled) {
		cfs_b->idle = 1;
		return 0;
	}
	…

	while (throttled && cfs_b->runtime > 0) {
		runtime = cfs_b->runtime;
		raw_spin_unlock(&cfs_b->lock);
		// 把任务组的可用运行时间分配给节流的公平运行队列
		runtime = distribute_cfs_runtime(cfs_b, runtime,
								runtime_expires);
		raw_spin_lock(&cfs_b->lock);

		throttled = !list_empty(&cfs_b->throttled_cfs_rq);
		cfs_b->runtime -= min(runtime, cfs_b->runtime);
	}
	…
}
```

&ensp;函数__refill_cfs_bandwidth_runtime负责重新填充任务组的带宽：“把可用运行时间设置成限额，把运行时间的到期时间设置成当前时间加上1个周期”

```c
// kernel/sched/fair.c
void __refill_cfs_bandwidth_runtime(struct cfs_bandwidth *cfs_b)
{
     u64 now;

     if (cfs_b->quota == RUNTIME_INF)
           return;

     now = sched_clock_cpu(smp_processor_id());
     cfs_b->runtime = cfs_b->quota;
     cfs_b->runtime_expires = now + ktime_to_ns(cfs_b->period);
}
```

&ensp;函数distribute_cfs_runtime负责把任务组的可用运行时间分配给节流的公平运行队列

```c
static void distribute_cfs_runtime(struct cfs_bandwidth *cfs_b)
{
	struct cfs_rq *cfs_rq;
	u64 runtime, remaining = 1;

	rcu_read_lock();
	list_for_each_entry_rcu(cfs_rq, &cfs_b->throttled_cfs_rq,
				throttled_list) {
		struct rq *rq = rq_of(cfs_rq);
		struct rq_flags rf;

		rq_lock_irqsave(rq, &rf);
		if (!cfs_rq_throttled(cfs_rq))
			goto next;

		/* By the above check, this should never be true */
		SCHED_WARN_ON(cfs_rq->runtime_remaining > 0);

		raw_spin_lock(&cfs_b->lock);
		/* cfs_rq->runtime_remaining是公平运行队列的剩余运行时间 */
		runtime = -cfs_rq->runtime_remaining + 1;
		if (runtime > cfs_b->runtime)
			runtime = cfs_b->runtime;
		cfs_b->runtime -= runtime;
		remaining = cfs_b->runtime;
		raw_spin_unlock(&cfs_b->lock);

		cfs_rq->runtime_remaining += runtime;

		/* we check whether we're throttled above */
		/* 上面检查过是否被节流 */
		if (cfs_rq->runtime_remaining > 0)
			unthrottle_cfs_rq(cfs_rq);

next:
		rq_unlock_irqrestore(rq, &rf);

		if (!remaining)
			break;
	}
	rcu_read_unlock();
}
```



&ensp;（3）取有余补不足：



## 2.9 SMP调度

&ensp;SMP系统进程调度器特性:
&ensp;（1）使每个处理器负载尽可能均衡
&ensp;（2）设置进程的处理器亲和性(affinity)，即允许进程在哪些处理器上执行
&ensp;（3）进程从一个处理器迁移到另一个处理器

### 2.9.1 进程的处理器亲和性
&ensp;进程描述符增加两个成员
```c
// include/linux/sched.h
struct task_struct {
	…
	int               nr_cpus_allowed;   // 保存允许的处理器掩码
	cpumask_t         cpus_allowed;		// 保存允许的处理器数量
	…
};
```
#### 1.应用编程接口
&ensp;内核系统调用
```c
// sched_setaffinity用来设置进程的处理器亲和性掩码
int sched_setaffinity(pid_t pid, size_t cpusetsize, cpu_set_t *mask);
// sched_getaffinity用来获取进程的处理器亲和性掩码
int sched_getaffinity(pid_t pid, size_t cpusetsize, cpu_set_t *mask);
```
&ensp;内核线程函数设置处理器亲和性掩码
```c
// kthread_bind用来把一个刚刚创建的内核线程绑定到一个处理器
void kthread_bind(struct task_struct *p, unsigned int cpu);
// set_cpus_allowed_ptr用来设置内核线程的处理器亲和性掩码
int set_cpus_allowed_ptr(struct task_struct *p, const struct cpumask *new_mask);
```
#### 2.使用cpuset配置
&ensp;cpuset在单独使用的时候，可以使用cpuset伪文件系统配置，配置方法



### 2.9.2 对调度器的扩展
&emsp;SMP系统上，调度类增加方法
```c
// kernel/sched/sched.h
struct sched_class {
     …
#ifdef CONFIG_SMP
	// 为进程选择运行队列
	int  (*select_task_rq)(struct task_struct *p, int task_cpu, int sd_flag, int flags);  
	// 在进程被迁移到新的处理器之前调用
	void (*migrate_task_rq)(struct task_struct *p);
	// 用来在进程被唤醒以后调用
	void (*task_woken) (struct rq *this_rq, struct task_struct *task);
	// 设置处理器亲和性的时候执行调度类的特殊处理
	void (*set_cpus_allowed)(struct task_struct *p,
					const struct cpumask *newmask);
#endif
     …
};
```

&ensp;进程在内存和缓存中的数据是最少的，是有价值的实现负载均衡的机会：1）创建新进程，2）调用execve装载程序

<center>创建新进程时负载均衡</center>

![20221106235035](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221106235035.png)

<center>装载程序时负载均衡</center>

![20221106235110](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221106235110.png)


### 2.9.3 限期调度类的处理器负载均衡



### 2.9.4 实时调度类的处理器负载均衡



### 2.9.5 公平调度类的处理器负载均衡

### 2.9.6 迁移线程

&ensp;每个处理器有一个迁移线程，线程名称是“migration/<cpu_id>”，属于停机调度类，可以抢占所有其他进程，其他进程不可以抢占它。迁移线程有两个作用   \
&ensp;（1）调度器发出迁移请求，迁移线程处理迁移请求，把进程迁移到目标处理器。
&ensp;（2）执行主动负载均衡。

### 2.9.7 隔离处理器











## 2.10 进程的上下文安全








# 第3章 内存管理

## 3.1 内存管理子系统架构
&emsp;用户空间、内核空间和硬件3个层面
![20221107001723](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221107001723.png)
#### 1.用户空间
&ensp;应用程序使用`malloc()`申请内存，使用`free()`释放内存。 \
&ensp;malloc()和free()是glibc库的内存分配器`ptmalloc`提供的接口，ptmalloc使用系统调用`brk`或`mmap`向内核以页为单位申请内存，然后划分成小内存块分配给应用程序    \
&ensp;用户空间的内存分配器，除了glibc库的ptmalloc，还有谷歌的tcmalloc和FreeBSD的`jemalloc`

#### 2.内核空间
（1）内核空间的基本功能   \
&emsp;虚拟内存管理负责从进程的虚拟地址空间分配虚拟页，sys_brk用来扩大或收缩堆，sys_mmap用来在内存映射区域分配虚拟页，sys_munmap用来释放虚拟页   \
&emsp;内核使用延迟分配物理内存的策略，进程第一次访问虚拟页的时候，触发页错误异常，页错误异常处理程序从页分配器申请物理页，在进程的页表中把虚拟页映射到物理页   \
&ensp;页分配器负责分配物理页，当前使用的页分配器是伙伴分配器。 \
&emsp;内核空间提供了把页划分成小内存块分配的块分配器，提供分配内存的接口kmalloc()和释放内存的接口kfree()，支持3种块分配器：SLAB分配器、SLUB分配器和SLOB分配器。   \

（2）内核空间的扩展功能。 \

&emsp;不连续页分配器提供了分配内存的接口vmalloc和释放内存的接口vfree  \
&emsp;连续内存分配器（Contiguous Memory Allocator，CMA）用来给驱动程序预留一段连续的内存，当驱动程序不用的时候，可以给进程使用；当驱动程序需要使用的时候，把进程占用的内存通过回收或迁移的方式让出来，给驱动程序使用  \



#### 3.硬件层面
&emsp;处理器包含一个称为内存管理单元（Memory Management Unit，MMU）的部件，负责把虚拟地址转换成物理地址   \
&emsp;内存管理单元包含一个称为页表缓存（Translation Lookaside Buffer，TLB）的部件，保存最近使用过的页表映射，避免每次把虚拟地址转换成物理地址都需要查询内存中的页表   \


## 3.2 虚拟地址空间布局

### 3.2.1 虚拟地址空间划分

&emsp;ARM64处理器不支持完全的64位虚拟地址，ARMv8.2 标准的大虚拟地址(Large Virtual Address，LVA)支持，并且页长度是64KB，那么虚拟地址的最大宽度是52位    \
&emsp;可以为虚拟地址配置比最大宽度小的宽度，并且可以为内核虚拟地址和用户虚拟地址配置不同的宽度。转换控制寄存器（Translation Control Register）TCR_EL1的字段T0SZ定义了必须是全0的最高位的数量，字段T1SZ定义了必须是全1的最高位的数量，用户虚拟地址的宽度是（64-TCR_EL1.T0SZ），内核虚拟地址的宽度是（64-TCR_EL1.T1SZ）   \

<table>
	<tr>
	    <th>页长度</th>
	    <th>虚拟地址宽度</th>
	</tr >
	<tr >
	    <td>4KB</td>
	    <td>39</td>
	</tr>
	<tr >
	    <td>16KB</td>
	    <td>47</td>
	</tr>
	<tr >
	    <td>64KB</td>
	    <td>42</td>
	</tr>
	<tr >
	    <td colspan="2">可选择48位虚拟地址</td>
	</tr>
</table>

### 3.2.2 用户虚拟地址空间布局

&ensp;进程的用户虚拟地址空间的起始地址是0，长度是TASK_SIZE，ARM64架构下TASK_SIZE下  \
&ensp;（1）32位用户空间程序：TASK_SIZE值是TASK_SIZE_32，即0x100000000，4GB    \
&ensp;（2）64位用户空间程序：TASK_SIZE值是TASK_SIZE_64，即 `2^VA_BITS`，VA_BITS是编译内核时选择的虚拟地址位数。   \

```c
//arch/arm64/include/asm/memory.h    linux4.x
#define VA_BITS          (CONFIG_ARM64_VA_BITS)
#define TASK_SIZE_64     (UL(1) << VA_BITS)

#ifdef CONFIG_COMPAT    /* 支持执行32位用户空间程序 */
#define TASK_SIZE_32     UL(0x100000000)
/* test_thread_flag(TIF_32BIT)判断用户空间程序是不是32位 */
#define TASK_SIZE       (test_thread_flag(TIF_32BIT) ? \
                  TASK_SIZE_32 : TASK_SIZE_64)
#define TASK_SIZE_OF(tsk)  (test_tsk_thread_flag(tsk, TIF_32BIT) ? \
                  TASK_SIZE_32 : TASK_SIZE_64)
#else
#define TASK_SIZE    TASK_SIZE_64
#endif /* CONFIG_COMPAT */
```


```c
// linux-5.10.102/arch/arm64/include/asm/memory.h
#define VA_BITS			(CONFIG_ARM64_VA_BITS)
#define _PAGE_OFFSET(va)	(-(UL(1) << (va)))
#define PAGE_OFFSET		(_PAGE_OFFSET(VA_BITS))
#define KIMAGE_VADDR		(MODULES_END)
#define BPF_JIT_REGION_START	(KASAN_SHADOW_END)
#define BPF_JIT_REGION_SIZE	(SZ_128M)
#define BPF_JIT_REGION_END	(BPF_JIT_REGION_START + BPF_JIT_REGION_SIZE)
#define MODULES_END		(MODULES_VADDR + MODULES_VSIZE)
#define MODULES_VADDR		(BPF_JIT_REGION_END)
#define MODULES_VSIZE		(SZ_128M)
#define VMEMMAP_START		(-VMEMMAP_SIZE - SZ_2M)
#define VMEMMAP_END		(VMEMMAP_START + VMEMMAP_SIZE)
#define PCI_IO_END		(VMEMMAP_START - SZ_2M)
#define PCI_IO_START		(PCI_IO_END - PCI_IO_SIZE)
#define FIXADDR_TOP		(PCI_IO_START - SZ_2M)
```

&ensp;进程的用户虚拟地址空间包含：    \
&ensp;（1）代码段、数据段和未初始化数据段    \
&ensp;（2）动态库代码段、数据段和初始化数据段    \
&ensp;（3）存放动态生成的数据的堆      \
&ensp;（4）存放局部变量和实现函数调用的栈   \
&ensp;（5）存放在栈底部的环境变量和参数字符串   \
&ensp;（6）把文件区间映射到虚拟地址空间的内存映射区域   \
&emsp;内核使用内存描述符`mm_struct`描述进程的用户虚拟地址空间，内存描述符主要成员


```c
atomic_t mm_users;  // 共享同一个用户虚拟地址空间进程的数量，即线程组包含的进程的数量
atomic_t mm_count;  // 内存描述符的引用计数
struct vm_area_struct *mmap;  // 虚拟内存区域链表
struct rb_root mm_rb;  // 虚拟内存区域红黑树
unsigned long(*get_unmapped_area)(struct file *filp, unsigned long addr, unsigned long len, unsigned long pgoff, unsigned long flags);  // 在内存映射区域找到一个没有映射的区域
pgd_t *pgd;  // 指向页全局目录，即第一级页表
unsigned long mmap_base;  // 内存映射区的起始地址
unsigned long task_size;  // 用户虚拟地址空间的长度
unsigned long start_code, end_code;  // 代码段的起始地址和结束地址
unsigned long start_data, end_data;  // 数据段的起始地址和结束地址
unsigned long start_brk, brk;  // 堆的起始地址和结束地址
unsigned long start_stack;  // 栈的起始地址
unsigned long arg_start, arg_end;  // 参数字符串起始地址和结束地址
unsigned long env_start, env_end;  // 环境变量的起始地址和结束地址
```


```c
struct mm_struct *mm;  // 进程mm指向一个内存描述符，内核线程mm为空指针
struct mm_struct　*active_mm;  // 进程的active_mm和mm总是指向同一个内存描述符
// 内核线程的active_mm在没有运行时是空指针，在运行时指向从上一个进程借用的内存描述符
```

&ensp;进程地址空间随机化：  \
&ensp;（1）进程描述符成员personality是否设置ADDR_NO_RANDOMIZE   \
&ensp;（2）全局变量`randomize_va_spce`：0表示关闭虚拟地址空间随机化，1表示内存映射区和栈起始地址随机化，2表示内存映射区、栈和堆起始地址随机化，文件`/proc/sys/kernel/randomize_va_space`修改 \

&ensp;栈向下增长，起始地址STACK_TOP，
```c
// arch/arm64/include/asm/processor.h
#define STACK_TOP_MAX         TASK_SIZE_64
#ifdef CONFIG_COMPAT  /* 支持执行32位用户空间程序 */
#define AARCH32_VECTORS_BASE  0xffff0000
#define STACK_TOP   (test_thread_flag(TIF_32BIT) ? \
                 AARCH32_VECTORS_BASE : STACK_TOP_MAX)
#else
#define STACK_TOP    STACK_TOP_MAX
#endif /* CONFIG_COMPAT */
```

&ensp;内存映射区域的起始地址是内存描述符的成员 mmap_base

<center>用户虚拟地址空间两种布局</center>

![20221109013928](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221109013928.png)

&ensp;新布局：内存映射区域自顶向下增长，起始地址是(STACK_TOP − 栈的最大长度 − 间隙)，默认启用内存映射区域随机化，需要把起始地址减去一个随机值   \

&ensp;进程调用execve以装载ELF文件的时候，函数load_elf_binary将会创建进程的用户虚拟地址空间   \

![20221109014232](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221109014232.png)

&ensp;函数arch_pick_mmap_layout负责选择内存映射区域的布局。ARM64架构定义的函数arch_pick_mmap_layout
```c
// linux-5.10.102/mm/util.c
void arch_pick_mmap_layout(struct mm_struct *mm, struct rlimit *rlim_stack)
{
	unsigned long random_factor = 0UL;

	if (current->flags & PF_RANDOMIZE)
		random_factor = arch_mmap_rnd();

	if (mmap_is_legacy(rlim_stack)) { // 自底向上
		mm->mmap_base = TASK_UNMAPPED_BASE + random_factor;
		mm->get_unmapped_area = arch_get_unmapped_area;  // 
	} else {  // 自顶向下
		mm->mmap_base = mmap_base(random_factor, rlim_stack);
		mm->get_unmapped_area = arch_get_unmapped_area_topdown;
	}
}

static int mmap_is_legacy(struct rlimit *rlim_stack)
{
	if (current->personality & ADDR_COMPAT_LAYOUT)
		return 1;

	if (rlim_stack->rlim_cur == RLIM_INFINITY)
		return 1;

	return sysctl_legacy_va_layout;
}
```

&ensp;内存映射区域的起始地址的计算

```c
// linux-5.10.102/arch/arm64/include/asm/efi.h
#ifdef CONFIG_COMPAT
#define STACK_RND_MASK			(test_thread_flag(TIF_32BIT) ? \
						0x7ff >> (PAGE_SHIFT - 12) : \
						0x3ffff >> (PAGE_SHIFT - 12))
#else
#define STACK_RND_MASK			(0x3ffff >> (PAGE_SHIFT - 12))
#endif
```



```c
// arch/arm64/mm/mmap.c
#define MIN_GAP (SZ_128M + ((STACK_RND_MASK << PAGE_SHIFT) + 1))
#define MAX_GAP (STACK_TOP/6*5)
static unsigned long mmap_base(unsigned long rnd)
{
     unsigned long gap = rlimit(RLIMIT_STACK);

     if (gap < MIN_GAP)
           gap = MIN_GAP;
     else if (gap > MAX_GAP)
           gap = MAX_GAP;

     return PAGE_ALIGN(STACK_TOP - gap - rnd);
}


```

&ensp;函数load_elf_binary：函数setup_arg_pages把栈顶设置为STACK_TOP减去随机值，然后把环境变量和参数从临时栈移到最终的用户栈；函数set_brk设置堆的起始地址，如果启用堆随机化，把堆的起始地址加上随机值

```c
// fs/binfmt_elf.c
static int load_elf_binary(struct linux_binprm *bprm)
{
     …
     retval = setup_arg_pages(bprm, randomize_stack_top(STACK_TOP),
                     executable_stack);
     …
     retval = set_brk(elf_bss, elf_brk, bss_prot);
     …
     if ((current->flags & PF_RANDOMIZE) && (randomize_va_space > 1)) {
           current->mm->brk = current->mm->start_brk =
                arch_randomize_brk(current->mm);
     }
     …
}

```

### 3.2.3 内核地址空间布局


<center>ARM64处理器架构内核地址空间布局</center>

![20221109225722](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221109225722.png)

&ensp;(1)先行映射区范围[PAGE_OFFSET, 2^64-1]，起始地址PAGE_OFFSET = (OxFFFF FFFF FFFF FFFF << (VA_BITS-1))，长度为内核虚拟地址空间的一半，虚拟地址和物理地址是线性关系  \ 
&emsp;虚拟地址 = ((物理地址-PHYS_OFFSET)+PAGE_OFFSET)，PHY_OFFSET是内存起始物理地址
&ensp;(2)vmemmap 区域的范围是[VMEMMAP_START, PAGE_OFFSET)，长度是VMEMMAP_SIZE =（线性映射区域的长度 / 页长度 * page结构体的长度上限）
&ensp;(3)PCI I/O区域的范围是[PCI_IO_START, PCI_IO_END)，长度是16MB，结束地址是PCI_IO_END = (VMEMMAP_START − 2MB)。外围组件互联（Peripheral Component Interconnect，PCI）是一种总线标准，PCI I/O区域是PCI设备的I/O地址空间
&ensp;(4)定映射区域的范围是[FIXADDR_START, FIXADDR_TOP)，长度是FIXADDR_SIZE，结束地址是FIXADDR_TOP = (PCI_IO_START − 2MB)
&ensp;(5)vmalloc区域的范围是[VMALLOC_START, VMALLOC_END），起始地址是VMALLOC_START，等于内核模块区域的结束地址，结束地址是VMALLOC_END = (PAGE_OFFSET − PUD_SIZE − VMEMMAP_SIZE − 64KB)，其中PUD_SIZE是页上级目录表项映射的地址空间的长度   \
&emsp;vmalloc区域是函数vmalloc使用的虚拟地址空间，内核镜像在vmalloc区域，起始虚拟地址是(KIMAGE_VADDR + TEXT_OFFSET) ，其中KIMAGE_VADDR是内核镜像的虚拟地址的基准值，等于内核模块区域的结束地址MODULES_END；TEXT_OFFSET是内存中的内核镜像相对内存起始位置的偏移      \
&ensp;(6)内核模块区域的范围是[MODULES_VADDR, MODULES_END)，长度是128MB，起始地址是MODULES_VADDR =（内核虚拟地址空间的起始地址 + KASAN影子区域的长度）。内核模块区域是内核模块使用的虚拟地址空间    \
&ensp;(7)KASAN影子区域的起始地址是内核虚拟地址空间的起始地址，长度是内核虚拟地址空间长度的1/8。内核地址消毒剂（Kernel Address SANitizer，KASAN）是一个动态的内存错误检查工具       \


## 3.3 物理地址空间

&ensp;处理器通过外围设备控制器的寄存器访问外围设备，寄存器分为控制寄存器、状态寄存器和数据寄存器三大类，外围设备的寄存器通常被连续地编址。处理器对外围设备寄存器的编址方式有两种：     \
&emsp;（1）I/O映射方式(I/O-mapped)  \
&emsp;（2）内存映射方式(memroy-mapped)：精简指令集的处理器通常只实现一个物理地址空间，外围设备和物理内存使用统一的物理地址空间，处理器可以像访问一个内存单元那样访问外围设备，不需要提供专门的I/O指令     \

&emsp;程序通过虚拟地址访问外设寄存器，内核函数把外设寄存器物理地址映射到虚拟地址空间
```c
// ioremap()把外设寄存器物理地址映射到内核虚拟地址空间
void* ioremap(unsigned long phys_addr, unsigned long size, unsigned long flags);
// io_remap_pfn_range()函数把外设寄存器的物理地址映射到进程的用户虚拟地址空间
int io_remap_pfn_range(struct vm_area_struct *vma, unsigned long addr,unsigned long pfn, unsigned long size, pgprot_t prot);
// iounmap()删除函数ioremap()创建映射
void iounmap(void *addr);
```
&ensp;ARM64架构两种内存类型：
&emsp;（1）正常内存(Normal Memory)：包括物理内存和只读存储器(ROM)，共享属性和可缓存     \
&emsp;（2）设备内存(Device Memory)：指分配给外围设备寄存器的物理地址区域，外部共享，不可缓存  \
&ensp;ARM64架构3种属性把设备分为4种类型:      \
&emsp;（1）Device-nGnRnE          \
&emsp;（2）Device-nGnRE。          \
&emsp;（3）Device-nGRE。       \
&emsp;（4）Device-GRE         \

&ensp;寄存器TCR_EL1（Translation Control Register for Exception Level 1，异常级别1的转换控制寄存器）的字段IPS（Intermediate Physical Address Size，中间物理地址长度）控制物理地址的宽度，IPS字段的长度是3位




## 3.4　内存映射

&ensp;进程在虚拟地址空间中创建映射：
&emsp;（1）文件映射，把文件一个区间映射到进程虚拟地址空间，数据源是存储设备上的文件，文件页   \
&emsp;（2）匿名映射，把物理内存映射到进程虚拟地址空间，无数据源，匿名页   \
&ensp;修改对其他进程可见和释放传递底层文件，内存映射分为共享映射和私有映射。
&ensp；（1）共享映射：修改数据时映射相同区域的其他进程可以看见，如果是文件支持的映射，修改会传递到底层文件。   \
&ensp;（2）私有映射：第一次修改数据时会从数据源复制一个副本，然后修改副本，其他进程看不见，不影响数据源    \
&emsp; 两个进程可以使用共享的文件映射实现共享内存，进程间通信？。匿名映射通常是私有映射，共享的匿名映射只可能出现在父进程和子进程之间。    \
&ensp;进程的虚拟地址空间中，代码段和数据段是私有的文件映射，未初始化数据段、堆和栈是私有的匿名映射
&ensp;内存映射的原理。   \
&ensp;（1）创建内存映射的时候，在进程的用户虚拟地址空间中分配一个虚拟内存区域。  \
&ensp;（2）Linux内核采用延迟分配物理内存的策略，在进程第一次访问虚拟页的时候，产生缺页异常。如果是文件映射，那么分配物理页，把文件指定区间的数据读到物理页中，然后在页表中把虚拟页映射到物理页；如果是匿名映射，那么分配物理页，然后在页表中把虚拟页映射到物理页


#### 3.4.1 应用编程接口

&ensp;系统调用
```c
// 1.mmap()创建内存映射
void *mmap(void *addr, size_t length, int prot, int flags, in fd, off_t offset);
// 2. mremap()扩大或缩小内存映射，可移动
void *mreemap(void *old_address, size_t old_size, size_t new_size, int flags, ... /*void *new_address */);
// 3. munmap() 删除内存印刷
int munmap(void *addr, size_t length);
// 4. brk() 设置堆上界
int brk(void *addr);
// 6. mprotect()设置虚拟内存区域的访问权限
int mprotect(void *addr, size_t len, int prot);
// 7. madvise 箱内核体术内存使用建议，配合内核预读和缓存
int madvise(void *addr, size_t length, int advice);

```
&ensp;内核空间函数
```c
// 1. remap_pfn_range把内存的物理页映射到进程的虚拟地址空间，实现进程和内核共享内存
int remap_pfn_range(struct vm_area_struct *vma, unsigned long addr,unsigned long pfn,unsigned long size, pgprot_t prot);

// 2.io_remap_pfn_range把外设寄存器的物理地址映射到进程的虚拟地址空间，进程可以直接访问外设寄存器
int io_remap_pfn_range(struct vm_area_struct *vma, unsigned long addr,unsigned long pfn, unsigned long size, pgprot_t prot);

```

&ensp;应用程序通常使用C标准库提供的函数malloc()申请内存。glibc库的内存分配器ptmalloc使用brk或mmap向内核以页为单位申请虚拟内存，然后把页划分成小内存块分配给应用程序。默认的阈值是128KB，如果应用程序申请的内存长度小于阈值，ptmalloc分配器使用brk向内核申请虚拟内存，否则ptmalloc分配器使用mmap向内核申请虚拟内存   \

&ensp;应用程序可以直接使用mmap向内核申请虚拟内存
系统调用mmap()  \
系统调用mprotect()  \
系统调用madvise()


### 3.4.2 数据结构

#### 1. 虚拟内存区域

&ensp;内核使用结构体`vm_area_struct`描述虚拟内存区域

```c
struct vm_area_struct {
	/* The first cache line has the info for VMA tree walking. */
	/* Our start address within vm_mm. */
	unsigned long vm_start;	  // 起始地址 
	/* The first byte after our end address within vm_mm. */
	unsigned long vm_end;  // 结束地址
	/* linked list of VM areas per task, sorted by address */
	// 虚拟内存区域链表，按起始地址排序
	struct vm_area_struct *vm_next, *vm_prev;
	// 	红黑树节点
	struct rb_node vm_rb;
	
	/* Largest free memory gap in bytes to the left of this VMA.
	 * Either between this VMA and vma->vm_prev, or between one of the
	 * VMAs below us in the VMA rbtree and its ->vm_prev. This helps
	 * get_unmapped_area find a free area of the right size.*/
	unsigned long rb_subtree_gap;

	/* Second cache line starts here. */
	// 指向内存描述符，即虚拟内存区域所属的用户虚拟地址空间
	struct mm_struct *vm_mm;	/* The address space we belong to. */
	
	/* Access permissions of this VMA.
	 * See vmf_insert_mixed_prot() for discussion.*/
	// 保护位，即访问权限
	pgprot_t vm_page_prot;
	unsigned long vm_flags;		/* Flags, see mm.h. */

	/* For areas with an address space and backing store,
	 * linkage into the address_space->i_mmap interval tree.*/
	// 为了支持查询一个文件区间被映射到哪些虚拟内存区域，
	// 把一个文件映射到的所有虚拟内存区域加入该文件的地址空间结构体
	// address_space的成员i_mmap指向的区间树
	struct {
		struct rb_node rb;
		unsigned long rb_subtree_last;
	} shared;

	
	/*  file's MAP_PRIVATE vma can be in both i_mmap tree and anon_vma
	 * list, after a COW of one of the file pages.	A MAP_SHARED vma
	 * can only be in the i_mmap tree.  An anonymous MAP_PRIVATE, stack
	 * or brk vma (with NULL file) can only be in an anon_vma list.*/
	// 把虚拟内存区域关联的所有anon_vma实例串联起来。
	// 一个虚拟内存区域会关联到父进程的anon_vma实例和自己的anon_vma实例 
	struct list_head anon_vma_chain; /* Serialized by mmap_lock &
					  * page_table_lock */
	// 指向一个anon_vma实例，结构体anon_vma用来组织匿名页
	// 被映射到的所有虚拟地址空间
	struct anon_vma *anon_vma;	/* Serialized by page_table_lock */

	/* Function pointers to deal with this struct. */
	// 虚拟内存操作集合
	const struct vm_operations_struct *vm_ops;

	/* Information about our backing store: */
	// 文件偏移，单位是页
	unsigned long vm_pgoff;		/* Offset (within vm_file) in PAGE_SIZE
					   units */
	// 文件，如果是私有的匿名映射，该成员是空指针
	struct file * vm_file;		/* File we map to (can be NULL). */
	void * vm_private_data;		/* was vm_pte (shared mem) */

#ifdef CONFIG_SWAP
	atomic_long_t swap_readahead_info;
#endif
#ifndef CONFIG_MMU
	struct vm_region *vm_region;	/* NOMMU mapping region */
#endif
#ifdef CONFIG_NUMA
	struct mempolicy *vm_policy;	/* NUMA policy for the VMA */
#endif
	struct vm_userfaultfd_ctx vm_userfaultfd_ctx;
} __randomize_layout;
```
<center>文件映射的虚拟内存区域</center>

![20221111234010](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221111234010.png)

&ensp;（1）成员vm_file指向文件的一个打开实例（file）。索引节点代表一个文件，描述文件的属性。    \
&ensp;（2）成员vm_pgoff存放文件的以页为单位的偏移。   \
&ensp;（3）成员vm_ops指向虚拟内存操作集合，创建文件映射的时候调用文件操作集合中的mmap方法（file->f_op->mmap）以注册虚拟内存操作集合。例如：假设文件属于EXT4文件系统，文件操作集合中的mmap方法是函数ext4_file_mmap，该函数把虚拟内存区域的成员vm_ops设置为ext4_file_vm_ops


<center>共享匿名映射的虚拟内存区域</center>

![20221111234048](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221111234048.png)

&ensp;（1）成员vm_file指向文件的一个打开实例（file）。   \
&ensp;（2）成员vm_pgoff存放文件的以页为单位的偏移。   \
&ensp;（3）成员vm_ops指向共享内存的虚拟内存操作集合shmem_vm_ops。

<center>私有匿名映射的虚拟内存区域</center>

![20221112001338](https://raw.githubusercontent.com/zhuangll/PictureBed/main/blogs/pictures/20221112001338.png)

&ensp;（1）页保护位（vm_area_struct.vm_page_prot）：描述虚拟内存区域的访问权限。内核定义了一个保护位映射数组，把VM_READ、VM_WRITE、VM_EXEC和VM_SHARED这4个标志转换成保护位组合        \
&ensp;P代表私有（Private），S代表共享（Shared），后面的3个数字分别表示可读、可写和可执行，例如__P000表示私有、不可读、不可写和不可执行，__S111表示共享、可读、可写和可执行  

```c
// mm/mmap.c
pgprot_t protection_map[16] = {
    __P000, __P001, __P010, __P011, __P100, __P101, __P110, __P111,
    __S000, __S001, __S010, __S011, __S100, __S101, __S110, __S111
};

pgprot_t vm_get_page_prot(unsigned long vm_flags)
{
    return __pgprot(pgprot_val(protection_map[vm_flags &
                (VM_READ|VM_WRITE|VM_EXEC|VM_SHARED)]) |
             pgprot_val(arch_vm_get_page_prot(vm_flags)));
}

// include/linux/mman.h
#ifndef arch_vm_get_page_prot
#define arch_vm_get_page_prot(vm_flags) __pgprot(0)
#endif
```

&ensp;虚拟内存区域标志：结构体vm_area_struct的成员vm_flags存放虚拟内存区域的标志，头文件“include/linux/mm.h”定义了各种标志         \
VM_READ、VM_WRITE、VM_EXEC、VM_SHARED、VM_GROWSDOWN、VM_DONTEXPAND、VM_ACCOUNT、VM_NORESERVE、VM_HUGETLB、VM_ARCH_1、VM_ARCH_2、VM_HUGEPAGE、VM_MERGEABLE


&ensp;虚拟内存操作集合（vm_operations_struct）：定义了虚拟内存区域的各种操作方法  
```c
// include/linux/mm.h
struct vm_operations_struct {
	// 在创建虚拟内存区域时调用open方法，通常不使用，设置为空指针
	void (*open)(struct vm_area_struct * area);
	// 在删除虚拟内存区域时调用close方法，通常不使用，设置为空指针
	void (*close)(struct vm_area_struct * area);
	// 使用系统调用mremap移动虚拟内存区域时调用mremap方法
	int (*mremap)(struct vm_area_struct * area);
	// 使用系统调用mremap移动虚拟内存区域时调用mremap方法
	int (*fault)(struct vm_fault *vmf);
	// huge_fault方法针对使用透明巨型页的文件映射
	int (*huge_fault)(struct vm_fault *vmf, enum page_entry_size pe_size);
	// 读文件映射的虚拟页时，如果没有映射到物理页，生成缺页异常
	void (*map_pages)(struct vm_fault *vmf,
			pgoff_t start_pgoff, pgoff_t end_pgoff);

	/* 通知以前的只读页即将变成可写，
	* 如果返回一个错误，将会发送信号SIGBUS给进程*/
	int (*page_mkwrite)(struct vm_fault *vmf);

	/* 使用VM_PFNMAP或者VM_MIXEDMAP时调用，功能和page_mkwrite相同*/
	int (*pfn_mkwrite)(struct vm_fault *vmf);
	…
}
```


#### 2.链表和树

<center>虚拟内存区域的链表和树</center>

![20221114005059](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221114005059.png)
&ensp;(1)双向链表，mm_struct.mmap指向第一个vm_area_struct实例   \
&ensp;(2)红黑树，mm_struct.mm_rb指向红黑树的根    \



### 3.4.3 创建内存映射
&ensp;C标准库封装了函数mmap用来创建内存映射
```c
asmlinkage long sys_mmap(unsigned long addr, unsigned long len, 
              unsigned long prot, unsigned long flags, 
              unsigned long fd, off_t off); 

asmlinkage long sys_mmap2(unsigned long addr, unsigned long len, 
              unsigned long prot, unsigned long flags, 
              unsigned long fd, off_t off); 

```

&ensp;ARM64架构只实现系统调用mmap

<center>系统调用sys_mmap执行流程</center>

![20221114010335](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221114010335.png)


<center>do_mmap的执行流程</center>

![20221114010503](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221114010503.png)

待补充


### 3.4.4 虚拟内存过量提交策略
&ensp;虚拟内存过量提交，是指所有进程提交的虚拟内存的总和超过物理内存的容量，内存管理子系统支持3种虚拟内存过量    \
&ensp;（1）OVERCOMMIT_GUESS(0)：猜测，估算可用内存的数量，因为没法准确计算可用内存的数量，所以说是猜测。   \
&ensp;（2）OVERCOMMIT_ALWAYS(1)：总是允许过量提交。   \
&ensp;（3）OVERCOMMIT_NEVER(2)：不允许过量提交。     \
&emsp;`/proc/sys/vm/overcommit_memory`修改策略
&ensp;在创建新的内存映射时，调用函数__vm_enough_memory根据虚拟内存过量提交策略判断内存是否足够



### 3.4.5 删除内存映射

&ensp;系统调用munmap用来删除内存映射，它有两个参数：起始地址和长度，`mm/mmap.c`中的函数do_munmap

<center>系统调用munmap执行流程</center>

![20221114231356](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221114231356.png)


## 3.5 物理内存组织

### 3.5.1 体系结构
&ensp;多处理器系统两种体系结构：
&ensp;(1)非一致内存访问(Non-Uniform Memory Access NUMA)：内存为多个内存节点多处理器系统  \
&ensp;(2)对称多处理器(Symmetric Multi-Process SMP)：一直内存访问(UMA)

### 3.5.2 内存模型
&ensp;内存管理子系统支持3种内存模型
&ensp;(1)平坦内存(Flat Memory)：内存物理地址空间是连续的   \
&ensp;(2)不连续内存(Discontiguous Memory)：内存物理地址空间存在空洞
&ensp;(3)系数内存(Sparse Memory)：内存物理地址空间存在空洞

### 3.5.3 三级结构

&ensp;内存管理子系统使用节点(node)、区域(zone)和页(page)三级结构描述物理内存。   \
#### 1.内存节点
&ensp;内存节点两种情况：
&ensp;（1）NUMA系统内存节点  \
&ensp;（2）具有不连续内存的UMA系统  \
&ensp;内存节点使用`pglist_data`结构体描述内存布局，内核定义宏NODE_DATA(nid)，获取节点的pglist_data实例。平坦内存模型，只有一个pglist_data实例contig_page_data

![20221114233416](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221114233416.png)
<center>内存节点的pglist_data实例</center>

&ensp;pglist_data结构主要成员：
```c
// include/linux/mmzone.h
typedef struct pglist_data {
    struct zone node_zones[MAX_NR_ZONES];          /* 内存区域数组 */
    struct zonelist node_zonelists[MAX_ZONELISTS]; /* 备用区域列表 */
    int nr_zones;                                  /* 该节点包含的内存区域数量 */
#ifdef CONFIG_FLAT_NODE_MEM_MAP                    /* 除了稀疏内存模型以外 */
    struct page *node_mem_map;                     /* 页描述符数组 */
#ifdef CONFIG_PAGE_EXTENSION
    struct page_ext *node_page_ext;                /* 页的扩展属性 */
#endif
#endif
    …
    unsigned long node_start_pfn;                  /* 该节点的起始物理页号 */
    unsigned long node_present_pages;              /* 物理页总数 */
    unsigned long node_spanned_pages;              /* 物理页范围的总长度，包括空洞 */
    int node_id;                                   /* 节点标识符 */
    …
} pg_data_t;
```

#### 2.内存区域

&ensp;内核定义内存节点区域
```c
// include/linux/mmzone.h
enum zone_type {
#ifdef CONFIG_ZONE_DMA
     ZONE_DMA,  // 直接内存访问区域
#endif
#ifdef CONFIG_ZONE_DMA32
     ZONE_DMA32,
#endif
    // 内核虚拟地址和物理地址是线性映射的关系，即虚拟地址 =（物理地址 + 常量）
     ZONE_NORMAL,  // 直接映射区域
#ifdef CONFIG_HIGHMEM
     ZONE_HIGHMEM,  // 高端内存区域
#endif
     ZONE_MOVABLE,  // 可移动区域
#ifdef CONFIG_ZONE_DEVICE
     ZONE_DEVICE,  // 设备区域
#endif
     __MAX_NR_ZONES
};

```

&ensp;每个内存区域用一个zone结构体描述
```c
// include/linux/mmzone.h
struct zone {
	unsigned long watermark[NR_WMARK];        /* 页分配器使用的水线 */
	…
	long lowmem_reserve[MAX_NR_ZONES];         /* 页分配器使用，当前区域保留多少页不能借给  
											高的区域类型 */
	…
	struct pglist_data  *zone_pgdat;          /* 指向内存节点的pglist_data实例 */
	struct per_cpu_pageset __percpu *pageset;  /* 每处理器页集合 */
	…
	unsigned long     zone_start_pfn;         /* 当前区域的起始物理页号 */

	unsigned long     managed_pages;          /* 伙伴分配器管理的物理页的数量 */
	unsigned long     spanned_pages;          /* 当前区域跨越的总页数，包括空洞 */
	unsigned long     present_pages;          /* 当前区域存在的物理页的数量，不包括空洞 */

	const char        *name;                  /* 区域名称 */
	…   
	struct free_area  free_area[MAX_ORDER];    /* 不同长度的空闲区域 */
	…
}
```


#### 3.物理页

&ensp;每个物理页对应一个page结构体，称为页描述符，内存节点的pglist_data实例的成员node_mem_map指向该内存节点包含的所有物理页的页描述符注册的数组。   \
&ensp;结构体page成员flags布局  \
| [SECTION] | [NODE] | ZONE | [LAST_CPUPID] | ... | FLAGS |  \
&ensp;SECTION是稀疏内存模型中的段编号，NODE是节点编号，ZONE是区域类型，FLAGS是标志位    \
&ensp;头文件`include/linux/mm_types.h`定义了page结构体
```c
// include/linux/mm.h
// 得到物理页所属的内存节点的编号
static inline int page_to_nid(const struct page *page)
{
     return (page->flags >> NODES_PGSHIFT) & NODES_MASK;
}
// 得到物理页所属的内存区域的类型
static inline enum zone_type page_zonenum(const struct page *page)
{
     return (page->flags >> ZONES_PGSHIFT) & ZONES_MASK;
}
```

## 3.6 引导内存分配器

&ensp;在内核初始化的过程中需要分配内存，内核提供了临时的引导内存分配器，在页分配器和块分配器初始化完毕后，把空闲的物理页交给页分配器管理，丢弃引导内存分配器，开启配置宏CONFIG_NO_BOOTMEM，`memblock`就会取代bootmem。
&ensp;

### 3.6.1 bootmem分配器


### 3.6.2 memblock分配器

#### 1.数据结构

&ensp;memblock分配器数据结构
```c
// include/linux/memblock.h
struct memblock {
	bool bottom_up;  /* 表示分配内存的方式 是从下向上的方向？ */
	phys_addr_t current_limit;  // 可分配内存的最大物理地址
	struct memblock_type memory;  // 存类型（包括已分配的内存和未分配的内存）
	struct memblock_type reserved;  // 预留类型（已分配的内存）
#ifdef CONFIG_HAVE_MEMBLOCK_PHYS_MAP
	struct memblock_type physmem;  // 物理内存类型
#endif   
};
```

&ensp;内存块类型的数据结构
```c
// include/linux/memblock.h
struct memblock_type {
	unsigned long cnt;        /* 内存块区域数量 */
	unsigned long max;        /* 已分配数组的大小 */
	phys_addr_t total_size;    /* 内存块区域的总长度 所有区域的长度 */
	struct memblock_region *regions;  // 指向内存块区域数组
	char *name;  // 存块类型的名称
};
```
&ensp;内存块区域的数据结构
```c
// include/linux/memblock.h
struct memblock_region {
	phys_addr_t base;  // 起始物理地址
	phys_addr_t size;  // 长度
	unsigned long flags;  // 标志 MEMBLOCK_NONE或其他标志
#ifdef CONFIG_HAVE_MEMBLOCK_NODE_MAP
	int nid;  // 节点编号
#endif   
};

/* memblock标志位的定义. */
enum {
	MEMBLOCK_NONE      = 0x0,   /* 无特殊要求 */
	MEMBLOCK_HOTPLUG   = 0x1,   /* 可热插拔区域 */
	MEMBLOCK_MIRROR    = 0x2,   /* 镜像区域 */
	MEMBLOCK_NOMAP     = 0x4,   /* 不添加到内核直接映射 */
};
```

#### 2.初始化

&ensp;源文件“mm/memblock.c”定义了全局变量memblock，把成员bottom_up初始化为假，表示从高地址向下分配。   \
&ensp;ARM64内核初始化memblock分配器的过程是：    \
&ensp;（1）解析设备树二进制文件中的节点“/memory”，把所有物理内存范围添加到memblock. memory，具体过程参考3.6.3节。    \
&ensp;（2）在函数arm64_memblock_init中初始化memblock。    \
&ensp;arm64_memblock_init主要流程：
> start_kernel() --> setup_arch() --> arm64_memblock_init()
```c
// arch/arm64/mm/init.c
void __init arm64_memblock_init(void)
{
	const s64 linear_region_size = -(s64)PAGE_OFFSET;
	// 解析设备树二进制文件中节点“/chosen”的属性“linux,usable-memory-range”，
	// 得到可用内存的范围，把超出这个范围的物理内存范围从memblock.memory中删除。
	fdt_enforce_memory_region();
	// 局变量memstart_addr记录内存的起始物理地址
	memstart_addr = round_down(memblock_start_of_DRAM(),
					ARM64_MEMSTART_ALIGN);
	// 把线性映射区域不能覆盖的物理内存范围从memblock.memory中删除
	memblock_remove(max_t(u64, memstart_addr + linear_region_size,
			__pa_symbol(_end)), ULLONG_MAX);
	if (memstart_addr + linear_region_size < memblock_end_of_DRAM()) {
		/* 确保memstart_addr严格对齐 */
		memstart_addr = round_up(memblock_end_of_DRAM() - linear_region_size,
						ARM64_MEMSTART_ALIGN);
		memblock_remove(0, memstart_addr);
	}

	if (memory_limit != (phys_addr_t)ULLONG_MAX) {
		memblock_mem_limit_remove_map(memory_limit);
		memblock_add(__pa_symbol(_text), (u64)(_end - _text));
	}

	…
	// 把内核镜像占用的物理内存范围添加到memblock.reserved
	memblock_reserve(__pa_symbol(_text), _end - _text);
	…
	// 从设备树二进制文件中的内存保留区域和节点“/reserved-memory”
	// 读取保留的物理内存范围，添加到memblock.reserved中
	early_init_fdt_scan_reserved_mem();
	…
}
```
#### 3.编程接口
&ensp;memblock分配器接口
```c
// 添加新的内存块区域到memblock.memory中
memblock_add
// 删除内存块区域
memblock_remove
// 分配内存
memblock_alloc
// 释放内存
memblock_free
```

#### 4.算法
&ensp;memblock分配器把所有内存添加到memblock.memory中，把分配出去的内存块添加到memblock.reserved中   \
&ensp;函数memblock_alloc负责分配内存，主要为函数memblock_alloc_range_nid  \
&ensp;(1)memblock_find_in_range_node函数memblock_find_in_range_node   \
&ensp;(2)memblock_reserve函数把分配出去的内存块区域添加到memblock.reserved中  \

### 3.6.3 物理内存信息

&ensp;内核初始化的过程中，引导内存分配器负责分配内存。ARM64架构使用扁平设备树（Flattened Device Tree，FDT）描述板卡的硬件信息。驱动开发者编写设备树源文件（Device Tree Source，DTS），存放在目录“arch/arm64/boot/dts”下，然后使用设备树编译器（Device Tree Compiler，DTC）把设备树源文件转换成设备树二进制文件（Device Tree Blob，DTB），接着把设备树二进制文件写到存储设备上。设备启动时，引导程序把设备树二进制文件从存储设备读到内存中，引导内核的时候把设备树二进制文件的起始地址传给内核，内核解析设备树二进制文件后得到硬件信息   \

&ensp; 设备树源文件`.dts`,描述物理内存布局
```c
/ {  // “/”根节点
    #address-cells = <2>;   // 地址的单元数量
    #size-cells = <2>;  // 一个长度的单元数量
    memory@80000000 {  // 描述物理内存布局
       device_type = "memory";  // 设备类型
	   // 物理内存范围
       reg = <0x00000000 0x80000000 0 0x80000000>,
             <0x00000008 0x80000000 0 0x80000000>;
    };
};
```

&ensp;内核在初始化的时候调用函数early_init_dt_scan_nodes以解析设备树二进制文件，从而得到物理内存信息   \
> start_kernel() --> setup_arch() --> setup_machine_fdt() --> early_init_dt_scan_nodes()
```c
// drivers/of/fdt.c
void __init early_init_dt_scan_nodes(void)
{
	…
	/* 初始化size-cells和address-cells信息 */
	// early_init_dt_scan_root，解析根节点的属性“#address-cells”得到地址的单元数量，
	// 保存在全局变量dt_root_addr_cells中；解析根节点的属性“#size-cells”得到
	// 长度的单元数量，保存在全局变量dt_root_size_cells中
	of_scan_flat_dt(early_init_dt_scan_root, NULL);

	/* 调用函数early_init_dt_add_memory_arch设置内存 */
	of_scan_flat_dt(early_init_dt_scan_memory, NULL);
}
```
&ensp;early_init_dt_scan_memory解析memory节点
```c
// drivers/of/fdt.c
int __init early_init_dt_scan_memory(unsigned long node, const char *uname,
                      int depth, void *data)
{
	// 解析节点的属性“device_type”
	const char *type = of_get_flat_dt_prop(node, "device_type", NULL);
	const __be32 *reg, *endp;
	int l;
	…

	/* 只扫描 "memory" 节点 */
	if (type == NULL) {
		/* 如果没有属性“device_type”，判断节点名称是不是“memory@0”*/
		if (!IS_ENABLED(CONFIG_PPC32) || depth != 1 || strcmp(uname, "memory@0") != 0)
			return 0;
	} else if (strcmp(type, "memory") != 0) // 描述物理内存信息
		return 0;

	reg = of_get_flat_dt_prop(node, "linux,usable-memory", &l);
	if (reg == NULL)
		reg = of_get_flat_dt_prop(node, "reg", &l);
	if (reg == NULL)
		return 0;

	endp = reg + (l / sizeof(__be32));
	…

	while ((endp - reg) >= (dt_root_addr_cells + dt_root_size_cells)) {
		u64 base, size;

		base = dt_mem_next_cell(dt_root_addr_cells, &reg);
		size = dt_mem_next_cell(dt_root_size_cells, &reg);

		if (size == 0)
			continue;
		…
		early_init_dt_add_memory_arch(base, size);
		…
	}

	return 0;
}
```
&ensp;解析出每块内存的起始地址和大小后，调用函数early_init_dt_add_memory_arch
```c
// drivers/of/fdt.c
void __init __weak early_init_dt_add_memory_arch(u64 base, u64 size)
{
    const u64 phys_offset = MIN_MEMBLOCK_ADDR;

    if (!PAGE_ALIGNED(base)) {
         if (size < PAGE_SIZE - (base & ~PAGE_MASK)) {
              pr_warn("Ignoring memory block 0x%llx - 0x%llx\n",
                  base, base + size);
              return;
         }
         size -= PAGE_SIZE - (base & ~PAGE_MASK);
         base = PAGE_ALIGN(base);
    }
    size &= PAGE_MASK;

    if (base > MAX_MEMBLOCK_ADDR) {
         pr_warning("Ignoring memory block 0x%llx - 0x%llx\n",
                  base, base + size);
         return;
    }

    if (base + size - 1 > MAX_MEMBLOCK_ADDR) {
         pr_warning("Ignoring memory range 0x%llx - 0x%llx\n",
                  ((u64)MAX_MEMBLOCK_ADDR) + 1, base + size);
         size = MAX_MEMBLOCK_ADDR - base + 1;
    }

    if (base + size < phys_offset) {
         pr_warning("Ignoring memory block 0x%llx - 0x%llx\n",
                base, base + size);
         return;
    }
    if (base < phys_offset) {
         pr_warning("Ignoring memory range 0x%llx - 0x%llx\n",
                base, phys_offset);
         size -= phys_offset - base;
         base = phys_offset;
    }
	// 把物理内存范围添加到memblock.memory
    memblock_add(base, size);
}
```


## 3.7 伙伴分配器

&ensp;内核初始化完毕后，使用页分配器管理物理页，当前使用的页分配器是伙伴分配器buddy allocato

### 3.7.1 基本的伙伴分配器
&ensp;连续的物理页称为页块（page block）。阶（order）是伙伴分配器的一个术语，是页的数量单位，2n个连续页称为n阶页块。满足以下条件的两个n阶页块称为伙伴（buddy）   \
&ensp;伙伴分配器分配和释放物理页的数量单位是阶

### 3.7.2 分区的伙伴分配器

#### 1.数据结构

&ensp;分区的伙伴分配器专注于某个内存节点的某个区域。内存区域的结构体成员free_area用来维护空闲页块，数组下标对应页块的阶数。结构体free_area的成员free_list是空闲页块的链表nr_free是空闲页块的数量。内存区域的结构体成员managed_pages是伙伴分配器管理的物理页的数量，不包括引导内存分配器分配的物理页

```c
include/linux/mmzone.h
struct zone {
    …
    /* 不同长度的空闲区域 */
    struct free_area   free_area[MAX_ORDER];  // MAX_ORDER是最大阶数
    …
    unsigned long      managed_pages;
    …
} ____cacheline_internodealigned_in_smp;

struct free_area {
     struct list_head  free_list[MIGRATE_TYPES];
     unsigned long     nr_free;
};

// include/linux/mmzone.h
/* 空闲内存管理-分区的伙伴分配器 */
#ifndef CONFIG_FORCE_MAX_ZONEORDER
#define MAX_ORDER   11
#else
#define MAX_ORDER   CONFIG_FORCE_MAX_ZONEORDER
#endif
```




#### 2．根据分配标志得到首选区域类型


#### 3. 备用区域列表



#### 4．区域水线


#### 5．防止过度借用


### 3.7.3　根据可移动性分组



### 3.7.4　每处理器页集合

&ensp;内核针对分配单页做了性能优化，为了减少处理器之间的锁竞争，在内存区域增加 1个每处理器页集合。
```c
include/linux/mmzone.h
struct zone {
     …
     struct per_cpu_pageset __percpu *pageset;  /* 在每个处理器上有一个页集合 */
     …
} ____cacheline_internodealigned_in_smp;

struct per_cpu_pageset {
     struct per_cpu_pages pcp;
     …
};

struct per_cpu_pages {
     int count;      /* 链表里面页的数量 */
     int high;       /* 如果页的数量达到高水线，需要返还给伙伴分配器 */
     int batch;      /* 批量添加或删除的页数量 */
     struct list_head lists[MIGRATE_PCPTYPES]; /* 每种迁移类型一个页链表 */
};
```



### 3.7.5　分配页
#### 1．分配接口
&ensp;页分配器分配页接口
```c
// 求分配一个阶数为order的页块，返回一个page实例
alloc_pages(gfp_mask, order)
// 在阶数为0情况下的简化形式，只分配一页
alloc_page(gfp_mask)
// 只能从低端内存区域分配页，并且返回虚拟地址
__get_free_pages(gfp_mask, order)
// 在阶数为0情况下的简化形式，只分配一页
__get_free_page(gfp_mask)
// 参数gfp_mask设置了标志位__GFP_ZERO且阶数为0情况下的简化形式，只分配一页，并且用零初始化
get_zeroed_page(gfp_mask)
```

#### 2．分配标志位
&ensp;分配页的函数都带一个分配标志位参数，分配标志位分为以下5类
&ensp;(1)区域修饰符



&ensp;(2)页移动性和位置提示




&ensp;(3)水线修饰符



&ensp;(4)回收修饰符




&ensp;(5)行动修饰符



#### 3．复合页
&ensp;如果设置了标志位__GFP_COMP并且分配了一个阶数大于0的页块，页分配器会把页块组成复合页（compound page）。复合页最常见的用处是创建巨型页。  \
&ensp;复合页的第一页叫首页（head page），其他页都叫尾页（tail page）

<center>复合页的结构</center>

![20221116001100](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221116001100.png)





#### 4．对高阶原子分配的优化处理



#### 5．核心函数的实现




### 3.7.6　释放页

&ensp;页分配器提供了以下释放页的接口       \
&ensp;（1）void __free_pages(struct page *page, unsigned int order)，第一个参数是第一个物理页的page实例的地址，第二个参数是阶数   \
&ensp;（2）void free_pages(unsigned long addr, unsigned int order)，第一个参数是第一个物理页的起始内核虚拟地址，第二个参数是阶数    \




## 3.8　块分配器

&ensp;Linux内核提供了块分配器，处理小块内存分配问题，最早为SLAB分配器。大量物理内存的大型计算机上SLUB分配器，小内存的嵌入式设备上SLOB   \

### 3.8.1 编程接口

&ensp;3种块分配器提供了统一的编程接口，块分配器在初始化的时候创建了一些通用的内存缓存，从普通区域分配页的内存缓存的名称是`kmalloc-<size>`，DMA区域分配页的内存缓存的名称是`dma-kmalloc-<size>`，执行命令`cat /proc/slabinfo`可以看到这些通用的内存缓存   \

```c
// 分配内存
void *kmalloc(size_t size, gfp_t flags);

// 重新分配内存
void *krealloc(const void *p, size_t new_size, gfp_t flags);

// 释放内存
void kfree(const void *objp);
```


&ensp;创建专用的内存缓存

```c
// 创建内存缓存
struct kmem_cache *kmem_cache_create(const char *name, size_t size, size_t align, unsigned long flags, void (*ctor)(void *));

// 从指定的内存缓存分配对象
void *kmem_cache_alloc(struct kmem_cache *cachep, gfp_t flags);

// 释放对象
void kmem_cache_free(struct kmem_cache *cachep, void *objp);

// 销毁内存缓存
void kmem_cache_destroy(struct kmem_cache *s);
```

### 3.8.2 SLAB分配器

#### 1.数据结构

<center>内存缓存的数据结构</center>

![20221116233943](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221116233943.png)

&ensp;（1）每个内存缓存对应一个kmem_cache实例    \


&ensp;（2）每个内存节点对应一个kmem_cache_node实例

&ensp;page结构体的成员   \
&ensp;1)flags设置标志位PG_slab，表示页属于SLAB分配器      \
&ensp;2)s_mem存放slab第一个对象的地址   \
&ensp;3)active表示已分配对象的数量   \
&ensp;4)lru作为链表节点加入其中一条slab链表   \
&ensp;5)slab_cache指向kmem_cache实例   \
&ensp;6)freelist指向空闲对象链表   \


&ensp;（3）kmem_cache实例的成员cpu_slab指向array_cache实例，


#### 2.空闲对象链表
&ensp;每个slab需要一个空闲对象链表，从而把所有空闲对象链接起来，空闲对象链表是用数组实现的，page->freelist指向空闲对象链表

<center>使用对象存放空闲对象链表-初始状态</center>

![20221116234847](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221116234847.png)


<center>使用对象存放空闲对象链表-分配最后一个空闲对象</center>

![20221116235027](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221116235027.png)

<center>空闲对象链表在slab外面</center>

![20221116235136](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221116235136.png)



#### 3.计算slab长度
&ensp;函数calculate_slab_order负责计算slab长度，从0阶到kmalloc()函数支持的最大阶数（KMALLOC_MAX_ORDER）





#### 4.着色




#### 5．每处理器数组缓存

&ensp;内存缓存为每个处理器创建了一个数组缓存（结构体array_cache）。释放对象时，把对象存放到当前处理器对应的数组缓存中

<center>每处理器数组缓冲</center>

![20221116235443](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221116235443.png)


#### 6．对NUMA的支持
<center>SLAB分配器支持NUMA</center>

![20221116235608](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221116235608.png)



#### 7．内存缓存合并

&ensp;减少内存开销和增加对象的缓存热度，块分配器会合并相似的内存缓存



#### 8.回收内存

&ensp;所有对象空闲的slab，没有立即释放，而是放在空闲slab链表中。只有内存节点上空闲对象的数量超过限制，才开始回收空闲slab，直到空闲对象的数量小于或等于限制    \
&ensp;结构体kmem_cache_node的成员slabs_free是空闲slab链表的头节点，成员free_objects是空闲对象的数量，成员free_limit是空闲对象的数量限制    \

<center>回收空闲slab</center>

![20221116235852](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221116235852.png)


### 3.8.3　SLUB分配器



#### 1．数据结构

<center>SLUB分配器内存缓存的数据结构</center>

![20221117000104](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221117000104.png)



#### 2．空闲对象链表


<center>空闲对象链表的初始状态</center>

![20221117000219](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221117000219.png)

<center>分配一个对象以后的空闲对象链表</center>

![20221117000252](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221117000252.png)



#### 3．计算slab长度

&ensp;SLUB分配器在创建内存缓存的时候计算了两种slab长度：最优slab和最小slab





#### 4．每处理器slab缓存



<center>SLUB分配器的每处理器slab缓存</center>

![2022-11-17_00-04](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/2022-11-17_00-04.png)


#### 5．对NUMA的支持

&ensp;（1）内存缓存针对每个内存节点创建一个kmem_cache_node实例   \
&ensp;（2）分配对象时，如果当前处理器的slab缓存是空的，需要重填当前处理器的slab缓存   \



#### 6.回收内存

&ensp;对于所有对象空闲的slab，如果内存节点的部分空闲slab的数量大于或等于最小部分空闲slab数量，那么直接释放，否则放在部分空闲slab链表的尾部


#### 7.调试



### 3.8.4　SLOB分配器


#### 1．数据结构

<center>SLOB分配器内存缓存的数据结构</center>

![20221117223330](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221117223330.png)


#### 2．空闲对象链表


<center>空闲对象链表的初始状态</center>

![20221117223614](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221117223614.png)

<center>分配一个对象以后的空闲对象链表</center>

![20221117223707](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221117223707.png)


#### 3．分配对象

&ensp;分配对象时，根据对象长度选择不同的策略




## 3.9　不连续页分配器



### 3.9.1　编程接口

&ensp;不连续页分配器提供了以下编程接口
```c
// vmalloc函数：分配不连续的物理页并且把物理页映射到连续的虚拟地址空间
void *vmalloc(unsigned long size);

// vfree函数：释放vmalloc分配的物理页和虚拟地址空间
void vfree(const void *addr);

// vmap函数：把已经分配的不连续物理页映射到连续的虚拟地址空间
// pages是page指针数组，count是page指针数组大小，flags标志位，prot页保护位
void *vmap(struct page **pages, unsigned int count, unsigned long flags, pgprot_t prot);

// vunmap函数：释放使用vmap分配的虚拟地址空间
void vunmap(const void *addr);

// kvmalloc函数：先尝试使用kmalloc分配内存块，如果失败，那么使用vmalloc函数分配不连续的物理页
void *kvmalloc(size_t size, gfp_t flags);

// kvfree函数：如果内存块是使用vmalloc分配的，那么使用vfree释放，否则使用kfree释放
void kvfree(const void *addr);
```






### 3.9.2　数据结构


<center>不连续页分配器的数据结构</center>

![2022-11-17_22-53_1](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/2022-11-17_22-53_1.png)

<center>使用vmap函数分配虚拟内存区域</center>

![20221117225854](https://raw.githubusercontent.com/zainll/PictureBed/main/blogs/pictures/20221117225854.png)


### 3.9.3　技术原理

&ensp;vmalloc虚拟地址空间的范围是[VMALLOC_START, VMALLOC_END)
```c
// arch/arm64/include/asm/pgtable.h
#define VMALLOC_START        (MODULES_END)
#define VMALLOC_END       (PAGE_OFFSET - PUD_SIZE - VMEMMAP_SIZE - SZ_64K)
```
&ensp;MODULES_END是内核模块区域的结束地址，PAGE_OFFSET是线性映射区域的起始地址，PUD_SIZE是一个页上层目录表项映射的地址空间长度，VMEMMAP_SIZE是vmemmap区域的长度。    \
&ensp;vmalloc虚拟地址空间的起始地址等于内核模块区域的结束地址。   \
&ensp;vmalloc虚拟地址空间的结束地址等于（线性映射区域的起始地址−一个页上层目录表项映射的地址空间长度−vmemmap区域的长度−64KB）   \
&ensp;函数vmalloc的执行过程分为3步       \
&ensp;（1）分配虚拟内存区域          \
&emsp;分配vm_struct实例和vmap_area实例    \
&ensp;（2） 分配物理页        \
&emsp;vm_struct实例的成员nr_pages存放页数n；分配page指针数组   \
&ensp;（3）在内核的页表中把虚拟页映射到物理页    \
&emsp;内核的页表就是0号内核线程的页表。0号内核线程的进程描述符是全局变量init_task，成员active_mm指向全局变量init_mm，init_mm的成员pgd指向页全局目录swapper_pg_dir





## 3.10　每处理器内存分配器


### 3.10.1　编程接口



### 3.10.2　技术原理




## 3.11　页表


### 3.11.1　统一的页表框架



### 3.11.2　ARM64处理器的页表



## 3.12　页表缓存


### 3.12.1　TLB表项格式



### 3.12.2　TLB管理



### 3.12.3　地址空间标识符




### 3.12.4　虚拟机标识符





## 3.13　巨型页

### 3.13.1　处理器对巨型页的支持



### 3.13.2　标准巨型页



### 3.13.3　透明巨型页


## 3.14　页错误异常处理

### 3.14.1　处理器架构特定部分


### 3.14.2　用户空间页错误异常




### 3.14.3　内核模式页错误异常




## 3.15　反碎片技术



### 3.15.1　虚拟可移动区域




### 3.15.2　内存碎片整理




## 3.16　页回收


### 3.16.1　数据结构





### 


### 3.16.3　计算扫描的页数


### 3.16.4　收缩活动页链表




### 3.16.5　回收不活动页



### 3.16.6　页交换




### 3.16.7　回收slab缓存





## 3.17　内存耗尽杀手



### 3.17.1　使用方法


### 3.17.2　技术原理





## 3.18　内存资源控制器






### 3.18.1　使用方法



### 3.18.2　技术原理






## 3.19　处理器缓存


### 3.19.1　缓存结构







### 3.19.2　缓存策略





## 3.20 连续内存分配器









## 3.21 userfaultfd




## 3.22 内存错误检测工具KASAN































































































































