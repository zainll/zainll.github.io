---
title: "DynamoRIO"
date: 2022-05-05T00:17:58+08:00
lastmod: 2022-05-05T00:17:58+08:00
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


# Dynamorio代码学习

## drrun

```c
_tmain  // drrun入口    tools/drdeploy.c
    dr_inject_process_create   // 创建注入子进程？ dr_inject_info_t *info 
        fork_suspended_child   // fork子进程
    dr_inject_process_inject   // 进程注入？  core/unix/injector.c
        switch (info->method) {
            case INJECT_EARLY: 
                return inject_early(info, library_path);   // exec 执行？
                    execute_exec   // 执行 libdynamorio.so？ 
                        execv
            case INJECT_LD_PRELOAD: 
                return inject_ld_preload(info, library_path);
                    pre_execve_ld_preload
                    execute_exec
                        execv
            case INJECT_PTRACE: 
                return inject_ptrace(info, library_path);  attach ？
                    our_ptrace   // ptrace ？
                    injectee_open  // Call sys_open in the child
                    elf_loader_read_headers  // 子进程执行mmap？
                    elf_loader_map_phdrs   // 计算 libdynamorio 地址？
                        injectee_map_file
                        injectee_unmap
                        injectee_prot
                        injectee_memset
                    our_ptrace_getregs
                    // 等待SIGTRAP信号
                    unexpected_trace_event // 处理非SIGTRAP信号，return false

    dr_inject_process_run
        execute_exec
    dr_inject_wait_for_child   // waiting for app to exit..
    dr_inject_process_exit  // 退出
 
```
&emsp;_tmain函数开始部分为配置参数，如 -verbose，-force，-attach，-takeovers，-c等,
  append_client添加client <br>
&emsp;use_debug verbose

## libdynamorio

```C
// core/arch/aarchxx/aarchxx.asm core/arch/riscv64/riscv64.asm  core/arch/x86/x86.asm
_start
    relocate_dynamorio
    privload_early_inject
    if (*argc == ARGC_PTRACE_SENTINEL)
        takeover_ptrace
            dynamorio_app_init
                dynamorio_app_init_part_one_options
                    open_log_file  // 日志
                dynamorio_app_init_part_two_finalize  // 初始化主要部分

            dynamorio_syscall  core/arch/x86_code.c // 不区分平台目录
                call_switch_stack
                    d_r_dispatch
            dynamo_start
                dynamorio_take_over_threads
                call_switch_stack
                    d_r_dispatch
                        while(true) {
                            dispatch_enter_dynamorio
                                handle_post_system_call
                                    post_system_call   // 信号前
                                handle_system_call
                                    pre_system_call    // 信号后
                            build_basic_block_fragment
                                build_bb_ilist    // 构建bb块
                                build_native_exec_bb  // 执行bb块？
                            dispatch_enter_fcache
                                enter_fcache
                                    (*entry)(dcontext);
                        }
```

dispatch_enter_dynamorio
    handle_system_call
        pre_system_call

        handle_post_system_call
            post_system_call


dynamorio_app_init_part_two_finalize           
    dynamo_thread_init
        os_thread_init
            signal_thread_init
                call_switch_stack


## client

### libbbbuf.so





- 参考学习链接

[DynamoRIO源码分析——劫持进程](https://zhuanlan.zhihu.com/p/623819001)
[DynamoRIO源码分析(二)--基本块(Basic Blocks)和跟踪 (trace) ](https://bbs.kanxue.com/thread-276890.htm)

DynamoRIO进阶指南
https://blog.csdn.net/oShuangYue12/article/details/109780166
DynamoRIO的入门指南（Ubuntu）
https://blog.csdn.net/ts_forever/article/details/124614200


https://www.anquanke.com/post/id/218568?display=mobile

[aarch64-linux-gnu 交叉编译 libpcap](https://blog.csdn.net/huaheshangxo/article/details/123897854)

