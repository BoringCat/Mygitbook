# Mimir备忘录 <!-- omit in toc -->
**本文环境：**
* Grafana Mimir：v2.9.1
* grafana/mimir-distributed Chart: 5.0.0

---

- [Helm Chart](#helm-chart)
  - [增加指控自发现](#增加指控自发现)
  - [增加默认时区](#增加默认时区)
  - [配置S3存储桶AK/SK](#配置s3存储桶aksk)
  - [优化存储配置](#优化存储配置)
  - [禁用匿名信息采集](#禁用匿名信息采集)
  - [多可用区配置](#多可用区配置)
  - [挂载共享存储](#挂载共享存储)
  - [禁用无用组件](#禁用无用组件)
  - [禁用nginx后使用自带nginx-ingress](#禁用nginx后使用自带nginx-ingress)
- [Mimir](#mimir)
  - [ring集体配置](#ring集体配置)
  - [limits](#limits)
  - [HA去重](#ha去重)
  - [Grpc压缩](#grpc压缩)
  - [缓存](#缓存)
  - [杂项](#杂项)

## Helm Chart
### 增加指控自发现
```yaml
global:
  podAnnotations:
    prometheus.io/path: /metrics
    prometheus.io/port: "8080"
    prometheus.io/scrape: "true"
```

### 增加默认时区
```yaml
global:
  extraEnv:
  - name: TZ
    value: Asia/Shanghai
```

### 配置S3存储桶AK/SK
```yaml
global:
  extraEnvFrom:
    - secretRef:
        name: mimir-storage-key
  s3:
    endpoint: xxxxxxxxxxxxxxxxx
    region: xxxxxxxxxxxxxx
    bucket_name: mimir
    access_key_id: '${MIMIR_S3_ACCESS_KEY}'
    secret_access_key: '${MIMIR_S3_SECRET_KEY}'
```

### 优化存储配置
1. 增加 prefix 配置
   ```yaml
   global:
     storage:
       alertmanager:
         prefix: alertmanager
       blocks:
         prefix: tsdb
       ruler:
         prefix: ruler
   ```
2. 配置 `mimir.config` 将 `alertmanager_storage` `blocks_storage` `ruler_storage` 的 s3 配置改为以下配置  
   ```yaml
         backend: s3
         s3:
           {{ toYaml .Values.global.s3 | nindent 4 }}
         storage_prefix: {{ .Values.global.storage.alertmanager.prefix }}
   ```

### 禁用匿名信息采集
```yaml
mimir:
  config: |
    usage_stats:
      enabled: false
```

### 多可用区配置
- StatefulSet 按可用区区分配置  
  ```yaml
  alertmanager:
    topologySpreadConstraints: null
    zoneAwareReplication: &zoneAwareReplication
      enabled: true
      maxUnavailable: 1
      zones:
        - name: 
          nodeSelector:
            key: value
  ingester:
    topologySpreadConstraints: null
    zoneAwareReplication: *zoneAwareReplication
  store_gateway:
    topologySpreadConstraints: null
    zoneAwareReplication: *zoneAwareReplication
  ```
- Deployment - 自动可用区均衡负载
  ```yaml
  distributor:
    topologySpreadConstraints: &topologySpreadConstraints
      maxSkew: 1
      topologyKey: eks.tke.cloud.tencent.com/zone-name
      whenUnsatisfiable: DoNotSchedule
  ruler:
    topologySpreadConstraints: *topologySpreadConstraints
  querier:
    topologySpreadConstraints: *topologySpreadConstraints
  query_frontend:
    topologySpreadConstraints: *topologySpreadConstraints
  ```

### 挂载共享存储
```yaml
alertmanager:
  persistentVolume: &disabled
    enabled: no
  env:
  - &env-podname
    name: PODNAME
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.name
  extraVolumes:
  - name: data
    nfs:
      path: /grafana-mimir/alertmanager/
      server: nfs
  extraVolumeMounts:
  - &extra-mount
    mountPath: /nfsdata
    name: data
    subPathExpr: $(PODNAME)
  initContainers:
  # 需要修改自动新建的文件夹的权限，默认是 root:root, 容器是 10001:10001
  # 正常情况下 volume 会跟随 fsUser 但某些情况下设置了 subPathExpr 后权限会不跟随
  - &extra-mount-init
    name: chown
    image: busybox:latest
    command: ['/bin/sh', '-c', 'chown 10001:10001 /nfsdata']
    env:
    - *env-podname
    securityContext:
      runAsNonRoot: false
      runAsUser: 0
    volumeMounts:
    - *extra-mount

store_gateway:
  persistentVolume: *disabled
  env: 
  - *env-podname
  extraVolumes:
  - name: data
    nfs:
      path: /grafana-mimir/store-gateway/
      server: nfs
  extraVolumeMounts:
  - *extra-mount
  initContainers:
  - *extra-mount-init

compactor:
  persistentVolume: *disabled
  env: 
  - *env-podname
  extraVolumes:
  - name: data
    nfs:
      path: /grafana-mimir/compactor/
      server: nfs
  extraVolumeMounts:
  - *extra-mount
  initContainers:
  - *extra-mount-init
```

### 禁用无用组件
```yaml
minio: *disabled
nginx: *disabled
gateway: *disabled
query_scheduler: *disabled
```

### 禁用nginx后使用自带nginx-ingress
- `ingress`
  - <details>
    <summary>内网网关</summary>

      ```yaml
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        annotations:
          nginx.ingress.kubernetes.io/whitelist-source-range: 127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,169.254.0.0/16,192.168.0.0/16
          nginx.ingress.kubernetes.io/proxy-connect-timeout: "3600"
          nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
          nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
          nginx.ingress.kubernetes.io/proxy-body-size: 4096m
          nginx.ingress.kubernetes.io/proxy-buffering: "off"
          nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
        name: internal-gateway
      spec:
        rules:
        - host: mimir.ingress.svc
          http:
            paths:
            - backend: &distributor
                service:
                  name: mimir-distributor-headless
                  port:
                    number: 8080
              path: /distributor
              pathType: Prefix
            - backend: *distributor
              path: /ingester/ring
              pathType: Exact
            - backend: *distributor
              path: /otlp/v1/metrics
              pathType: Prefix
            
            - backend: &alertmanager
                service:
                  name: mimir-alertmanager-headless
                  port:
                    number: 8080
              path: /alertmanager
              pathType: Prefix
            - backend: *alertmanager
              path: /multitenant_alertmanager/status
              pathType: Exact
            - backend: *alertmanager
              path: /multitenant_alertmanager/configs
              pathType: Exact
            - backend: *alertmanager
              path: /multitenant_alertmanager/ring
              pathType: Exact
            - backend: *alertmanager
              path: /api/v1/alerts
              pathType: Exact

            - backend: &ruler
                service:
                  name: mimir-ruler
                  port:
                    number: 8080
              path: /prometheus/config/v1/rules
              pathType: Prefix
            - backend: *ruler
              path: /prometheus/api/v1/rules
              pathType: Prefix
            - backend: *ruler
              path: /prometheus/api/v1/alerts
              pathType: Prefix
            - backend: *ruler
              path: /ruler/ring
              pathType: Exact

            - backend: &query-frontend
                service:
                  name: mimir-query-frontend
                  port:
                    number: 8080
              path: /prometheus
              pathType: Prefix
            - backend: *query-frontend
              path: /api/v1/status/buildinfo
              pathType: Exact
            - backend: *query-frontend
              path: /prometheus/api/v1/read
              pathType: Exact
            - backend:
                service:
                  name: mimir-store-gateway-zone-a
                  port:
                    number: 8080
              path: /store-gateway
              pathType: Prefix
            - backend:
                service:
                  name: mimir-store-gateway-zone-b
                  port:
                    number: 8080
              path: /store-gateway
              pathType: Prefix
            - backend:
                service:
                  name: mimir-store-gateway-zone-c
                  port:
                    number: 8080
              path: /store-gateway
              pathType: Prefix
      ```

    </details>
  - <details>
    <summary>公网网关</summary>

    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      annotations:
        nginx.ingress.kubernetes.io/proxy-connect-timeout: "3600"
        nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
        nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
        nginx.ingress.kubernetes.io/proxy-body-size: 4096m
        nginx.ingress.kubernetes.io/proxy-buffering: "off"
        nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
      name: internet-gateway
    spec:
      rules:
      - host: yourdomain.doo.foo
        http:
          paths:
          - &distributor-distributor
            backend: &distributor
              service:
                name: mimir-distributor-headless
                port:
                  number: 8080
            path: /distributor
            pathType: Prefix
          - &distributor-ingester-ring
            backend: *distributor
            path: /ingester/ring
            pathType: Exact
          - &distributor-otlp-metrics
            backend: *distributor
            path: /otlp/v1/metrics
            pathType: Prefix
          
          - &alertmanager-alertmanager
            backend: &alertmanager
              service:
                name: mimir-alertmanager-headless
                port:
                  number: 8080
            path: /alertmanager
            pathType: Prefix
          - &alertmanager-status
            backend: *alertmanager
            path: /multitenant_alertmanager/status
            pathType: Exact
          - &alertmanager-configs
            backend: *alertmanager
            path: /multitenant_alertmanager/configs
            pathType: Exact
          - &alertmanager-ring
            backend: *alertmanager
            path: /multitenant_alertmanager/ring
            pathType: Exact
          - &alertmanager-alerts
            backend: *alertmanager
            path: /api/v1/alerts
            pathType: Exact

          - &ruler-config-rules
            backend: &ruler
              service:
                name: mimir-ruler
                port:
                  number: 8080
            path: /prometheus/config/v1/rules
            pathType: Prefix
          - &ruler-api-rules
            backend: *ruler
            path: /prometheus/api/v1/rules
            pathType: Prefix
          - &ruler-api-alerts
            backend: *ruler
            path: /prometheus/api/v1/alerts
            pathType: Prefix
          - &ruler-ring
            backend: *ruler
            path: /ruler/ring
            pathType: Exact

          - &query-frontend-prometheus
            backend: &query-frontend
              service:
                name: mimir-query-frontend
                port:
                  number: 8080
            path: /prometheus
            pathType: Prefix
          - &query-frontend-buildinfo
            backend: *query-frontend
            path: /api/v1/status/buildinfo
            pathType: Exact
          - &query-frontend-user_limits
            backend: *query-frontend
            path: /api/v1/user_limits
            pathType: Exact

          - &overrides-exporter
            backend:
              service:
                name: mimir-overrides-exporter
                port:
                  number: 8080
            path: /overrides-exporter/ring
            pathType: Exact

          - &compactor
            backend:
              service:
                name: mimir-compactor
                port:
                  number: 8080
            path: /compactor/ring
            pathType: Exact

          - &ingester-zone-a
            backend:
              service:
                name: mimir-ingester-zone-a
                port:
                  number: 8080
            path: /ingester
            pathType: Prefix
          - &ingester-zone-b
            backend:
              service:
                name: mimir-ingester-zone-b
                port:
                  number: 8080
            path: /ingester
            pathType: Prefix
          - &ingester-zone-c
            backend:
              service:
                name: mimir-ingester-zone-c
                port:
                  number: 8080
            path: /ingester
            pathType: Prefix

          - &store-gateway-zone-a
            backend:
              service:
                name: mimir-store-gateway-zone-a
                port:
                  number: 8080
            path: /store-gateway
            pathType: Prefix
          - &store-gateway-zone-b
            backend:
              service:
                name: mimir-store-gateway-zone-b
                port:
                  number: 8080
            path: /store-gateway
            pathType: Prefix
          - &store-gateway-zone-c
            backend:
              service:
                name: mimir-store-gateway-zone-c
                port:
                  number: 8080
            path: /store-gateway
            pathType: Prefix
      - host: yourdomain-zone-a.doo.foo
        http:
          paths:
          - *distributor-distributor
          - *distributor-ingester-ring
          - *distributor-otlp-metrics
          - *alertmanager-alertmanager
          - *alertmanager-status
          - *alertmanager-configs
          - *alertmanager-ring
          - *alertmanager-alerts
          - *ruler-config-rules
          - *ruler-api-rules
          - *ruler-api-alerts
          - *ruler-ring
          - *query-frontend-prometheus
          - *query-frontend-buildinfo
          - *query-frontend-user_limits
          - *overrides-exporter
          - *compactor
          - *ingester-zone-a
          - *store-gateway-zone-a
      - host: yourdomain-zone-b.doo.foo
        http:
          paths:
          - *distributor-distributor
          - *distributor-ingester-ring
          - *distributor-otlp-metrics
          - *alertmanager-alertmanager
          - *alertmanager-status
          - *alertmanager-configs
          - *alertmanager-ring
          - *alertmanager-alerts
          - *ruler-config-rules
          - *ruler-api-rules
          - *ruler-api-alerts
          - *ruler-ring
          - *query-frontend-prometheus
          - *query-frontend-buildinfo
          - *query-frontend-user_limits
          - *overrides-exporter
          - *compactor
          - *ingester-zone-b
          - *store-gateway-zone-b
      - host: yourdomain-zone-c.doo.foo
        http:
          paths:
          - *distributor-distributor
          - *distributor-ingester-ring
          - *distributor-otlp-metrics
          - *alertmanager-alertmanager
          - *alertmanager-status
          - *alertmanager-configs
          - *alertmanager-ring
          - *alertmanager-alerts
          - *ruler-config-rules
          - *ruler-api-rules
          - *ruler-api-alerts
          - *ruler-ring
          - *query-frontend-prometheus
          - *query-frontend-buildinfo
          - *query-frontend-user_limits
          - *overrides-exporter
          - *compactor
          - *ingester-zone-c
          - *store-gateway-zone-c
      tls:
      - hosts:
        - '*.doo.foo'
        secretName: ssl-doo-foo
    ```

    </details>
- `coredns` Corefile
  ```ini
  .:53 {
      hosts {
          xx.xx.xx.xx mimir.ingress.svc
          fallthrough
      }
  }
  ```

## Mimir
Helm Chart Values 路径: `mimir.structuredConfig`
### ring集体配置
```yaml
distributor:
  ring: &ring
    kvstore:
      store: xxx
      xxx: {}
ingester:
  ring: *ring
ruler:
  ring: *ring
alertmanager:
  sharding_ring: *ring
compactor:
  sharding_ring: *ring
store_gateway:
  sharding_ring: *ring
```
### limits
```yaml
mimir:
  structuredConfig:
    limits:
      # 写速率限制
      ingestion_rate: 10000
      ingestion_burst_size: 100000
      max_global_series_per_user: 0
      # 乱序写入区间
      out_of_order_time_window: 10m
      # 查询限制
      max_fetched_series_per_query: 1024
      # 数据保留时间
      compactor_blocks_retention_period: 1y
```
### HA去重
```yaml
mimir:
  structuredConfig:
    limits:
      # 多Prometheus采集去重
      accept_ha_samples: true
      ha_cluster_label: cluster
      ha_replica_label: __replica__
    distributor:
      ha_tracker:
        enable_ha_tracker: true
        kvstore:
          store: xxx
          xxx: {}  
```
### Grpc压缩
```yaml
mimir:
  structuredConfig:
    frontend:
      grpc_client_config: &grpc-client
        grpc_compression: snappy
    ingester_client: 
      grpc_client_config: *grpc-client
    frontend_worker:
      grpc_client_config: *grpc-client
    ruler:
      ruler_client: *grpc-client
      query_frontend:
        grpc_client_config: *grpc-client
```
### 缓存
```yaml
mimir:
  structuredConfig:
    frontend:
      # 建议与支持客户端缓存（Client-side caching）的RESP3协议一起使用
      cache_results: false
      results_cache: 
        backend: redis
        redis: &redis-cache
          endpoint: redis:6379
        compression: snappy
    ruler_storage:
      cache: 
        backend: redis
        redis: *redis-cache
    blocks_storage:
      bucket_store:
        index_cache:
          backend: redis
          redis: *redis-cache
        # chunks_cache: 
        #   backend: redis
        #   redis: *redis-cache
        metadata_cache: 
          backend: redis
          redis: *redis-cache
```
### 杂项
```yaml
mimir:
  structuredConfig:
    server:
      log_format: json
      log_source_ips_enabled: true
    tenant_federation:
      # 开启跨租户查询
      enabled: true
    limits:
      # 外部块上传
      compactor_block_upload_enabled: true
    frontend:
      # 并发查询请求
      max_outstanding_per_tenant: 2048
      # 慢查询阈值
      log_queries_longer_than: 1s
      # 慢日志输出HTTP头
      log_query_request_headers: X-Grafana-Org-Id,X-Grafana-User
      # 禁止打印查询状态
      query_stats_enabled: no
    ruler:
      # 规则默认执行间隔
      evaluation_interval: 15s
      tenant_federation:
        # 开启跨租户查询
        enabled: true
```
