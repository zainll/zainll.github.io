---
title: "hexo->hugo迁移"
date: 2022-05-05T00:18:23+08:00
lastmod: 2022-05-05T00:18:23+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- blog
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


# hugo运行
```sh
hugo -F --cleanDestinationDir

# 本地预览
hugo server
```
参考链接：
- https://www.sulvblog.cn/
- https://www.jianshu.com/p/fa95c0c1fdab
- https://lishensuo.github.io/
- https://freeze.org.cn/page/7/#main
https://blog.csdn.net/qq_45975757/article/details/108923612
- https://luckyu.com.cn/index.html?_sw-precache=b052c2fa6d5b2f1a059fb72907f20d38

- https://blog.csdn.net/qq_45975757/article/details/108923612



```sh
mongodb+srv://twikoo:zhuang738191@cluster0.dzagnuh.mongodb.net/?retryWrites=true&w=majority

{"code":100,"message":"Twikoo 云函数运行正常，请参考 https://twikoo.js.org/quick-start.html#%E5%89%8D%E7%AB%AF%E9%83%A8%E7%BD%B2 完成前端的配置","version":"1.6.7"}
```

## 托管
&ensp; 为了提高访问速度托管在gitee上，迁移完成后将会同时托管到github中。
&ensp; 通过不同分支保存源码和静态网页内容，用br_hugo管理源码，master分支管理public

# hexo


```sh
# 清理缓存
hexo clean
# 生成网页
hexo g
# 启动本地服务端口
hexo s
# 发布到github
hexo d


# 强制推送备份源码分支
git push -f origin backup
```
## GitHub Pages + Hexo使用及配置

github上创建一个  username.github.io 的工程，username 必须为github的用户名

## 参考链接

https://www.jianshu.com/p/f82c76b90336

https://www.jianshu.com/p/5d0b31032d55

https://blog.csdn.net/weixin_41922289/article/details/95639870

https://theme-next.org/

https://hexo.io/zh-cn/docs/

https://www.jianshu.com/p/3a05351a37dc

https://www.zhyong.cn/posts/ca02/

http://theme-next.iissnan.com/

https://liam.page/

https://liam.page/en/



## 装饰

- Hexo博客添加helper-live2d动态模型插件
https://blog.csdn.net/qq_30930805/article/details/


- emojiall 图标可嵌入博客中
https://www.emojiall.com/zh-hans/sub-categories/A15


##  图床

> vscode + PicGo + github

```sh
# 快捷方式
# 粘贴板上传
ctrl + alt + u
# 目录选择上传
ctrl + alt + e

```

参考链接：
https://blog.csdn.net/qq_44314954/article/details/122951033
https://blog.csdn.net/qq_44314954/article/details/122951033