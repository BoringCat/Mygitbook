# ArchLinux备忘录 <!-- omit in toc -->

- [配置Bitwarden为系统SSH Agnet](#配置bitwarden为系统ssh-agnet)
- [升级Python版本](#升级python版本)
- [字体](#字体)
  - [软件包](#软件包)
  - [配置](#配置)
- [zram](#zram)

## 配置Bitwarden为系统SSH Agnet
1. 设置里开启  
   ![启用SSH Agent](/assets/linux/20251027-Bitwarden启用SSHAgent.png)
2. 配置环境变量
   - rc文件
     ```sh
     if [[ -e "$HOME/.bitwarden-ssh-agent.sock" ]]; then
       export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
     elif [[ -e "${XDG_RUNTIME_DIR}/ssh-agent.socket" ]]; then
       export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
     fi
     ```
   - systemd  
     创建文件 `~/.config/environment.d/ssh-agent.conf`  
     ```ini
     SSH_AUTH_SOCK=$HOME/.bitwarden-ssh-agent.sock
     ```

## 升级Python版本
```sh
# 检查包
pacman -Qoq /usr/lib/python3.XX > /tmp/py3XX.txt
# 更新文件数据库
sudo pacman -Fy
# 获取没有更新Python版本的包
cat /tmp/py3XX.txt | xargs pacman -Fl 2>/tmp/aur3xx.txt | grep -Eo '[^ ]+ usr/lib/python3\.[0-9]+' | uniq | grep 'usr/lib/python3.XX' | cut -d' ' -f1
```

## 字体
### 软件包
```sh
pacman -S adobe-source-code-pro-fonts adobe-source-han-sans-cn-fonts\
 adobe-source-han-sans-otc-fonts adobe-source-han-serif-cn-fonts\
 adobe-source-han-serif-otc-fonts cantarell-fonts gsfonts noto-fonts\
 noto-fonts-cjk noto-fonts-emoji powerline-fonts ttf-dejavu ttf-hack\
 ttf-opensans ttf-roboto wqy-microhei wqy-microhei-lite wqy-zenhei\
 xorg-font-util xorg-fonts-100dpi xorg-fonts-75dpi xorg-fonts-alias-100dpi\
 xorg-fonts-alias-75dpi xorg-fonts-encodings
```

### 配置
[local.conf](./configs/fonts-local.conf)

## zram
- 引导参数  
  `zswap.enabled=0`
- /etc/modules-load.d/zram.conf
  ```
  zram
  ```
- /etc/modprobe.d/zram.conf
  ```
  options zram num_devices=2
  ```
- /etc/udev/rules.d/99-zram.rules
  ```
  ACTION=="add", KERNEL=="zram0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="24G", RUN="/usr/bin/mkswap -U clear /dev/%k",     TAG+="systemd"
  ACTION=="add", KERNEL=="zram1", ATTR{comp_algorithm}="zstd", ATTR{disksize}="8G",  RUN="/usr/bin/mkfs.xfs -b size=4k /dev/%k", TAG+="systemd"
  ```
- /etc/fstab
  ```
  # zram0
  /dev/zram0 none swap defaults,pri=100          0 0
  # zram1
  /dev/zram1 /tmp xfs  rw,noatime,discard,nouuid 0 0
  ```