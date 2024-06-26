# 使用xDroid作为抓包测试环境  <!-- omit in toc -->

**本文环境：**
* 系统：`Arch Linux 6.2.11-arch1-1`
* Docker版本：`23.0.3-ce, build 3e7cbfdee1`
* xDroid版本：`aur/xdroid-bin 11.0.20-1 (+5 0.36)`

---

- [安装 mitmproxy](#安装-mitmproxy)
- [进行抓包](#进行抓包)
  - [启动 mitmproxy](#启动-mitmproxy)
  - [配置代理](#配置代理)
    - [配置HTTP代理](#配置http代理)
    - [配置透明代理](#配置透明代理)
    - [配置基于daed的透明代理](#配置基于daed的透明代理)
  - [配置证书](#配置证书)
- [模拟故障](#模拟故障)
  - [模拟 DNS 故障](#模拟-dns-故障)
    - [配置 DNS 服务器](#配置-dns-服务器)
    - [配置 xDroid 的 DNS](#配置-xdroid-的-dns)
  - [模拟网络故障](#模拟网络故障)
    - [编写 mitmproxy 脚本](#编写-mitmproxy-脚本)
    - [启用 mitmproxy 脚本](#启用-mitmproxy-脚本)


## 安装 mitmproxy
**<font color=lightgreen>推荐使用 virtualenv</font>**
```sh
pip install mitmproxy
```

## 进行抓包
### 启动 mitmproxy
**<font color=lightgreen>推荐使用 mitmweb</font>** 比较好看，也比较好操作
```sh
mitmweb --no-web-open-browser
```
如果你想在其他机器上看结果
```sh
mitmweb --web-host 0.0.0.0
```
### 配置代理
#### 配置HTTP代理
* 正常情况下地址都是 192.168.252.1，可以用 `ip a sh xdroid-0` 看
  ```sh
  adb shell settings put global http_proxy 192.168.252.1:8080
  ```
* 删除
  ```sh
  adb shell settings delete global http_proxy
  ```

#### 配置透明代理
根据[官方文档](https://docs.mitmproxy.org/stable/howto-transparent/#3-create-an-iptables-ruleset-that-redirects-the-desired-traffic-to-mitmproxy)修改
```sh
sudo iptables -t nat -A PREROUTING -i xdroid-0 -p tcp -j REDIRECT --to-port 8080
sudo iptables -t nat -A PREROUTING -i xdroid-0 -p udp -j REDIRECT --to-port 8080
```
**如果出现，`Extension REDIRECT revision 0 not supported, missing kernel module?` 则需要加载模块 xt_REDIRECT**

然后需要在 mitmweb 的启动参数里加上 `--mode transparent --showhost`

#### 配置基于daed的透明代理
<font color=red>如果你不知道这是什么，那就跳过</font>

<details>
<summary>注意事项</summary>
如果你的daed配置了https的探测目标，则本机需要安装mitmproxy的证书，否则daed可能认为这个节点不可用，连接就hand住了
</details>

1. mitmproxy 需要以 `-m socks5` 的模式启动
2. 添加指向 mitmproxy 的节点
3. 添加 mitmproxy 群组
4. 将节点加入群组
5. 配置路由
   ```
   l4proto(tcp) && sip(192.168.250.0/24, 192.168.251.0/24, 192.168.252.0/24) -> mitmproxy
   ```
6. 配置 xdroid-xxxxxxxxx 网卡为LAN接口
7. 重载

### 配置证书
当你没有配置证书时，mitmweb上是不会展示任何https请求的，因为它不会使用TUNNEL的方式去代理，同时终端上会疯狂打印以下日志
```log
Client TLS handshake failed. The client does not trust the proxy's certificate for foo.doo.com (tlsv1 alert unknown ca)
```

1. 打开终端
2. 启动 mitmproxy
3. 使用 curl 或 wget 下载证书
   - `curl --proxy localhost:8080 http://mitm.it/cert/cer -o mitmproxy-ca-cert.cer`
   - `env http_proxy=localhost:8080 wget http://mitm.it/cert/cer -O mitmproxy-ca-cert.cer`
4. 获取证书的哈希值 `openssl x509 -in mitmproxy-ca-cert.cer -noout -subject_hash_old`
5. 重命名证书为 `哈希值.0`
6. 向系统空间添加证书
   ```sh
   for overlayDir in `find ~/.zhuoyi/ -mindepth 2 -maxdepth 2 -name overlayfs -type d`
   do
     sudo mkdir -p "${overlayDir}/system/etc/security/cacerts/"
     sudo cp ${哈希值}.0 "${overlayDir}/system/etc/security/cacerts/"
     sudo chown root:root "${overlayDir}/system/etc/security/cacerts/${哈希值}.0"
   done
   ```
7. 向用户空间添加证书
   ```sh
   for miscDir in `find ~/.zhuoyi/ -mindepth 3 -maxdepth 3 -name misc -type d`
   do
     sudo mkdir -p "${commonDir}/user/0/cacerts-added/"
     sudo cp ${哈希值}.0 "${commonDir}/user/0/cacerts-added/"
     sudo chown root:root "${miscDir}/user/0/cacerts-added/${哈希值}.0"
   done
   ```
8. 验证证书存在于信任的凭据  
   设置 => 安全 => 信任的凭据
   ![Mitmproxy-Android-Cacert](../../assets/linux/Android/Mitmproxy-Android-Cacert.png)

## 模拟故障

### 模拟 DNS 故障

#### 配置 DNS 服务器

* 解析超时
  ```ini
  .:53 {
    acl foo.doo.com foo2.doo.com {
      drop
    }
    forward . /etc/resolv.conf
  }
  ```
* 解析失败
  ```ini
  .:53 {
    acl foo.doo.com foo2.doo.com {
      block
    }
    forward . /etc/resolv.conf
  }
  ```
* 返回无记录
  ```ini
  .:53 {
    template IN ANY foo.doo.com foo2.doo.com {
      rcode NXDOMAIN
    }
    forward . /etc/resolv.conf
  }
  ```

```sh
docker run --name=xdroid-dns -v /path/to/Corefile:/etc/coredns/Corefile coredns/coredns
docker inspect xdroid-dns | jq '.[].NetworkSettings.Networks | .[].IPAddress' -r 
```

#### 配置 xDroid 的 DNS
1. 查看并备份现有DNS配置
   ```sh
   adb shell 'getprop | grep dns'
    [net.dns1]:  [192.168.3.1]
    [net.dns2]:  [223.6.6.6]
    [net.eth0.dns1]:  [10.0.2.3]
   ```
2. 配置dns
   ```sh
   adb shell setprop net.dns1 172.17.0.2
   adb shell setprop net.dns2 172.17.0.2
   adb shell setprop net.eth0.dns1 172.17.0.2
   ```

### 模拟网络故障
#### 编写 mitmproxy 脚本
* 网络超时
  ```python
  import asyncio
  from mitmproxy import ctx
  from mitmproxy.proxy import server_hooks
  
  class BlockConnection():
      filter = []

      async def server_connect(self, data: server_hooks.ServerConnectionHookData):
          host = data.server.address[0]
          if data.server.sni:
              host = data.server.sni
          ctx.log.debug("获取到主机: %s" % host)
          if (host in self.filter):
              ctx.log.info("暂停连接到 %s 1145秒" % host)
              await asyncio.sleep(1145)
              ctx.log.info("将结束到 %s 的请求" % host)
              data.server.error = "Timeout!"
  
  addons = [BlockConnection()]
  ```
* HTTP Send超时
  ```python
  from mitmproxy import (http, ctx)
  
  class BlockHttpRequest():
      filter = []

    async def request(self, flow: http.HTTPFlow) -> None:
        if (flow.request.host in self.filter):
            ctx.log.info("暂停请求 %s" % flow.request)
            flow.intercept()
            await flow.wait_for_resume()
            ctx.log.info("将结束到 %s 的请求" % flow.request)
            flow.kill()

  addons = [BlockHttpRequest()]
  ```
* HTTP Read超时
  ```python
  from mitmproxy import (http, ctx)
  
  class BlockHttpResponse():
      filter = []

    async def response(self, flow: http.HTTPFlow) -> None:
        if (flow.request.host in self.filter):
            ctx.log.info("暂停接收 %s" % flow.request)
            flow.intercept()
            await flow.wait_for_resume()
            ctx.log.info("将结束到 %s 的请求" % flow.request)
            flow.kill()

  addons = [BlockHttpResponse()]
  ```

#### 启用 mitmproxy 脚本
```sh
mitmweb --no-web-open-browser -s /path/to/script1.py -s /path/to/script2.py
```