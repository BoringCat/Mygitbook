# 为Centos7编译兼容IPv6 TOA的内核 <!-- omit in toc -->

- [准备](#准备)- [获取内核源码](#获取内核源码)
- [准备编译环境](#准备编译环境)
  - [安装devel包](#安装devel包)
  - [安装内核源码](#安装内核源码)
- [TOA补丁（可选）](#toa补丁可选)
- [内核补丁](#内核补丁)
  - [准备工作](#准备工作)
  - [创建patch文件](#创建patch文件)
- [进行编译](#进行编译)
  - [准备配置文件（如果有）](#准备配置文件如果有)
  - [跑！](#跑)
- [获取内核](#获取内核)
- [测试](#测试)
  - [服务端](#服务端)
  - [客户端](#客户端)

## 获取内核源码
每个版本的Centos内核源码都能在 vault.centos.org 找到，当然也可以选择国内镜像，正常目录为 centos-vault
示例地址（Centos7.5）：
```url
https://vault.centos.org/7.5.1804/os/Source/SPackages/kernel-3.10.0-862.el7.src.rpm
```

## 准备编译环境
**推荐：Docker环境编译，使用Centos官方镜像，镜像版本对应内核版本，能减少很多问题**  
以Centos7为例：  
文档：  
- [HowTos/I_need_the_Kernel_Source - CentOS Wiki][1]
- [HowTos/Custom_Kernel - CentOS Wiki][2]
### 安装devel包
```sh
yum install asciidoc audit-libs-devel bash bc binutils binutils-devel bison diffutils elfutils \
    elfutils-devel elfutils-libelf-devel findutils flex gawk gcc gettext gzip hmaccalc hostname java-devel \
    m4 make module-init-tools ncurses-devel net-tools newt-devel numactl-devel openssl \
    patch pciutils-devel perl perl-ExtUtils-Embed pesign python-devel python-docutils redhat-rpm-config \
    rpm-build sh-utils tar xmlto xz zlib-devel
```
~~_（加上它们的依赖共184个包............）_~~
### 安装内核源码
```sh
rpm -i kernel-3.10.0-862.el7.src.rpm
# 或
yum install https://vault.centos.org/7.5.1804/os/Source/SPackages/kernel-3.10.0-862.el7.src.rpm
```

## TOA补丁（可选）
可以在编译好内核后直接在系统中编译（需要安装内核`headers`和`devel`包）
<details>
  <summary><strong>制作方法</strong></summary>

  参考文档：[Building a custom kernel/Source RPM - Fedora Project Wiki][3]

  1. 去SPECS目录  
    `cd ~/rpmbuild/SPECS`
  2. 解压源码，生成BUILD目录  
    `rpmbuild -bp --target=$(uname -m) kernel.spec`
  3. 去BUILD目录  
    `cd ~/rpmbuild/BUILD`
  4. 拷贝内核源码，避免更改  
    `cp -r kernel-$ver.$subver.$fedver kernel-$ver.$subver.$fedver.new`
  5. 解压你的TOA模块到内核源码内（`kernel-$ver.$subver.$fedver.new`）
  6. 写Kconfig  
        ``` config
        config	TOA
            tristate "The private TCP option"
            default m
            ---help---
            This option saves the original IP address and source port of a TCP segment
            after LVS performed NAT on it. So far, this module supports IPv4 and IPv6.

            Say m if unsure.
        ```
  7. 修改TOA模块上级的Kconfig和Makefile  
     - Kconfig  
        增加：`source "path/to/toa/Kconfig"`
     - Makefile  
        增加：`obj-$(CONFIG_TOA)		+= toa/`  
        **注意！：这里的CONFIG_TOA需要与TOA的Kconfig文件对应**
  8. 用diff生成patch文件  
    `diff -uNrp kernel-$ver.$subver.$fedver kernel-$ver.$subver.$fedver.new > ../SOURCES/add-toa.patch`
  9.  修订patch文件，去除一级目录
  10. 将patch文件加入`kernel.spec`  
     - 修改：`%define listnewconfig_fail 1` --> `%define listnewconfig_fail 0`
     - 在相应地方增加：`PatchXXXX: add-toa.patch`
     - 在相应地方增加：`ApplyOptionalPatch: add-toa.patch`

</details>
<br/>

## 内核补丁
需要修改的文件：
- net/ipv6
  - af_inet6.c
  - tcp_ipv6.c
- include/net
  - ipv6.h
  - transp_v6.h
### 准备工作
1. 去SPECS目录  
`cd ~/rpmbuild/SPECS`
1. 解压源码，生成BUILD目录  
 `rpmbuild -bp --target=$(uname -m) kernel.spec`
3. 去BUILD目录  
 `cd ~/rpmbuild/BUILD`
4. 拷贝内核源码，避免更改  
 `cp -r kernel-$ver.$subver.$fedver kernel-$ver.$subver.$fedver.new`
### net/ipv6/af_inet6.c <!-- omit in toc -->
找到 `inet6_stream_ops` 在它下面加入 `EXPORT_SYMBOL(inet6_stream_ops);`
### net/ipv6/tcp_ipv6.c <!-- omit in toc -->
找到结构体 `ipv6_mapped` 和 `ipv6_specific` 的预定义，去除 `static const` 类型定义  
找到结构体 `ipv6_mapped` 和 `ipv6_specific` 的定义，**分别**在下面加入 `EXPORT_SYMBOL(ipv6_mapped);` `EXPORT_SYMBOL(ipv6_specific);`
找到函数 `tcp_v6_syn_recv_sock` 去除 `static` 类型定义，在下面加入 `EXPORT_SYMBOL(tcp_v6_syn_recv_sock);`
### include/net/ipv6.h <!-- omit in toc -->
在文件末尾加入以下内容，注意**不要**放到 **#ifdef** 里面
```
/* public func in tcp_ipv6.c */
extern struct sock *tcp_v6_syn_recv_sock(struct sock *sk, struct sk_buff *skb,
					struct request_sock *req,
					struct dst_entry *dst);
extern struct inet_connection_sock_af_ops ipv6_specific;
```
### include/net/transp_v6.h <!-- omit in toc -->
找到 `ipv4_specific` 在它附近（前后都行）加入
```
extern struct inet_connection_sock_af_ops ipv6_mapped;
```
### 创建patch文件
命令：`diff -uNrp kernel-$ver.$subver.$fedver kernel-$ver.$subver.$fedver.new > ../SOURCES/toa-kernel.patch`  
修订patch文件，去除一级目录  
将patch文件加入`kernel.spec`  
- 在相应地方增加：`PatchXXXX: toa-kernel`
- 在相应地方增加：`ApplyOptionalPatch: toa-kernel`

## 进行编译
### 准备配置文件（如果有）
从现有Centos中拷贝/boot/config-`uname -r` 到 `~/rpmbuild/SOURCES/kernel-$ver-$target.config`  
在配置文件第一行加入架构的注释，例如：`# x86_64`
### 跑！
去`~/rpmbuild/SPECS`目录，执行命令
```sh
rpmbuild -bb --target=`uname -m` kernel.spec 2> build-err.log | tee build-out.log
```
然后去睡个好觉

## 获取内核
编译好的内核包在 `~/rpmbuild/RPMS/$target/`，里面还有一些其他包  
正常情况下只需要安装 `kernel-$ver-$subver.$rhver.$buildid.$target.rpm`  
需要配置开发的环境的建议把 devel 和 headers 也装了

## 测试
### 服务端
#### v4 <!-- omit in toc -->
```py
import socket
sport = 12345

def listen():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', sport))
    s.listen(10)
    while True:
        client, address = connection.accept()
        print(address)
        client.close()

if __name__ == "__main__":
    try:
        listen()
    except KeyboardInterrupt:
        pass
```
#### v6 <!-- omit in toc -->
```py
import socket
sport = 12345

def listen():
    s = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('::', sport))
    s.listen(10)
    while True:
        client, address = connection.accept()
        print(address)
        client.close()

if __name__ == "__main__":
    try:
        listen()
    except KeyboardInterrupt:
        pass
```
### 客户端
准备工作：限制内核RST包
```sh
iptables -A OUTPUT -d $DSTIP -p tcp --dport $DSTPORT --tcp-flags RST RST -j DROP
```
```py
from scapy.all import *
# 参数
src = sys.argv[1]
dst = sys.argv[2]
sport = random.randint(1024,65535)
dport = int(sys.argv[3])
tsrc = sys.argv[5]
tsport = int(sys.argv[6])
# TOA OPTION
OPTION_ID = int(sys.argv[4])
HEX = "%04X%02X%02X%02X%02X" % (tsport, *map(int,tsrc.split('.')))
bHEX = bytes.fromhex(HEX)
print(HEX)
# SYN
ip=IP(src=src,dst=dst)
SYN=TCP(sport=sport,dport=dport,flags='S',seq=1000)
SYN.options = [[OPTION_ID, bHEX]]
SYNACK=sr1(ip/SYN)
# ACK
ACK=TCP(sport=sport, dport=dport, flags='A', seq=SYNACK.ack, ack=SYNACK.seq + 1)
ACK.options = [[OPTION_ID, bHEX]]
send(ip/ACK)
```

[1]: https://wiki.centos.org/HowTos/I_need_the_Kernel_Source
[2]: https://wiki.centos.org/HowTos/Custom_Kernel
[3]: https://fedoraproject.org/wiki/Building_a_custom_kernel/Source_RPM