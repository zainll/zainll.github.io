---
title: "cmake"
date: 2022-05-17T00:17:58+08:00
lastmod: 2022-05-18T00:17:58+08:00
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



## 1.cmake简述
&ensp;CMake是跨平台编译管理工具,为第三方依赖和引入,创建编译系统,程序测试及安装.Cmake工具使用CMakeLists.txt文件,跨平台执行相同编译命令,生成对应平台的可执行程序或者链接库.

<!--more-->

&ensp;CMake工程简单例子
```sh
cmake_minimum_required(VERSION 3.12)
project(myproj)
find_package(Poco REQUIRED COMPONENTS Net Util)
add_executable(MyExe)
target_source(MyExe PRIVATE "main.cpp")
target_link_library(MyExe PRIVATE Poco::Net PocoUtil)

target_complie_definition(MyExe PRIVATE std_cxx_14)
```

## 2.Target 和围绕 Target 的配置
&ensp;C/C++工程通常都是为了生成可执行程序或者链接库，在现代 CMake 里他们被统称为`target`，创建命令分别是`add_library()`和`add_executable()`。其中链接库的类型又分为很多种，最常用的就是`SHARED`以及`STATIC`，在命令中加入关键词进行声明：add_library(MyLib SHARED)，第一个参数为target的名称，后续的配置都需要用到这个名字。
&ensp;指定target的源文件：
```sh
target_source(MyLib PRVIATE "main.cpp" "func.cpp")
```
&emsp;PRIVATE关键词用于描述参数的“应用范围”，此外还有INTERFACE和PUBLIC两种可能的值

&ensp;较多的源文件，可以使用 CMake 的file命令进行遍历拿到全部的源文件
```sh
file(GLOB_RECURSE SRCS ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
```
&emsp;命令第一个参数GLOB_RECURSE表明递归的查找子文件夹，第二个参数SRCS则是存储结果的变量名，第三个参数为目标文件的匹配模式，找到符合条件的 cpp 文件后，他们的路径会以字符串数组的形式保存在 SRCS 变量中，使用方式如下：
```sh
target_source(MyLib PRIVATE ${SRCS})
```
&ensp;配置target时通常还需要指定头文件目录：
```sh
target_include_directories(MyLib PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include/)
```
&ensp;编译时需要的语言特性：
```sh
target_compile_features(MyLib PRIVATE std_cxx_14)
```
&ensp;编译时的宏定义：
```sh
target_compile_definitions(MyLib PRIVATE LogLevel=3)
```
&ensp;参数想直接传给底层的编译器（比如 gcc, clang, cl），可以使用
```sh
target_compile_options(MyLib PRIVATE -Werror -Wall -Wextra)

```

## 3.Build Specification 和 Usage Requirement

&ensp;C/C++通过 include 头文件的方式引入依赖，在动态或静态链接后可以调用依赖实现。一个可执行程序可能会依赖链接库，链接库也同样可能依赖其他的链接库
&ensp;CMake 提供的解决方案是，在对 target 进行配置时，可以规定配置的类型，分为 build specification 和 usage requirement 两类，会影响配置的应用范围。Build specification 类型的配置仅在编译的时候需要满足，通过PRIVATE关键字声明；Usage requirement 类型的配置则是在使用时需要满足，即在其他项目里，使用本项目已编译好的 target 时需要满足，这种类型的配置使用INTERFACE关键词声明。在实际工程中，有很多配置在编译时以及被使用时都需要被满足的，这种配置通过PUBLIC关键词进行声明。

&ensp;一个 library，在编译时静态链接了 Boost，在我们的实现文件中使用了 c++14 的特性，并用到了 Boost 的头文件和函数。随后我们对外发布了这个库，其中有头文件和预编译好的动态链接库。尽管我们的实现代码里用了 C++14，但在对外提供的头文件中只用到 C++03 的语法，也没有引入任何 Boost 的代码。这种情况下，当其他工程在使用我们的 library 时，其使用的编译器不需要开启 C++14 的支持，开发环境下也不需要安装 Boost。我们 library 的 CMake 配置中可以这么写：
```sh
target_compile_features(MyLib PRIVATE cxx_std_14)
target_link_libraries(MyLib PRIVATE Boost::Format)
```
&emsp;PRIVATE 说明 c++14 的支持只在编译时需要用到，Boost 库的链接也仅在编译时需要。但如果我们对外提供的头文件中也使用了 C++14，那么就需要使用 PUBLIC 修饰，改为：
```sh
target_compile_features(MyLib PUBLIC cxx_std_14)
target_link_libraries(MyLib PRIVATE Boost::Format)
```
&emsp;当 library 是 header-only 时，我们的工程是不需要单独编译的，因此也就没有 build specification，通过INTERFACE修饰配置即可
```sh
arget_compile_features(MyLib INTERFACE cxx_std_14)
```
&ensp;Usage requirement 类型的配置，即通过INTERFACE或是PUBLIC修饰的配置是会传递的，比如 LibA 依赖 LibB 后，会继承 LibB 的 usage requirement，此后 LibC 依赖 LibB 时，LibA 和 libB 的 usage requirement 都会继承下来，

