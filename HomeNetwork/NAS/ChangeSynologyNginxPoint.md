# 更改群晖DSM的默认端口
## 文件存储目录
`/usr/syno/share/nginx`（可能会变）

## 需要修改的文件
```
DSM.mustache
server.mustache
WWWService.mustache
```
### 获得方法
```
grep -E "listen[ ]+(\[::\])?:?(80|443)" /usr/syno/share/nginx -Ro | cut -d ':' -f1 | sort | uniq
```

## 修改命令
```sh
#!/bin/sh

SYNO_NGINX_PATH=${SYNO_NGINX_PATH:-/usr/syno/share/nginx}
FILE_LIST=$(grep -E "listen[ ]+(\[::\])?:?(80|443)" ${SYNO_NGINX_PATH} -Ro | cut -d ':' -f1 | sort | uniq)
for file in `echo ${FILE_LIST}`
do
sed -Ei 's/(listen[ ]+(\[::\])?:)?80/\18080/g;s/(listen[ ]+(\[::\])?:)?443/\144333/g' ${file}
done
synoservice --restart nginx
netstat -lnp | grep nginx
```