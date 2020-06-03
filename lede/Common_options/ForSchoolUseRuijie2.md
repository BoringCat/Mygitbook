# 在路由器上跑minieap <!-- omit in toc -->
**备忘录**  

- [适用情况](#适用情况)
- [编译与安装](#编译与安装)
  - [获取源码（编译脚本）](#获取源码编译脚本)
  - [在SDK中编译](#在sdk中编译)
  - [在源码在编译（不建议）](#在源码在编译不建议)
  - [奇奇怪怪的方法](#奇奇怪怪的方法)
  - [安装](#安装)
- [配置（无LUCI）](#配置无luci)
- [配置（LUCI）](#配置luci)

## 适用情况
1. 学校升级了锐捷客户端，mentohust无法成功认证
2. 学校开启了客户端校验，mentohust无法成功认证
3. libpcap装不上的系统..............

## 编译与安装
### 获取源码（编译脚本）
在Git上拉[minieap-openwrt](https://github.com/BoringCat/minieap-openwrt))代码

```
git clone https://github.com/BoringCat/minieap-openwrt.git package/minieap
```

（可选）在Git上拉[luci-app-minieap](https://github.com/BoringCat/luci-app-minieap)代码

```
git clone https://github.com/BoringCat/luci-app-minieap.git package/luci-app-minieap
# 编译 po2lmo (如果有po2lmo可跳过)
git clone https://github.com/openwrt-dev/po2lmo.git
pushd po2lmo
make && sudo make install
popd
# 选择要编译的包 LuCI -> 3. Applications --> luci-app-minieap
```

### 在SDK中编译
1. 输入 `make defconfig` 输出默认配置文件

2. 输入`make package/minieap/compile V=s` 编译minieap包。若没有错误就可以使用 `find -name '*minieap*.ipk' -type f` 找到ipk文件)  
   **注意：SDK中不能直接输入`make`来编译所有包**


3. 安装ipk或安装固件

### 在源码在编译（不建议）
1. 输入`make menuconfig`，找到 Network--->Ruijie--->minieap 将其设定为 '<M\>' 编译为ipk，或 '<\*>' 安装到编译出的固件中

2. 若要编译整个系统，则可以输入`make V=s`(或`make -j$(cpu核心数+2)`)

3. 若只编译minieap，输入`make package/minieap/compile V=s` 。

4. 若没有错误就可以使用 `find -name '*minieap*.ipk' -type f` 找到ipk文件)  

### 奇奇怪怪的方法
* [配合 toolchain 使用方法（需要交叉编译基础）](https://github.com/BoringCat/minieap-openwrt#%E9%85%8D%E5%90%88-toolchain-%E4%BD%BF%E7%94%A8%E6%96%B9%E6%B3%95%E9%9C%80%E8%A6%81%E4%BA%A4%E5%8F%89%E7%BC%96%E8%AF%91%E5%9F%BA%E7%A1%80)


### 安装
（普通ipk安装.jpg）

## 配置（无LUCI）
请参考 [官方文档][1] 和 程序帮助 `minieap -h`

## 配置（LUCI）
未完成...............  
无法访问相应设备


[1]: https://github.com/updateing/minieap/blob/master/README.md