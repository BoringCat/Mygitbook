# Prometheus备忘录 <!-- omit in toc -->
**本文环境：**
* Prometheus：v2.37.2-lts

---

- [配置文件](#配置文件)
- [RemoteWrite](#remotewrite)
  - [queue\_config](#queue_config)
- [RemoteRead](#remoteread)
- [TLS](#tls)
- [需要重载的情况](#需要重载的情况)


## 配置文件
相对路径: 配置文件所在路径

## RemoteWrite
### queue_config
远程写内存三兄弟
- `max_samples_per_send`: 每个批次最多发送多少指标  
- `capacity`: 缓存指标数量  
- `max_shards`: 最多同时发送多少个请求  

最大使用内存计算公式: `512 * (max_samples_per_send + capacity) * max_shards`  
`512`: 为预估值，与序列的标签数量和程度有关，[官方文档][Remote write tuning]的预估在164左右

其他
- `batch_send_deadline`: 缓存的指标数达到 `max_samples_per_send` 前最多等待多久
- `min_backoff`: 当发送失败时（5xx 或 429(需要开启)） 重试前等待多长时间
- `max_backoff`: 当发送失败时重试前最长等待多长时间
- `retry_on_http_429`: 当返回429时重试  
  适用情况：多个client同时写一个 租户/系统。这种情况下会经常出现两个发送批次大于写入速率限制的情况，实际上平均写入速率并未超过限制。

## RemoteRead
- `filter_external_labels`: 是否使用 `global.external_labels` 中的label作为默认的查询条件  
  如果你没有配，建议调为 false
- `read_recent`: 是否从远程读取最近的数据

## TLS
- `cert_file`: 客户端证书验证用的证书
- `key_file`: 客户端证书验证用的私钥


## 需要重载的情况
- 主配置文件变更
- `rule_files`匹配的文件变革

[Remote write tuning]: https://prometheus.io/docs/practices/remote_write/
