## LEDE路由器上SS + 透明代理 <!-- omit in toc -->
**备忘录**  

- [编译与安装](#编译与安装)
- [配置](#配置)
- [进阶](#进阶)

#### 编译与安装  
1. 在Git上拉取编译SS所需的代码和依赖  
<a href="https://github.com/shadowsocks/openwrt-feeds" target="_blank">shadowsocks/openwrt-feeds</a>  
<a href="https://github.com/shadowsocks/openwrt-shadowsocks" target="_blank">shadowsocks/openwrt-shadowsocks</a>  
<a href="https://github.com/shadowsocks/luci-app-shadowsocks" target="_blank">shadowsocks/luci-app-shadowsocks</a>  
(可选)<a href="https://github.com/aa65535/openwrt-simple-obfs" target="_blank">aa65535/openwrt-simple-obfs</a>  
``` shell
git clone https://github.com/shadowsocks/openwrt-feeds.git package/feeds
git clone https://github.com/shadowsocks/openwrt-shadowsocks.git package/shadowsocks-libev
git clone https://github.com/shadowsocks/luci-app-shadowsocks.git package/luci-app-shadowsocks
git clone https://github.com/aa65535/openwrt-simple-obfs.git package/simple-obfs
```
2. 输入`make menuconfig`，找到  
>Network ---> shadowsocks-libev  
Network ---> simple-obfs  
LuCI ---> 3. Applications ---> luci-app-shadowsocks  
**注：LEDE自带 luci-app-shadowsocks-libev 和 luci-app-shadowsocks-without-ipset**

将其设定为 '<m>' 编译为ipk，或 '<\*>' 安装到编译出的固件中。

4. 若是从SDK中编译，  
输入`make package/shadowsocks-libev/compile V=s`编译 shadowsocks-libev 与 shadowsocks-libev-server 包。  
输入`make package/luci-app-shadowsocks/compile V=s`编译luci-app-shadowsocks包。  
输入`make package/simple-obfs/compile V=s`编译simple-obfs 与 编译simple-obfs-server 包。  
若没有错误就可以在 "bin/_$Arch_/packages/base" 或 "bin/_$Arch_/packages/package" 里面找到ipk包。
(不知道为什么我编译ARMV7的路由器时，ipk文件在"bin/packages/_$Arch_"内)  
懒人福利：
```
make package/shadowsocks-libev/compile -j
make package/luci-app-shadowsocks/compile -j
make package/simple-obfs/compile -j
```

5. 若是从源码中编译，可以输入`make V=s`(或`make -j$(cpu核心数+2)`)编译整个LEDE路由系统。具体固件生成的位置要翻阅一下官方文档。即使是是编译固件也会生成ipk包，在 bin/_$Arch_/packages 内。  

6. 安装ipk或安装固件。  

+ openwrt-shadowsocks的依赖有 zlib、libev、libcares、libpcre、libpthread、libsodium、libmbedtls，可选依赖有kmod-ipt-ipset(用于udp透明代理)  
luci-app-shadowsocks的依赖有 iptables.  
openwrt-simple-obfs的依赖有 libev、libpthread.  

#### 配置
+ **初始化**  
启动并连接到路由器，打开浏览器进入路由器Luci管理界面(默认为192.168.1.1)。  
无Luci界面可用uci进行配置，具体配置方法可查询wiki <a href="https://github.com/shadowsocks/luci-app-shadowsocks/wiki/Use-UCI-system" target="_blank">luci-app-shadowsocks - wiki - Use UCI system</a>  
选择服务--->影梭，进入到SS的控制界面。  
![GotoSetting](../../assets/lede/Common_options/SS-GotoSetting.png)  
点击"服务器管理"，删除名为simple的服务器配置(或直接点"修改")，然后点击"添加"新建服务器配置![NewServer](../../assets/lede/Common_options/SS-NewServer.png)  
在编辑服务器界面，需要输入  
> 你的服务器别名 (可选)  
> Tcp 快速打开 (Tcp fast open)(我记得这个选项在服务器端不是去掉了吗？)(根据服务器配置选择)  
> Tcp 无延时 (新版本出来的选项，没用过)(根据服务器配置选择)  
> 服务器地址 (必须)  
> 服务器端口 (必须)  
> 连接超时 (若服务器响应比较慢，可设置较大的数值)  
> 密码 (必须)  
> 直接密钥 (可选)  
> 加密方式 (必须)  
> 插件名称 (可选)  
> 插件参数 (可选)  
> 插件在[进阶](#进阶)里面讲到  
> ![EditServer](../../assets/lede/Common_options/SS-EditServer.png)  

接着点击下方的"保存"，暂时在Luci中保存配置。  

+ **启动**  
点击"基本设置"，选择你要使用的服务，然后"点击右下角保存与应用即可"。正常情况下启动SOCKS5代理即可。

#### 进阶
+ **使用Simple-obfs**  
使用Simple-obfs的配置及其简单，首先确认服务器是否使用了插件Simple-obfs，接着在编辑服务器界面的插件名称处填入 "Simple-obfs"，在插件参数中填入 "obfs=(http/tls);obfs-host=_$Website_"，保存并应用即可。  
**\*其中 obfs 参数为服务器上设定的 "plugin-opts" 参数，obfs-host 参数为任意合法根网址**  

+ **内网区域设定**  
1、进入SS的控制界面，前往"访问控制"。  
2、“内网区域” 的 “接口” 设置可调整属于内网区域。例如：路由器有两个LAN区域，一个是有线的(LAN)，一个是无线的(WLAN)。要让有线的设备使用透明代理又不让无线的设备透明代理，就可以去掉WLAN前面的勾，这样WLAN下的设备就不能享受透明代理了。  

+ **内网主机代理方式**  
使用环境：内网中有一台或多台设备需要不同于默认配置的代理方式  
1、进入SS的控制界面，前往"访问控制"。  
2、在 “内网主机” 的 “接口” 设置中点击 “添加”。  
3、选择需要配置设备的MAC地址，以及其代理类型。  
4、保存并应用。  

+ **透明代理 + GFWlist + ignore\_list**  
**\*该文档所有配置参考与 <a href="https://github.com/shadowsocks/luci-app-shadowsocks/wiki" target="_blank">luci-app-shadowsocks - wiki</a>**
1. 透明代理  
要启动透明代理，需要在SS配置主界面设置透明代理的主服务器与UDP服务器(可选)  
![Tramsparent-Proxy](../../assets/lede/Common_options/SS-Tramsparent-Proxy.png)

2. GFWlist  
GFWlist用于排除DNS干扰，需配合dnsmasq使用<a href="https://github.com/shadowsocks/luci-app-shadowsocks/wiki/GfwList-Support" target="_blank">(Wiki)</a>  
1、下载<a href="https://github.com/cokebar/gfwlist2dnsmasq" target="_blank">gfwlist2dnsmasq</a>脚本，用于更方便的生成 dnsmasq 配置文件。  
2、新建"/etc/dnsmasq.d"文件夹，并在"/etc/dnsmasq.conf"中加入`conf-dir=/etc/dnsmasq.d`使得dnsmasq加载 /etc/dnsmasq.d 目录下所有的配置。  
3、运行 gfwlist2dnsmasq.sh 生成dnsmasq配置文件。命令：`gfwlist2dnsmasq.sh -p 5300 -o /etc/dnsmasq.d/gfwlist` (-p 5300为SS端口转发的本地端口)。  
4、重启dnsmasq，使配置生效。  
5、在SS配置主界面设置端口转发的服务器与目标地址，若要更改本地端口，需要同步更改gfwlist2dnsmasq的命令。  
![Port-forward](../../assets/lede/Common_options/SS-Port-forward.png)  
6(Luci)、自动更新gfwlist。在Luci的 系统 ---> 计划任务中添加一条`30    4     *     *     0     /root/gfwlist2dnsmasq.sh -p 5300 -o /etc/dnsmasq.d/gfwlist>/dev/null 2>&1`  
6(tty)、在`/etc/crontabs/root`中添加一行`30    4     *     *     0     /root/gfwlist2dnsmasq.sh -p 5300 -o /etc/dnsmasq.d/gfwlist>/dev/null 2>&1`。若无此文件，则新建该文件并在shell中输入`echo root > /etc/crontabs/cron.update`，最后启动crontab计划任务`/etc/init.d/cron start`  

3. ignore\_list  
启用了透明代理后默认所有流量都代理到SS服务器，这不仅会加大服务器负担，还会白白浪费流量，减慢访问国内网页的速度。这就需要我们忽略掉对国内IP的代理。<a href="https://github.com/shadowsocks/luci-app-shadowsocks/wiki/use-crontab-to-update-the-ignore.list" target="_blank">(Wiki)</a>  
1、按Wiki内容新建`update_ignore_list`脚本。  
终端配置计划任务方法：在`/etc/crontabs/root`中添加一行`30    4     *     *     0     /root/update_ignore_list>/dev/null 2>&1`。若无此文件，则新建该文件并在shell中输入`echo root > /etc/crontabs/cron.update`，最后启动crontab计划任务`/etc/init.d/cron start`  
2、手动更新一次ignore_list.  
3、进入SS的控制界面，点击"访问控制"。在 “外网区域” 的 “被忽略IP列表” 中选择 “自定义” 然后填入`/etc/ignore.list`  
4、保存并应用，享受无墙的感觉。
