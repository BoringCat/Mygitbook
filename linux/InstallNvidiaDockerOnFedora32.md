# 在Fedora32上安装Nvidia-docker <!-- omit in toc -->

- [系统环境](#系统环境)
- [配置](#配置)
  - [1. 查看支持系统](#1-查看支持系统)
  - [2. 使用 Centos7 的 repo 进行安装](#2-使用-centos7-的-repo-进行安装)
  - [3. 安装 nvidia-docker2](#3-安装-nvidia-docker2)
  - [4. Reload docker](#4-reload-docker)
  - [5. 验证](#5-验证)
- [Docker-Compose注意事项](#docker-compose注意事项)
- [用途？](#用途)

## 系统环境
- 系统: Fedora 32 (Thirty Two)
- 内核: 5.6.13-300.fc32.x86_64
- Docker-ce版本：Docker version 19.03.9, build 9d98839
- GPU: Nvidia GeForce GTX 1060

## 配置
原帖 [nvidia-docker/issues/553#issuecomment-381075335][1] 是在Fedora27成功配置
### 1. 查看支持系统
前往 [nvidia.github.io][2] 查看支持的系统
### 2. 使用 Centos7 的 repo 进行安装
*我试过改成Centos8，下载下来的文件还是centos7的*
```sh
 wget https://nvidia.github.io/nvidia-docker/centos7/nvidia-docker.repo -O /etc/yum.repos.d/nvidia-docker.repo
```

### 3. 安装 nvidia-docker2
```sh
dnf install nvidia-docker2
```
结果（输出找不到了，用 `dnf history` 看吧）: 
```
命令行   ： install nvidia-docker2
已改变的包：
    安装 libnvidia-container-tools-1.1.1-1.x86_64 @libnvidia-container
    安装 libnvidia-container1-1.1.1-1.x86_64      @libnvidia-container
    安装 nvidia-container-runtime-3.2.0-1.x86_64  @nvidia-container-runtime
    安装 nvidia-container-toolkit-1.1.1-2.x86_64  @nvidia-container-runtime
    安装 nvidia-docker2-2.3.0-1.noarch            @nvidia-docker

```

### 4. Reload docker
- systemd
  ```
  systemctl reload docker
  ```
- 原帖
  ```
  pkill -SIGHUP dockerd
  ```

### 5. 验证
```sh
nvidia-docker run --rm nvidia/cuda nvidia-smi
```
或
```sh
docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi
```

## Docker-Compose注意事项
1. `runtime` 项在 `version: 2.3` 及之后的版本中支持。`version: 2` 是不行的
2. `nvidia-docker` 就是一个shell脚本，里面还有选择GPU的参数。这里就不列出

## 用途？
- OpenCV图像识别加速
- 其他奇奇怪怪的能用GPU加速的东西


[1]: https://github.com/NVIDIA/nvidia-docker/issues/553#issuecomment-381075335
[2]: https://nvidia.github.io/nvidia-docker/