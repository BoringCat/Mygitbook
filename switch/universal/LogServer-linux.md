# 启用交换机的日记备份并用 rsyslog 接收
**环境：Centos 7 已关闭SELinux**  
**\*交换机模拟环境：GNS3**  
**\*交换机实体环境：Ruijie S2628G/S2628G-E/S12010/N18010**

## #配置rsyslog
Centos 7最小化安装自带rsyslog。若无，可执行 `yum install rsyslog` 安装  
1. 备份默认配置文件`cp /etc/rsyslog.conf /etc/rsyslog.conf.bak`
2. 开启UDP端口监听  
打开配置文件 /etc/rsyslog.conf  
找到`# Provides UDP syslog reception` 行  
取消其下方 `$ModLoad imudp` 与 `$UDPServerRun 514` 的注释  
保存退出
3. 允许接收外来日志  
打开 /etc/sysconfig/rsyslog  
找到SYSLOGD_OPTIONS,加入参数“-r” 表示允许接收外来日志消息  
保存退出  
4. 创建日志接收配置文件（也可直接写在 /etc/rsyslog.conf 中）  
创建文件 /etc/rsyslog.d/switch.conf 添加以下内容  
```
$template myFormat,"[%timestamp:8:15%]%msg%\n"
$template Remote,"/opt/switch/log/%$YEAR%-%$MONTH%/%fromhost-ip%/%$DAY%.log"
:fromhost-ip, !isequal, "127.0.0.1" ?Remote;myFormat
#*.*  ?Remote
& stop
```
其中：  
`$template` 是定义模板  
`$template myFormat,"[%timestamp:8:15%]%msg%\n"` 是 名为myFormat的模板，数据为 `[%timestamp:8:15%]%msg%\n` 其中 %timestamp% 是日志发送的时间 ; %msg% 是日志  
`$template Remote,"/opt/switch/log/%$YEAR%-%$MONTH%/%fromhost-ip%/%$DAY%.log"` 是 名为Remote的模板，数据为 `/opt/switch/log/%$YEAR%-%$MONTH%/%fromhost-ip%/%$DAY%.log` 其中 %$YEAR% %$MONTH% %$DAY% 为服务器的时间 ; %fromhost-ip% 为发送日志主机的IP地址  
`:fromhost-ip, !isequal, "127.0.0.1" ?Remote;myFormat` 是 以远程日志的ip地址作为判断条件，若不为"127.0.0.1"则以myFormat的格式存储到Remote中  
`*.*  ?Remote` 是将任意地址的日志储存到Remote中(此处已注释)

\*网上有些模板是以 `& ~` 结尾的。最新版rsyslog提示使用 stop 代替 ~  
\*首次运行前需创建目录模板Remote的根目录  

注：保存配置文件后需要重新启动rsyslog服务，并且在服务运行期间不能修改占用目录的结构。

**至此，rsyslog的配置已经完成**

5. 配置防火墙 (以iptables为例)  
在 `/etc/sysconfig/iptables` 中的 `:OUTPUT ACCEPT [0:0]` 下添加 `-A INPUT -s 10.0.6.0/24 -p udp --dport 514 -j ACCEPT`  
示例：
```
...
:INPUT ACCEPT [0:0]
...
:FORWARD ACCEPT [0:0]
...
:OUTPUT ACCEPT [0:0]
...
-A INPUT -s 10.0.6.0/24 -p udp --dport 514 -j ACCEPT
...
```
修改完成后需重启iptables服务

## #配置交换机
## 1. GNS3内路由器 (以Cisco3660为例)
1. 进入全局配置模式
2. 输入命令
```
service timestamps log datetime localtime
logging userinfo
logging buffered 16384
logging source-interface f0/0
logging trap informational
logging origin-id hostname
logging 10.0.6.254
```
在日志前加入本地时间，并记录使用特权模式的用户信息  
日志本地缓存大小为16K  
将日志等级为 6(informational) 以下的日志以接口 f0/0 的 IP 为源 IP 发送到服务器 10.0.6.254 并在开头加上交换机的hostname  

## 2. 锐捷交换机 (非11.X软件平台)  
1. 进入全局配置模式
2. 输入命令
```
service sequence-numbers
logging userinfo
logging userinfo command-log
logging buffered 32768
logging source ip 10.0.6.10
logging trap informational
logging 10.0.6.254
```
在日志前加入本地时间与序号，并记录使用登录的用户信息以及全局配置模式下输入的命令  
日志本地缓存大小为32K  
将日志等级为 6(informational) 以下的日志以 10.0.6.10 为源 IP 发送到服务器 10.0.6.254

源 IP 适用于需要用特定VLAN发送日志的情况，默认情况下是使用有IP地址的最小的VLAN  
例如：VLAN10 10.1.1.0/24，VLAN 20 10.0.6.10  
交换机会选择 VLAN 10 的IP地址作为源地址发送

## #验证
在Cisco交换机日志上会出现这样一句
```
%SYS-6-LOGGINGHOST_STARTSTOP: Logging to host 10.0.6.254 port 514 started - CLI initiated
```
证明交换机配置成功

锐捷交换机上并未发现类似命令，只能在服务器上确认

在服务器上的`/opt/switch/log`目录里面出现当前年月的文件夹，并且文件夹内有以交换机IP命名的文件夹，里面存在以日期命名文件  
例如：`/opt/switch/log/2018-02/10.1.1.1/20.log`  
证明服务器配置成功
