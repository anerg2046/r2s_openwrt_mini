# 最小化NanoPi R2s OpenWrt固件

不到30M的固件，对系统负载极低，只保留最基本和常用的功能

基于https://github.com/coolsnowwolf/lede

包含的软件:

* PassWall
* 京东签到
* 上网时间控制
* 网络唤醒
* UPnP
* KMS服务器
* FlowOffload

> **注意：** 已交换lan和wan，接线的时候请注意靠外侧的是lan口，如不想交换，可以注释掉或删掉diy-part1.sh中相关代码