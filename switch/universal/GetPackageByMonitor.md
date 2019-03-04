---
description: GetPackageByMonitor
---


## 通过交换机的镜像功能抓包
**\*交换机实体环境：Ruijie S2628G**  
**\*\*可能这篇不会更新思科的配置方法了 QAQ**

### # 锐捷交换机(非11.X软件平台)
#### 1. 官方文档
```
路径：实施一本通/四、功能配置/1、基础配置/7、镜像/1、多对一镜像(包含一对一镜像)
......
一、组网需求
配置端口镜像，实现监控服务器能够监控g0/1及g0/2口入方向和出方向的数据流，同时监控服务器依然能够实现对外网网络的访问

二、组网拓扑
```
![Topology](../../.gitbook/assets/RG-Monitor-Topology.png)
```
三、配置要点
要实现监控服务器即能对外网网络的访问，需要在配置交换机端口镜像的目的端口后面加上switch关键字

四、配置步骤  
交换机配置：
Ruijie>enable                                     
Ruijie#configure terminal
Ruijie(config)#monitor session 1 source interface gigabitEthernet 0/1 both
------>指定端口镜像的源端口为g0/1，即被监控端口，交换机可以指定多个源端口。both表示双方向的数据流，
如果只需要镜像进入交换机方向的数据流，则将both关键字改为关键字rx，
命令就变为了：monitor session 1 source interface gigabitEthernet 0/1 rx。
如果只需要镜像从交换机出来方向的流量，则可将both关键字改为tx。

Ruijie(config)#monitor session 1 source interface gigabitEthernet 0/2 both
------>指定端口镜像的源端口g0/2，即被监控端口。交换机可以指定多个源端口。both表示双方向的数据流，
如果只需要镜像进入交换机方向的数据流，则将both关键字改为关键字rx，
如果只需要镜像从交换机出来方向的流量，则可将both关键字改为tx。

Ruijie(config)#monitor session 1 destination interface gigabitEthernet 0/24 switch
------>指定g0/24口为端口镜像的目的端口，即监控端口。后面加了一个关键字swith，表示目的端口也能够上网，
如果不加关键字，那么该端口将不能访问外网。（11.x版本强制要加此关键字）

Ruijie(config)#end
Ruijie#wr
......
```
#### 2. 实验
1. 准备一台上网机(本文使用Linux)，一台电脑抓包(ArchLinux with Wireshark)，以及一台可网管交换机(Ruijie S2628G)  
2. 由于实验时交换机仍需要正常工作，因此选用f0/10与f0/20端口进行连线，上网机连f0/10，电脑连f0/20
3. 确定上网机能正常上网
4. 进行交换机配置：  
1）进入全局模式  
2）输入命令：`monitor session 1 source interface f0/10 both` `monitor session 1 destination interface f0/20`  
2.1）命令中监控端口没有加switch关键字是为了不抓到本机的包  
3）用网线连接交换机与电脑，关闭电脑上任何进行网络通讯的进程，开启对eth0(电脑网卡)的抓包，确定无法抓取任何包  
3.1）建议关闭网络管理服务，如：NetworkManager。以及DHCP服务，如：dhclient。避免产生DHCP以及其他广播包  
4）在确定电脑启动抓包时将上网机插入交换机，同时能观察到电脑上抓取到数据包  
5）为确认抓取到的包是上网机的，在上网机完成网络初始化后获取其IP，并对任意一个能ping通的IP地址发送ICMP包  
5.1）在电脑上抓取到ICMP报文后观测其目的IP，若IP正确，则能确保一对一镜像配置成功。  
\*注：配置一对一镜像或多对一镜像并不会影响监控端口原本的配置。在不需要使用该功能时输入`no monitor session 1 source interface f0/10 both` `no monitor session 1 destination interface f0/20`  即可

#### 3. 远程镜像
**好吧锐捷接入层交换机的远程镜像功能都不完整**
