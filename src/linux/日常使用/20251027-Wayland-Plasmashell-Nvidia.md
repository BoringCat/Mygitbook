# 解决Wayland下Plasmashell经常卡死的问题 <!-- omit in toc -->


## 环境
操作系统： Arch Linux   
KDE Plasma 版本： 6.5.0  
KDE 程序框架版本： 6.19.0  
Qt 版本： 6.10.0  
内核版本： 6.17.5-arch1-1 (64 位)  
图形平台： Wayland  
处理器： 6 × Intel® Core™ i5-9600KF CPU @ 3.70GHz  
内存： 16 GiB 内存  
图形处理器： GeForce GTX 1650


## 1. 原因
你可能是 X11+NVIDIA<555 的受害者，并且参考了[Wiki的内容](https://wiki.archlinuxcn.org/wiki/NVIDIA#TwinView_%E5%92%8C%E5%9E%82%E7%9B%B4%E5%90%8C%E6%AD%A5)配置了以下环境变量
```bash
export __GL_SYNC_TO_VBLANK=1
export __GL_SYNC_DISPLAY_DEVICE=DP-0
export VDPAU_NVIDIA_SYNC_DISPLAY_DEVICE=DP-0
```

## 2. 方法
从 `/etc/environment` `/etc/bash.bashrc` 等地方移除这些环境变量
