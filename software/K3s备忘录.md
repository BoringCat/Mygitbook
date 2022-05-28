# K3s备忘录 <!-- omit in toc -->

- [与PVE集成](#与pve集成)
  - [Containerd + ZFS](#containerd--zfs)
  - [Ceph-csi](#ceph-csi)

## 与PVE集成
### Containerd + ZFS
1. 在要安装的机器上创建 zfs 路径
   ```sh
   zfs create -o mountpoint=/var/lib/rancher/k3s/agent/containerd/io.containerd.snapshotter.v1.zfs ${你的池}/${你的路径}
   ```
2. 根据 [k3s 安装文档][2] 以及 [配置参考][3]，在安装时配置 `--snapshotter=zfs` 即可  
   PS: 我也不知道为什么文档里面 Agent 和 Server 的 Agent 选项不一致，不是说
   > K3s agent 选项是可以作为 server 选项的，因为 server 内部嵌入了 agent 进程。

### Ceph-csi
#### 1. 创建 rbd 池 <!-- omit in toc -->
```sh
ceph osd pool create k3s
```
#### 2. 创建账号 <!-- omit in toc -->
允许对 k3s 池进行读写操作

```
root@pve0:~# ceph auth get-or-create client.k3s mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=k3s'
[client.k3s]
    key = 5L2g5Lul5Li65L2g5piv6LCB5ZWK77yf5ruaIQo=
```
#### 3. `ceph -s` 获取集群ID <!-- omit in toc -->
```sh
root@pve0:~# ceph -s
  cluster:
    id:     12345678-qwer-asdf-zxcv-9876543210jk
    health: HEALTH_OK
```
#### 4. 从 [ceph-csi/deploy/rbd/kubernetes at v3.6.1 · ceph/ceph-csi (github.com)][1] 下载所有文件 <!-- omit in toc -->
#### 5. 在 k3s 上创建命名空间 `ceph-csi` <!-- omit in toc -->
```sh
kubectl create namespace ceph-csi
```
#### 6. 修改配置文件   <!-- omit in toc -->
##### 1. `csi-config-map.yaml`   <!-- omit in toc -->
| Key       | 所需数据          |
| :-------- | :---------------- |
| clusterID | 集群ID            |
| monitors  | 集群所有mon的地址 |
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ceph-csi-config
  namespace: ceph-csi
data:
  config.json: |-
    [
      {
        "clusterID": "12345678-qwer-asdf-zxcv-9876543210jk",
        "monitors": [
          "mon.1:6789",
          "mon.2:6789",
          "mon.3:6789"
        ]
      }
    ]
```
##### 2. `secret.yaml`   <!-- omit in toc -->
| Key     | 所需数据     |
| :------ | :----------- |
| userID  | 创建的用户名 |
| userKey | 用户的Key    |
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: csi-rbd-secret
  namespace: ceph-csi
stringData:
  userID: k3s
  userKey: 5L2g5Lul5Li65L2g5piv6LCB5ZWK77yf5ruaIQo=
```
##### 3. `storageclass.yaml`   <!-- omit in toc -->
| Key                                                     | 所需数据                   |
| :------------------------------------------------------ | :------------------------- |
| clusterID                                               | 集群ID                     |
| pool                                                    | 集群存储池                 |
| `csi.storage.k8s.io/controller-expand-secret-namespace` | secret.yaml 所在的命名空间 |
| `csi.storage.k8s.io/node-stage-secret-namespace`        | secret.yaml 所在的命名空间 |
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-rbd-sc
provisioner: rbd.csi.ceph.com
parameters:
  clusterID: 12345678-qwer-asdf-zxcv-9876543210jk
  pool: k3s
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
  csi.storage.k8s.io/provisioner-secret-namespace: ceph-csi
  csi.storage.k8s.io/controller-expand-secret-name: csi-rbd-secret
  csi.storage.k8s.io/controller-expand-secret-namespace: ceph-csi
  csi.storage.k8s.io/node-stage-secret-name: csi-rbd-secret
  csi.storage.k8s.io/node-stage-secret-namespace: ceph-csi
  csi.storage.k8s.io/fstype: xfs
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
  - discard
```
##### 4. `csi-rbdplugin-provisioner.yaml`   <!-- omit in toc -->
这里移除 kms 的配置，有需要的可以另行配置  
1. 删除 POD `csi-rbdplugin` 的这些 `env`
   ```yaml
   - name: KMS_CONFIGMAP_NAME
     value: encryptionConfig
   ```
2. 删除 POD `csi-rbdplugin` 的这些 `volumeMounts`
   ```yaml
   - name: ceph-csi-encryption-kms-config
     mountPath: /etc/ceph-csi-encryption-kms-config/
   - name: ceph-config
     mountPath: /etc/ceph/
   - name: oidc-token
     mountPath: /run/secrets/tokens
     readOnly: true
   ```
3. 删除 POD `csi-rbdplugin-controller` 的这些 `volumeMounts`
   ```yaml
   - name: ceph-config
     mountPath: /etc/ceph/
   ```
4. 删除 Deployment 的这些 `volumes`
   ```yaml
   - name: ceph-config
     configMap:
       name: ceph-config
   - name: ceph-csi-encryption-kms-config
     configMap:
       name: ceph-csi-encryption-kms-config
   - name: oidc-token
     projected:
       sources:
         - serviceAccountToken:
             path: oidc-token
             expirationSeconds: 3600
             audience: ceph-csi-kms
   ```
##### 5. `csi-rbdplugin.yaml`   <!-- omit in toc -->
这里移除 kms 的配置，有需要的可以另行配置  
1. 删除 POD `csi-rbdplugin` 的这些 `env`
   ```yaml
   - name: KMS_CONFIGMAP_NAME
     value: encryptionConfig
   ```
2. 删除 POD `csi-rbdplugin` 的这些 `volumeMounts`
   ```yaml
   - name: ceph-csi-encryption-kms-config
     mountPath: /etc/ceph-csi-encryption-kms-config/
   - name: ceph-config
     mountPath: /etc/ceph/
   - name: oidc-token
     mountPath: /run/secrets/tokens
     readOnly: true
   ```
3. 删除 DaemonSet 的这些 `volumes`
   ```yaml
   - name: ceph-config
     configMap:
       name: ceph-config
   - name: ceph-csi-encryption-kms-config
     configMap:
       name: ceph-csi-encryption-kms-config
   - name: oidc-token
     projected:
       sources:
         - serviceAccountToken:
             path: oidc-token
             expirationSeconds: 3600
             audience: ceph-csi-kms
   ```
#### 7. 导入配置文件 <!-- omit in toc -->
```sh
kubectl apply -f ./
```
#### 8. 确认所有pod拉起 <!-- omit in toc -->
```sh
root@pve0:~/ceph-rbd# kubectl get -n ceph-csi pods
NAME                                         READY   STATUS       RESTARTS   AGE
csi-rbdplugin-52p2k                          3/3     Running      0          15m
csi-rbdplugin-8sf4q                          3/3     Running      0          15m
csi-rbdplugin-99gv8                          3/3     Running      0          15m
csi-rbdplugin-mqdp4                          3/3     Running      0          15m
csi-rbdplugin-provisioner-788f95964d-cwtb4   7/7     Running      0          15m
csi-rbdplugin-provisioner-788f95964d-qc5rk   7/7     Running      0          15m
csi-rbdplugin-provisioner-788f95964d-xx6qd   7/7     Running      0          15m
```


[1]: https://github.com/ceph/ceph-csi/tree/v3.6.1/deploy/rbd/kubernetes
[2]: https://docs.rancher.cn/docs/k3s/quick-start/_index
[3]: https://docs.rancher.cn/docs/k3s/installation/install-options/server-config/_index#agent-%E8%BF%90%E8%A1%8C%E6%97%B6
