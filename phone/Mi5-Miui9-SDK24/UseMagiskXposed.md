## 在MIUI9上面安装Magisk和使用systemless-Xposed

### 前提条件
**1. 未更改过系统的Boot分区，如SuperSU等Systemless应用**  
**2. 未安装任何版本的Xposed，包括apk**  
**3. 该操作会有一定几率导致卡MI**  
**3. 本文假设你已经解锁Bootloader并且拥有TWRP Recovery**  

### 1、下载Magisk
[Magisk — XdaDevelopers](https://forum.xda-developers.com/apps/magisk)  

### 2、刷入Magisk
1. 进入TWRP Recovery
2. 找到Magisk-vxx.x.zip
3. 刷入Zip
4. 重启进入系统
5. 若系统没有安装 Magisk Manager APP，可以打开Magisk-vxx.x.zip，解压common/magisk.apk，然后安装

### 3、安装Xposed Framework
1. 打开 Magisk Manager 选择“下载”选项卡
2. 搜索 "Xposed Framework"
3. 按照系统版本选择模块
4. 安装模块
5. 在模块的详情页下载并安装 Systemless Xposed App(点击模块即可弹出)
6. 重启系统

| Android版本 | SDK |
| :-: | :-: |
| Android 8.1 | 27 |
| Android 8.0 | 26 |
| Android 7.1 | 25 |
| Android 7.0 | 24 |
| Android 6.0 | 23 |
| Android 5.1 | 22 |
| Android 5.0 | 21 |

### 4、验证  
1. 在 Magisk 的“模块”中能看到 “Xposed Framework (SDK XX)” 是激活状态的  
![Magisk-Modes](../../.gitbook/assets/Magisk-Modes.png)
2. 打开Xposed Installer可以看到 “Xposed 框架 XX.X (Systemless) 版已激活”  
![Xposed-Installer](../../.gitbook/assets/Xposed-Installer.png)

### 额外内容
+ **修复启用Xposed框架后手银行app闪退的问题**  
在Xposed Installer中搜索 “Xposed淘宝闪退补丁”，并安装。  
至于为什么是淘宝闪退补丁以及为什么淘宝完全没有问题我也不清楚╭(๑¯д¯๑)╮
