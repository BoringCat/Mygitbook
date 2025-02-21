# 解决 Container Station3 LXD权限问题 <!-- omit in toc -->

- [清空目录richacl](#清空目录richacl)

## 清空目录richacl
1. 找到 container-station-data 文件夹路径
2. 切换到 admin
   ```
   sudo -i
   ```
3. 进入 container-station-data 文件夹的 lxd 存储
   ```
   cd /share/Container/container-station-data/lib/lxd/
   ```
4. 清除 containers 目录的 acl  
  `richacl -D containers`
5. 清除 storage-pools/default/containers 目录的 acl  
  `richacl -D storage-pools/default/containers`
