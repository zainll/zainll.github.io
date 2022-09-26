---
title: "leetcode基础题目"
date: 2022-05-05T00:17:58+08:00
lastmod: 2022-05-05T00:17:58+08:00
author: ["Zain"]
keywords: 
- 
categories: 
- 
tags: 
- leetcode
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

- 参考博客：
https://programmercarl.com/
https://mp.weixin.qq.com/s/AWsL7G89RtaHyHjRPNJENA


# 总结


# leetcode基础题目

## 1.[两数之和](https://leetcode.cn/problems/two-sum/)
> 思路：两层循环

```c
int* twoSum(int* nums, int numsSize, int target, int* returnSize){
    *returnSize = 0;
    int* res = (int *)malloc(sizeof(int) * 2);
    for (int i = 0; i < numsSize; i++) {
        int tmp = target - nums[i];
        for (int j = i + 1; j < numsSize; j++) {
            if (nums[j] == tmp) {
                res[0] = i;
                res[1] = j;
                *returnSize = 2;
            }
        }
    }
    return res;
}
```

## 2.[两数相加](https://leetcode.cn/problems/add-two-numbers/)
> 思路：两个链表，判断链表是否为空，求和不为空链表节点，第一次添加到头节点，之后添加到尾节点，最后判断进位

```c
struct ListNode* addTwoNumbers(struct ListNode* l1, struct ListNode* l2) {
    struct ListNode* head = NULL;
    struct ListNode* tail = NULL;
    int carry = 0;
    while (l1 || l2) {
        int n1 = l1 ? l1->val : 0;
        int n2 = l2 ? l2->val : 0;
        int sum = n1 + n2 + carry;
        if (!head) {
            head = tail = malloc(sizeof(struct ListNode));
            tail->val = sum % 10;
            tail->next= NULL;
        } else {
            tail->next = malloc(sizeof(struct ListNode));
            tail->next->val = sum % 10;
            tail = tail->next;
            tail->next = NULL;
        }
        carry = sum / 10;
        if (l1) {
            l1 = l1->next;
        }
        if (l2) {
            l2 = l2->next;
        }
    }

    if (carry > 0) {
        tail->next = malloc(sizeof(struct ListNode));
        tail->next->val = carry;
        tail->next->next = NULL;
    }
    return head;
}
```


## 3. [无重复字符的最长子串](https://leetcode.cn/problems/longest-substring-without-repeating-characters/)
> 双指针，前后快慢指针，table表标记字符是否出现过，fast标记，slow去除标记，求 fast-slow 最大值

```c
int lengthOfLongestSubstring(char * s){
    int slow = 0;
    int fast = 0;
    int len = strlen(s);
    int table[256] = {0};
    int maxLen = 0;
    // fast从0开始
    while (fast < len) {
        if (table[s[fast]] == 0) {
            table[s[fast]] = 1;
            fast++;
        //} else if (table[s[right]] == 1) {
        } else {
            table[s[slow]] = 0;
            slow++;
        }
        maxLen = fmax(maxLen, fast - slow);
    }
    return maxLen;
}

```

## 4. [寻找两个正序数组的中位数](https://leetcode.cn/problems/median-of-two-sorted-arrays/)

> 思路：每个数组各自索引，判断大小移动索引，最后判断是奇数还是偶数

```c
double findMedianSortedArrays(int* nums1, int nums1Size, int* nums2, int nums2Size){
    int numSize = nums1Size + nums2Size;
    int* res = (int *)malloc(sizeof(int) * numSize);
    int half = numSize / 2 + 1;
    int p1 = 0;
    int p2 = 0;
    for (int i = 0; i < half; i++) {
        int n;
        if (p1 < nums1Size && p2 < nums2Size) {
            n = nums1[p1] < nums2[p2] ? nums1[p1++] : nums2[p2++];
        } else if (p1 < nums1Size) {
            n = nums1[p1++];
        } else if (p2 < nums2Size) {
            n = nums2[p2++];
        }
        res[i] = n;
    }

    if (numSize % 2 == 0) {
        return (res[half - 1] + res[half - 2]) / 2.0;
    } else {
        return res[half-1];
    }
}
```

## 6. [字形变换](https://leetcode.cn/problems/zigzag-conversion/)

> 

```c


```











