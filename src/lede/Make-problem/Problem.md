## LEDE编译的问题与解决方案 <!-- omit in toc -->
(或可用于OpenWrt)  

**本文的所有问题都是在编译LEDE时遇到的**  

### 标题 <!-- omit in toc -->

- [ArchLinux](#archlinux)
  - [**停在 ./stage1flex -o stage1scan.c ./scan.l**](#停在-stage1flex--o-stage1scanc-scanl)
  - [**在编译 e2fsprogs/debugfs 时 create_inode.o 报错**](#在编译-e2fsprogsdebugfs-时-create_inodeo-报错)
  - [**OpenWrt 18.06.1 SDK 更新feed报错**](#openwrt-18061-sdk-更新feed报错)
  - [**OpenWrt 18.06.1 SDK 第一次Make任意包时出错**](#openwrt-18061-sdk-第一次make任意包时出错)
  - [**OpenWrt 18.06.1 SDK 编译MentoHUST出错**](#openwrt-18061-sdk-编译mentohust出错)
- [Centos 7](#centos-7)
  - [**在编译 gcc 时 libgcc/unwind-dw2.c 报错**](#在编译-gcc-时-libgccunwind-dw2c-报错)

---

## ArchLinux
### **停在 ./stage1flex -o stage1scan.c ./scan.l**  
默认情况下执行 `make V=s` 会出现以下情况
```
...  
./stage1flex -o stage1scan.c ./scan.l  
...  
(make fail)
```
没有任何错误提示，Google完全没有答案(￣△￣；)  
经过千辛万苦终于找到解决方案：  
将与此MarkDown文件位于同一目录下的 [`200-build-AC_USE_SYSTEM_EXTENSIONS-in-configure.ac.patch`](200-build-AC_USE_SYSTEM_EXTENSIONS-in-configure.ac.patch) 复制到编译目录的 `tools/flex/patches/` 下  
``` shell
cp 200-build-AC_USE_SYSTEM_EXTENSIONS-in-configure.ac.patch $CodePath/tools/flex/patches/
```

---

### **在编译 e2fsprogs/debugfs 时 create_inode.o 报错**  
```
执行 `make V=s` 到 `making all in debugfs` 后报错：
make[6]: Entering directory '/home/boringcat/BPI/R2/LEDE/bpi-r2_lede/build_dir/host/e2fsprogs-1.43.5/debugfs'
./../misc/create_inode.c:399:18: error: conflicting types for 'copy_file_range'
 static errcode_t copy_file_range(ext2_filsys fs, int fd, ext2_file_t e2_file,
                  ^~~~~~~~~~~~~~~
In file included from ./../misc/create_inode.c:19:
/usr/include/unistd.h:1110:9: note: previous declaration of 'copy_file_range' was here
 ssize_t copy_file_range (int __infd, __off64_t *__pinoff,
         ^~~~~~~~~~~~~~~
make[6]: *** [Makefile:423: create_inode.o] Error 1
...
```
Google到这是 glibc 升级到 2.27 后导致的  
查看glibc版本的方法：`ldd --version` 或通过包管理器参看  
解决方案：(来源：<a href="http://xetal.ddns.net:81/Kinsei/Xetal7688/Xetal7688-Lede/commit/58a95f0f8ff768b43d68eed2b6a786e0f40f723b" target="_blank">tools/e2fsprogs: fix building on a glibc 2.27 host (58a95f0f) · Commits · XetalKinsei / Xetal7688 / Xetal7688-Lede · GitLab</a>)  
将与此MarkDown文件位于同一目录下的 [`005-misc-rename-copy_file_range-to-copy_file_chunk.patch`](005-misc-rename-copy_file_range-to-copy_file_chunk.patch) 复制到编译目录的 `tools/e2fsprogs/patches/` 下  
``` shell
cp 005-misc-rename-copy_file_range-to-copy_file_chunk.patch $CodePath/tools/e2fsprogs/patches/
```  

---

### **OpenWrt 18.06.1 SDK 更新feed报错**  
执行 `./scripts/feeds update -a` 在 git clone 完成后报错
``` shell
Create index file './feeds/base.index' 
.xargs.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
.sed.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
.find.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
.xargs.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
.sed.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
.sed.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
Collecting package info: merging.../bin/sh: 行 1:  5424 已完成               cat /home/boringcat/rother/x86/openwrt-sdk-18.06.1.Linux-x86_64/feeds/base.tmp/info/.files-packageinfo-4916
      5425                       | awk '{gsub(/\//, "_", $0);print "/home/boringcat/rother/x86/openwrt-sdk-18.06.1.Linux-x86_64/feeds/base.tmp/info/.packageinfo-" $0}'
      5426 已放弃               (核心已转储)| xargs cat > /home/boringcat/rother/x86/openwrt-sdk-18.06.1.Linux-x86_64/feeds/base.tmp/.packageinfo 2> /dev/null
Collecting package info: done
.xargs.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
.find.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
.sed.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
.xargs.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
.sed.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
.sed.bin: loadlocale.c:129: _nl_intern_locale_data: Assertion `cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' failed.
Collecting target info: merging.../bin/sh: 行 1:  5576 已完成               cat /home/boringcat/rother/x86/openwrt-sdk-18.06.1.Linux-x86_64/feeds/base.tmp/info/.files-targetinfo-4916
      5577                       | awk '{gsub(/\//, "_", $0);print "/home/boringcat/rother/x86/openwrt-sdk-18.06.1.Linux-x86_64/feeds/base.tmp/info/.targetinfo-" $0}'
      5578 已放弃               (核心已转储)| xargs cat > /home/boringcat/rother/x86/openwrt-sdk-18.06.1.Linux-x86_64/feeds/base.tmp/.targetinfo 2> /dev/null
Collecting target info: done
```
谷歌到解决这个问题需要设置 `LC_ALL=C` 原因..................找不到.............  
输入 `export LC_ALL=C` 后再执行 `./scripts/feeds update -a` 一切正常  
_**PS：建议在新终端内执行，不然你的补全将变得很奇怪 (特别是oh-my-zsh)**_

---

### **OpenWrt 18.06.1 SDK 第一次Make任意包时出错**  
不管是什么包，第一次make都要先编译工具链 (toolchain)，而编译时又报错：
``` shell
env: 'time': No such file or directory
```
这是缺少GNU time的原因 <a href="https://bugs.openwrt.org/index.php?do=details&task_id=1918&status%5B0%5D=&pagenum=2" target="_blank">(原文地址)</a> 安装相应包就好了  
例如 Archlinux 就是安装 time 包

---

### **OpenWrt 18.06.1 SDK 编译MentoHUST出错**  
在确认执行 `./scripts/feeds install libpcap` 并且确认输出 Installing package 'libpcap' from base 后，编译MentoHUST报错：
``` shell
x86_64-openwrt-linux-musl-gcc: error: /home/boringcat/rother/x86/openwrt-sdk-18.06.1-x86-64_gcc-7.3.0_musl.Linux-x86_64/build_dir/target-x86_64_musl/libpcap-*/ipkg-install/usr/lib/libpcap.a: No such file or directory
```
原因是文件目录结构及文件名改变，可能是libpcap的源码更改  
解决方法(步骤)：  
1. 找到Makefile文件：package/MentoHUST-OpenWrt-ipk/src
2. 替换 "ipkg-install/" 为".pkgdir/libpcap/"
3. 替换 "libpcap.a" 为 "libpcap.so"

---

## Centos 7
### **在编译 gcc 时 libgcc/unwind-dw2.c 报错**  
选中 `Development ---> gcc` 后执行 `make V=s` 或 `make package/gcc/compile` 后出现以下情况
``` shell
../.././libgcc/unwind-dw2.c:41:21: fatal error: sys/sdt.h: No such file or directory
```
Google到这是由于安装了 systemtap-sdt-devel 导致的  
unwind-dw2.c 文件的第40-42行，如果有安装sdt则引用 sys/sdt.h ：
``` C
#ifdef HAVE_SYS_SDT_H
#include <sys/sdt.h>
#endif
```
但交叉编译的 include/sys 文件夹里面没有 sdt.h 头文件，于是报错  
解决方案：将系统的 sdt.h 文件链接到 include/sys 内  
<a href="https://github.com/openwrt/packages/issues/296#issuecomment-371704322" target="_blank">原句</a>:`create soft link from system /usr/include/sys/sdt.h to openwrt statding_dir/toolchain/include/sys/sdt.h`  
以X86为例  
``` shell
ln -s /usr/include/sys/sdt.h staging_dir/toolchain-x86_64_gcc-5.4.0_musl-1.1.16/include/sys/sdt.h
```