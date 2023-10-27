## 如何取消Miui9的 /data 分区加密 <!-- omit in toc -->
#### 注意：该操作会丢失手机上所有的的数据！是<font color=red>所有！！！</font> <!-- omit in toc -->  
#### 注意2：该操作会使手机变的及其不安全！ <!-- omit in toc -->  
~~*其实贼简单*~~

- [0、解锁Bootloader](#0解锁bootloader)
- [1、刷入 TWRP Recovery](#1刷入-twrp-recovery)
- [2、进行数据备份](#2进行数据备份)
- [3、格式化分区](#3格式化分区)
- [4、恢复备份](#4恢复备份)
- [5、恢复data分区(应用程序及其数据)](#5恢复data分区应用程序及其数据)
- [6、尽情享受吧](#6尽情享受吧)

### 0、解锁Bootloader
~~_**你都要折腾手机了居然不去解锁 (ﾉ ○ Д ○)ﾉ**_~~  
在这里：<a href="http://www.miui.com/unlock/index.html" target="_blank">申请解锁小米手机</a>

### 1、刷入 TWRP Recovery
这是写这篇文档时我能找到的最新的 TWRP Recovery（支持简体中文）：
<a href="https://dl.twrp.me/gemini/" target="_blank">TWRP for gemini</a>  
主要更改语言位置：  
1. 在第一次进入Recovery时，会询问是否保持System分区的只读状态。这时候可以选右边的“Select Language”选项，然后拉到最上方选择“Chinese(simplified)”  
2. 在主界面选择“Settings”，然后选上方最后一个地球图标的按钮，接着找到并选择“Chinese(simplified)”，按下下方“Set Language”按钮  

```
fastboot flash recovery $(recovery.img)
fastboot boot $(recovery.img)            (这句可以直接引导进recovery)
```

### 2、进行数据备份
1. (基于MIUI)在手机上启用小米云同步，备份如联系人、短信、照片等数据  
2. 使用TWRP自带的备份功能备份data分区(不包括/data/media/0, 也就是sdcard) （也可以同时备份其他分区），然后将手机连上电脑，使用MTP拷贝手机上备份和重要的数据。
3. 我的手机是MI5 128G版，当初为了备份全部数据用了adb+tar+管道+dd的方法来备份整个sdcard \_(:з」∠)\_ ~~(dd主要是用来看速度)~~

### 3、格式化分区
**注：其实从TWRP备份开始，你的手机都要在TWRP里面了(๑˙ー˙๑)，所以....... 感受宁静吧**  
0. 由于不清楚直接格式化data分区是否是格式化加密前的分区，我就用终端辅助操作了
1. 在TWRP里面选择 “终端”，然后输入mount，看到块设备dm-1(之内的名字) 然后umount它。或者在挂载选项卡里面取消data分区的挂载。
2. 回到终端输入mount看看dm-1是否消失，如果数据太多可以用grep筛选。
3. 确认dm-1消失，进入“清除”选项卡，选择格式化data分区，等待格式化完成。
4. 格式化完成后重启回到recovery，看看日志中是否有“新增块设备”之类的日志，没有就证明成功取消加密

### 4、恢复备份
连接电脑、启动MTP、拷数据、睡一觉  
如果没有/data/media/0文件夹的话得先新建一个或者回到系统让系统帮你新建（回到系统时注意拔掉电源线，避免触发自动加密）

### 5、恢复data分区(应用程序及其数据)
使用TWRP自带的恢复功能恢复data分区

### 6、尽情享受吧
![高级设置](../../assets/phone/Mi5-Miui9-SDK24/Advanced-Setting.png)  
![加密手机](../../assets/phone/Mi5-Miui9-SDK24/Encryption-Phone.png)
