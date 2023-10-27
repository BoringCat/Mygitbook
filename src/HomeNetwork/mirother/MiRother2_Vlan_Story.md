## 小米路由器R2D的VLAN与路由的问题 <!-- omit in toc --> 

- [前言](#前言)
- [准备开搞](#准备开搞)
- [第一次尝试](#第一次尝试)
- [第二次尝试](#第二次尝试)
- [第三次尝试](#第三次尝试)
- [成功](#成功)

### 前言
家里免费送的移动宽带不好用，有时连“中国教育考试网”都上不去 \_\(:3 」∠\)\_ 。可怜“郊区”地方电信连光纤都没有。于是办了个联通的宽带，把接着移动的小米路由器2接到了联通上。移动随便搞了台Tplink接着。  
但是家里两个网实在是不方便，因为小米路由器2算是家庭媒体存储中心，联通又是内网。一旦接到Tplink就访问不到小米路由器了。找遍了小米路由器2的网页管理后台都找不到有关静态路由的设置。便想着开启小米路由器的SSH然后当成Linux来玩。

ps:神TM小米路由器SSH设置静态路由重启失效
***
### 准备开搞
首先当然是去“[MiWiFi – 开放平台](http://www.miwifi.com/miwifi_open.html)”（在小米路由器的DNS劫持下要输入 www1.miwifi.com）申请开启SSH，然后下载开启SSH的bin文件。按照页面给出的刷入方式搞进去，等路由器重启以后就能用页面给的root密码登录进去了。  
接着当然是先改root密码，毕竟8位随机字母加数字的密码你记也记不住。
### 第一次尝试
**小米路由器的LUCI是魔改的！不能改switch配置！**  
根据 Openwrt wiki 以及个人知识储备，我开始修改配置文件
> `/etc/config/network`  

将  
> ``` config
> config switch_vlan 'eth0_1'  
> option device 'eth0'  
> option vlan '1'  
> option ports '0 2 3 5*'
> 
> config switch_vlan 'eth0_2'  
> option device 'eth0'  
> option vlan '2'  
> option ports '4 5'  
> ```
改成了  
> ```
> config switch_vlan 'eth0_1'  
> option device 'eth0'  
> option vlan '1'  
> option ports '0 2 5*'
> 
> config switch_vlan 'eth0_2'  
> option device 'eth0'  
> option vlan '2'  
> option ports '4 5'  
> 
> config switch_vlan 'eth0_3'  
> option device 'eth0'  
> option vlan '3'  
> option ports '3 5'  
> ...
> 
> ...  
> config interface 'link'  
> option ifname 'eth0.3'  
> option proto 'dhcp'  
> ```
然后信心满满的输入 `/etc/init.d/network restart`  
接着把自己电脑的网线接到三号口，输入`dmesg`看到
> robo_link_down: applying EEE WAR for 53125 port 3 link-up

嗯应该口是没错了..............嗯？怎么我有IP地址？怎么我还能跟其他电脑通信？  
算了不管这么多，先试试用网线把两台路由器连起来，然后抓包。  
emmmmmmmmmmmmmmmmm，Tplink的DHCP包跑了过来(｀･д･´) 。  
好吧......... 第一次失败！  
***
### 第二次尝试
Baidu到小米路由器是用了闭源驱动的，改了`/etc/config/network`只是在系统里生效而已，下面硬件还是像以前那样工作。还需要更改`/etc/config/misc`。  
于是我打开了`misc`，搜索vlan关键字，找到了一个比较相似的地方
> `/etc/config/misc`  
> ```
> config misc ports  
> option vlan1 '0 2 3 5*'  
> option vlan2 '4 5'  
> option vlan1_bridgeap '0 2 3 4 5*'  
> option vlan2_bridgeap '5'  
> ```
> ~~_(老哥你tab/空格并用啊)_~~

把这段改成
> ```
> config misc ports  
> option vlan1 '0 2 5*'  
> option vlan2 '4 5'  
> option vlan3 '3 5'  
> option vlan1_bridgeap '0 2 4 5*'  
> option vlan2_bridgeap '5'  
> option vlan3_bridgeap '3 5'  
> ```
然后保存，reboot！  
.......................怎么........还是一样？？？？？？ (°ー°〃)  
想了想没道理啊，eth0.3出来了，`ifup link` 也生效。为什么还是在同一广播域下  
（＠\_＠;）  
第二次失败！
***
### 第三次尝试
经过了一段时间的查找资料和研究以后，发现小米路由器有nvram，怪不得以前修改的配置文件全部没有生效，原来这些配置文件只是让系统知道下面硬件是什么配置而已。
接着开始尝试修改nvram里面的内容，发现命令就是`nvram`
>  **输出nvram中有关vlan的配置**  
`nvram show | grep vlan`
> ```
> vlan1hwname=et0  
> size: 20153 bytes (45383 left)  
> vlan1ports=0 2 3 5*  
> vlan2hwname=et0  
> vlan2ports=4 5  
> lan_vlan_id=1  
> br0_ifnames=vlan1 wl0 wl1  
> lan_ifnames=vlan1 wl0 wl1   
> landevs=vlan1 wl0 wl1  
> wl0_vlan_prio_mode=off  
> wl1_vlan_prio_mode=off  
> ```

> 发现总有一行 size: 20153 bytes (45383 left) 混迹其中，严重影响阅读。  
于是将输入改成 `nvram show 2> /dev/null | grep vlan`

事实上nvram的输出并没有这么工整，稍加整理后发现规律
> ```
> vlan1hwname=et0  
> vlan1ports=0 2 3 5\*  
> vlan2hwname=et0  
> vlan2ports=4 5  
> ```
添加vlan3的配置便可  
在记事本上修改后如下
> ```
> vlan1hwname=et0  
> vlan1ports=0 2 5\*  
> vlan2hwname=et0  
> vlan2ports=4 5  
> vlan3hwname=et0  
> vlan3ports=3 5  
> ```
输入命令
```
nvram set vlan3hwname=et0
nvram set vlan3ports='3 5'
```
然后保存 `nvram commit`  

我并不清楚nvram的配置是不是立即生效，我还是重启了一次路由器。
接着我电脑拿不到IP地址了，修改应该是生效了。
***
### 成功
用网线把小米路由器与Tplink连起来后，看到小米路由器上eth0.3获取到IP，在Tplink上绑定MAC-IP-ARP后添加到192.168.31.0/24的路由。  
连接在Tplink下的设备可以正常ssh小米路由器，甚至可以通过修改默认路由的方法通过小米路由器上网  
最终实现的拓扑如下~~(及其简单)~~  
![MiRother-fin](../../assets/HomeNetwork/mirother/MiRother-fin.png)
