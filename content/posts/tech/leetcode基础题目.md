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
weight: 1
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


# 总结


# leetcode基础题目


- 经典题目：



[3.无重复字符的最长子串](#3)  &emsp;&emsp;
[4.](#4) &emsp;&emsp;[6.](#6) &emsp;&emsp;  [7.](#7) &emsp;&emsp;  [8.](#8) &emsp;&emsp; [9.](#9) &emsp;&emsp; [11.](#11) &emsp;&emsp; [12.](#12) &emsp;&emsp; [13.](#13) &emsp;&emsp; [21.](#21) &emsp;&emsp; [24.](#24) &emsp;&emsp; [28.](#28) &emsp;&emsp; [38.](#38) &emsp;&emsp; [53.](#53) &emsp;&emsp; [66.](#66) &emsp;&emsp; [82.](#82) &emsp;&emsp; [94.](#94) &emsp;&emsp; [104.](#104) &emsp;&emsp; [108.](#108) &emsp;&emsp; [109.](#109) &emsp;&emsp; [110.](#110) &emsp;&emsp; [112.](#112) &emsp;&emsp; [121.](#121) &emsp;&emsp; [136.](#136) &emsp;&emsp; [142.](#142) &emsp;&emsp; [160.](#160) &emsp;&emsp; [169.](#169) &emsp;&emsp; [173.](#173) &emsp;&emsp; [189.](#189) &emsp;&emsp; [201.](#201) &emsp;&emsp; [203.](#203) &emsp;&emsp; [206.](#206) &emsp;&emsp; [217.](#217) &emsp;&emsp; [226.](#226) &emsp;&emsp; [231.](#231) &emsp;&emsp; [234.](#234) &emsp;&emsp; [367.](#367) &emsp;&emsp; [389.](#389) &emsp;&emsp; [442.](#442) &emsp;&emsp; [476.](#476) &emsp;&emsp; [617.](#617) &emsp;&emsp; [701.](#701) &emsp;&emsp; [938.](#938) &emsp;&emsp; [1089.](#1089) &emsp;&emsp; [1207.](#1207)



### 1.[两数之和](https://leetcode-cn.com/problems/two-sum/)

> 思路：两层遍历

```c
int* twoSum(int* nums, int numsSize, int target, int* returnSize) {
    int i, j;
    int *ret = (int *)malloc(sizeof(int) * 2);
    for (i = 0; i < numsSize; i++) {
        int key = target - nums[i];
        for (j = i + 1; j < numsSize; j++) {
            if (nums[j] == key) {
                ret[0] = i;
                ret[1] = j;
            }
        }
    }
    *returnSize = 2;
    return ret;
}
```

### 2.[两数相加](https://leetcode-cn.com/problems/add-two-numbers/)

> 思路：两个链表，判断链表是否为空or，求和不为空链表节点值，第一次添加头节点，之后添加到尾节点，注意处理进位

```c
struct ListNode* addTwoNumbers(struct ListNode* l1, struct ListNode* l2) {
    struct ListNode *head = NULL, *tail = NULL;
    int carry = 0;
    while (l1 || l2) {
        int n1 = l1 ? l1->val : 0;
        int n2 = l2 ? l2->val : 0;
        int sum = n1 + n2 + carry;
        if (!head) {
            head = tail = malloc(sizeof(struct ListNode));
            tail->val = sum % 10;
            tail->next = NULL;
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

### <span id="3">3</span>.[无重复字符的最长子串](https://leetcode-cn.com/problems/longest-substring-without-repeating-characters/)


> 思路：双指针，前后快慢指针，table表标记字符是否出现过，right标记，left去除标记，求right-left最大值

```c
int lengthOfLongestSubstring(char * s){
    int len = strlen(s);
    printf("len = %d\n", len);
    int left = 0;
    int right = 0;
    char table[256] = {0};
    int maxLen = 0;
    while (right < len) {
        printf("%d \t", right);
        if (table[s[right]] == 0) {
            table[s[right]] = 1;
            right++;
        //} else if (table[s[right]] == 1) {
        } else {
            table[s[left]] = 0;
            left++;
        }
        maxLen = fmax(maxLen, right - left);
    }
    return maxLen;
}
```

### <span id="4">4</span>.[寻找两个正序数组的中位数](https://leetcode-cn.com/problems/median-of-two-sorted-arrays/)

> 思路：每个数组各自索引，判断大小移动索引，最后判断是奇数还是偶数

```c
double findMedianSortedArrays(int* nums1, int nums1Size, int* nums2, int nums2Size){
    int sum = nums1Size + nums2Size;
    int *nums = (int *)malloc(sizeof(int) * sum);
    int i = 0, j = 0, k = 0;
    int half = sum / 2 + 1;
    
    while (k < half) {
        int n;
        if (i < nums1Size && j < nums2Size) {
            n = (nums1[i] < nums2[j]) ? nums1[i++] : nums2[j++];
        } else if (i < nums1Size) {
            n = nums1[i++];
        } else if (j < nums2Size) {
            n = nums2[j++];
        }
        nums[k++] = n;
    }

    if (sum % 2 == 0) {
        return (nums[k-1] + nums[k-2]) / 2.0;
    } else {
        return nums[k-1];
    }
}
```

### <span id="6">6</span>.[Z 字形变换](https://leetcode-cn.com/problems/zigzag-conversion/)

> 思路：计算位置？

```c
char * convert(char * s, int numRows){
    uint16_t len = strlen(s);

    if (len < numRows) {
        numRows = len;
    }

    char* out = calloc(len + 1, sizeof(char));
    if (numRows < 2) {
        memcpy(out, s, len + 1);
        return out;
    }

    uint16_t max = numRows - 1;
    uint16_t rr = 2 * max;
    uint16_t i = 0;
    uint16_t o = 0;
    uint16_t delta = 0;

    // first row
    while (i < len) {
        out[o++] = s[i];
        i += rr;
    }

    // middle rows
    for (uint16_t l = 1; l < max; l++) {
        i = l;
        delta = 2 * l;
        while (i < len) {
            out[o++] = s[i];
            delta = rr - delta;
            i += delta;
        }
    }

    // last row
    i = max;
    while (i < len) {
        out[o++] = s[i];
        i += rr;
    }

    return out;
}
```

### <span id="7">7</span>.[整数反转](https://leetcode-cn.com/problems/reverse-integer/)

> 思路：(取余数)* 10，注意越界，INT_MAX / 10 && pop > 7

```c
int reverse(int x){
    int rev = 0;
    while (x != 0) {
        int pop = x % 10;
        x /= 10;
        if (rev > INT_MAX / 10 || (rev == INT_MAX / 10 && pop > 7))
            return 0;
        if (rev < INT_MIN / 10 || (rev == INT_MIN / 10 && pop < -8))
            return 0;
        rev = rev * 10 + pop;
    }
    return rev;
}
```

### <span id="8">8</span>.[字符串转换整数 (atoi)](https://leetcode-cn.com/problems/string-to-integer-atoi/)

> 思路：

```c
int myAtoi(char * s){
    long flag = 1;
    long num = 0;
    //int singleRes=0;
    while(*s == ' ') {
        s++;
    }
    if(*s=='-') {
        flag=-1;
        s++;
    } else if (*s=='+') {
        s++;
        flag=1;
    }

     while(*s!='\0' && (*s<='9' && *s>='0')) {
           if(num>INT_MAX/10 || (num==INT_MAX/10 && *s>'7')){//因为是从正数转化为负数，所以要都按正数溢出标准
               if(flag==1) {
                   return INT_MAX;
               } else {
                   return INT_MIN;
               }
           } else {
               num=num*10+(*s-'0');
               s++;    
           }
       }
   if(flag==1) {
       return num;
   } else {
       return -num;
   }
}
```

```c
int myAtoi(char * s){
int minusFlag = 0;
    int length = strlen(s);
    long int result = 0;
    char numberBuffer[11];
    int counter = 0;
    while (s[counter] == ' ') {
        counter++;
    }
    s = &s[counter];
    counter = 0;

    for (int i = 0; i < length; i++) {
        if (i == 0) {
            if (s[0] == '-') {
                minusFlag = 1;
                i++;
            } else if (s[0] == '+') {
                i++;
            }
        }
        if (counter > 10) {
            if (minusFlag) {
                return __INT_MAX__ * -1 - 1;
            } else {
                return __INT_MAX__;
            }
        }

        if (s[i] < '0' || s[i] > '9') {
            break;
        }
        if (counter == 0 && s[i] == '0') {
            continue;
        }

        numberBuffer[counter] = s[i];
        counter++;
    }

    int i = 0;
    while (counter > 0) {
        if (minusFlag) {
            result -= (numberBuffer[i] - '0') * pow(10.0, counter - 1);
        } else {
            result += (numberBuffer[i] - '0') * pow(10.0, counter - 1);
        }
        i++;
        counter--;
    }

    if (result > __INT_MAX__) {
        return __INT_MAX__;
    } else if (result < __INT_MAX__ * -1 - 1) {
        return __INT_MAX__ * -1 - 1;
    }
    return result;
}
```

### <span id="9">9</span>.[回文数](https://leetcode-cn.com/problems/palindrome-number/)

> 思路：将每一位按序装入数组，遍历数组首尾是否相等 ;    递归

```c
bool isPalindrome(int x)
{
    if (x < 0) {
        return false;
    }

    int table[20] = {0};
    int count = 0;
    while (x) {
        table[count++] = x % 10;
        x = x / 10;
        printf("x = %d\n", x);
    }

    for (int i = 0; i < count / 2; i++) {
        if (table[i] != table[count - i - 1]) {
            return false;
        }
    }
    return true;
}
```

```c
bool isPalindrome(int x){
    if (x < 0 || (x % 10 == 0 && x != 0)) {
        return false;
    }

    int revertedNumber = 0;
    while (x > revertedNumber) {
        revertedNumber = revertedNumber * 10 + x % 10;
        x /= 10;
    }

    return x == revertedNumber || x == revertedNumber / 10;
}
```

### <span id="11">11</span>.[盛最多水的容器](https://leetcode-cn.com/problems/container-with-most-water/)

> 思路：双指针，头尾向中间

```c
int maxArea(int* height, int heightSize)
{
    int left = 0;
    int right = heightSize - 1;
    int maxNum = 0;
    while (left < right) {
        int hMax = fmin(height[left], height[right]);
        int tmp = hMax * (right - left);
        maxNum = fmax(maxNum, tmp);
        if (height[left] < height[right]) {
            left++;
        } else {
            right--;
        }
    }
    return maxNum;
}
```

```c
int maxArea(int* height, int heightSize)
{
    int left = 0;
    int right = heightSize - 1;
    int mArea = 0;
    while (left < right) {
        int h = fmin(height[left], height[right]);
        int m = h * (right - left);
        mArea = fmax(mArea, m);
        if (height[left] < height[right]) {
            left++;
        } else {
            right--;
        }
    }
    return mArea;

}
```

```c
int maxArea(int* height, int heightSize){
  // Start with maximum container width
    int start = 0;
    int end = heightSize - 1;
    int res = 0;

    while (start < end) {
        // Calculate current area by taking minimum of two heights
        int currArea = (end - start) * fmin(height[start], height[end]);

        if (currArea > res)
            res = currArea;

        if (height[start] < height[end]) {
            start = start + 1;
        } else {
            end = end - 1;
        }
    }

    return res;
}
```

### <span id="12">12</span>.[整数转罗马数字](https://leetcode-cn.com/problems/integer-to-roman/)

> 思路：

```c
const int values[] = {1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1};
const char* symbols[] = {"M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"};

char* intToRoman(int num)
{
    char* roman = malloc(sizeof(char) * 16);
    roman[0] = '\0';
    for (int i = 0; i < 13; i++) {
        while (num >= values[i]) {
            num -= values[i];
            strcpy(roman + strlen(roman), symbols[i]);
        }
        if (num == 0) {
            break;
        }
    }
    return roman;
}
```


```c
char *getOne(char c)
{
    switch (c)
    {
    case '9':
        return "IX";

    case '8':
        return "VIII";

    case '7':
        return "VII";

    case '6':
        return "VI";

    case '5':
        return "V";

    case '4':
        return "IV";

    case '3':
        return "III";

    case '2':
        return "II";

    case '1':
        return "I";

    case '0':
        return "";

    default:
        return NULL;
    }
}

char *getTen(char c)
{
    switch (c)
    {
    case '9':
        return "XC";

    case '8':
        return "LXXX";

    case '7':
        return "LXX";

    case '6':
        return "LX";

    case '5':
        return "L";

    case '4':
        return "XL";

    case '3':
        return "XXX";

    case '2':
        return "XX";

    case '1':
        return "X";

    case '0':
        return "";

    default:
        return NULL;
    }
}

char *getHundred(char c)
{
    switch (c)
    {
    case '9':
        return "CM";

    case '8':
        return "DCCC";

    case '7':
        return "DCC";

    case '6':
        return "DC";

    case '5':
        return "D";

    case '4':
        return "CD";

    case '3':
        return "CCC";

    case '2':
        return "CC";

    case '1':
        return "C";

    case '0':
        return "";

    default:
        return NULL;
    }
}

char *getThousand(char c)
{
    switch (c)
    {
    case '3':
        return "MMM";

    case '2':
        return "MM";

    case '1':
        return "M";

    default:
        return NULL;
    }
}

char * intToRoman(int num){
int length;
    char number[5];
    char *s = malloc(16 * sizeof(char));

    sprintf(number, "%i", num);

    length = strlen(number);

    switch (length)
    {
    case 4:
        sprintf(s, "%s%s%s%s", getThousand(number[0]), getHundred(number[1]),
                getTen(number[2]), getOne(number[3]));
        break;

    case 3:
        sprintf(s, "%s%s%s", getHundred(number[0]), getTen(number[1]),
                getOne(number[2]));
        break;

    case 2:
        sprintf(s, "%s%s", getTen(number[0]), getOne(number[1]));
        break;

    case 1:
        s = getOne(number[0]);
        break;

    default:
        break;
    }
    return s;
}
```

### <span id="13">13</span>.[罗马数字转整数](https://leetcode-cn.com/problems/roman-to-integer/)

> 思路：

```c
int romanToInt(char * s){
int romanToInt = 0;
    for (int i = 0; i < strlen(s); i++) {
        switch (s[i]) {
        case 'I':
            if (i + 1 < strlen(s)) {
                if (s[i + 1] == 'V' || s[i + 1] == 'X') {
                    romanToInt -= 1;
                    break;
                }
            }
            romanToInt += 1;
            break;
        case 'V':
            romanToInt += 5;
            break;
        case 'X':
            if (i + 1 < strlen(s)) {
                if (s[i + 1] == 'L' || s[i + 1] == 'C') {
                    romanToInt -= 10;
                    break;
                }
            }
            romanToInt += 10;
            break;
        case 'L':
            romanToInt += 50;
            break;
        case 'C':
            if (i + 1 < strlen(s)) {
                if (s[i + 1] == 'D' || s[i + 1] == 'M') {
                    romanToInt -= 100;
                    break;
                }
            }
            romanToInt += 100;
            break;
        case 'D':
            romanToInt += 500;
            break;
        case 'M':
            romanToInt += 1000;
            break;
        default:
            break;
        }
    }
    return romanToInt;
}
```

### <span id="20">20</span>.[有效的括号](https://leetcode-cn.com/problems/valid-parentheses/)

> 思路：配对判断

```c
bool isValid(char * s) {
    int i, k = 0, len = strlen(s);
    char *store = calloc(len, sizeof(char));

    for (i = 0; s[i] != '\0'; i++) {
        switch (s[i]) {
        case '(':
        case '{':
        case '[':
            store[k++] = s[i];
            break;
        case ')':
            if (k < 1 || store[--k] != '(')
                goto out;
            break;
        case '}':
            if (k < 1 || store[--k] != '{')
                goto out;
            break;
        case ']':
            if (k < 1 || store[--k] != '[')
                goto out;
            break;
        }
    }
out:
    free(store);
    return s[i] == '\0' && k == 0;
}
```

### <span id="21">21</span>.[合并两个有序链表](https://leetcode-cn.com/problems/merge-two-sorted-lists/)

> 思路：先添加头，然后判断 l1 != NULL && l2 != NULL 添加谁

```c
struct ListNode* mergeTwoLists(struct ListNode* l1, struct ListNode* l2) {
    struct ListNode* head = NULL;
    struct ListNode* tmp = NULL;

    if (l1 == NULL) {
        return l2;
    }
    if (l2 == NULL) {
        return l1;
    }

    if (l1 != NULL && l2 != NULL) {
        if (l1->val < l2->val) {
            head = tmp = l1;
            l1 = l1->next;
        } else {
            head = tmp = l2;
            l2 = l2->next;
        }

        while (l1 && l2) {
            if (l1->val < l2->val) {
                tmp->next = l1;
                l1 = l1->next;
            } else {
                tmp->next = l2;
                l2 = l2->next;
            }
            tmp = tmp->next;
        }

        if (l1) {
            tmp->next = l1;
        }
        if (l2) {
            tmp->next = l2;
        }
        return head;
    }

    return NULL;
}
````

```c
struct ListNode* mergeTwoLists(struct ListNode* l1, struct ListNode* l2) {
    struct ListNode *list = NULL;
    struct ListNode *tmp = NULL;

    if (!l1)
        return l2;
    if (!l2)
        return l1;

    if (l1 && l2) {
        if (l1->val < l2->val) {
            list = tmp = l1;
            l1 = l1->next;
        } else {
            list = tmp = l2;
            l2 = l2->next;
        }

        while (l1 && l2) {
            if (l1->val < l2->val) {
                tmp->next = l1;
                l1 = l1->next;
            } else {
                tmp->next = l2;
                l2 = l2->next;
            }
            tmp = tmp->next;
        }

        if (l1)
            tmp->next = l1;
        if (l2)
            tmp->next = l2;

        return list;
    }

    return NULL;

}
 /* if (!list1)
        return list2;
    if (!list2)
        return list1;
    if (list1->val < list2->val)
    {
        list1->next = mergeTwoLists(list1->next, list2);
        return list1;
    }
    else
    {
        list2->next = mergeTwoLists(list1, list2->next);
        return list2;
    } */
```

### <span id="24">24</span>.[两两交换链表中的节点](https://leetcode-cn.com/problems/swap-nodes-in-pairs/)

> 思路：递归；借助节点

```c
struct ListNode* swapPairs(struct ListNode* head) {
    if (head == NULL || head->next == NULL) {
        return head;
    }
    struct ListNode* first = head->next;
    head->next = swapPairs(head->next->next);
    first->next = head;
    head = head->next;
    return first;
}
```

```c
struct ListNode* swapPairs(struct ListNode* head) {
 if (!head || !head->next)
        return head;
    struct ListNode *tmp = head->next;
    head->next = swapPairs(head->next->next);
    tmp->next = head;
    return tmp;
}
```

### 26.[删除有序数组中的重复项](https://leetcode-cn.com/problems/remove-duplicates-from-sorted-array/)

> 思路：++

```c
int removeDuplicates(int* nums, int numsSize) {
    if(numsSize == 0) {
        return 0;
    }
    int fast = 1, low = 0;
    while (fast < numsSize) {
        if (nums[fast] != nums[low]) {
            nums[low + 1] = nums[fast];
            low++;
        }
        fast++;
    }
    return low + 1;
}
```


```c
int removeDuplicates(int* nums, int numsSize) {
    int count = 0, i;
    for (i = 1; i < numsSize; i++) {
        if (nums[i] == nums[i - 1])
            count++;
        else
            nums[i - count] = nums[i];
    }
    return numsSize - count;
}
```

### 27.[移除元素](https://leetcode-cn.com/problems/remove-element/)

> 思路：nums[start++] = nums[i];

```c
int removeElement(int* nums, int numsSize, int val){
 int i, start = 0;
    for (i = 0; i < numsSize; i++)
    {
        if (nums[i] != val) {
            nums[start++] = nums[i];
        }
    }
    return start;
}
```

### <span id="28">28</span>.[实现 strStr()](https://leetcode-cn.com/problems/implement-strstr/)

> 思路：

```c
int strStr(char * haystack, char * needle){
    int i = 0;
    int j = 0;
    int k = 0;
    int hlen = 0;
    int nlen = 0;

    if (needle == NULL || *needle == 0)
        return 0;

    if (haystack == NULL || *haystack == 0)
        return -1;

    hlen = strlen(haystack);
    nlen = strlen(needle);

    if (hlen < nlen)
        return -1;

    for (i = 0; i <= hlen - nlen; i++) {
        j = 0;
        if (haystack[i] != needle[j++])
            continue;

        k = i + 1;
        for (; j < nlen; j++) {
            if (haystack[k] != needle[j]) {
                break;
            } else {
                k++;
            }
        }
        if (j == nlen)
            return i;
    }
    return -1;
}
```

### 29.[两数相除](https://leetcode-cn.com/problems/divide-two-integers/)

> 思路：

```c
int divide(int dividend, int divisor) {
    int cnt = 0;
    int sign = 1;
    if ((dividend ^ divisor) < 0) { // 两数任意一个为负数
        sign = -1;
    }
    if (divisor == INT_MIN) { // 除数边界值特殊处理
        if (dividend == INT_MIN) {
            return 1;
        } else {
            return 0;
        }
    }
    if (dividend == INT_MIN) { // 被除数边界值特殊处理
        if (divisor == -1) {
            return INT_MAX;
        } else if (divisor == 1) {
            return INT_MIN;
        }
        dividend += abs(divisor); // 先执行一次加操作，避免abs转换溢出
        cnt++;
    } 
    int a = abs(dividend);
    int b = abs(divisor);
    while (a >= b) {
        int c = 1;
        int s = b;
        // 需指数级快速逼近，以避免执行超时
        while (s < (a >> 1)) { // 逼近至一半，同时避免溢出
            s += s;
            c += c;
        }
        cnt += c;
        a -= s;
    }
    return (sign == -1) ? -cnt : cnt;
}
```

```c
int divide(int dividend, int divisor){
    int sign = 1;
    long int output = 0;
    
    if (dividend < 0) {
        sign *= -1;
    } else {
        dividend *= -1;
    }

    if (divisor < 0) {
        sign *= -1;
    } else {
        divisor *= -1;
    }
    while (dividend <= divisor) {
        long int tmp = 0;
        long int div = divisor;
        while (dividend <= div) {
            tmp += (tmp + 1);
            dividend -= div;
            div += div;
        }
        if (output >= INT_MAX) {
            if (sign == -1) {
                return INT_MIN;
            } else {
                return INT_MAX;
            }
        }
        output += tmp;
    }

    return output * sign;
}
```

### 35.[搜索插入位置](https://leetcode-cn.com/problems/search-insert-position/)

> 思路：

```c
int searchInsert(int* nums, int numsSize, int target) {
    int left = 0;
    int right = numsSize - 1;
    int mid;
    while (left <= right) {
        // mid = (right + left) / 2;
        mid = left + (right - left) / 2;
        if (nums[mid] == target) {
            return mid;
        } else if (nums[mid] < target) {
            left = mid + 1;
        } else {
            right = mid - 1;
        }
    }
    return left;
}
```

```c
int searchInsert(int* nums, int numsSize, int target) {
    int idx = numsSize - 1;
    if (numsSize > 0) {
        if (target > nums[idx]) {
            return numsSize;
        }
        return searchInsert(nums, numsSize - 1, target);
    }
    return 0;
}
```

### <span id="38">38</span>.[外观数列](https://leetcode-cn.com/problems/count-and-say/)

> 思路：

```c
char * countAndSay(int n) {
    char *p = (char *)malloc(5000);
    char *p1 = (char *)malloc(5000);
    p[0] = '1';
    p[1] = '\0';
    for(int i = 1; i < n; ++i) {
        int x = 0;
        for(int j = 0; p[j]; ++j) {
            int y = 1; //计数器
            while (p[j+1] && p[j] == p[j+1]) {
                ++y;
                ++j;
            }
            p1[x++] = y+48;
            p1[x++] = p[j];
        }
        strcpy(p, p1);
        p[x] = '\0';
    }
    return p;
}
```

```c
char * countAndSay(int n) {
 // Calculating the length of array
    double result = 1.0;
    for (int i = 0; i < n - 1; i++) {
        result *= 1.4;
    }

    int k, j, count, convert = (int)result;

    // Creating array with the length calculated above
    char *arr = malloc(convert + 4);
    arr[0] = '1';
    arr[1] = '\0';

    for (int i = 2, length; i <= n; i++) {
        length = strlen(arr);
        char newArr[length * 2];
        strcpy(newArr, arr);

        k = 0;
        j = 0;
        count = 1;

        while (newArr[j] != '\0') {
            if (newArr[j] == newArr[j + 1]) {
                count++;
                j++;
            } else {
                arr[k] = (48 + count);
                arr[k + 1] = newArr[j];
                arr[k + 2] = '\0';
                j++;
                k += 2;
                count = 1;
            }
        }
    }

    return arr;
}
```


### <span id="53">53</span>.[最大子数组和](https://leetcode-cn.com/problems/maximum-subarray/)

> 思路：累加，动态规划

```c
int maxcmp(int a, int b) {
    return a >= b ? a : b;
}

int maxSubArray(int* nums, int numsSize) {
    int maxSoFar = nums[0];
    int maxEndingHere = nums[0];
    for (int i = 1; i < numsSize; i++) {
        maxEndingHere = maxcmp(maxEndingHere + nums[i], nums[i]);
        maxSoFar = maxcmp(maxSoFar, maxEndingHere);
    }
    return maxSoFar;
}
```

### <span id="66">66</span>.[加一](https://leetcode-cn.com/problems/plus-one/)

> 思路：判断是否发生进位，最后判断最高位是否进位

```c
// The returned array must be malloced, assume caller calls free().
int *plusOne(int *digits, int digitsSize, int *returnSize) {
    for (int i = digitsSize - 1; i >= 0; i--) {
        if (digits[i] < 9) {
            digits[i]++;
            *returnSize = digitsSize;
            return digits;
        } else {
            digits[i] = 0;
        }
    }
    
    int* newdigit = (int *)malloc(sizeof(int) * (digitsSize + 1));
    newdigit[0] = 1;
    for (int i = 1; i < (digitsSize + 1); i++) {
        newdigit[i] = digits[i-1];
    }
    *returnSize = digitsSize + 1;
    return newdigit;
}
```

```c
int* plusOne(int* digits, int digitsSize, int* returnSize) {
   *returnSize = digitsSize;
   digits[digitsSize - 1] += 1;
   int carry = digits[digitsSize - 1] / 10;
   for (int i = digitsSize - 1; i >= 0; i--) {
       digits[i] =  (carry + digits[i]) % 10;
       int t = carry;
       carry = (carry + digits[i]) / 10;
       printf("carry = %d\n", carry);       
   }

   if (carry == 1) {
       *returnSize = digitsSize + 1;
       int *res = malloc(sizeof(int) * (*returnSize));
       res[0] = 1;
       for (int i = 0; i < digitsSize; i++) {
           res[i+1] = digits[i];
       }
       return res;
   }
   return digits;
}
```

### <span id="82">82</span>.[删除排序链表中的重复元素 II](https://leetcode-cn.com/problems/remove-duplicates-from-sorted-list-ii/)

> 思路：递归，判断是否和下一个链表值相等

```c
struct ListNode* deleteDuplicates(struct ListNode* head) {
   /*  if (head == NULL) {
        return NULL;
    }

    if (head->next && head->val == head->next->val) {
        while (head->next && head->val == head->next->val) {
            head = head->next;
        }
        return deleteDuplicates(head->next);
    } else {
        head->next = deleteDuplicates(head->next);
    }
    return head; */
     if (head == NULL)
        return NULL;

    if (head->next && head->val == head->next->val) {
        /* Remove all duplicate numbers */
        while (head->next && head->val == head->next->val) {
            head = head->next;
        }
        return deleteDuplicates(head->next);
    } else {
        head->next = deleteDuplicates(head->next);
    }
    return head;

}
```

### 83.[删除排序链表中的重复元素](https://leetcode-cn.com/problems/remove-duplicates-from-sorted-list/)

> 思路：判断相等，next = next->next

```c
/* struct ListNode* deleteDuplicates(struct ListNode* head){
    if (head == NULL) {
        return NULL;
    }
    int table[201] = {0};
    struct ListNode* cur = head;
    table[cur->val + 100] = 1;
    while (cur != NULL && cur->next) {
        if (table[cur->next->val + 100] == 1) {
            if (cur->next->next != NULL) {
                cur->next = cur->next->next;
                continue;
            } else {
                cur->next = NULL;
                break;
            }
        } else {
            table[cur->next->val + 100] = 1;
        }

        cur = cur->next;
    }
    return head;

} */

struct ListNode* deleteDuplicates(struct ListNode* head) {
    struct ListNode* cur = head;
    while (cur && cur->next) {
        if (cur->val == cur->next->val) {
            cur->next = cur->next->next;
        } else {
            cur = cur->next;
        }
    }
    return head;
}
```

```c
/**
 * Definition for singly-linked list.
 * struct ListNode {
 *     int val;
 *     struct ListNode *next;
 * };
 */

struct ListNode* deleteDuplicates(struct ListNode* head) {
    if (head == NULL) {
        return NULL;
    } else {
        struct ListNode* s = head;
        struct ListNode* t = head->next;
        while (t != NULL) {
            if (s->val == t->val) {
                struct ListNode* y;
                y=s->next;
                s->next=t->next;
                t=y->next;
                free(y);
            } else {
                s=s->next;
                t=t->next;
            }
        }
    }
    return head;
}
```

### 84.[柱状图中最大的矩形](https://leetcode-cn.com/problems/largest-rectangle-in-histogram/)

> 思路：单调栈？

```c
int largestRectangleArea(int* heights, int heightsSize){
/*     int *data = (int*)malloc(sizeof(int) * (heightsSize + 2));
    int *stack = (int*)malloc(sizeof(int) * (heightsSize + 2));

    //给heights前后+0，成新数组data
    data[0] = 0;
    for (int i = 1; i <= heightsSize; i++) {
        data[i] = heights[i - 1];
    }
    data[heightsSize + 1] = 0;

    int j = 0, area = 0;
    stack[j] = 0;
    for (int i = 1; i <= heightsSize + 1; i++) {
        while (j > 0 && data[stack[j]] >= data[i]) {
            int sidx = stack[j - 1];
            int h = data[stack[j]];
            //area = fmax(area, data[stack[top]] * (i - stack[top - 1] - 1));
            area = fmax(area, h * (i - sidx  - 1));
            j--;
        }

        stack[++j] = i;
    }

    return area; */

    int* stack = (int*)malloc(sizeof(int) * (heightsSize + 2));
    int* nheights = (int*)malloc(sizeof(int) * (heightsSize + 2));

    for (int i = 0; i < heightsSize; i++) {
        nheights[i+1] = heights[i];
    }
    nheights[0] = 0;
    nheights[heightsSize + 1] = 0;

    int maxArea = 0;
    int top = 0;
    stack[top] = 0;
    for (int i = 1; i <= heightsSize + 1; i++) {
        while (top > 0 && nheights[stack[top]] >= nheights[i]) {
            int h = nheights[stack[top]];
            int s = stack[top - 1];
            int area =  nheights[stack[top]] * (i - s -1);
            maxArea = fmax(maxArea, area);
            top--;
        }
        top++;
        stack[top] = i;

    }
    return maxArea; 
}
```

```c
void showIntArr(const char *brief, int *arr, uint32_t nums) {
    printf("%s:", brief);
    for (uint32_t i = 0; i < nums; i++) {
        printf("%d ",arr[i]);
    }
    printf("\n");

    return;
}

int largestRectangleArea(int* heights, int heightsSize){
    int *stack = (int *)malloc(sizeof(int) * (heightsSize + 1));
    uint32_t stackIdx = 0;

    int maxAns = 0;
    int tmpAns = 0;
    int high = 0;
    int wide = 0;
    stack[stackIdx++] = -1;
    for (uint32_t i = 0; i < heightsSize; i++) {
        //showIntArr("stack", stack, stackIdx);
        if (stackIdx == 1) {  /* 单调栈为空 */
            stack[stackIdx++] = i;
            continue;
        }

        // printf("stackIdx - 1 [%d]\n", stackIdx - 1);
        if (heights[i] >= heights[stack[stackIdx - 1]]) {
            stack[stackIdx++] = i;
            continue;
        }

        while ((stackIdx > 1) && heights[i] < heights[stack[stackIdx - 1]]) {  /* 遍历到的元素小于栈顶元素 */
            high = heights[stack[stackIdx - 1]];
            stackIdx--;
            wide = i - stack[stackIdx - 1] - 1;
            tmpAns = high * wide;
            //printf("i[%u] high[%d] wide[%d]\n", i, high, wide);
            if (tmpAns > maxAns) {
                maxAns = tmpAns;
            }
        }
        stack[stackIdx++] = i;
    }

    while (stackIdx > 1) {
        high = heights[stack[stackIdx - 1]];
        stackIdx--;
        wide = heightsSize - stack[stackIdx - 1] - 1;
        tmpAns = high * wide;
        //printf("ele[%d] high[%d] wide[%d]\n", heightsSize, high, wide);
        if (tmpAns > maxAns) {
            maxAns = tmpAns;
        }
    }

    return maxAns;
}
```

### <span id="94">94</span>.[二叉树的中序遍历](https://leetcode-cn.com/problems/binary-tree-inorder-traversal/)

> 思路：递归，中序，注意封装递归函数

```c
/**
 * Definition for a binary tree node.
 * struct TreeNode {
 *     int val;
 *     struct TreeNode *left;
 *     struct TreeNode *right;
 * };
 */

void processTraversal(struct TreeNode* root, int* res, int* size)
{
    if (!root) {
        return;
    }

    processTraversal(root->left, res, size);
    res[*size] = root->val;
    *size += 1;
    processTraversal(root->right, res, size);
}

int* inorderTraversal(struct TreeNode* root, int* returnSize){
    int* res = malloc(sizeof(int) * 256);
    *returnSize = 0;

    processTraversal(root, res, returnSize);
    return res;
}
```

### 101.[对称二叉树](https://leetcode-cn.com/problems/symmetric-tree/)

> 思路：递归判断，注意递归出口判断条件

```c
bool checkSymmetric(struct TreeNode *left, struct TreeNode *right)
{
    if (!left || !right)
        return left == right;
    if (left->val != right->val)
        return 0;
    return checkSymmetric(left->left, right->right) &&
           checkSymmetric(left->right, right->left);
}

bool isSymmetric(struct TreeNode *root)
{
    return root == NULL || checkSymmetric(root->left, root->right);
}
```

### <span id="104">104</span>.[二叉树的最大深度](https://leetcode-cn.com/problems/maximum-depth-of-binary-tree/)

> 思路：求树深度递归 return 1 + maxval(maxDepth(root->left), maxDepth

```c
/**
 * Definition for a binary tree node.
 * struct TreeNode {
 *     int val;
 *     struct TreeNode *left;
 *     struct TreeNode *right;
 * };
 */
int maxval(int a, int b) {
    return a > b ? a : b;
}

int maxDepth(struct TreeNode *root) {
    if (root == NULL) {
        return 0;
    }
    return 1 + maxval(maxDepth(root->left), maxDepth(root->right));
}
```

```c
int max(int a, int b) {
    return a >= b ? a : b;
}

int height(struct TreeNode* root) {
    if (root == NULL) {
        return 1;
    }
    return 1 + max(height(root->left), height(root->right));
}

int maxDepth(struct TreeNode* root) {
    if (root == NULL) {
        return 0;
    }
    int left = height(root->left);
    int right = height(root->right);
    return fmax(left, right);
}
```

### <span id="108">108</span>.[将有序数组转换为二叉搜索树](https://leetcode-cn.com/problems/convert-sorted-array-to-binary-search-tree/)

> 思路：递归处理从中间分左右两部分，先添加当前节点在递归。

```c
/**
 * Definition for a binary tree node.
 * struct TreeNode {
 *     int val;
 *     struct TreeNode *left;
 *     struct TreeNode *right;
 * };
 */
struct TreeNode* convertBST(int* nums, int left, int right)
{
    if (left > right) {
        return NULL;
    } else {
        int mid = (right + left) / 2;
        struct TreeNode* new_val = malloc(sizeof(struct TreeNode));
        new_val->val = nums[mid];
        new_val->left = convertBST(nums, left, mid - 1);
        new_val->right = convertBST(nums, mid + 1, right);
        return new_val;
    }
}

struct TreeNode* sortedArrayToBST(int* nums, int numsSize){
    if (numsSize == 0) {
        return NULL;
    }
    return convertBST(nums, 0, numsSize - 1);
}
```


### <span id="109">109</span>.[有序链表转换二叉搜索树](https://leetcode-cn.com/problems/convert-sorted-list-to-binary-search-tree/)

> 思路：先找到中间节点和尾节点，将中间节点添加到树上，递归处理中间节点前部和后部两部分，递归出口为找不着新节点

```c
/**
 * Definition for singly-linked list.
 * struct ListNode {
 *     int val;
 *     struct ListNode *next;
 * };
 */
/**
 * Definition for a binary tree node.
 * struct TreeNode {
 *     int val;
 *     struct TreeNode *left;
 *     struct TreeNode *right;
 * };
 */

struct TreeNode* buildBST(struct ListNode* head, struct ListNode* tail)
{
    if (head == tail) {
        return NULL;
    }
    struct ListNode* slow = head;
    struct ListNode* fast = head;
    while (fast != tail && fast->next != tail) {
        fast = fast->next->next;
        slow = slow->next;
    }
    //struct TreeNode* node = (struct TreeNode)malloc(sizeof(struct TreeNode));
    struct TreeNode *node = malloc(sizeof(struct TreeNode));
    node->val = slow->val;
    node->left = buildBST(head, slow);
    node->right = buildBST(slow->next, tail);
    return node;

}

struct TreeNode* sortedListToBST(struct ListNode* head){
    if (!head) {
        return NULL;
    }
    return buildBST(head, NULL);
}
```


### <span id="110">110</span>.[平衡二叉树](https://leetcode-cn.com/problems/balanced-binary-tree/)

> 思路：分别求左右子树的深度height，比较左右深度差值。递归判断左右子树是否为平衡二叉树

```c
/**
 * Definition for a binary tree node.
 * struct TreeNode {
 *     int val;
 *     struct TreeNode *left;
 *     struct TreeNode *right;
 * };
 */

int max(int a, int b)
{
    return a >= b ? a : b;
}

int height(struct TreeNode* root)
{
    if (root == NULL) {
        return  0;
    } else {
        return 1 + max(height(root->left), height(root->right));
    }
}

bool isBalanced(struct TreeNode* root){

    if (root == NULL) {
        return 1;
    }

    int left = height(root->left);
    int right = height(root->right);
    return abs(left - right) <= 1 && isBalanced(root->left) && isBalanced(root->right);
}
```


### <span id="112">112</span>.[ 路径总和](https://leetcode-cn.com/problems/path-sum/submissions/)

> 思路：递归：左右子树 递归出口； 注意书判空

```c
bool hasPathSum(struct TreeNode* root, int targetSum){
    if (root == NULL) {
        return false;
    }

    if (root->left == NULL && root->right == NULL && root->val == targetSum) {
        return true;
    }
    return hasPathSum(root->left, targetSum - root->val) || hasPathSum(root->right, targetSum - root->val);

}
```

### <span id="121">121</span>.[买卖股票的最佳时机](https://leetcode-cn.com/problems/best-time-to-buy-and-sell-stock/)

> 思路：动态规划，股票是连续收益的 maxcmp(0, maxCur + prices[i] - prices[i - 1])，收益累计

```c
int maxcmp(int a, int b)
{ 
    return (a >= b) ? a : b; 
}

int maxProfit(int* prices, int pricesSize){
    int maxCur = 0, maxSoFar = 0;
    for (int i = 1; i < pricesSize; i++) {
        maxCur = maxcmp(0, maxCur + prices[i] - prices[i - 1]);
        maxSoFar = maxcmp(maxSoFar, maxCur);
        printf("i = %d\t maxCur = %d \t maxSoFar = %d\n", i, maxCur, maxSoFar);
    }
    return maxSoFar;
}
```

### 125.[验证回文串](https://leetcode-cn.com/problems/valid-palindrome/)

> 思路：判断是否是字母和数字，库函数 isalnum; 注意库函数 isalpha 为判断是否为字母。头尾双指针，逼近中间，注意非数字字母忽略

```c
bool isPalindrome(char * s){
    int len = strlen(s);
    int left = 0;
    int right = len - 1;
    while (left <= right) {
        //while (left < right && !isalpha(s[left])) {
        while (left < right && !isalnum(s[left])) {
            left++;
        }
        //while (left < right && !isalpha(s[right])) {
        while (left < right && !isalnum(s[right])) {
            right--;
        }
        printf("left = %d\t right = %d\n", left, right);
        if (tolower(s[left]) != tolower(s[right])) {
            return false;
        }
        left++;
        right--;
    }
    return true;
}
```

### <span id="136">136</span>.[只出现一次的数字](https://leetcode-cn.com/problems/single-number/)

> 思路：n ^ n = 0 一个数与自己异或为 0

```c
int singleNumber(int* nums, int numsSize){
    int res = 0;
    for (int i = 0; i < numsSize; i++) {
        res = res ^ nums[i];
    }
    return res;

}
```

### 141.[环形链表](https://leetcode-cn.com/problems/linked-list-cycle/)

> 思路：快慢双指针，fast一次走两步，slow一次走一步，判断是否能相遇

```c
bool hasCycle(struct ListNode *head) {
    struct ListNode *slow = head;
    struct ListNode *fast = head;
    while (slow && fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
        if (slow == fast) {
            return true;
        }
    }
    return false;
}
```

### <span id="142">142</span>.[环形链表 II](https://leetcode-cn.com/problems/linked-list-cycle-ii/)

> 思路：快慢双指针，判断出环向后，从链表入口开始，和slow指针相同速度遍历，直到相遇

```c
struct ListNode *detectCycle(struct ListNode *head) {
    struct ListNode* slow = (struct ListNode*)malloc(sizeof(struct ListNode));
    struct ListNode* fast = (struct ListNode*)malloc(sizeof(struct ListNode));
    slow = head;
    fast = head;
    while (fast != NULL && fast->next != NULL) {
        slow = slow->next;
        fast = fast->next->next;
        if (slow == fast) {
            struct ListNode* entry = head;
            while (slow != entry) {
                slow = slow->next;
                entry = entry->next;
            }
            return entry;
        }
    }
    return NULL;
}
```

### 153.[寻找旋转排序数组中的最小值](https://leetcode-cn.com/problems/find-minimum-in-rotated-sorted-array/)

> 思路：二分查找

```c
int findMin(int* nums, int numsSize){
    int low = 0;
    int high = numsSize - 1;
    while (low < high) {
        int mid = low + (high - low) / 2;
        if (nums[mid] < nums[high]) {
            high = mid;
        } else {
            low = mid + 1;
        }
    }
    return nums[low];
}
```

```c
int findMin(int* nums, int numsSize){
    int i;
    for (i = 0; i < numsSize - 1; i++) {
        if (nums[i] > nums[(i+1)]) {
            return nums[i+1];
        }
    }
    return nums[0];

}
```

### <span id="160">160</span>.[相交链表](https://leetcode.cn/problems/intersection-of-two-linked-lists/)

> 思路：
一、
二、先统计两个链表结点个数，然后长链表先走个数差位

```c
struct ListNode *getIntersectionNode(struct ListNode *headA, struct ListNode *headB) {
    struct ListNode *cur1 = headA;
    struct ListNode *cur2 = headB;
    if (cur1 == NULL || cur2 == NULL)
        return NULL;
    while (cur1 && cur2 && cur1 != cur2) {
        cur1 = cur1->next;
        cur2 = cur2->next;
        if (cur1 == cur2) {
            return cur1;
        }
        if (!cur1) {
            cur1 = headB;
        }
        if (!cur2) {
            cur2 = headA;
        }
    }
    return cur1;
}
```


### <span id="169">169</span>.[多数元素](https://leetcode-cn.com/problems/majority-element/)

> 思路：选定一个主元素，计数器

```c
int majorityElement(int* nums, int numsSize){
    int count = 1;
    int majorNum = nums[0];
    for (int i = 1; i < numsSize; i++) {
        if (count == 0) {
            majorNum = nums[i];
            count++;
        } else if (majorNum == nums[i]) {
            count++;
        } else {
            count--;
        }
    }
    return majorNum;
}
```


### <span id="173">173</span>.[二叉搜索树迭代器](https://leetcode-cn.com/problems/binary-search-tree-iterator/)

> 思路：

```c
typedef struct {
    int* res;
    int size;
    int idx;
} BSTIterator;

int getTreeSize(struct TreeNode* root) {
    if (root == NULL) {
        return 0;
    }
    return 1 + getTreeSize(root->left) + getTreeSize(root->right);
}

void inorder(int* ret, int* retSize, struct TreeNode* root) {
    if (root == NULL) {
        return;
    }
    inorder(ret, retSize, root->left);
    ret[(*retSize)++] = root->val;
    inorder(ret, retSize, root->right);
}

int* inorderTraversal(int* retSize, struct TreeNode* root) {
    *retSize = 0;
    int* ret = malloc(sizeof(int) * getTreeSize(root));
    inorder(ret, retSize, root);
    return ret;
}

BSTIterator* bSTIteratorCreate(struct TreeNode* root) {
    BSTIterator* ret = malloc(sizeof(BSTIterator));
    ret->res = inorderTraversal(&(ret->size), root);
    ret->idx = 0;
    return ret;
}

int bSTIteratorNext(BSTIterator* obj) {
    return obj->res[(obj->idx)++];
}

bool bSTIteratorHasNext(BSTIterator* obj) {
    return (obj->idx < obj->size);
}

void bSTIteratorFree(BSTIterator* obj) {
    free(obj->res);
    free(obj);
}
```

### <span id="189">189</span>.[轮转数组](https://leetcode-cn.com/problems/rotate-array/)

> 思路：
一、每次移动一个数
二、先整体翻转，在翻转前k个，最后翻转 numsSize - k个


```c
void moveOne(int* nums, int numsSize)
{
    int tmp = nums[numsSize - 1];
    for (int i = numsSize - 1; i > 0; i--) {
        nums[i] = nums[i-1]; 
    }
    nums[0] = tmp;
}

void rotate(int* nums, int numsSize, int k)
{
    for (int i = 0; i < k; i++) {
        moveOne(nums, numsSize);
    }
}
```

```c
/* */ 
void swap(int* a, int* b) {
    int t = *a;
    *a = *b;
    *b = t;
}
void reverse(int* nums, int start, int end) {
    while (start < end) {
        swap(&nums[start], &nums[end]);
        start += 1;
        end -= 1;
    }
}
void rotate(int* nums, int numsSize, int k) {
    k %= numsSize;
    for (int i = 0; i < numsSize; i++) {
        printf("nums[%d] = %d\t", i, nums[i]);
    }
    printf("\n");
    reverse(nums, 0, numsSize - 1);
    for (int i = 0; i < numsSize; i++) {
        printf("nums[%d] = %d\t", i, nums[i]);
    }
    printf("\n");
    reverse(nums, 0, k - 1);
    for (int i = 0; i < numsSize; i++) {
        printf("nums[%d] = %d\t", i, nums[i]);
    }
    printf("\n");
    reverse(nums, k, numsSize - 1);
    for (int i = 0; i < numsSize; i++) {
        printf("nums[%d] = %d\t", i, nums[i]);
    }
    printf("\n");
}



/*
void rotate(int* nums, int numsSize, int k){
     for (int i = 0; i < k; i++) {
        int lastElement = nums[numsSize - 1];
        for (int j = numsSize - 1; j > 0; j--) {
            nums[j] = nums[j - 1];
        }
        nums[0] = lastElement;
    } 
}*/

/*  
void rotate(int* nums, int numsSize, int k){
    if (k == numsSize / 2 && numsSize % 2 != 1) {
        for (int i = 0; i < k; i++) {
            int tmp = nums[i];
            nums[i] = nums[k+i];
            nums[k+i] = tmp;
        }
        return;
    }
  
    int i = 0;
    int tmp = nums[0];
    int p = 0;
    int count = 0;
    do {
        p = (i + k) % numsSize;
        printf("p = %d\n",p);
        int t = nums[p];
        nums[p] = tmp;
        tmp = t;
        i = p;
     } while (i != 0);
} */ 
```

### 190.[颠倒二进制位](https://leetcode-cn.com/problems/reverse-bits/submissions/)

> 思路：32位，

```c
uint32_t reverseBits(uint32_t n) {
    uint32_t m = 0;
    int cnt = 32;
    while (cnt) {
        m <<= 1;
        m += (n & 0x1);
        n >>= 1;
        cnt--;
    }
    return m;
}
```

### 191.[位1的个数](https://leetcode-cn.com/problems/number-of-1-bits/submissions/)

> 思路：n & 0x1

```c
int hammingWeight(uint32_t n) {
    int cnt = 0;
    while (n) {
        if (n & 0x1) {
            cnt++;
        }
        n >>= 1;
    }
    return cnt;
    
}
```

### <span id="201">201</span>.[数字范围按位与](https://leetcode-cn.com/problems/bitwise-and-of-numbers-range/)

> 思路：n & (n - 1) 去除n最高位的1

```c
int rangeBitwiseAnd(int left, int right){
    while (left < right) {
        right &= right - 1;
    }
    return right;
}
```

### <span id="203">203</span>.[移除链表元素](https://leetcode-cn.com/problems/remove-linked-list-elements/)

> 思路：递归

```c
struct ListNode *removeElements(struct ListNode *head, int val)
{
    if (head == NULL) {
         return NULL;
    }

    if (head->val == val) {
        return removeElements(head->next, val);
    } else {
        head->next = removeElements(head->next, val);
    }
    return head;
}

```

### <span id="206">206</span>.[反转链表](https://leetcode-cn.com/problems/reverse-linked-list/)

> 思路：

```c
struct ListNode* reverseList(struct ListNode* head){
    struct ListNode* res = NULL;
    while (head) {
        struct ListNode* pre_node = head;
        head = head->next;
        pre_node->next = res;
        res = pre_node;
    }
    return res;
}
```

### <span id="209">209</span>.[长度最小的子数组](https://leetcode-cn.com/problems/minimum-size-subarray-sum/)

> 思路：双指针：累加sum，判断sum，大于target，计算长度，减sum，移动left

```c
int minSubArrayLen(int target, int* nums, int numsSize){
    int i = 0;
    int sum = 0;
    int len = INT_MAX;
    
    for (int j = 0; j < numsSize; j++) {
        sum += nums[j];
        if (sum < target) {
            continue;
        } else {
            while (sum >= target) {
                len = fmin(len,j-i+1);
                sum -= nums[i];
                i++;
            }
        }
    }
    
    if (len==INT_MAX) {
        len=0;
    }
    return len;
}
```

```c
int minSubArrayLen(int target, int* nums, int numsSize){
    int left = 0;
    int right = 0;
    int sum = 0;
    int len = INT_MAX;
    while (right < numsSize) {
        sum += nums[right];
        right++;
        if (sum < target) {
            continue;
        } else {
            while (sum >= target) {
                len = fmin(len,right-left);
                sum -= nums[left];
                left++;
            }
        }
    }

    if (len == INT_MAX) {
        len = 0;
    }
    return len;
}
```


### 215.[数组中的第K个最大元素](https://leetcode-cn.com/problems/kth-largest-element-in-an-array/)

> 思路：排序，第k个最大

```c
int Cmp(const void* a, const void* b)
{
    return *(int *)b - *(int *)a;
}

int findKthLargest(int* nums, int numsSize, int k){
    qsort(nums, numsSize, sizeof(int), Cmp);
    return nums[k-1];
}
```

### <span id="217">217</span>.[存在重复元素](https://leetcode-cn.com/problems/contains-duplicate/)

> 思路：
一、排序，比较前一个数和当前数是否相等
二、uthash

```c
int Cmp(const void* a, const void* b)
{
    return *(int *)a - *(int *)b;
}

bool containsDuplicate(int* nums, int numsSize){
    if (numsSize <= 1) {
        return true;
    }
    qsort(nums, numsSize, sizeof(int), Cmp);
    for (int i = 1; i < numsSize; i++) {
        if (nums[i-1] == nums[i]) {
            return true;
        }
    }
    return false;
}
```

```c
struct my_struct {
    int id;
    UT_hash_handle hh;
};

struct my_struct *users = NULL;

bool containsDuplicate(int* nums, int numsSize){
   struct my_struct *s;
   HASH_FIND_INT(users, nums[i], s);
   if (s == NULL) {
       s = (struct my_struct*)malloc(sizeof(struct my_struct));
       s->id = nums[i];
       HASH_ADD_INT(users, id, s);
   } else {
       return true;
   }
   return false;
}
```

### <span id="226">226</span>.[翻转二叉树](https://leetcode-cn.com/problems/invert-binary-tree/)

> 思路：判空，交换左右子树，递归调用

```c
struct TreeNode* invertTree(struct TreeNode* root){
    
    if (root == NULL) {
        return NULL;
    }

    struct TreeNode* tmp = root->left;
    root->left = root->right;
    root->right = tmp;

    invertTree(root->left);
    invertTree(root->right);
    return root;
}
```

```c
struct TreeNode* invertTree(struct TreeNode* root){
    if (root == NULL) {
        return NULL;
    }

    struct TreeNode *left = (struct TreeNode *)malloc(sizeof(struct TreeNode));
    struct TreeNode *right = (struct TreeNode *)malloc(sizeof(struct TreeNode));
    left = invertTree(root->left);
    right = invertTree(root->right);
    root->left = right;
    root->right = left;
    return root;
}
```

### <span id="231">231</span>.[2的幂](https://leetcode-cn.com/problems/power-of-two/)

> 思路：一：累计除2，判断最后是否为1，即整除
二、递归，判断对2取余

```c
bool isPowerOfTwo(int n)
{
    if (!n) {
        return false;
    }
        
    while (n % 2 == 0) {
        n /= 2;
    }
    return n == 1;
}
```

```c
bool isPowerOfTwo(int n){

    if (n == 0) {
        return false;
    }

    if (n == 1) {
        return true;
    }
    
    bool res = false;
    if (n % 2 != 0) {
        return false;
    }else {
       res = isPowerOfTwo(n/2);
    }
    return res;
}
```

```c
bool isPowerOfTwo(int n){
    //用位运算来判断有几个1，要是只有一个1那就是2的幂。
    if (n >= 2147483647 || n <= -2147483648) {
        return false;
    }
    int nu m =0;
    while (n>0 && n!=0) {
        n &= (n-1);
        num++;
    }
    if (num!=1) {
        return false;
    }
    return true;

}

```

### <span id="234">234</span>.[回文链表](https://leetcode-cn.com/problems/palindrome-linked-list/submissions/)

> 思路；
一、通过一个数组记录链表中的元素值，在判断数组是否是回文。
二、翻转链表后半部分

```c
#define MAXSIZE 100000

bool isPalindrome(struct ListNode* head){
    int size = 0;
    int nums[MAXSIZE] = {0};
    struct ListNode* p = head;
    // 判断条件
    while (p) {
        nums[size++] = p->val;
        p = p->next;
    }
    printf("size = %d\n", size);
    int left = 0;
    int right = size - 1;
    while (left <= right) {
        if (nums[left] != nums[right]) {
            return false;
        }
        left++;
        right--;
    }
    return true;
}
```

```c
struct ListNode *reverse(struct ListNode *head)
{
    struct ListNode *res = NULL;
    while (head) {
        struct ListNode *pre_node = head;
        head = head->next;
        pre_node->next = res;
        res = pre_node;
    }
    return res;
}
bool isPalindrome(struct ListNode *head)
{
    struct ListNode *slow = head;
    struct ListNode *fast = head;
    struct ListNode *last;
    while (fast && fast->next) {
        slow = slow->next;
        faast = fast->next->next;
    }
    if (fast != NULL) {
        slow = slow->next;
    }
    last = reverse(slow);
    while (last) {
        if (head->val != last->val) {
            return 0;
        }
        head = head->next;
        last = last->next;
    }
    return 1;
}
```

### 242.[有效的字母异位词](https://leetcode-cn.com/problems/valid-anagram/submissions/)

> 思路：先比较长度，不相等 false，通过表格记录第一个字符串中字符，遍历第二个字符串时表格记录--，最后，判断表格中所有值是否为零

```c
#define NUMSIZE 256

bool isAnagram(char * s, char * t){
    int sLen = strlen(s);
    int tLen = strlen(t);
    if (sLen != tLen) {
        return false;
    }
    int table[256] = {0};

    for (int i = 0; i < sLen; i++) {
        table[s[i]]++;
    }
    for (int i = 0; i < tLen; i++) {
        table[t[i]]--;
    }

    for (int i = 0; i < NUMSIZE; i++) {
        if (table[i] != 0) {
            return false;
        }
    }
    return true;
}
```

### 268.[丢失的数字](https://leetcode-cn.com/problems/missing-number/)

> 思路：边求和，边减去数组中的数字

```c
int missingNumber(int* nums, int numsSize){
    int mNum = 0;
    for (int i = 0; i < numsSize; i++) {
        mNum += (i + 1);
        mNum -= nums[i];
    }
    return mNum;
}
```



### 278.[第一个错误的版本](https://leetcode-cn.com/problems/first-bad-version/)

> 思路：二分查找

```c
int firstBadVersion(int n) {
    int left = 1;
    int right = n;
    while (left <= right) {
        int mid = left + (right - left) / 2;
        if (isBadVersion(mid) && !isBadVersion(mid-1)) {
            return mid;
        } else if (isBadVersion(mid) && isBadVersion(mid-1)) {
            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }
    return -1;
}
```

```c
int firstBadVersion(int n) {
    int low = 1, high = n;
    while (low <= high) {
        int mid = low + (high - low) / 2;
        if (isBadVersion(mid)) {
            high = mid - 1;
        } else {
            low = mid + 1;
        }
    }
    return low;
}
```

### 283.[移动零](https://leetcode-cn.com/problems/move-zeroes/)

> 思路：不等于零时向数组中添加，等于零时跳过，最后填充0
nums[start++] = nums[i]

```c
void moveZeroes(int* nums, int numsSize){
    int start = 0;
    for (int i = 0; i < numsSize; i++) {
        if (nums[i] != 0) {
            nums[start++] = nums[i];
        }
    }

    for (; start < numsSize; start++) {
        nums[start] = 0;
    }    
}
```

### 287.[寻找重复整数](https://leetcode-cn.com/problems/find-the-duplicate-number/)

> 思路：循环遍历，标记，判断是否标记过，return

```c
#define MAXSIZE 100001

int findDuplicate(int* nums, int numsSize){
    int table[MAXSIZE] = {0};
    for (int i = 0; i < numsSize; i++) {
        if (table[nums[i]] != 0) {
            return nums[i];
        } else {
            table[nums[i]]++;
        }
    }
    return -1;
}
```

### 344.[反转字符串](https://leetcode-cn.com/problems/reverse-string/)

> 思路：双指针，交换

```c
void reverseString(char* s, int sSize){
    int left =0;
    int right = sSize - 1;
    while (left < right) {
        char c = s[left];
        s[left] = s[right];
        s[right] = c;
        left++;
        right--;
    }
}
```

### <span id="367">367</span>.[有效的完全平方数](https://leetcode-cn.com/problems/valid-perfect-square/)

> 思路：for 循环，条件 i * i <= num 

```c
bool isPerfectSquare(int num)
{
    for (long i = 0; i * i <= num; i++) {
        if (i * i == num) {
            return true;
        }
    }
    return false;
}


```

### 387.[字符串中的第一个唯一字符](https://leetcode-cn.com/problems/first-unique-character-in-a-string/)

> 思路：两次遍历，第一次遍历见字母标记得到统计表格中，第二次遍历找出统计表格中第一个为1字符，返回对应下标。

```c
#define NUMSIZE 256

int firstUniqChar(char * s){
    int sLen = strlen(s);
    int table[NUMSIZE] = {0};
    for (int i = 0; i < sLen; i++) {
        table[s[i]]++;
    }

    for (int i = 0; i < sLen; i++) {
        if (table[s[i]] == 1) {
            return i;
        }
    }
    return -1;
}
```

### <span id="389">389</span>.[找不同](https://leetcode-cn.com/problems/find-the-difference/)

> 思路：字符可以转化为数字，为了防止溢出通过 - 'a'，求两个字符串的差值，在加上'a'

```c
char findTheDifference(char * s, char * t){
    int sLen = strlen(s);
    int tLen = strlen(t);
    int nS = 0;
    int nT = 0;
    for (int i = 0; i < sLen; i++) {
        nS += s[i] - 'a';
    }
    for (int i = 0; i < tLen; i++) {
        nT += t[i] - 'a';
    }
    return (char)(nT - nS + 'a');
}
```

### 404.[左叶子之和](https://leetcode-cn.com/problems/sum-of-left-leaves/)

> 思路：递归：判断左子树是否为叶子结点，是则记录sum，返回 sum + 递归调用左子树 + 递归调用右子树

```c
int sumOfLeftLeaves(struct TreeNode* root){
    if (root == NULL) {
        return 0;
    }
    int sum = 0;
    if (root->left) {
        if (root->left->left == NULL && root->left->right == NULL) {
            sum += root->left->val;
        }
    }
    return  sum + sumOfLeftLeaves(root->left) + sumOfLeftLeaves(root->right);
}
```

```c
int isleaf(struct TreeNode* root)
{
    return root->left == NULL && root->right == NULL;
}

int sumOfLeftLeaves(struct TreeNode* root)
{
    if(root == NULL) {
        return 0;
    }
    if (root->left) {
        if(isleaf(root->left)) {
            // 此处直接递归，少一层调用
            return root->left->val + sumOfLeftLeaves(root->right);
        }
    }
    return sumOfLeftLeaves(root->left) + sumOfLeftLeaves(root->right);
}
```

### <span id="442">442</span>.[数组中重复的数据](https://leetcode-cn.com/problems/find-all-duplicates-in-an-array/)

> 思路：
一、通过表标记数组中出现过的数字，当再次出现时将数字添加到返回数组中。
二、

```c
#define MAXSIZE 100000

int* findDuplicates(int* nums, int numsSize, int* returnSize){
    int table[MAXSIZE] = {0};
    *returnSize = 0;
    int *res = (int *)malloc(sizeof(int) * MAXSIZE);
    for (int i = 0; i < numsSize; i++) {
        if (table[nums[i]] == 1) {
            res[*returnSize] = nums[i];
            (*returnSize)++;
        } else {
            table[nums[i]]++;
        }
    }
    return res;
}
```

```c
int* findDuplicates(int* nums, int numsSize, int* returnSize) {
    int table[100000] = {0};
    int *res = (int *)malloc(sizeof(int) * 100000);
    int j = 0;
    for (int i = 0; i < numsSize; i++) {
        table[nums[i]]++;
        if (table[nums[i]] == 2) {
            res[j++] = nums[i];
        }
    }
    *returnSize = j;
    return res;
}
```


### 461.[汉明距离](https://leetcode-cn.com/problems/hamming-distance/)

> 思路：
一、求 x ^ y 中 1 的个数
二、比较x，y的每一位 和 1与

```c
int hammingDistance(int x, int y)
{
    int n = x ^ y;
    int res = 0;
    while (n) {
        int p = n & 1;
        if (p) {
            res++;
        }
        n >>= 1;
    }
    return res;
}
```

```c
int hammingDistance(int x, int y){
    int count = 0;
    while (x || y) {
        int nX = x & 0x1;
        int nY = y & 0x1;
        if (nX != nY) {
            count++;
        }
        x >>= 1;
        y >>= 1;
    }
    return count;

}
```

### <span id="476">476</span>.[数字的补数](https://leetcode-cn.com/problems/number-complement/)

> 思路：
一、按位与1求与，再取反(!)，然后移位，
二、先统计位数，在取位数相同全一数，最后与原数字求异或 ^

```c
int findComplement(int num){
    int res = 0;
    int count = 0;
    while (num) {
        int t = !(num & 0x1);
        t <<= count;
        printf("t = %d\n", t);
        res += t;
        count++;
        num>>=1;
    }
    return res;

}
```

```c
int findComplement(int num){
    int totalBits = 0;
    int tmp = num;
    while (tmp) {
        totalBits++;
        tmp >>= 1;
    }
    int flipNumber = 1;
    for (int i = 1; i < totalBits; i++) {
        flipNumber += UINT32_C(1) << i;
    }
    num = num ^ flipNumber;
    return num;
}

```

### 509.[斐波那契数列](https://leetcode-cn.com/problems/fibonacci-number/)

> 思路：一、递归  二、迭代

- 递归
```c
int fib(int n){
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);

}
```

- 迭代
```c
int fib(int n){
    if (n <= 1) {
        return n;
    }
    int* nums = (int *)malloc(sizeof(int) * (n + 1));
    nums[0] = 0;
    nums[1] = 1;
    for (int i = 2; i <= n; i++) {
        nums[i] = nums[i - 1] + nums[i - 2];
    }
    return nums[n];
}
```

### 520.[检测大写字母](https://leetcode-cn.com/problems/detect-capital/submissions/)

> 思路：
一、先判断第二个字母是否为大写，1.word[1] 大写，从从零开始判断是否全为大写 2.word[1]为小写，从word是否全为小写。
二、

```c
bool detectCapitalUse(char * word){

    int len = strlen(word);
    if (len <= 1) {
        return true;
    }

    int i = 1;
    if (isupper(word[i])) {
        i = 0;
        while (word[i] != '\0') {
            if (!isupper(word[i])) {
                return false;
            }
            i++;
        }
    } else {
        while (word[i] != '\0') {
            if (isupper(word[i])) {
                return false;
            }
            i++;
        }
    }
    return true;
}
```

```c
bool detectCapitalUse(char * word){
    int len = strlen(word);
    if (len == 1) {
        return true;
    }
    for (int i = 1; i < len; i++) {
        // word[0] 每次都需要判断，一个复杂度。
        if (isupper(word[0]) && isupper(word[1])) {
            if (!isupper(word[i])) {
                return false;
            }
        } else {
            if (isupper(word[i])) {
                return false;
            }
        }
    }
    return true;
   
}
```


### 561.[拆分数组I](https://leetcode-cn.com/problems/array-partition-i/)

> 思路：排序，取偶数位求和。

```c
int Cmp(const void* a, const void* b)
{
    return *(int *)a - *(int *)b;
}
int arrayPairSum(int* nums, int numsSize){
    qsort(nums, numsSize, sizeof(int), Cmp);
    int minSum = 0;
    for (int i = 0; i < numsSize; i++) {
        if (i % 2 == 0) {
            minSum += nums[i];
        }    
    }
    return minSum;
}
```

### <span id="617">617</span>.[合并二叉树](https://leetcode-cn.com/problems/merge-two-binary-trees/)

> 思路：递归，判空，

```c
struct TreeNode* newNode(int val)
{
    struct TreeNode* node = malloc(sizeof(struct TreeNode));
    node->val = val;
    node->left = NULL;
    node->right = NULL;
    return node;
}

struct TreeNode* mergeTrees(struct TreeNode* root1, struct TreeNode* root2){

   /*  if (root1 == NULL && root2 == NULL) {
        return NULL;
    } */
    if (root1 == NULL) {
        return root2;
    }

    if (root2 == NULL) {
        return root1;
    }
    
   /*  struct TreeNode* root = (struct TreeNode*)malloc(sizeof(struct TreeNode));
    root->val += root1 == NULL ? 0 : root1->val;
    root->val += root2 == NULL ? 0 : root2->val;
    root->left = NULL;
    root->right = NULL; */
    int val = (root1 == NULL ? 0 : root1->val) + (root2 == NULL ? 0 : root2->val);
    struct TreeNode* root  = newNode(val);
    root->left = mergeTrees(root1->left, root2->left);
    root->right = mergeTrees(root1->right, root2->right);
    return root;
}
```

### 647.[回文子串](https://leetcode-cn.com/problems/palindromic-substrings/)

> 思路：左侧判断去重，左右判断相等。

```c
int countSubstrings(char * s)
{
    int len = strlen(s);
    int res = len; // 每个字符都是回文
    for (int i = 0; i < len; i++) {
        int p = i - 1;
        while (p >= 0 && s[p] == s[i]) { // 左侧去重
            res++;
            p--;
        }
        int q = i + 1;
        while (p >= 0 && q < len && s[p] == s[q]) { // 判断左右相等
            res++;
            p--;
            q++;
        }
    }
    return res;
}
```

```c
int countSubstrings(char * s){
    int len = strlen(s);
    int count = 0;
    for (int i = 0; i < len; i++) {
        count += countPalin(s, i, i, len);
        if (i != len - 1) {
            count += countPalin(s, i, i+1, len);
        }
    }
    return count;
}

int countPalin(char *s, int head, int tail, int len)
{
    int ret = (s[head] == s[tail]) ? 1 : 0;
    if (ret && head - 1 >= 0 && tail + 1 < len) {
        ret += countPalin(s, head - 1, tail + 1, len);
    }
    return ret;
}
```

### 674.[最长连续递增序列](https://leetcode-cn.com/problems/longest-continuous-increasing-subsequence/)

> 思路：双循环判断，

```c
int findLengthOfLCIS(int* nums, int numsSize){
    if (numsSize == 1) {
        return 1;
    }
    int p2 = 0;
    int res = 0;
    for (int i = 1; i < numsSize; i++) {
        while (i < numsSize && nums[i-1] < nums[i]) {
            i++;
        }
        res = res > i - p2 ? res : i - p2;
        p2 = i;

    } 
    return res;
}
```


```c
int findLengthOfLCIS(int* nums, int numsSize){
    int maxLen = 0;
    int i = 0;
    while (i < numsSize) {
        int start = i;
        while (start + 1 < numsSize && nums[start] < nums[start + 1]) {
            start++;
        }
        maxLen = maxLen > (start - i + 1) ? maxLen : (start - i + 1);
        start++;
        i = start;
    }
    return maxLen;
}
```

### 700.[二叉搜索树中的搜索](https://leetcode-cn.com/problems/search-in-a-binary-search-tree/)

> 思路：递归，注意 判空 root == NULL

```c
struct TreeNode* searchBST(struct TreeNode* root, int val){
    if (root == NULL) {
        return NULL;
    }
    if (root->val == val) {
        return root;
    } else if (root->val > val) {
        return searchBST(root->left, val);
    } else {
        return searchBST(root->right, val);
    }
    return NULL;
}
```

### <span id="701">701</span>.[二叉搜索树中的插入操作](https://leetcode-cn.com/problems/insert-into-a-binary-search-tree/)

> 思路：递归，递归出口，root == NULL, 新建树结点 malloc

```c
struct TreeNode* insertIntoBST(struct TreeNode* root, int val){

    if (root == NULL) {
        struct TreeNode* newNode = (struct TreeNode*)malloc(sizeof(struct TreeNode));
        newNode->val = val;
        newNode->left = NULL;
        newNode->right = NULL;
        return newNode;
    }
    if (root->val < val) {
        root->right = insertIntoBST(root->right, val);
    }
    if (root->val > val) {
        root->left = insertIntoBST(root->left, val);
    }
    return root;
}
```

### 704.[二分查找](https://leetcode-cn.com/problems/binary-search/)

> 思路：二分查找，注意 left <= right ，包含等于

```c
int search(int* nums, int numsSize, int target){
    int left = 0;
    int right = numsSize - 1;
    while (left <= right) {
        int mid = left + (right - left) / 2;
        if (nums[mid] == target) {
            return mid;
        } else if (nums[mid] > target) {
            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }
    return -1;
}
```

### 709.[转换成小写字母](https://leetcode-cn.com/problems/to-lower-case/)

> 思路；库函数 isupper, tolower

```c
char * toLowerCase(char * s){
    int len = strlen(s);
    for (int i = 0; i < len; i++) {
        if (isupper(s[i])) {
            s[i] = tolower(s[i]);
        }
    }
    return s;
}
```

### 771.[宝石和石头](https://leetcode-cn.com/problems/jewels-and-stones/)

> 思路：表记录stones中每个字符个数，求和jewels字符表中的值

```c
int numJewelsInStones(char * jewels, char * stones){
    int table[256] = {0};
    int sLen = strlen(stones);
    for (int i = 0; i < sLen; i++) {
        table[stones[i]]++;
    }

    int jLen = strlen(jewels);
    int sum = 0;
    for (int i = 0; i < jLen; i++) {
        sum +=  table[jewels[i]];
    }
    return sum;
}
```


### 852.[山脉数组的峰顶索引](https://leetcode-cn.com/problems/peak-index-in-a-mountain-array/)

> 思路：判断条件，完全

```c
int peakIndexInMountainArray(int* arr, int arrSize){

  int low = 1, high = arrSize;
    while (low <= high) {
        int mid = low + (high - low) / 2;
        if (arr[mid - 1] < arr[mid] && arr[mid] > arr[mid + 1])
            return mid;
        else if (arr[mid - 1] < arr[mid] && arr[mid] < arr[mid + 1])
            low = mid + 1;
        else
            high = mid - 1;
    }
    return -1;

}
```

### 876.[链表的中间结点](https://leetcode-cn.com/problems/middle-of-the-linked-list/)

> 思路：快慢指针，第二个指针通过 偶数判断  for循环

```c
struct ListNode* middleNode(struct ListNode* head){

    struct ListNode* pos1 = head;
    struct ListNode* pos2 = head;
    for (int i = 0; pos1->next != NULL; pos1 = pos1->next, i++) {
        if (i % 2 == 0) {
            pos2 = pos2->next;
        }
    }
    return pos2;
}
```

### 905.[按奇偶排序数组](https://leetcode-cn.com/problems/sort-array-by-parity/)

> 思路: 一、双指针，同917
二、判断，前后索引移动，双指针

- 解法一：
```c
int* sortArrayByParity(int* nums, int numsSize, int* returnSize)
{
    *returnSize = numsSize;
    int start = 0;
    int end = numsSize - 1;
    while (start < end) {
        while (start < end && nums[start] % 2 == 0) {
            start++;
        }
        while (end > start && nums[end] % 2 == 1) {
            end--;
        }
        while (start < end && nums[start] % 2 != 0 && nums[end] % 2 != 1) {
            int tmp = nums[start];
            nums[start] = nums[end];
            nums[end] = tmp;
            start++;
            end--;
        }
    }
    return nums;
}

int* sortArrayByParity(int* nums, int numsSize, int* returnSize){
    *returnSize = numsSize;
    int left = 0;
    int right = numsSize - 1;
    while (left < right) {
         if (nums[left] % 2 == 0) {
            left++;
            continue;
         }
         if (nums[right] % 2 == 1) {
             right--;
             continue;
         }

         int tmp = nums[left];
         nums[left] = nums[right];
         nums[right] = tmp;
         left++;
         right--;
    }
    return nums;

}
```

- 解法二；
```c
int* sortArrayByParity(int* nums, int numsSize, int* returnSize){
    int *res = (int *)malloc(sizeof(int) * numsSize);
    *returnSize = numsSize;
    int j = 0;
    int p = numsSize - 1;
    for (int i = 0; i < numsSize; i++) {
        if (nums[i] % 2 == 0) {
            res[j] = nums[i];
            j++;
        } else {
            res[p] = nums[i];
            p--;
        }
    }
    return res;
}
```


### 917.[仅仅反转字母](https://leetcode-cn.com/problems/reverse-only-letters/)

> 思路：双指针，库函数 isalpha， continue

```c
char * reverseOnlyLetters(char * s){
    int len = strlen(s);
    int left = 0;
    int right = len - 1;
    while (left < right) {
        if (!isalpha(s[left])) {
            left++;
            continue;
        }
         if (!isalpha(s[right])) {
            right--;
            continue;
        }
        //if (isalpha(s[left]) && isalpha(s[right])) {
            char c = s[left];
            s[left] = s[right];
            s[right] = c;
            left++;
            right--;
        //}
       
    }
    return s;
}
```


### <span id="938">938</span>.[二叉搜索树的范围和](https://leetcode-cn.com/problems/range-sum-of-bst/)

```c
int rangeSumBST(struct TreeNode* root, int low, int high){

    if (root == NULL) {
        return 0;
    }

    if (low > root->val) {
        return rangeSumBST(root->right, low, high);
    }
    if (high < root->val) {
        return rangeSumBST(root->left, low, high);
    }
    return root->val + rangeSumBST(root->left, low, high) + rangeSumBST(root->right, low, high);

}
```

```c
int rangeSumBST(struct TreeNode* root, int low, int high){
    if (root == NULL) {
        return 0;
    } else if (root->val >= low && root->val <= high) {
        return root->val + rangeSumBST(root->left, low, high) + rangeSumBST(root->right, low, high);
    } else {
        return rangeSumBST(root->left, low, high) + rangeSumBST(root->right, low, high);
    }
}
```




### 965.[单值二叉树](https://leetcode-cn.com/problems/univalued-binary-tree/)

> 思路：递归，递归出口：root == NULL

```c
bool isUnivalTree(struct TreeNode* root){
    // root不判空会报错：
    // member access within null pointer of type 'struct TreeNode'
    if (root == NULL) {
        return true;
    }
    // 多余
   /*  if (root->left == NULL && root->right == NULL) {
        return true;
    } */


    if (root->left != NULL) {
        if (root->left->val != root->val) {
            return false;
        }
    }

    if (root->right != NULL) {
        if (root->right->val != root->val) {
            return false;
        }
    }

    return isUnivalTree(root->left) && isUnivalTree(root->right);

}
```


### 977.[有序数组的平方](https://leetcode-cn.com/problems/squares-of-a-sorted-array/submissions/)

> 思路: 
一、先平方，再排序
二、双指针，左右指针比较绝对值大小，从后向前填充结果数组

```c
int Cmp(const void* a,  const void* b)
{
    return *(int *)a - *(int *)b;
}

int* sortedSquares(int* nums, int numsSize, int* returnSize){

    int* squareNum = (int *)malloc(sizeof(int) * numsSize);
    *returnSize = numsSize;
    for (int i = 0; i < numsSize; i++) {
        //squareNum[i] = nums[i] * nums[i];
        squareNum[i] = pow(nums[i], 2);
    }
    qsort(squareNum, numsSize, sizeof(int), Cmp);
    return squareNum;
}
```

```c
int* sortedSquares(int* nums, int numsSize, int* returnSize){
    int*  squareNum = (int *)malloc(sizeof(int) * numsSize);
    *returnSize = numsSize;
    int left = 0;
    int right = numsSize - 1;
    int i = numsSize - 1;
    while (left < right) {
        if (fabs(nums[left]) > nums[right]) {
            squareNum[i--] = nums[left] * nums[left];
            left++;
        } else {
            squareNum[i--] = nums[right] * nums[right];
            right--;
        }
    }
    squareNum[i] = nums[left] * nums[left];
    return squareNum;
}
```

### <span id="1089">1089</span>.[复写零](https://leetcode-cn.com/problems/duplicate-zeros/)

> 思路：将原数组复制一份，根据复制数组，修改原数组值

```c
void duplicateZeros(int* arr, int arrSize)
{
    int b[arrSize]; // = {0};
    memcpy(b, arr, sizeof(int) * arrSize);
    for (int i = 0, j = 0; i < arrSize && j < arrSize; i++) {
        arr[j++] = b[i];
        if (j < arrSize && b[i] == 0) {
            arr[j++] = 0;
        }
    }W
}
```

```c
void duplicateZeros(int* arr, int arrSize){

    int * nums = (int *)malloc(sizeof(int) * arrSize);
    for (int i = 0; i < arrSize; i++) {
        nums[i] = arr[i];
    }

    int j = 0;
    for (int i = 0; i < arrSize; i++, j++) {
        arr[i] = nums[j];
        if (i + 1 < arrSize && nums[j] == 0) {
            arr[++i] = 0; 
        }
    }

}
```



### 1184.[公交站间的距离](https://leetcode-cn.com/problems/distance-between-bus-stops/submissions/)

> 思路: 保证 start 小于 destination， 计算一圈的总长度sum，计算start到destination的距离d，取d与sum-d两者较小值

```c
int distanceBetweenBusStops(int* distance, int distanceSize, int start, int destination){
    
    if (start > destination) {
        int tmp = start;
        start = destination;
        destination = tmp;
    }

    int min = 0;
    int sum = 0;
    for (int i = 0; i < distanceSize; i++) {
        sum += distance[i];
        if (i >= start && i < destination) {
            min += distance[i];
        }
    }

    min = min < (sum - min) ? min : sum - min;
    return min;
}
```

### 1189.[ “气球” 的最大数量](https://leetcode-cn.com/problems/maximum-number-of-balloons/)

> 思路：统计字符次数，注意 字符串指针  取值 *p  或者 字符数组 test[i]

```c
int maxNumberOfBalloons(char * text){
    int len = strlen(text);
    int table[5] = {0};

    char* p = text;
    while (*p != '\0') {
        if (*p == 'b') {
            table[0]++;
        }
        if (*p == 'a') {
            table[1]++;
        }
        if (*p == 'l') {
            table[2]++;
        }
        if (*p == 'o') {
            table[3]++;
        }
        if (*p == 'n') {
            table[4]++;
        }
        p++;
    }

    table[2] /= 2;
    table[3] /= 2;
    int min = INT_MAX;
    for (int i = 0; i < 5; i++) {
        min = min < table[i] ? min : table[i];
    }
    return min;

}


/* int maxNumberOfBalloons(char * text){
    int len = strlen(text);

    int testNum[5] = {0};

    for (int i = 0; i < len; i++) {
        if (text[i] == 'b') {
            testNum[0]++;
        }
        if (text[i] == 'a') {
            testNum[1]++;
        }

        if (text[i] == 'l') {
            testNum[2]++;
        }

        if (text[i] == 'o') {
            testNum[3]++;
        }

        if (text[i] == 'n') {
            testNum[4]++;
        }
    }

    testNum[2] /= 2;
    testNum[3] /= 2;

    int res = INT_MAX;
    for (int i = 0; i < 5; i++) {
        res = res < testNum[i] ? res : testNum[i];
    }
    return res;

} */
```



### <span id="1207">1207</span>.[独一无二的出现次数](https://leetcode-cn.com/problems/unique-number-of-occurrences/)

解法一
> 通过一个表统计每个数字出现的次数，定义另外一个表记录表一中每一项的，如果出现相同数字，则返回false，遍历到最后时返回true



<details>
<summary>uniqueOccurrences</summary>

```c
bool uniqueOccurrences(int* arr, int arrSize){
    int table[2001] = {0};

    for (int i = 0; i < arrSize; i++) {
        table[arr[i] + 1000]++;
        printf("table[arr[%d] + 1000] = %d\n", i, table[arr[i] + 1000]);
    }

    int table1[2001] = {0};
    for (int i = 0; i < 2001; i++) {
        table1[i] = 0;
        if (table[i] != 0) {
            if (table1[table[i]] != 0) {
                printf("table1[table[%d]] = %d\n", i, table1[table[i]]);
                return false;
            } else {
                table1[table[i]]++;
            }
        }
        
    }
    return true;

}
```

解法二：
> 同解法一
```c
/* */
bool uniqueOccurrences(int* arr, int arrSize){
   int hashTable[2001]={0};//初始化一张表，下标对应元素值，存储对应元素出现的次数
    for(int i=0;i<arrSize;i++) {
        hashTable[arr[i]+1000]++;
    }
    bool visited[1001]={false};
    for(int i=0;i<2001;i++) {
        if(hashTable[i]) { //如果i在数组中
            if(visited[hashTable[i]]) { //如果之前出现过与i相同的重复次数
                return false;
            } else {
                visited[hashTable[i]]=true;//说明与i相同的重复次数还未出现，设置为已访问过
            }
        }
    }
    return true;

} 

```
</details>





- 参考博客：
https://programmercarl.com/
https://mp.weixin.qq.com/s/AWsL7G89RtaHyHjRPNJENA


https://programmercarl.com/
https://mp.weixin.qq.com/s/AWsL7G89RtaHyHjRPNJENA












