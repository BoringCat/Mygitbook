# Centos备忘录  <!-- omit in toc -->

- [批量改源 (7)](#批量改源-7)
- [epel](#epel)
- [zabbix改源](#zabbix改源)
- [Tomcat](#tomcat)
- [终端自动登录](#终端自动登录)

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

## zabbix改源
``` sh
cp /etc/yum.repos.d/zabbix.repo /etc/yum.repos.d/zabbix.repo.bak && \
sed -e 's!//repo\.zabbix\.com!//mirrors.tuna.tsinghua.edu.cn/zabbix!g' \
    -e 's!https://mirrors\.tuna!https://mirrors.tuna!g' \
    -i /etc/yum.repos.d/zabbix.repo
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