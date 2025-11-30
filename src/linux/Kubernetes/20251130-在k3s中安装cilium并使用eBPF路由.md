# 在k3s中安装cilium并使用eBPF路由 <!-- omit in toc -->

> **本文环境：**
> * k3s version v1.32.10+k3s1 (1c5d65ce)  
    go version go1.24.9
> * debian 13.2 (trixie)  
    6.12.57+deb13-amd64

- [安装 k3s 集群](#安装-k3s-集群)
- [安装 Cilium](#安装-cilium)
- [用](#用)


## 安装 k3s 集群

根据 [K3s 安装选项介绍][k3s/install-options]、[K3s Server 配置参考][k3s/server-config] 和 [Cilium 安装文档][install-cilium] 得来
```sh
TOKEN=`dd if=/dev/urandom bs=4M count=1 | md5sum | xargs printf "%s\n" | head -1`
ARGS=(
    --write-kubeconfig-mode=0644
    --flannel-backend=none
    --disable-network-policy
    --disable-kube-proxy
    --disable-cloud-controller
    # 下面这些组件按需禁用
    --disable=servicelb
    --disable=traefik
    --disable=metrics-server
    --disable=local-storage
)
echo $TOKEN

# 第一个节点
curl -sfL https://get.k3s.io | K3S_TOKEN=${TOKEN}\
    INSTALL_K3S_EXEC="${ARGS[@]}"\
    INSTALL_K3S_CHANNEL=v1.32\
    sh - --cluster-init

# 其他控制平面节点
curl -sfL https://get.k3s.io | K3S_TOKEN=${TOKEN}\
    INSTALL_K3S_EXEC="${ARGS[@]}"\
    INSTALL_K3S_CHANNEL=v1.32\
    sh - --server https://${第一个节点IP}:6443

# Agent节点
curl -sfL https://get.k3s.io | K3S_TOKEN=${TOKEN}\
    INSTALL_K3S_EXEC="${ARGS[@]}"\
    INSTALL_K3S_CHANNEL=v1.32\
    K3S_URL=https://${第一个节点IP}:6443\
    sh -
```

安装完成后除了第一个节点以外，其他节点都是`NotReady`，这是正常现象，毕竟现在没有网络

| NAME  | STATUS   | ROLES                     | AGE  | VERSION       |
| :---- | :------- | :------------------------ | :--- | :------------ |
| k3s-1 | Ready    | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |
| k3s-2 | NotReady | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |
| k3s-3 | NotReady | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |

## 安装 Cilium

1. 安装 Helm  
   参考 [Installing Helm][install-helm] 安装
2. 配置仓库
   ```sh
   helm repo add cilium https://helm.cilium.io/
   ```
3. 安装 Cilium
   ```sh
   helm install cilium cilium/cilium --version 1.18\
       --namespace kube-system\
       --set k8sServiceHost=${第一个节点IP}\
       --set k8sServicePort=6443\
       --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16"\
       --set bpf.datapathMode=netkit\
       --set bpf.masquerade=true\
       --set bpf.distributedLRU.enabled=true\
       --set bpf.mapDynamicSizeRatio=0.08\
       --set ipv4.enabled=true\
       --set enableIPv4BIGTCP=true\
       --set kubeProxyReplacement=true\
       --set bpfClockProbe=true
   ```

   每一项的作用

   | 项目                                       | 作用                                                              |
   | :----------------------------------------- | :---------------------------------------------------------------- |
   | `k8sServiceHost`                           | 指定 K8s API 服务地址                                             |
   | `k8sServicePort`                           | 指定 K8s API 服务端口                                             |
   | `ipam.operator.clusterPoolIPv4PodCIDRList` | 设定集群的Pod地址池与K3s配置一致                                  |
   | `bpf.datapathMode=netkit`                  | 使用 [netkit](https://www.netkit.org/) 网卡<br/>需要Kernel >= 6.8 |
   | `bpf.masquerade`                           | 使用 eBPF 来做 NAT                                                |
   | `bpf.distributedLRU.enabled`               | 启用分布式 LRU 后端内存                                           |
   | `bpf.mapDynamicSizeRatio`                  | 设定动态映射内存百分比                                            |
   | `ipv4.enabled`                             | 启用IPv4                                                          |
   | `enableIPv4BIGTCP`                         | 开启IPv4高吞吐能力                                                |
   | `kubeProxyReplacement`                     | 替代 kube-proxy                                                   |
   | `bpfClockProbe`                            | 启用 eBPF 时钟源探测                                              |
4. 等待完成

## 用
现在所有节点都是`Ready`了

| NAME  | STATUS | ROLES                     | AGE  | VERSION       |
| :---- | :----- | :------------------------ | :--- | :------------ |
| k3s-1 | Ready  | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |
| k3s-2 | Ready  | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |
| k3s-3 | Ready  | control-plane,etcd,master | 1h   | v1.32.10+k3s1 |


[k3s/install-options]: https://docs.rancher.cn/docs/k3s/installation/install-options/
[k3s/server-config]: https://docs.rancher.cn/docs/k3s/installation/server-config/
[install-cilium]: https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-cilium
[install-helm]: https://helm.sh/zh/docs/intro/install/