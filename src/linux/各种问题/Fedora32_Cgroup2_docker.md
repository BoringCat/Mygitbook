# 在Fedora 32 上 禁用 Cgruop2 <!-- omit in toc -->
**\* 不知道什么时候失效，当然越快越好**

- [环境](#环境)
  - [系统](#系统)
  - [Docker-ce](#docker-ce)
- [配置过程](#配置过程)
- [问题](#问题)
- [解决方案](#解决方案)
  - [1. 治标](#1-治标)
  - [2. 治本（禁用cgroup2）](#2-治本禁用cgroup2)

## 环境
### 系统
- 系统: Fedora 32 (Thirty Two)
- 内核: 5.6.12-300.fc32.x86_64

### Docker-ce
```
Client: Docker Engine - Community
 Version:           19.03.8
 API version:       1.40
 Go version:        go1.12.17
 Git commit:        afacb8b7f0
 Built:             Wed Mar 11 01:27:05 2020
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          19.03.8
  API version:      1.40 (minimum version 1.12)
  Go version:       go1.12.17
  Git commit:       afacb8b7f0
  Built:            Wed Mar 11 01:25:01 2020
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.2.13
  GitCommit:        7ad184331fa3e55e52b890ea95e65ba581ae3429
 runc:
  Version:          1.0.0-rc10
  GitCommit:        dc9208a3303feef5b3839f4323d9beb36df0a9dd
 docker-init:
  Version:          0.18.0
  GitCommit:        fec3683
```

## 配置过程
参考 [Docker Community Edition 镜像使用帮助 — 清华大学开源软件镜像站][1]

## 问题
```
docker run --rm -it alpine
docker: Error response from daemon: cgroups: cgroup mountpoint does not exist: unknown.
```

## 解决方案
### 1. 治标
```sh
mkdir /sys/fs/cgroup/systemd
mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd
```

### 2. 治本（禁用cgroup2）
1. /etc/default/grub
   ```
   GRUB_CMDLINE_LINUX=systemd.unified_cgroup_hierarchy=0
   ```
2. Upgrade grub2
   - EFI
      ```sh
      grub2-mkconfig > /boot/efi/EFI/fedora/grub.cfg
      ```
   - BIOS
      ```sh
      grub2-mkconfig > /boot/grub2/grub.cfg
      ```
3. reboot


[1]: https://mirrors.tuna.tsinghua.edu.cn/help/docker-ce/