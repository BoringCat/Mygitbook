## OpenWrt/LEDE路由器上v2ray + 透明代理 <!-- omit in toc -->

**以OpenWrt X86 18.06.1为例**

- [安装](#安装)
- [配置（无LUCI）](#配置无luci)
- [透明代理](#透明代理)

### 安装
0. [**官方安装文档**](https://www.v2ray.com/chapter_00/install.html)

1. 下载对于版本的压缩包 [v2ray-core/releases](https://github.com/v2ray/v2ray-core/releases)  

2. 解压，复制各文件到指定位置  

|   文件名    |          目录          |      备注      |
| :---------: | :--------------------: | :------------: |
|    v2ray    |     /usr/bin/v2ray     | 添加可执行权限 |
|    v2ctl    |     /usr/bin/v2ctl     | 添加可执行权限 |
|  geoip.dat  |  /etc/v2ray/geoip.dat  |
| geosite.dat | /etc/v2ray/geosite.dat |
|   *.json    |      /etc/v2ray/       |

   并且链接以下文件

|         源文件         |      目的文件      |
| :--------------------: | :----------------: |
|  /etc/v2ray/geoip.dat  | /usr/bin/geoip.dat |
| /etc/v2ray/geosite.dat | /usr/bin/geoip.dat |

3. 或者...一键脚本？_~~(我没有在路由器上尝试过)~~_
   ``` sh
   bash <(curl -L -s https://install.direct/go.sh)
   ```

### 配置（无LUCI）
0. [**官方配置文件文档**](https://www.v2ray.com/chapter_02/)  

1. 配置文件全部名称
   ``` json
   {
   "log": {},
   "api": {},
   "dns": {},
   "stats": {},
   "routing": {},
   "policy": {},
   "reverse": {},
   "inbounds": [],
   "outbounds": [],
   "transport": {}
   }
   ```
   详细配置建议对照官方文档编写，或者用Win、Linux、MacOS上面的图形化客户端导出（毕竟太多了）

2. 启动
   ``` sh
   v2ray --config /etc/v2ray/config.json
   ```
   启动到无输出后台：
   ``` sh
   nohub v2ray --config /etc/v2ray/config.json &
   ```

### 透明代理
0. [**官方配置文件文档**]([https://www.v2ray.com/chapter_02/](https://toutyrater.github.io/app/transparent_proxy.html))  

1. 设置inbounds
   ```json
   {
       "port": 12345,
       "protocol": "dokodemo-door",
       "settings": {
            "network": "tcp,udp",
            "followRedirect": true
       },
       "sniffing": {
           "enabled": true,
           "destOverride": ["http", "tls"]
       }
   }
   ```
|配置项|备注|
|:-:|:-:|
|port|透明代理的端口，可以选个你喜欢的，只要路由器内部不冲突|
|protocol|必须是 `dokodemo-door` ([任意门](https://www.v2ray.com/chapter_02/protocols/dokodemo.html))
|settings.followRedirect|这里要为 true 才能接受来自 iptables 的流量|

2. 设置全部outbounds(blackhole除外)
   ``` json
   "streamSettings": {
       ...
       "sockopt": {
            "mark": 255
        }
   }
   ```

|配置项|备注|
|:-:|:-:|
|streamSettings.sockopt.mark| streamSettings.sockopt.mark 是 SO_MARK，用于 iptables 识别，每个 outbound 都要配置；255可以改成其他数值，但要与下面的 iptables 规则对应；如果有多个 outbound，最好将所有 outbound 的 SO_MARK 都设置成一样的数值 |

3. 设置iptables规则  
   _想要简单，就在v2ray配置文件里面写路由。需要快，就手撸iptables_

   1. v2ray自带路由  
      [**官方文档**](https://www.v2ray.com/chapter_02/03_routing.html)  
      路由配置名称：
      ``` json
      "rother": {
          "domainStrategy": "AsIs",
          "rules": [],
          "balancers": []
      }
      ```

|配置项|备注|
|:-:|:-:|
|domainStrategy|域名解析策略，根据不同的设置使用不同的策略。|
|rules|对应一个数组，数组中每个元素是一个规则。当没有匹配到任何规则时，流量默认由主出站(第一个outbound)协议发出。
      
      ``` json
      "rules": [
          {
              "type": "field",
              "domain": [
                  "baidu.com",
                  "qq.com",
                  "geosite:cn"
              ],
              "ip": [
                  "0.0.0.0/8",
                  "10.0.0.0/8",
                  "fc00::/7",
                  "fe80::/10",
                  "geoip:cn"
              ],
              "port": "0-100",
              "network": "tcp",
              "source": [
                  "10.0.0.1"
              ],
              "user": [
                  "love@v2ray.com"
              ],
              "inboundTag": [
                  "tag-vmess"
              ],
              "protocol":["http", "tls", "bittorrent"],
              "outboundTag": "direct",
              "balancerTag": "balancer"
          }
      ]
      ```

|配置项|备注|
|:-:|:-:|
|rules|当多个属性同时指定时，这些属性需要同时满足，才可以使当前规则生效。|
|type|目前只支持"field"这一个选项。|
|domain|域名数组<br>纯字符串: 当此字符串匹配目标域名中任意部分，该规则生效。比如"sina.com"可以匹配"sina.com"、"sina.com.cn"和"www.sina.com"<br>正则表达式: 由"regexp:"开始，余下部分是一个正则表达式。<br>子域名 (推荐): 由"domain:"开始，余下部分是一个域名。<br>完整匹配: 由"full:"开始，余下部分是一个域名。<br>特殊值"geosite:cn": 内置了一些常见的国内网站域名。<br>特殊值"geosite:speedtest" (V2Ray 3.32+): Speedtest.net 的所有公用服务器列表。<br>从文件中加载域名: 形如"ext:file:tag"
|ip|IP地址数组<br>IP: 形如"127.0.0.1"。<br>CIDR: 形如"10.0.0.0/8".<br>GeoIP: 形如"geoip:cn"<br>从文件中加载 IP: 形如"ext:file:tag"
|port|单端口a或端口范围"a-b"|
|source|原地址数组<br>可以为IP或CIDR
|user|用户，inbound规定的|
|protocol|协议数组|

      默认排除大陆地址与域名的规则：
      ``` json
      "rules":[
          {
              "type": "field",
              "port": null,
              "outboundTag": "direct",
              "ip": [
                  "geoip:cn"
              ],
              "domain": null
          },
          {
              "type": "field",
              "port": null,
              "outboundTag": "direct",
              "ip": null,
              "domain": [
                  "geosite:cn"
              ]
          }
      ],
      ```
      默认排除私有地址的规则：
      ``` json
      "rules":[
          {
              "type": "field",
              "port": null,
              "outboundTag": "direct",
              "ip": [
                  "geoip:private"
              ],
              "domain": null
          }
      ],
      ```

   2. TCP透明代理
      ``` sh
      # 新建一个名为 V2RAY 的链
      iptables -t nat -N V2RAY
      # 根据 RFC5735 过滤私有地址、多播地址与保留地址
      iptables -t nat -A V2RAY -d 0.0.0.0/8 -j RETURN
      iptables -t nat -A V2RAY -d 10.0.0.0/8 -j RETURN
      iptables -t nat -A V2RAY -d 127.0.0.0/8 -j RETURN
      iptables -t nat -A V2RAY -d 169.254.0.0/16 -j RETURN
      iptables -t nat -A V2RAY -d 172.16.0.0/12 -j RETURN
      iptables -t nat -A V2RAY -d 192.168.0.0/16 -j RETURN
      iptables -t nat -A V2RAY -d 224.0.0.0/4 -j RETURN
      iptables -t nat -A V2RAY -d 240.0.0.0/4 -j RETURN
      # 直连 SO_MARK 为 0xff 的流量(0xff 是 16 进制数，数值上等同与上面配置的 255)，此规则目的是避免代理本机(网关)流量出现回环问题
      iptables -t nat -A V2RAY -p tcp -j RETURN -m mark --mark 0xff
      # 其余流量转发到 12345 端口（即 V2Ray）
      iptables -t nat -A V2RAY -p tcp -j REDIRECT --to-ports 12345
      # 对局域网其他设备进行透明代理
      iptables -t nat -A PREROUTING -p tcp -j V2RAY
      # 对本机进行透明代理
      iptables -t nat -A OUTPUT -p tcp -j V2RAY
      ```
      备注：`iptables -t nat -A PREROUTING -p tcp -j V2RAY` 中可加上 `-m multiport --dports (想代理的端口)` 来限制代理的端口
   3. UDP透明代理(我没使用)
      ``` sh
      ip rule add fwmark 1 table 100
      ip route add local 0.0.0.0/0 dev lo table 100
      iptables -t mangle -N V2RAY_MASK
      # 根据 RFC5735 过滤私有地址、多播地址与保留地址
      iptables -t mangle -A V2RAY -d 0.0.0.0/8 -j RETURN
      iptables -t mangle -A V2RAY -d 10.0.0.0/8 -j RETURN
      iptables -t mangle -A V2RAY -d 127.0.0.0/8 -j RETURN
      iptables -t mangle -A V2RAY -d 169.254.0.0/16 -j RETURN
      iptables -t mangle -A V2RAY -d 172.16.0.0/12 -j RETURN
      iptables -t mangle -A V2RAY -d 192.168.0.0/16 -j RETURN
      iptables -t mangle -A V2RAY -d 224.0.0.0/4 -j RETURN
      iptables -t mangle -A V2RAY -d 240.0.0.0/4 -j RETURN
      iptables -t mangle -A V2RAY_MASK -p udp -j TPROXY --on-port 12345 --tproxy-mark 1
      iptables -t mangle -A PREROUTING -p udp -j V2RAY_MASK
      ```