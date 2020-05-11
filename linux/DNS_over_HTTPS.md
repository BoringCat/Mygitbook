# 基于Docker与Nginx的DOH服务器搭建
**本文环境：**
* 系统：Arch Linux 5.6.10-arch1-1
* Docker版本：19.03.8-ce, build afacb8b7f0

## 前言与说明
### 起因
电信宽带屏蔽DNS
```sh
nslookup raw.githubusercontent.com 192.168.3.1  
Server:		192.168.3.1
Address:	192.168.3.1#53

Name:	raw.githubusercontent.com
Address: 0.0.0.0
Name:	raw.githubusercontent.com
Address: ::
```
以及其他需要..........

### 系统选择
∵ 阿里云香港  
∴ VPS2Arch

## 搭建方法
**\* 本文使用Docker-Compose，纯Docker的方法也是一样的**
### 1. 配置Docker-Compose
详情请参考：[goofball222/dns-over-https#Usage](https://hub.docker.com/r/goofball222/dns-over-https#Usage)
```yaml
version: '2'
services:
  dns-over-https:
    image: goofball222/dns-over-https
    container_name: dns-over-https
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./doh-proxy/dohconf/:/opt/dns-over-https/conf/
    environment:
      - TZ=Asia/Shanghai
    labels:
      - traefik.backend=securedns
      - traefik.frontend.rule=Host:securedns.domain.name
      - traefik.port=8053
      - traefik.docker.network=proxy
      - traefik.enable=true
  proxy:
    image: nginx:alpine
    restart: unless-stopped
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/htpasswd.conf:/etc/nginx/htpasswd.conf:ro
      - ./nginx/log:/var/log/nginx      # 可选，正常情况下这里只有错误日志
    links:
      - dns-over-https:doh              # :doh 为昵称
```

### 2. 配置DOH
`./doh-proxy/dohconf/doh-server.conf`
```diff
--- a/doh-proxy/dohconf/doh-server.conf.default
+++ b/doh-proxy/dohconf/doh-server.conf
@@ -1,10 +1,10 @@
 # HTTP listen port
 listen = [
-    "127.0.0.1:8053",
-    "[::1]:8053",
+    # "127.0.0.1:8053",
+    # "[::1]:8053",
 
     ## To listen on both 0.0.0.0:8053 and [::]:8053, use the following line
-    # ":8053",
+    ":8053",
 ]
 
 # Local address and port for upstream DNS
@@ -41,10 +41,10 @@ timeout = 10
 tries = 3
 
 # Only use TCP for DNS query
-tcp_only = false
+tcp_only = true
 
 # Enable logging
-verbose = false
+verbose = true
 
 # Enable log IP from HTTPS-reverse proxy header: X-Forwarded-For or X-Real-IP
 # Note: http uri/useragent log cannot be controlled by this config
```
#### 配置解释
|配置|解释|
|:--|:--|
|listen|监听地址，Nginx要能连接上|
|tcp_only|仅允许TCP查询。没什么关系，反正扔docker里面|
|verbose|启动日志。没什么关系|
|upstream|上游DNS。默认给的挺好，就没改|

### 3. 配置Nginx
**\*大概，我只是找不到原网站了**  
`./nginx/conf.d/doh.conf`
```conf
upstream doh {
    zone doh 64k;
    server doh:8053;
    keepalive_timeout 60s;
    keepalive_requests 100;
    keepalive 10;
}

# 缓存，其实感觉没什么卵用
proxy_cache_path /var/cache/nginx/doh_cache levels=1:2 keys_zone=doh_cache:10m;

log_format  dns  '$remote_addr - $remote_user [$time_local] "$request" '
                     '[ $msec, $request_time, $upstream_response_time $pipe ] '
                     '$status $body_bytes_sent "-" "-" "$http_x_forwarded_for" '
                     '$upstream_http_x_dns_question $upstream_http_x_dns_type '
                     '$upstream_http_x_dns_result '
                     '$upstream_http_x_dns_ttl $upstream_http_x_dns_answers '
                     '$upstream_cache_status';

server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  <你喜欢>;
    charset utf-8;

    # enable ssl
    ssl_protocols       TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    # config ssl certificate
    ssl_certificate           /path/to/file.cert
    ssl_certificate_key       /path/to/file.key

    location /dns-query {
        access_log  /var/log/nginx/doh-access.log dns;

        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_cache_methods GET POST;
        proxy_cache doh_cache;
        proxy_cache_key $scheme$proxy_host$uri$is_args$args$request_body;
        proxy_pass http://doh;
    }

}
```

## 使用方法
下文中 DNS over https client 缩写为 (DOHC)
### 1. 配置Docker-Compose
**\* 对我还是用Docker-Compose**
```yaml
  dohc:
    image: goofball222/dns-over-https
    container_name: dns-over-https-client
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./dohconf/:/opt/dns-over-https/conf/
    ports: 
      # 根据DOHC配置中的端口进行配置
    environment:
      - TZ=Asia/Shanghai
    labels:
      - traefik.backend=securedns
      - traefik.frontend.rule=Host:securedns.domain.name
      - traefik.port=8053
      - traefik.docker.network=proxy
      - traefik.enable=true
    command: ["doh-client"]
```

### 2. 配置DOHC
```diff
--- a/doh-client.conf.default
+++ b/doh-client.conf
@@ -1,12 +1,12 @@
 # DNS listen port
 listen = [
-    "127.0.0.1:53",
-    "127.0.0.1:5380",
-    "[::1]:53",
-    "[::1]:5380",
+    # "127.0.0.1:53",
+    # "127.0.0.1:5380",
+    # "[::1]:53",
+    # "[::1]:5380",
 
     ## To listen on both 0.0.0.0:53 and [::]:53, use the following line
-    # ":53",
+    "0.0.0.0:5454",
 ]
 
 # HTTP path for upstream resolver
@@ -14,7 +14,7 @@ listen = [
 [upstream]
 
 # available selector: random or weighted_round_robin or lvs_weighted_round_robin
-upstream_selector = "random"
+upstream_selector = "weighted_round_robin"
 
 # weight should in (0, 100], if upstream_selector is random, weight will be ignored
 
@@ -23,11 +23,19 @@ upstream_selector = "random"
 #    url = "https://dns.google/dns-query"
 #    weight = 50

 ## CloudFlare's resolver, bad ECS, good DNSSEC
 ## ECS is disabled for privacy by design: https://developers.cloudflare.com/1.1.1.1/nitty-gritty-details/#edns-client-subnet
-[[upstream.upstream_ietf]]
-    url = "https://cloudflare-dns.com/dns-query"
-    weight = 50
+# [[upstream.upstream_ietf]]
+#     url = "https://cloudflare-dns.com/dns-query"
+#     weight = 50
 
 ## CloudFlare's resolver, bad ECS, good DNSSEC
 ## ECS is disabled for privacy by design: https://developers.cloudflare.com/1.1.1.1/nitty-gritty-details/#edns-client-subnet
@@ -63,10 +71,12 @@ upstream_selector = "random"
 # If you want to preload IP addresses in /etc/hosts instead of using a
 # bootstrap server, please make this list empty.
 bootstrap = [
+    "192.168.3.1:53",
+    "119.29.29.29:53",
 
     # Google's resolver, bad ECS, good DNSSEC
-    "8.8.8.8:53",
-    "8.8.4.4:53",
+    # "8.8.8.8:53",
+    # "8.8.4.4:53",
 
     # CloudFlare's resolver, bad ECS, good DNSSEC
     #"1.1.1.1:53",
@@ -131,4 +141,4 @@ no_ipv6 = false
 no_user_agent = false
 
 # Enable logging
-verbose = false
+verbose = true
```
#### 配置解释
|配置|解释|
|:--|:--|
|listen|本地dns请求的地址与端口，若不是特殊环境，可以设置为53|
|upstream_selector|多个地址时的选择方式|
|[[upstream.upstream_ietf]]|DOH服务器地址与权重|
|bootstrap|解析DOH服务器的DNS|

### 3. 使用
如果DOHC配置设定 `listen` 中存在 53 端口，可以在计算机设置中使用（但不建议）

**建议的配置：**  
1. 设定 `listen` 使用本地回环地址与大于 1024 的非 53 端口  
2. 在 dnsmasq 中按需使用