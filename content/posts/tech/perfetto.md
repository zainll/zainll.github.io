---
title: "perfetto"
date: 2023-08-15T00:17:58+08:00
lastmod: 2023-08-15T00:17:58+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- tech
- tool
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





# perfetto

[perfetto UI](https://ui.perfetto.dev/)

[perfetto 官网](https://perfetto.dev/)
[perfetto 开源代码](https://github.com/google/perfetto)


```sh

python3 record_android_trace -c /home/zain/work/code/opentool/config.pbtx   -o /home/zain/work/tmp/


```



```xml

buffers: {
    size_kb: 63488
    fill_policy: RING_BUFFER
}
buffers: {
    size_kb: 20480
    fill_policy: RING_BUFFER
}
buffers: {
    size_kb: 63488
    fill_policy: RING_BUFFER
}
data_sources: {
    config {
        name: "android.packages_list"
        target_buffer: 1
    }
}
data_sources: {
    config {
        name: "linux.process_stats"
        target_buffer: 1
        process_stats_config {
            scan_all_processes_on_start: true
            proc_stats_poll_ms: 1000
        }
    }
}
data_sources: {
    config {
        name: "android.log"
        android_log_config {
            log_ids: LID_SYSTEM
        }
    }
}
data_sources: {
    config {
        name: "android.surfaceflinger.frametimeline"
    }
}
data_sources: {
    config {
        name: "android.game_interventions"
    }
}
data_sources: {
    config {
        name: "android.network_packets"
        network_packet_trace_config {
            poll_ms: 250
        }
    }
}
data_sources: {
    config {
        name: "android.packages_list"
    }
}
data_sources: {
    config {
        name: "linux.sys_stats"
        sys_stats_config {
            meminfo_period_ms: 1000
            meminfo_counters: MEMINFO_ACTIVE_FILE
            vmstat_period_ms: 1000
            stat_period_ms: 1000
            stat_counters: STAT_CPU_TIMES
            stat_counters: STAT_FORK_COUNT
            cpufreq_period_ms: 1000
        }
    }
}
data_sources: {
    config {
        name: "android.heapprofd"
        target_buffer: 0
        heapprofd_config {
            sampling_interval_bytes: 4096
            shmem_size_bytes: 8388608
            block_client: true
        }
    }
}
data_sources: {
    config {
        name: "android.java_hprof"
        target_buffer: 0
        java_hprof_config {
        }
    }
}
data_sources: {
    config {
        name: "linux.ftrace"
        ftrace_config {
            ftrace_events: "sched/sched_switch"
            ftrace_events: "power/suspend_resume"
            ftrace_events: "sched/sched_wakeup"
            ftrace_events: "sched/sched_wakeup_new"
            ftrace_events: "sched/sched_waking"
            ftrace_events: "power/cpu_frequency"
            ftrace_events: "power/cpu_idle"
            ftrace_events: "mm_event/mm_event_record"
            ftrace_events: "kmem/rss_stat"
            ftrace_events: "ion/ion_stat"
            ftrace_events: "dmabuf_heap/dma_heap_stat"
            ftrace_events: "kmem/ion_heap_grow"
            ftrace_events: "kmem/ion_heap_shrink"
            ftrace_events: "sched/sched_process_exit"
            ftrace_events: "sched/sched_process_free"
            ftrace_events: "task/task_newtask"
            ftrace_events: "task/task_rename"
            ftrace_events: "lowmemorykiller/lowmemory_kill"
            ftrace_events: "oom/oom_score_adj_update"
            ftrace_events: "ftrace/print"
            atrace_categories: "freq"
            atrace_categories: "idle"
            atrace_categories: "am"
            atrace_categories: "vm"
            atrace_categories: "gfx"
            atrace_categories: "view"
            atrace_categories: "binder_driver"
            atrace_categories: "hal"
            atrace_categories: "dalvik"
            atrace_categories: "camera"
            atrace_categories: "input"
            atrace_categories: "res"
            atrace_categories: "memory"
            atrace_apps: "*"
        }
    }
}
duration_ms: 10000



```
