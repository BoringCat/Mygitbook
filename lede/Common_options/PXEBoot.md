## 基于OpenWrt/LEDE的PXE网络启动
### 前言  
本文以bios下启动syslinux引导WinPE的ISO文件以及UEFI下引导WinPE的WIM文件为例  
关于如何引导liveCD，OpenWrt的Wiki上有详细的资料[PXE-Boot from OpenWRT [OpenWrt Project]](https://openwrt.org/doc/howto/tftp.pxe-server)

### 如何配置
**以LEDE系统为例 (1GB rootfs rw)**   
**\*前提：** 完整的OpenWrt/LEDE路由系统、有uhttpd以及dnsmasq且dnsmasq可载入自定义配置文件与启动tftp服务。   
#### 准备工作
1. 在Linux系统上提取syslinux或grub2的文件，在windows系统镜像boot.wim中提取pxe文件夹  
2. 将syslinux或grub2的文件复制(scp)到路由器的 `/opt/pxe` 文件夹内(需新建)  
  将windows的pxe文件夹复制到 `/opt/pxe` 文件夹内并改名为 `boot`  
#### 传统BIOS引导
1. 在 `/etc/dnsmasq.conf` 内输入或在 `/etc/dnsmasq.d/` 下新建文件并输入  
``` config
enable-tftp
tftp-root=/opt/pxe
dhcp-boot=syslinux/bios/lpxelinux.0
```
这三句的意思分别是：  
1) 启动dnsmasq上自带的tftp服务器  
2) 设定tftp服务器的根目录为 /opt/pxe  
3) 设定默认的引导为 syslinux/bios/lpxelinux.0  

**这时候要确保存在目录 /opt/pxe ，否则dnsmasq无法启动!!**  

2. 在 `/opt/pxe/syslinux/bios` 中新建文件夹 `pxelinux.cfg`  
3. 在一台使用syslinux引导的电脑上复制 `syslinux.cfg` 以及这个配置文件所需要的全部文件到路由器上的 `/opt/pxe/syslinux/bios/pxelinux.cfg/` 并重命名 `syslinux.cfg` 为 `default`  

4. 修改 `/opt/pxe/syslinux/bios/pxelinux.cfg/default` 为PXE的引导文件 (可参照[PXELINUX - Syslinux Wiki](http://www.syslinux.org/wiki/index.php?title=PXELINUX))  
例：
``` syslinux
...
LABEL WIN10PE
    KERNEL memdisk
    APPEND raw iso Iinitrd=tftp://192.168.1.1/boot/WIN10PE.ISO
...
```
5. 传统BIOS可以进行网络引导了  
~~*6. TFTP慢的要死*~~  
#### UEFI引导
1. 复制windows系统镜像boot.wim中 `1\windwos\Boot\EFI\bootmgfw.efi` 到 `/opt/pxe` 文件夹内并改名为 `bootx64.efi`
2. 在dnsmasq的配置文件中添加以下内容  
``` config
dhcp-match=set:efi-x86_64,option:client-arch,7
dhcp-match=set:efi-x86_64,option:client-arch,9
dhcp-boot=tag:efi-x86_64,bootx64.efi
```
关于`client-arch`的值可在 [iPXE - open source boot firmware#notes](http://ipxe.org/cfg/platform#notes) 以及 [RFC 4578#page-3](https://tools.ietf.org/html/rfc4578#page-3) 中查询

3. 将WinPE的WIM文件以及SDI文件复制到路由器的 `/opt/pxe/boot` 文件夹内
4. 在Windows上新建BCD文件 (Win7及以上) (需要管理员权限)  
**\*注意 ramdisksdipath 与 ramdisk 的目录名称，由于Linux对大小写敏感，文件名大小写需要和目录里面一样**
``` cmd
bcdedit /createstore BCD
bcdedit /store BCD /create {ramdiskoptions} /d "Ramdisk options"
bcdedit /store BCD /set {ramdiskoptions} ramdisksdidevice boot
bcdedit /store BCD /set {ramdiskoptions} ramdisksdipath \boot\boot.sdi
bcdedit /store BCD /create /d "WinPE 3.0 32bit" /application osloader　得到ID

set id= 得到的ID

bcdedit /store BCD /set %id% systemroot \windows
bcdedit /store BCD /set %id% detecthal Yes
bcdedit /store BCD /set %id% winpe Yes
bcdedit /store BCD /set %id% osdevice ramdisk=[boot]\Boot\boot32.wim,{ramdiskoptions}
bcdedit /store BCD /set %id% device ramdisk=[boot]\boot\boot32.wim,{ramdiskoptions}
bcdedit /store BCD /create {bootmgr} /d "Windows Boot Manager"　
bcdedit /store BCD /set {bootmgr} nointegritychecks yes
bcdedit /store BCD /set {bootmgr} timeout 0
bcdedit /store BCD /default %id%
bcdedit /store BCD /displayorder %id%
```
5. 复制BCD文件到路由器的 `/opt/pxe/boot` 文件夹内  
6. UEFI可以进行网络引导了  
~~*7. 传输速度五六百K每秒你敢信*~~

### 优化
+ **通过HTTP获取WinPE的ISO文件**  
**\*仅以传统BIOS，使用syslinux引导为例**  
\*使用系统自带的uhttpd
1. 复制WinPE的ISO文件到路由器的 `/opt/pxe/boot` 内，并将其链接到 `/www` 下  
例：  
``` shell
ln -s /opt/pxe/boot/WIN10PE.ISO /www/WIN10PE.ISO
```
2. 更改syslinux的PXE引导配置文件
`diff /opt/pxe/syslinux/bios/pxelinux.cfg/default`  
例：  
``` config
...
LABEL WIN10PE
    KERNEL memdisk
    APPEND raw iso Iinitrd=http://192.168.1.1/WIN10PE.ISO
...
```
3. 感受飞一般的加载速度 (实机 + 将ISO放在/tmp中可达40\~50Mib/s (可能更快，我的ISO就180M))


+ **调整BCD文件内影响PXE的隐藏参数**  
1. 打开CMD cd 到 BCD 文件所在的目录下
2. 输入以下命令
```cmd
bcdedit /store BCD /set {ramdiskoptions} ramdisktftpblocksize 40960
bcdedit /store BCD /set {ramdiskoptions} ramdisktftpwindowsize 10
```
3. 复制 BCD 文件到路由器的 `/opt/pxe/boot` 文件夹内  
