# Centos备忘录  <!-- omit in toc -->

- [批量改源 (7)](#批量改源-7)
- [epel](#epel)
- [终端自动登录](#终端自动登录)

## 批量改源 (7)
```sh
sed -e 's!^mirrorlist=!#mirrorlist=!g' \
    -e 's!^#baseurl=!baseurl=!g' \
    -e 's!//mirror\.centos\.org!//mirrors.sjtug.sjtu.edu.cn!g' \
    -e 's!http://mirrors\.sjtug!https://mirrors.sjtug!g' \
    -i /etc/yum.repos.d/CentOS-Base.repo
```

## epel
```sh
yum install epel-release
sed -e 's!^metalink=!#metalink=!g' \
    -e 's!^#baseurl=!baseurl=!g' \
    -e 's!//download\.fedoraproject\.org/pub!//mirrors.sjtug.sjtu.edu.cn/fedora!g' \
    -e 's!http://mirrors\.sjtug!https://mirrors.sjtug!g' \
    -i /etc/yum.repos.d/epel.repo
```

## 终端自动登录
```sh
# /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
```