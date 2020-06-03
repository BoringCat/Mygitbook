# 在锐捷三层交换机上部署DHCPv6-PD <!-- omit in toc -->
- [1. 设备](#1-设备)
- [2. 配置](#2-配置)
- [3. 验证配置](#3-验证配置)
- [4. 个人总结](#4-个人总结)

## 1. 设备
* 核心设备：RG-N18010
* 服务器：Debian 9 ESXI5.5虚拟机
* 交换设备：通用二层交换机
* 验证设备： 
  1. OpenWRT X86 18.06.2 ESXI5.5虚拟机
  2. 任意终端设备（以Windows 10笔记本与Android P手机为例）
* 实验网络结构：  

|VLAN|注释|地址段|
|:-:|:-:|:-:|
|VLAN10|服务器VLAN|2001::/64|
|VLAN100|用户VLAN|2001:0:0:100::/64|

  * 假设Ipv6地址段：2001::/48  
  假设PD地址段：2001:250::/48  
  DHCPv6服务器地址：2001::666/64  

## 2. 配置
1. 核心设备

```
Ruijie>en

Password:
Ruijie#conf t
Ruijie(config)#vlan 10
Ruijie(config-vlan)#vlan 100
Ruijie(config-vlan)#int vlan 10
Ruijie(config-if-VLAN 10)#ipv6 enable
Ruijie(config-if-VLAN 10)#ipv6 add 2001::1/64
Ruijie(config-if-VLAN 10)#int vlan 100
Ruijie(config-if-VLAN 100)#ipv6 enable
Ruijie(config-if-VLAN 100)#ipv6 add 2001:0:0:100::1/64
Ruijie(config-if-VLAN 100)#no ipv6 nd suppress-ra
Ruijie(config-if-VLAN 100)#ipv6 dhcp relay destination 2001::666 VLAN 10
Ruijie(config-if-VLAN 100)#end
Ruijie#
```

2. 服务器
   1. 设置网卡，添加地址：`2001::666/64`，网关：`2001::1`
   2. 安装软件包 `isc-dhcp-server`
   3. 配置文件 `/etc/dhcp/dhcpd6.conf`
      1. (可选) 无域名可以注释掉 `option dhcp6.domain-search`
      2. (可选) 设置全局Ipv6 DNS `option dhcp6.name-servers 2001:da8::666`
      3. 添加所属子网地址池 (受限于gitbook无法换行) `subnet6 2001::/64 { range6 2001::666 2001::666; } `
      4. 添加地址段 `subnet6 2001:0:0:100::/64 { `
      5. 设置前缀与分配的掩码 `prefix6 2001:250:: 2001:250:0:ffff:: /64; }`
   4. 配置文件 `/etc/default/isc-dhcp-server`
      1. 绑定DHCPv6网卡 例如；`INTERFACESv6="ens32"`
   5. 启动服务 `systemctl start isc-dhcp-server.service`

## 3. 验证配置
   1. 保持OpenWRT默认配置不变，删除`/etc/config/network`的ULA前缀，通过LUCI确认DHCPv6-PD正常分配，并且br-lan接口获得ipv6地址  
   ![OpenWrt-PD](../../.gitbook/assets/OpenWRT_PD.jpg)
   2. 打开Windows的 `控制面板\网络和 Internet\网络连接` 查看网络连接详细信息，确认客户端已获取Ipv6地址  
   ![Win10Ipv6](../../.gitbook/assets/Windows10-Ipv6.png)

## 4. 个人总结
* 锐捷三层交换机可进行IA_PD分配，但是无法添加静态路由。思科有命令：`ipv6 dhcp iapd-route-add`，但是锐捷没有  
  但是你可以通过DHCPV6 relay的方式通过一台服务器分配IA_PD，同时交换机上会添加静态路由
  简单来说：A能做B和C但不能同时做，他要叫D帮他做C，自己做B  
  ~~*(NMD，WSM.jpg)*~~