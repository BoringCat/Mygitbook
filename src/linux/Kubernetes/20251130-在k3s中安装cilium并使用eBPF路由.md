# 在k3s中安装cilium并使用eBPF路由 <!-- omit in toc -->

> **本文环境：**
> * k3s version v1.32.10+k3s1 (1c5d65ce)  
    go version go1.24.9
> * debian 13.2 (trixie)  
    6.12.57+deb13-amd64
> * Cilium  
    v1.18.4

- [安装 k3s 集群](#安装-k3s-集群)
- [安装 Cilium](#安装-cilium)
- [用](#用)


## 安装 k3s 集群

根据 [K3s 安装选项介绍][k3s/install-options]、[K3s Server 配置参考][k3s/server-config] 和 [Cilium 安装文档][install-cilium] 得来
```sh
ARGS=(
    --write-kubeconfig-mode=0644
    --flannel-backend=none
    --prefer-bundled-bin
    --disable-network-policy
    --disable-kube-proxy
    --disable-cloud-controller
    # 下面这些组件按需禁用
    --disable=servicelb
    --disable=traefik
    --disable=metrics-server
    --disable=local-storage
)
TOKEN=`dd if=/dev/urandom bs=4M count=1 | md5sum | xargs printf "%s\n" | head -1`
printf 'TOKEN=%s\n' $TOKEN

# 先下载安装脚本（对我就是一个apt包也不装）
wget https://get.k3s.io -O /tmp/getk3s.sh

# 第一个节点
env K3S_TOKEN=${TOKEN}\
    INSTALL_K3S_EXEC="${ARGS[*]}"\
    INSTALL_K3S_CHANNEL=v1.32\
    sh /tmp/getk3s.sh --cluster-init

# 其他控制平面节点
env K3S_TOKEN=${TOKEN}\
    INSTALL_K3S_EXEC="${ARGS[*]}"\
    INSTALL_K3S_CHANNEL=v1.32\
    sh /tmp/getk3s.sh --server https://${第一个节点IP}:6443

# Agent节点
env K3S_TOKEN=${TOKEN}\
    INSTALL_K3S_EXEC="${ARGS[*]}"\
    INSTALL_K3S_CHANNEL=v1.32\
    K3S_URL=https://${第一个节点IP}:6443\
    sh /tmp/getk3s.sh
```

安装完成后所有节点都是`NotReady`，这是正常现象，毕竟现在没有网络

| NAME  | STATUS   | ROLES                     | AGE  | VERSION       |
| :---- | :------- | :------------------------ | :--- | :------------ |
| k3s-1 | NotReady | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |
| k3s-2 | NotReady | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |
| k3s-3 | NotReady | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |

## 安装 Cilium

1. 安装 Helm  
   参考 [Installing Helm][install-helm] 安装
2. 配置仓库
   ```sh
   helm repo add cilium https://helm.cilium.io/
   # 获取版本
   helm search repo cilium
   ```
3. 安装 Cilium
   ```sh
   helm install cilium cilium/cilium --version 1.18.4\
     --set k8sServiceHost=${第一个节点IP}\
     --set k8sServicePort=6443\
     --set ipam.operator.clusterPoolIPv4PodCIDRList=10.42.0.0/16\
     --set bpf.datapathMode=netkit\
     --set bpf.masquerade=true\
     --set bpf.distributedLRU.enabled=true\
     --set bpf.mapDynamicSizeRatio=0.08\
     --set ipv4.enabled=true\
     --set enableIPv4BIGTCP=true\
     --set kubeProxyReplacement=true\
     --set bpfClockProbe=true\
     --set routingMode=native\
     --set autoDirectNodeRoutes=true\
     --set ipv4NativeRoutingCIDR=10.42.0.0/16\
     --set envoy.enabled=false\
     --set socketLB.enabled=true
   ```

   每一项的作用

   | 项目                                       | 值                        | 作用                                                                                             |
   | :----------------------------------------- | :------------------------ | :----------------------------------------------------------------------------------------------- |
   | `k8sServiceHost`                           | `172.21.1.1`              | 指定 K8s API 服务地址                                                                            |
   | `k8sServicePort`                           | `6443`                    | 指定 K8s API 服务端口                                                                            |
   | `ipam.operator.clusterPoolIPv4PodCIDRList` | `10.42.0.0/16`            | 设定集群的Pod地址池与K3s配置一致                                                                 |
   | `bpf.datapathMode`                         | `netkit`                  | 使用 [netkit](https://www.netkit.org/) 网卡<br/>需要Kernel >= 6.8                                |
   | `bpf.masquerade`                           | `true`                    | 使用 eBPF 来做 NAT                                                                               |
   | `bpf.distributedLRU.enabled`               | `true`                    | 启用分布式 LRU 后端内存                                                                          |
   | `bpf.mapDynamicSizeRatio`                  | `0.08`                    | 设定动态映射内存百分比                                                                           |
   | `ipv4.enabled`                             | `true`                    | 启用IPv4                                                                                         |
   | `enableIPv4BIGTCP`                         | `true`                    | 启用高吞吐模式                                                                                   |
   | `kubeProxyReplacement`                     | `true`                    | 替代 kube-proxy                                                                                  |
   | `bpfClockProbe`                            | `true`                    | 启用 eBPF 时钟源探测                                                                             |
   | `routingMode`                              | `native`                  | 使用节点原生路由模式处理流量                                                                     |
   | `ipv4NativeRoutingCIDR`                    | `10.42.0.0/16`            | 指定可以进行路由的CIDR                                                                           |
   | `autoDirectNodeRoutes`                     | `true`                    | 自动检测节点路由                                                                                 |
   | `socketLB.enabled`                         | `true`                    | 启用 socketLB 劫持入流量                                                                         |
   | `envoy.enabled`                            | `false`                   | 禁用内嵌的envoy                                                                                  |
   | `image.repository`                         | `quay.io/cilium/cilium`   | cilium的镜像（国内可以对这个地址做代理）                                                         |
   | `image.useDigest`                          | `false`                   | 不在镜像版本后面加上 digest 信息                                                                 |
   | `operator.image.repository`                | `quay.io/cilium/operator` | cilium-operator的镜像（国内可以对这个地址做代理）<br/>需要两个镜像: operator 和 operator-generic |
   | `operator.image.useDigest`                 | `false`                   | 不在镜像版本后面加上 digest 信息                                                                 |

4. 等待完成

## 用
现在所有节点都是`Ready`了

| NAME  | STATUS | ROLES                     | AGE  | VERSION       |
| :---- | :----- | :------------------------ | :--- | :------------ |
| k3s-1 | Ready  | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |
| k3s-2 | Ready  | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |
| k3s-3 | Ready  | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |

可以验证网络是否正常

执行 `kubectl run --image alpine/kubectl -it --rm --wait --restart Never test --command /bin/sh`  
然后跑
```sh
nslookup kubernetes.default.svc.cluster.local
nslookup kubernetes.default.svc.cluster.local ${其中一个coredns的IP}
kubectl api-resources
```
是能出数据的

[k3s/install-options]: https://docs.rancher.cn/docs/k3s/installation/install-options/
[k3s/server-config]: https://docs.rancher.cn/docs/k3s/installation/server-config/
[install-cilium]: https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-cilium
[install-helm]: https://helm.sh/zh/docs/intro/install/