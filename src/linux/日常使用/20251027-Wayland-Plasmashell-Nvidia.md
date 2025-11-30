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
**So NVIDIA......**

## 2. 方法
~/.config/systemd/user/plasma-plasmashell.service.d/override.conf
```ini
[Service]
Environment=__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
Environment=__GLX_VENDOR_LIBRARY_NAME=mesa
```
### 缺点
- 无法获取窗口预览图
