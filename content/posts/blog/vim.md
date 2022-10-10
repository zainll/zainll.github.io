---
title: "vim"
date: 2022-05-05T00:18:23+08:00
lastmod: 2022-05-05T00:18:23+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- vim
- tool
description: ""  #描述
weight:  # 输入1可以顶置文章，用来给文章展示排序，不填就默认按时间排序
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








# Vim

## vim快捷方式

```sh
# 编辑模式 i  a   o
# i 进入编辑模式
# 退出ESC 返回命令模式
# 保存退出
wq
# 放弃退出
!q
# 回到文件首部
gg
# 到文件尾部
GG

```

[史上最全的vim快捷键](https://blog.csdn.net/qq_48711800/article/details/119388911)     \
[Vim使用笔记 ](https://www.cnblogs.com/jiqingwu/archive/2012/06/14/vim_notes.html#id59)


## Windows使用Vim
* 在Windows系统中，安装git后已经存在vim，找到vim.exe所在目录，添加到环境变量path中即可。
* Windows下载 Vim安装  参考博客：[在Windows下安装和使用vim](https://blog.csdn.net/mrzry1024/article/details/126189352)




# PowerVim

## PowerVim快捷键

```sh
;n       # 打开文件目录树显示在屏幕左侧
;m       # 打开当前函数和变量目录树显示在屏幕右侧
;w       # 保存文件
;u       # 向上翻半屏
;d       # 向下翻半屏
;1       # 光标快速移动到行首
;2       # 光标快速移动到行末
;a       # 快速切换.h和cpp文件，写C++的时候很方便
;e       # 打开一个新文件
;z       # 切回shell交互命令，输入fg在切回vim，非常实用
;s       # 水平分屏，并打开文件目录选取想打开的文件，如果想新建文件，;e 就好
;v       # 竖直分屏，并打开文件目录选取想打开的文件，如果想新建文件，;e 就好
;fw      # 查找项目内关键字
;ff      # 查找项目内文件名
;gt      # 跳转到变量或者函数定义的地方，前提是安装ctags，并且在在PowerVim输入 ;tg命令 Jump to the definition of the keyword where the cursor is located, but make sure you have make ctags
;gr      # 跳回，对应着;gt
;tg      # 对当前目录打ctag
;y       # 保存当前选中的目录到系统剪切板，前提是vim支持系统剪切板的寄存器
dsfa;w
;h/l/k/j  # 光标向左右上下窗口移动，特别是打开多个窗口。使用这个快捷键组合非常实用
;gg       # 按顺序光标跳转各个窗口
# Shortcuts without ;

e        # 快速删除光标所在的词
tabc     # 关闭当前tab，可以用:tabnew来打开一个新的tab Close tab, of course you should :tabnew a file first.
F1       # 编译C++代码，自己写的C++例子的时候一键编译。前提手动在当前目录建一个bin文件夹，这是用来存放编译产生的执行文件
gc       # 快速注释选中的块（是visual模式下选中的块）
gcc      # 快速当前行
{        # 光标向上移动一个代码块s
}        # 光标向下移动一个代码块

```

## PowerVim安装及配置

[【VIM】PowerVim安装及使用](https://blog.csdn.net/weixin_44583590/article/details/120896928)

[PowerVim - 使Vim更加强大易用](https://www.jianshu.com/p/c2641958b30f?utm_campaign=maleskine&utm_content=note&utm_medium=seo_notes&utm_source=recommendation)

[安装PowerVim 问题解决过程记录](https://blog.csdn.net/u010707098/article/details/125117224)

## ctags



