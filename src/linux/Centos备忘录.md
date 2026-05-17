# Centos备忘录  <!-- omit in toc -->

- [批量改源 (7)](#批量改源-7)
- [epel](#epel)
- [SCLo](#sclo)
- [zabbix改源](#zabbix改源)
- [docker-ce](#docker-ce)
- [Tomcat](#tomcat)
- [终端自动登录](#终端自动登录)
- [加快内核压缩](#加快内核压缩)
- [微软大战代码](#微软大战代码)

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

## 加快内核压缩
/etc/dracut.conf.d/compress_xz.conf
```conf
compress=" xz -0 -T0 "
```

## 微软大战代码
1. 下载来自 AlmaLinux 8 的软件包和 patchelf
   - [glibc](https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/os/Packages/glibc-2.28-251.el8_10.34.x86_64.rpm) ([本站](../assets/linux/备忘录/glibc-2.28-251.el8_10.34.x86_64.rpm))
   - [libstdc++](https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/os/Packages/libstdc++-8.5.0-28.el8_10.alma.1.x86_64.rpm) ([本站](../assets/linux/备忘录/libstdc++-8.5.0-28.el8_10.alma.1.x86_64.rpm))
   - [patchelf](https://github.com/NixOS/patchelf/releases) ([本站](../assets/linux/备忘录/patchelf-0.18.0-x86_64.tar.gz))
2. 解压 `glibc` `libstdc++` `patchelf` 到 `/usr/local/glibc-2.28`
   ```sh
    mkdir /usr/local/glibc-2.28
    cd /usr/local/glibc-2.28
    rpm2cpio /path/to/glibc-2.28-xxx.rpm | cpio -idmv
    rpm2cpio /path/to/libstdc++-8.5.0-xxx.rpm | cpio -idmv
    tar xvf /path/to/patchelf-xxx.tar.gz
   ```
3. 创建环境变量  
   `$HOME/.vscode-server/server-env-setup`  
   ```sh
   export VSCODE_SERVER_CUSTOM_GLIBC_LINKER=/usr/local/glibc-2.28/usr/lib64/ld-linux-x86-64.so.2
   export VSCODE_SERVER_CUSTOM_GLIBC_PATH=/usr/local/glibc-2.28/usr/lib64/
   export VSCODE_SERVER_PATCHELF_PATH=/usr/local/glibc-2.28/bin/patchelf
   ```