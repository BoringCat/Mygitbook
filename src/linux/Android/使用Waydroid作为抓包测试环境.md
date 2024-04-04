# 使用Waydroid作为抓包测试环境  <!-- omit in toc -->

**本文环境：**
* 系统：`Arch Linux 6.8.2-zen2-1-zen`
* Waydroid：
  - `archlinuxcn/waydroid 1.4.2-3`
  - `archlinuxcn/waydroid-image 18.1_20240323-1`
  - `waydroid-script-git r177.1a2d3ad-1`
* Weston: `extra/weston 13.0.0-2`
---

- [配置环境](#配置环境)
- [启动环境](#启动环境)
- [配置透明代理](#配置透明代理)
  - [基于Iptable的透明代理](#基于iptable的透明代理)
  - [基于daed的透明代理](#基于daed的透明代理)

### 配置环境
- (Xorg环境) 配置Weston  
  `~/.config/weston.ini`  
  ```ini
  [core]
  idle-time=0
  
  [shell]
  locking=false
  panel-position=none
  ```
- 配置ndk  
  [参考链接](https://github.com/casualsnek/waydroid_script?tab=readme-ov-file#install-libndk-arm-translation)
  - Intel CPU
    ```sh
    sudo waydroid-extras install libndk
    ```
  - AMD CPU
    ```sh
    sudo waydroid-extras install libhoudini
    ```
- 配置证书
  1. 启动 mitmproxy
     ```sh
     mitmproxy
     ```
  2. 下载pem证书
     ```sh
     curl --proxy localhost:8080 http://mitm.it/cert/pem -o mitmproxy-ca-cert.pem
     ```
  3. 安装证书
     ```sh
     sudo waydroid-extras install mitm -c mitmproxy-ca-cert-android.pem
     ```
- 配置网络  
  ```sh
  sudo iptables -t nat -A POSTROUTING -s 192.168.240.0/24 ! -d 192.168.240.0/24 -j MASQUERADE
  sudo iptables -A FORWARD -i waydroid0 -j ACCEPT
  sudo iptables -A FORWARD -o waydroid0 -j ACCEPT
  ```

### 启动环境
- 启动Container  
  ```sh
  sudo systemctl start waydroid-container.service
  ```
- (Xorg环境) 启动Weston  
   ```sh
   weston &
   ```
- 启动session  
  ```sh
  waydroid session start
  ```
  > 如果是weston，可能需要
  > ```sh
  > env WAYLAND_DISPLAY=wayland-1 waydroid session start
  > ```

### 配置透明代理
#### 基于Iptable的透明代理
```sh
sudo iptables -t nat -A PREROUTING -i waydroid0 -p tcp -j REDIRECT --to-ports 8080
sudo iptables -t nat -A PREROUTING -i waydroid0 -p udp -j REDIRECT --to-ports 8080
```
**如果出现，`Extension REDIRECT revision 0 not supported, missing kernel module?` 则需要加载模块 xt_REDIRECT**

然后需要在 mitmweb 的启动参数里加上 `--mode transparent --showhost`

#### 基于daed的透明代理
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
   l4proto(tcp) && sip(192.168.240.0/24) -> mitmproxy
   ```
6. 配置 waydroid0 网卡为LAN接口
7. 重载
