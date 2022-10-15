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
disable_existing_loggers: true

formatters:
    standard:
        format: "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    error:
        format: "%(levelname)s <PID %(process)d:%(processName)s> %(name)s.%(funcName)s(): %(message)s"

version: 1
disable_existing_loggers: False
formatters:
    standard:
        format: "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    simple:
        #format: "%(levelname)s <PID %(process)d:%(processName)s> %(name)s.%(funcName)s(): %(message)s"
        format: "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
handlers:
    console:
        class: logging.StreamHandler
        level: DEBUG
        formatter: simple
        stream: ext://sys.stdout
    info_file_handler:
        class: logging.handlers.RotatingFileHandler
        level: DEBUG
        formatter: simple
        filename: ./logs/log.log
        maxBytes: 10485760
        backupCount: 20
        encoding: utf8
    error_file_handler:
        class: logging.handlers.RotatingFileHandler
        level: ERROR
        formatter: simple
        filename: errors.log
        maxBytes: 10485760
        backupCount: 20
        encoding: utf8
loggers:
    my_module:
            level: ERROR
            handlers: [info_file_handler]
            # 打开日志记录器
            propagate: False
root:
    level: DEBUG
    handlers: [console,info_file_handler,error_file_handler]

```

```python
# logging.py
import os
import yaml
import logging.config
import logging
import coloredlogs


class Logger():
    def __init__(self, default_path = "logging.yaml", default_level = logging.INFO,env_key = "LOG_CFG"):

def setup_logging(default_path = "logging.yaml",default_level = logging.INFO,env_key = "LOG_CFG"):
    path = default_path
    value = os.getenv(env_key,None)
    if value:
        path = value
    if os.path.exists(path):
        with open(path,"r") as f:
            config = yaml.load(f)
            logging.config.dictConfig(config)
    else:
        logging.basicConfig(level = default_level)


def setup_logging(default_path='logging.yaml', default_level=logging.INFO, env_key='LOG_CFG'):
    """
    | **@author:** Prathyush SP
    | Logging Setup
    """
    path = default_path
    value = os.getenv(env_key, None)
    if value:
        path = value
    if os.path.exists(path):
        with open(path, 'rt') as f:
            try:
                config = yaml.safe_load(f.read())
                logging.config.dictConfig(config)
                coloredlogs.install()
            except Exception as e:
                print(e)
                print('Error in Logging Configuration. Using default configs')
                logging.basicConfig(level=default_level)
                coloredlogs.install(level=default_level)
    else:
        logging.basicConfig(level=default_level)
        coloredlogs.install(level=default_level)
        print('Failed to load configuration file. Using default configs')

```



参考链接：
- https://blog.csdn.net/weixin_43988680/article/details/123528294
- https://zhuanlan.zhihu.com/p/425678081
- https://blog.csdn.net/qq_35812205/article/details/126480417


# c log
## zlog
https://blog.csdn.net/twd_1991/article/details/80481920

http://hardysimpson.github.io/zlog/UsersGuide-CN.html


