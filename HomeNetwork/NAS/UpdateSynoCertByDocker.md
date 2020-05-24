# 在群晖上用docker的Certbot
- 本文使用镜像为[boringcat/certboot-cf-ssh][1]而不是[certbot/dns-cloudflare][2]是因为执行reload脚本需要ssh
- 你可以去dockerhub上查看这个镜像的[Dockerfile][3]

## 先决条件
在DSM上上传证书，并设为默认证书

## 工作原理
### 群晖的证书位置
- 自带应用目录： /usr/syno/etc/certificate//usr/syno/etc/certificate/
- 附加应用目录： /usr/local/etc/certificate/\$subscriber/\$service
- 默认证书目录： /usr/syno/etc/certificate/system/default/
- 配置文件位置： /usr/syno/etc/certificate/_archive/INFO （JSON）

### 重载/重启命令
- 群晖应用管理命令是 `synoservice`
- 重启命令： --restart， 重载命令： --reload
- 附加应用的名字是 `pkgctl-$subscriber`
- DSM等默认web是 `nginx`

## Docker-Compose配置
```yaml
version: "2"

service:
  certbot-renew:
    image: boringcat/certboot-cf-ssh:latest
    hostname: certbot-renew
    container_name: certbot-renew
    volumes:
      - ./certbot/etc-letsencrypt:/etc/letsencrypt
      - ./certbot/var-lib-letsencrypt:/var/lib/letsencrypt
      - ./certbot/var-log-letsencrypt:/var/log/letsencrypt
      - ./certbot/ssh_keys:/srv/ssh_keys:ro
      - /etc/localtime:/etc/localtime:ro
    environment:
      TZ: Asia/Shanghai
    command: 
      - "renew"
      - "--no-random-sleep-on-renew"
```

## 给群晖Crontab的脚本
- `renew.sh`
  ```sh
  #!/bin/sh
  
  docker-compose -f /volume2/docker/docker-compose.yml up --no-start certbot-renew
  
  docker start -ia certbot-renew
  ```
- `reload.sh`
  ```sh
  #!/bin/sh
  cd $(dirname `realpath $0`)

  source ./reload_func.sh
  copyToDeafult
  [ $? -ne 0 ] && [ "$1" != "--force" ] && echo "Nothing to Reload"
  copyToServices
  reloadALL
  ```
- `reload_func.sh`
  ```sh
  ID="1Lk1Fl"
  CERTBOT_PATH="/volume2/docker/certbot/etc-letsencrypt"
  DOMAIN="home.boringcat.top"
  
  archpath="/usr/syno/etc/certificate/_archive/${ID}"
  CERT_PATH="${CERTBOT_PATH}/live/${DOMAIN}"

  # 获取使用SSL证书的应用，并返回命令
  getServices() {
      local INFO
      local FORMENT
      INFO="/usr/syno/etc/certificate/_archive/INFO"
      FORMENT=$1
      subscribers_pkg=$(jq -c ".\"${ID}\".services[]|{subscriber,service,isPkg,owner}" $INFO)
  
      case $FORMENT in
          "cp")
              for n in $(echo $subscribers_pkg)
              do
                  subscriber=$(echo $n | jq -r '.subscriber')
                  service=$(echo $n | jq -r '.service')
                  isPkg=$(echo $n | jq -r '.isPkg')
                  owner=$(echo $n | jq -r '.owner')
                  [ "$isPkg" = "false" ] && \
                  echo "{\"aim\":\"/usr/syno/etc/certificate/$subscriber/$service\",\"owner\":\"$owner\"}" || \
                  echo "{\"aim\":\"/usr/local/etc/certificate/$subscriber/$service\",\"owner\":\"$owner\"}"
              done
          ;;
          "reload")
              for n in $(echo $subscribers_pkg)
              do
                  subscriber=$(echo $n | jq -r '.subscriber')
                  service=$(echo $n | jq -r '.service')
                  isPkg=$(echo $n | jq -r '.isPkg')
                  [ "$service" = "default" ] && continue
                  [ "$isPkg" = "false" ] && \
                  echo "$service" || \
                  echo "pkgctl-$subscriber"
              done
          ;;
      esac
  }
  
  # 复制证书到群晖默认目录
  copyToDeafult() {
      local cpnum
      cpnum=0
  
      cd ${CERT_PATH}
      for n in *.pem
      do
          diff $(realpath $n) $archpath/$n 2>&1 > /dev/null
          if [ $? -eq 0 ]; then
              continue
          fi
          cp -v $(realpath $n) $archpath/$n
          let cpnum++
      done
      if [ $cpnum -gt 0 ]; then
          rsync -avzh $archpath/ /usr/syno/etc/certificate/system/default/
          return 0
      fi
      return 1
  }
  
  # 复制证书到群晖应用目录
  copyToServices() {
      for j in $(getServices cp)
      do
      echo $j
          aim=$(echo $j | jq -r '.aim')
          owner=$(echo $j | jq -r '.owner')
          rsync -avzh /usr/syno/etc/certificate/system/default/ $aim/
          ogid=$(id -g $owner)
          chown $owner:$ogid $aim/*
          chmod 400 $aim/*
          chmod 755 $aim
      done
  }
  
  # 重载Web服务
  reloadDefault() {
      synoservice --reload nginx
      /volume2/docker/nginx/reload.sh
  }
  
  # 重载应用
  reloadServices() {
      for service in $(getServices reload)
      do
          service_status=$(synoservice --status $service | grep -Eo "status=\[.*\]$" | cut -d'[' -f2 | cut -d']' -f1)
          [ "$service_status" = "enable" ] && echo -e "Reloading $service ...\c" && synoservice --reload $service && echo 'Done!' || echo "$service is Disabled."
      done
  }
  
  # 重载
  reloadALL() {
      reloadDefault
      reloadServices
  }
  ```

## Certbot的Deploy脚本
```sh
ssh -i /srv/ssh_keys/reload_rsa -o "StrictHostKeyChecking no" root@172.17.0.1 'PATH=/usr/local/bin:$PATH; /volume2/docker/nginx/reload.sh'
```

[1]: https://hub.docker.com/r/boringcat/certboot-cf-ssh
[2]: https://hub.docker.com/r/certbot/dns-cloudflare
[3]: https://hub.docker.com/r/boringcat/certboot-cf-ssh/dockerfile