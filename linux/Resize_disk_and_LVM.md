## 调整磁盘大小及其上面的LVM

### 0. 前言
**WTM知道LVM可以添加硬盘扩容！  
WTM也知道分区大小可以扩大！  
WTM知道在LVM上添加无数个虚拟硬盘不会影响性能！  
但是哪个运维会这样子干啊！  
最后几十个PV的LVM谁敢维护啊！**

### 1. 操作
首先，/dev/mapper/iscsi-storage-srv 是已经被格式化为xfs系统的LV  
1. 挂载 /dev/mapper/iscsi-storage-srv 到 /srv 上  
``` shell
root@service:~# mount /dev/mapper/iscsi-storage-srv /srv
root@service:~# lsblk /dev/sdb
sdb                      8:16   0   99G  0 disk 
└─sdb1                   8:17   0   99G  0 part 
  └─iscsi-storage-srv 254:3    0   99G  0 lvm  /srv
```
2. 确认挂载成功，输出xfs信息
``` shell
root@service:~# xfs_info /dev/mapper/iscsi--storage-srv 
meta-data=/dev/mapper/iscsi--storage-srv isize=512    agcount=4, agsize=6553344 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1 spinodes=0 rmapbt=0
         =                       reflink=0
data     =                       bsize=4096   blocks=26213376, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal               bsize=4096   blocks=12799, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```
3. 在虚拟机上拓展磁盘到100G，接着重新扫描磁盘  
（我是通过SSH操作的，这里把dmesg的信息拷贝了过来）
``` shell
root@service:~# echo 1 > /sys/block/sdb/device/rescan 
[  635.424954] sd 0:0:1:0: [sdb] 209715200 512-byte logical blocks: (107 GB/100 GiB)
[  635.424959] sd 0:0:1:0: [sdb] 4096-byte physical blocks
[  635.426115] sdb: detected capacity change from 106300440576 to 107374182400
```
4. 通过 `lsblk` 确认磁盘大小
``` shell
root@service:~# lsblk /dev/sdb
NAME                   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdb                      8:16   0  100G  0 disk 
└─sdb1                   8:17   0   99G  0 part 
  └─iscsi-storage-srv 254:3    0   99G  0 lvm  /srv
```
5. 通过 `parted` 调整分区大小  
   注意：通过 `parted` 的 `resizepart` 命令调整分区大小需要先通过 `print free` 来查看空闲区域的末尾位置。这里我没有调整单位大小，就在107GB后面随便加了个'.6'来确保分区末尾在磁盘的末尾。  
   可以使用`unit B`调整单位大小为B  
   另外，使用gpt分区表的话，会提示gpt分区表没有占满整个硬盘，询问是否修复？这里一定要修复，不然无法使用那部分空间。
``` shell
root@service:~# parted /dev/sdb
GNU Parted 3.2
Using /dev/sdb
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) print free                                                       
Warning: Not all of the space available to /dev/sdb appears to be used, you can fix the GPT to use all of the space (an extra 2097152 blocks) or continue with the current setting? 
Fix/Ignore? Fix                                                           
Model: MSFT Virtual HD (scsi)
Disk /dev/sdb: 107GB
Sector size (logical/physical): 512B/4096B
Partition Table: gpt
Disk Flags: 

Number  Start   End     Size    File system  Name  Flags
        17.4kB  1049kB  1031kB  Free Space
 1      1049kB  106GB   106GB                      lvm
        106GB   107GB   1074MB  Free Space

(parted) resizepart 1 107.6GB                                             
(parted) print free
Model: MSFT Virtual HD (scsi)
Disk /dev/sdb: 107GB
Sector size (logical/physical): 512B/4096B
Partition Table: gpt
Disk Flags: 

Number  Start   End     Size    File system  Name  Flags
        17.4kB  1049kB  1031kB  Free Space
 1      1049kB  107GB   107GB                      lvm

(parted) q                                                                
Information: You may need to update /etc/fstab.
```
6. 通过 `lsblk` 确认分区大小
``` shell
root@service:~# lsblk /dev/sdb                                                     
NAME                   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdb                      8:16   0  100G  0 disk 
└─sdb1                   8:17   0  100G  0 part 
  └─iscsi-storage-srv 254:3    0   99G  0 lvm  /srv
```
7. 调整PV大小
``` shell
root@service:~# pvdisplay /dev/sdb1
  --- Physical volume ---
  PV Name               /dev/sdb1
  VG Name               iscsi-storage
  PV Size               99.00 GiB / not usable 2.98 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              25343
  Free PE               0
  Allocated PE          25343
  PV UUID               bE4qfW-Wz4M-PSUf-PD3d-eHMK-pCtt-PCEWLe
   
root@service:~# pvresize /dev/sdb1
  Physical volume "/dev/sdb1" changed
  1 physical volume(s) resized / 0 physical volume(s) not resized
root@service:~# pvdisplay /dev/sdb1
  --- Physical volume ---
  PV Name               /dev/sdb1
  VG Name               iscsi-storage
  PV Size               100.00 GiB / not usable 1.98 MiB
  Allocatable           yes 
  PE Size               4.00 MiB
  Total PE              25599
  Free PE               256
  Allocated PE          25343
  PV UUID               bE4qfW-Wz4M-PSUf-PD3d-eHMK-pCtt-PCEWLe
```
8. 调整LV大小（使用 -r 同时调整 xfs 分区的大小）
``` shell
root@service:~# lvresize -l +100%FREE /dev/iscsi-storage/srv -r
  Size of logical volume iscsi-storage/srv changed from 99.00 GiB (25343 extents) to 100.00 GiB (25599 extents).
  Logical volume iscsi-storage/srv successfully resized.
meta-data=/dev/mapper/iscsi-storage-srv isize=512    agcount=4, agsize=6487808 blks
         =                       sectsz=4096  attr=2, projid32bit=1
         =                       crc=1        finobt=1 spinodes=0 rmapbt=0
         =                       reflink=0
data     =                       bsize=4096   blocks=25951232, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal               bsize=4096   blocks=12671, version=2
         =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 25951232 to 26213376
```
9. 通过 `lsblk` 确认分区大小
``` shell
root@service:~# lsblk /dev/sdb
NAME                   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdb                      8:16   0  100G  0 disk 
└─sdb1                   8:17   0  100G  0 part 
  └─iscsi-storage-srv 254:3    0  100G  0 lvm  /srv
```
9. 通过 `df -h` 确认文件系统大小
``` shell
root@service:~# df -h /srv/
Filesystem                      Size  Used Avail Use% Mounted on
/dev/mapper/iscsi-storage-srv  100G  159M  100G   1% /srv
```
### 2. 总结(杂谈)
在写这篇记录的时候，一位运维的朋友跟我说现实中不会有这种情况的，有也是一下子加几十上百G的空间，VG再大的也不会塞几十个PV进去。但谁知道你老板会怎么叫你加空间啊？万一每次他觉得只加个10G就够了，或者只能给你10G，以后要再加，那怎么办？  
我写这篇记录，只是为了记住这次实践而已。也只是好奇虚拟化技术出来这么久了，也没有前人弄个类似的方案写成文档。难道拓展容量真的是加虚拟硬盘吗？