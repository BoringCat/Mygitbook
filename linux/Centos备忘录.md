# Centos备忘录  <!-- omit in toc -->

- [批量改源 (7)](#批量改源-7)
- [epel](#epel)
- [SCLo](#sclo)
- [zabbix改源](#zabbix改源)
- [docker-ce](#docker-ce)
- [Tomcat](#tomcat)
- [终端自动登录](#终端自动登录)
- [LVM](#lvm)
  - [root缓存](#root缓存)
- [加快内核压缩](#加快内核压缩)

## 批量改源 (7)
```sh
cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak && \
sed -e 's!^mirrorlist=!#mirrorlist=!g' \
    -e 's!^#baseurl=!baseurl=!g' \
    -e 's!//mirror\.centos\.org!//mirrors.sjtug.sjtu.edu.cn!g' \
    -e 's!http://mirrors\.sjtug!https://mirrors.sjtug!g' \
    -i /etc/yum.repos.d/CentOS-Base.repo
```

## epel
```sh
yum install epel-release && \
cp /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.bak && \
sed -e 's!^metalink=!#metalink=!g' \
    -e 's!^#baseurl=!baseurl=!g' \
    -e 's!//download\.fedoraproject\.org/pub!//mirrors.sjtug.sjtu.edu.cn/fedora!g' \
    -e 's!http://mirrors\.sjtug!https://mirrors.sjtug!g' \
    -i /etc/yum.repos.d/epel.repo
```

## SCLo
```sh
yum install centos-release-scl && \
cp /etc/yum.repos.d/CentOS-SCLo-scl.repo /etc/yum.repos.d/CentOS-SCLo-scl.repo.bak && \
cp /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo.bak && \
sed -e 's!^mirrorlist=!#mirrorlist=!g' \
    -e 's!^#[ ]*baseurl=!baseurl=!g' \
    -e 's!//mirror\.centos\.org!//mirrors.sjtug.sjtu.edu.cn!g' \
    -e 's!http://mirrors\.sjtug!https://mirrors.sjtug!g' \
    -i /etc/yum.repos.d/CentOS-SCLo-scl.repo \
    /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
```

## zabbix改源
``` sh
cp /etc/yum.repos.d/zabbix.repo /etc/yum.repos.d/zabbix.repo.bak && \
sed -e 's!//repo\.zabbix\.com!//mirrors.tuna.tsinghua.edu.cn/zabbix!g' \
    -e 's!https://mirrors\.tuna!https://mirrors.tuna!g' \
    -i /etc/yum.repos.d/zabbix.repo
```

## docker-ce
``` sh
yum remove docker docker-common docker-selinux docker-engine && \
yum install yum-utils device-mapper-persistent-data lvm2 wget && \
wget -O /etc/yum.repos.d/docker-ce.repo.bak https://download.docker.com/linux/centos/docker-ce.repo && \
sed 's+download.docker.com+mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo.bak > /etc/yum.repos.d/docker-ce.repo && \
yum makecache fast && \
yum install docker-ce
```

## Tomcat
在bin中添加文件setenv.sh
``` sh
JAVA_HOME="/path/to/java"
```
即可完成JAVA配置

## 终端自动登录
```sh
# /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
```

## LVM
### root缓存
/etc/dracut.conf.d/idmcache.conf
```conf
add_dracutmodules+=" lvm "
add_drivers+=" dm_cache "
```

## 加快内核压缩
/etc/dracut.conf.d/compress_xz.conf
```conf
compress=" xz -0 -T0 "
```