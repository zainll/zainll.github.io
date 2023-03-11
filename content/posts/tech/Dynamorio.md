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


# DynamoRIO官方

https://dynamorio.org/  <brs>
https://github.com/DynamoRIO/dynamorio

```sh

git clone https://github.com/DynamoRIO/dynamorio.git  --recursive

```


## 编译
- 注意wsl中需要root用户编译
https://dynamorio.org/page_building.html

```sh
# Android 编译配置
mkdir build
cd build
cmake \
-DCMAKE_TOOLCHAIN_FILE=../dynamorio/make/toolchain-android=arm64.cmake \
-DANDROID_TOOLCHAIN=/home/zain/tool/android-ndk-r21e/toolchains \
-DDR_COPY_TO_DEVICE=OFF \
-DCMAKE_BUILD_TYPE=Debug \
-DBUILD_TESTS=OFF \
-DBUILD_SAMPLES=ON \
-DBUILD_CLIENTS=ON \
../


../dynamorio
/home/zain/tool/android-ndk-r21e/toolchains
-DANDROID_TOOLCHAIN=/android_toolchain_using \
```

```sh
# AArch64 树莓派 编译配置
mkdir build
cd build
cmake \
-DCMAKE_TOOLCHAIN_FILE=../dynamorio/make/toolchain-arm32.cmake \
-DANDROID_TOOLCHAIN=/home/zain/tool/raspbian_complier/arm-bcm2708/arm-linux-gnueabihf/bin \
-DDR_COPY_TO_DEVICE=OFF \
-DCMAKE_BUILD_TYPE=Debug \
-DBUILD_TESTS=OFF \
-DBUILD_SAMPLES=ON \
-DBUILD_CLIENTS=ON \
../dynamorio

cmake \
-DCMAKE_TOOLCHAIN_FILE=../dynamorio/make/toolchain-aarch64_raspbian_armv8.cmake \
-DANDROID_TOOLCHAIN=/home/zain/tool/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin \
-DDR_COPY_TO_DEVICE=OFF \
-DCMAKE_BUILD_TYPE=Debug \
-DBUILD_TESTS=OFF \
-DBUILD_SAMPLES=ON \
-DBUILD_CLIENTS=ON \
../dynamorio

/home/zain/tool/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin



-DCMAKE_TOOLCHAIN_FILE=../dynamorio/make/toolchain-aarch64_raspbian.cmake \
../dynamorio
/home/zain/tool/android-ndk-r21e/toolchains
-DANDROID_TOOLCHAIN=/android_toolchain_using \
```




```sh
# x64 编译配置
cd dynamorio
mkdir build
cd build
cmake \
-DDR_COPY_TO_DEVICE=OFF \
-DCMAKE_BUILD_TYPE=Debug \
-DBUILD_TESTS=OFF \
-DBUILD_SAMPLES=ON \
-DBUILD_CLIENTS=ON \
../dynamorio/

# 编译
make -j12
```

```sh
# 使用
# 帮助
./bin64/drrun --help
# 参数 -c 指定client so 
# libbbbuf
./bin64/drrun -verbose -c ./api/bin/libbbbuf.so -- ls
bin64/drrun -debug -loglevel 2 -- ls
./bin64/drrun -attach <pid> 
```

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
                        dispatch_enter_dynamorio
                        build_basic_block_fragment
                        dispatch_enter_fcache
```

## client

### libbbbuf.so





- 学习链接
DynamoRIO进阶指南
https://blog.csdn.net/oShuangYue12/article/details/109780166
DynamoRIO的入门指南（Ubuntu）
https://blog.csdn.net/ts_forever/article/details/124614200


[aarch64-linux-gnu 交叉编译 libpcap](https://blog.csdn.net/huaheshangxo/article/details/123897854)

