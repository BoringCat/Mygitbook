# OpenKruiseGame配置 <!-- omit in toc -->

> **本文环境：**
> * k3s version v1.28.3-tke.8  

---

- [部署](#部署)
  - [cert-manager](#cert-manager)
  - [Kruise](#kruise)
  - [KruiseGame](#kruisegame)
  - [tke-extend-network-controller](#tke-extend-network-controller)
- [配置](#配置)


## 部署
### cert-manager
> 它被 tke-extend-network-controller 依赖，因为本文是在腾讯云上实践的  
> 如果你用不上，那也不需要装这个
1. 添加仓库  
   `helm repo add jetstack https://charts.jetstack.io`
2. 安装插件  
   ```sh
   helm install -n cert-manager --create-namespace\
     cert-manager jetstack/cert-manager\
     --version v1.16.2\
     --set crds.enabled=true\
     --set prometheus.enabled=true
   ```
3. 如果你没有安装 prometheus operator，但你又有独立部署的 prometheus 实例，并且你想监控 cert-manager
   ```sh
   kubectl patch -n cert-manager svc cert-manager\
     --type=merge\
     -p '{"metadata":{"annotations":{"prometheus.io/scrape":"true","prometheus.io/port":"9402"}}}'
   ```

### Kruise
1. 添加仓库  
   `helm repo add openkruise https://openkruise.github.io/charts/`
2. 安装插件  
   `helm install -n default kruise openkruise/kruise --version 1.7.3`

### KruiseGame
1. 添加仓库  
   `helm repo add openkruise https://openkruise.github.io/charts/`
2. 安装插件  
   `helm install -n default kruise openkruise/kruise-game --version 0.9.0`

<details>
  <summary><strong>坑</strong></summary>

你看它的 [values.yaml][kruise-game/0.9/values] 里面是不是有一个 `replicaCount: 1`  
欸那我岂不是可以加多几个副本，保证可用性？

<font color=red><strong>欸嘿，不行！</strong></font>

看[源码][kruise-game/0.9/webhook]，它有个 webhook-server-certs-dir 的命令行参数，指向 /tmp/webhook-certs/

再看 [chart 里面和 deployment 相关][kruise-game/0.9/manager]的模板，没有任何 cert 关键字捏  
> 事实上整个 chart 的文件里面一个 cert 关键字都没有

所以，它**会走到自动生成证书的逻辑**，并把生成的证书同步到 `mutatingwebhookconfigurations.admissionregistration.k8s.io/kruise-game-mutating-webhook` 里面。  
然后会发生什么事大概能猜到了，你加越多副本，API调用的成功率就越低，因为ca证书对不上

</details>

### tke-extend-network-controller
直接在 TKE 应用市场安装，这样最方便

<details>
  <summary><strong>吐槽</strong></summary>

  不是哥们，你都是专门为腾讯云写的了，为什么不在容器上绑定角色，直接从 metadata 里面获取临时密钥就好了，非要配置 secretID 和 secretKey  
  为了你这个 APIKey，我还得创建一个子账号，并且确保这个子账号存活且不会被其他人更改和使用，而且 APIKey 还是持久的，等保轮换根本搞不了  
  明明配一个角色就能完事

</details>

## 配置

[kruise-game/0.9/values]: https://github.com/openkruise/charts/blob/master/versions/kruise-game/0.9/values.yaml
[kruise-game/0.9/webhook]: https://github.com/openkruise/kruise-game/blob/ecce453d7f53b82826760356d122e83b221a6180/pkg/webhook/webhook.go#L57
[kruise-game/0.9/manager]: https://github.com/openkruise/charts/blob/master/versions/kruise-game/0.9/templates/manager.yaml