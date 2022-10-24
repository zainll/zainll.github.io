---
title: "logging"
date: 2022-09-05T00:17:58+08:00
lastmod: 2022-09-05T00:17:58+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- tech
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


# python logging

```sh
#  logging.yaml：
version: 1
disable_existing_loggers: False

formatters:
    simple:
        format: '%(asctime)s %(levelname)s %(message)s'
    upgrade:
        format: "%(asctime)s -Loc %(filename)s -Pid %(process)d -%(name)s -%(levelname)s - %(message)s"

handlers:
    console:
        class: logging.StreamHandler
        level: DEBUG
        formatter: simple
        stream: ext://sys.stdout

    all_file_handler:
        class: logging.handlers.RotatingFileHandler
        level: DEBUG
        formatter: upgrade
        filename: ./logs/all_log.log
        maxBytes: 10485760 # 10MB
        backupCount: 50 #保留50个log文件
        encoding: utf8
    
    server_file_handler:
        class: logging.handlers.RotatingFileHandler
        level: INFO # 只在文件中记录INFO级别及以上的log
        formatter: upgrade
        filename: ./logs/server.log
        maxBytes: 10485760 # 10MB
        backupCount: 20
        encoding: utf8

loggers:
    server:
        level: DEBUG #允许打印DEBUG及以上log
        handlers: [server_file_handler]
        propagate: true #设为false则禁止将日志消息传递给父级记录器的处理程序中

root:
    level: DEBUG
    handlers: [console, all_file_handler]


```

```python
# logger.py
# logging.py
from fileinput import filename
import os
import time
import yaml
import logging.config
import logging
import datetime
#import coloredlogs


class Logger():
    def __init__(self,  log_name="log.log", log_path = "./logs", default_path = "logging.yaml", default_level = logging.INFO,env_key = "LOG_CFG"):
        self.log_name = log_name
        self.log_path = log_path
        #time_stamp = time.
        now = time.strftime('%Y-%m-%d %H_%M_%S_')
        # 文件的命令以及打开路径
        log_filename =  self.log_path + "/" + now + self.log_name 
        with open(file=default_path, mode='r', encoding="utf-8")as file:
            logging_yaml = yaml.load(stream=file, Loader=yaml.FullLoader)
            logging_yaml['handlers']['all_file_handler']['filename'] = log_filename
        print("logging_yaml ",logging_yaml)
        handlers = logging_yaml['handlers']
        for key, value in handlers.items():
            if 'filename' in value:
                log_path = (os.path.split(value['filename'])[0])
                print("log_path")
                if not os.path.exists(log_path):
                    os.makedirs(log_path)
        # 配置logging日志：主要从文件中读取handler的配置、formatter（格式化日志样式）、logger记录器的配置
        logging.config.dictConfig(config=logging_yaml)
        ###设置完毕###
        # 获取根记录器：配置信息从yaml文件中获取
        root = logging.getLogger()
        # 子记录器的名字与配置文件中loggers字段内的保持一致
        server = logging.getLogger("server")
        print("rootlogger:", root.handlers)
        print("serverlogger:", server.handlers)
        print("子记录器与根记录器的handler是否相同：", root.handlers[0] == server.handlers[0])



if __name__ =='__main__':
    Logger()
    logging.info("first log")

```



参考链接：
- https://blog.csdn.net/weixin_43988680/article/details/123528294
- https://zhuanlan.zhihu.com/p/425678081
- https://blog.csdn.net/qq_35812205/article/details/126480417
- https://blog.csdn.net/TracelessLe/article/details/108887001


# c log
## zlog
https://blog.csdn.net/twd_1991/article/details/80481920

http://hardysimpson.github.io/zlog/UsersGuide-CN.html


