---
title: "git"
date: 2022-09-05T00:17:58+08:00
lastmod: 2022-09-05T00:17:58+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- tech
- git
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

## git操作


```sh
# 下载代码，ssh或https 一种方式出错换用另一种
git clone

# 创建分支
git checkout -b br_master

# 提交
git status
git add .
git commit 
# 合并到前一个commit
git commit --amend

# 拉取更新代码
git pull

# 推送
git push

# 合并已push的commit
git rebase -i HEAD~n

# 强制更新覆盖本次
git fetch --all
git reset --hard HEAD
git pull

# 强制推送
git push -u origin br_master --force

# 回合代码
git rebase master

# 回退已提交commit
git reset --soft  <commit-ID>

# 忽略部分文件提交
git add filename
# 放入本地栈
git stash -u -k     
git commit
git push
# 弹出本地栈
git stash pop 

```

## git配置

```sh
git config --global user.name "xxx"
git config --global user.email "xxx@163.com"
git config --list
user.name=xxx
user.email=xxx@163.com

# 生成秘钥
ssh-keygen -t rsa -C 'xxx@163.com'
# cd ~/.ssh 将 id_rsa.pub 添加道GitHub
# 测试链接
ssh -T git@github.com


# 设置默认编辑为vim
git config --global core.editor "vim"
```

[玩转WSL(6)之Git配置](https://zhuanlan.zhihu.com/p/252505037)



[git同时配置Gitee和Github](https://www.cnblogs.com/tcdhl/p/14646365.html)


[Git设置换行符为LF](https://blog.csdn.net/sunday2018/article/details/116402894)


[git使用小技巧 url.](https://blog.csdn.net/weixin_42309693/article/details/121718073)

[gitee突然无法访问](https://www.cnblogs.com/jerrybky/p/17188466.html)

## 自动上传脚本
```sh
#!/usr/bin/env bash
# Filename: deploy.sh
#

#### Action 1 ####

echo -e "
===========Building web pages... [HTML]==============="
# Build the project.
#hugo --config ./config/_default/config.toml --gc --minify
hugo -F --cleanDestinationDir

#### Action 2 ####

echo -e "
++++++++++++++++Upload the HUGO br_hugo site...++++++++++++++
"
# ----------------------------------------------
# Add changes to git.
git status
git add .
# Commit changes.
msg="Update $(date +"[%x %T]")"
if [ -n "$*" ]; then
    msg="$*"
fi
git commit -m "$msg"
# Push source and build repos.
git push origin br_hugo
# ----------------------------------------------


#### Action 3 ####

echo -e "
-----------Upload pages to master CODING... [HTML]----------
"
# Go To Repository folder
cd public
# ----------------------------------------------
# Add changes to git.
git status
git add .
# Commit changes.
msg="Update $(date +"[%x %T]")"
if [ -n "$*" ]; then
    msg="$*"
fi
git commit -m "$msg"
# Push source and build repos.
git push origin master
# ----------------------------------------------
# Come Back up to the Project Root
cd ..

echo -e "
===========Upload Successful [HTML]===========
"
```