## 4.寻找和使用链接库

&ensp;C/C++标准没有规范库的安装位置和安装形式，通过 CMake 提供的方案寻找依赖，不光可以定位到头文件目录和链接库路径，还能够获取到库的 usage requirement。
&ensp;在 CMake 中寻找第三方库的命令为find_package，其背后的工作方式有两种，一种基于 Config File 的查找，另一种则是基于 Find File 的查找。在执行find_package时，实际上 CMake 都是在找这两类文件，找到后从中获取关于库的信息。
### 4.1 通过 Config file 找到依赖
&ensp;Config File 是依赖的开发者提供的 cmake 脚本，通常会随预编译好的二进制一起发布，供下游的使用者使用。在 Config file 里，会对库里包含的 target 进行描述，说明版本信息以及头文件路径、链接库路径、编译选项等 usage requirement

&ensp;CMake 对 Config file 的命名是有规定的，对于find_package(ABC)这样一条命令，CMake 只会去寻找ABCConfig.cmake或是abc-config.cmake。CMake 默认寻找的路径和平台有关，在 Linux 下寻找路径包括/usr/lib/cmake以及/usr/lib/local/cmake，在这两个路径下可以发现大量的 Config File，一般在安装某个库时，其自带的 Config file 会被放到这里来。

### 4.2 通过 Find file 找到依赖

&ensp;对于find_package(ABC)命令，如果 CMake 没有找到 Config file，他还会去试着寻找FindABC.cmake。Find file 在功能上和 Config file 相同，区别在于 Find file 是由其他人编写的，而非库的开发者。如果你使用的某个库没有提供 Config file，你可以去网上搜搜 Find file 或者自己写一个，然后加入到你的 CMake 工程中。

&ensp;CMake 官方为我们写好了很多 Find file，在CMake Documentation这一页面可以看到，OpenGL，OpenMP，SDL 这些知名的库官方都为我们写好了 Find 脚本，因此直接调用 find_package 命令即可。但由于库的安装位置并不是固定的，这些 Find 脚本不一定能找到库，此时根据 CMake 报错的提示设置对应变量即可，通常是需要提供安装路径，这样就可以通过 Find file 获取到库的 usage requirement。不论是 Config file 还是 Find file，其目的都不只是找到库这么简单，而是告诉 CMake 如何使用这个库。
库 CMake 官方也没有提供 Find file，这时候就要自己写了或者靠搜索了，写好后放到本项目的目录下，修改CMAKE_MODULE_PATH这个 CMAKE 变量：
```sh
list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_SOURCE_DIR}/cmake)
```
&emsp;${CMAKE_SOURCE_DIR}/cmake目录下的 Find file 就可以被 CMake 找到了。
&ensp;通过 CMake 的find_library和find_path两个命令就可以完成任务：
```sh
find_library(MPI_LIBRARY
  NAMES mpi
  HINTS "${CMAKE_PREFIX_PATH}/lib" ${MPI_LIB_PATH}
  # 如果默认路径没找到libmpi.so，还会去MPI_LIB_PATH找，下游使用者可以设置这个变量值
)
find_path(MPI_INCLUDE_DIR
  NAMES mpi.h
  PATHS "${CMAKE_PREFIX_PATH}/include" ${MPI_INCLUDE_PATH}
  # 如果默认路径没找到mpi.h，还会去MPI_INCLUDE_PATH找，下游使用者可以设置这个变量值
)
```

### 4.3.find_package 的处理
&ensp;find_package这个命令，这个命令可以指定很多参数，比如指定版本，指定具体的模块等等。以 SFML 多媒体库为例，其包含了 network 模块，audio 模块，graphic 模块等等，但我很多时候只用到 graphic 模块，那么其他的模块对应的链接库不需要被链接，于是 CMake 脚本可以这么写：
```sh
# 要求大版本号为2的SFML库的graphic模块
find_package(SFML 2 COMPONENTS graphics REQUIRED)
# SFML提供的target名字为sfml-graphics
target_link_libraries(MyEXE PRIVATE sfml-graphics)
```

### 5.使用 CMake 来编译

&ensp;CMake 生成好编译环境后，底层的 make, ninja, MSBuild 编译命令都是不一样的，但 CMake 提供了一个统一的方法进行编译：
```sh
cmake --build .
```
&emsp;使用--buildflag，CMake 就会调用底层的编译命令，在跨平台时十分方便。
&emsp;对于 Visual Studio，其 Debug 和 Release 环境是基于 configuration 的，因此CMAKE_BUILD_TYPE变量无效，需要在 build 时指定：
```sh
cmake --build . --config Release
```

## CPM

[使用CPM管理CMake C++工程中的外部依赖库](https://blog.csdn.net/davidhopper/article/details/121030549)


- 参考链接:
cmake
https://ukabuer.me/blog/more-modern-cmake/
Makefile
