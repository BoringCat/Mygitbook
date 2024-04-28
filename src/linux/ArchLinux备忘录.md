# ArchLinux备忘录 <!-- omit in toc -->

## 升级Python版本
```sh
# 检查包
pacman -Qoq /usr/lib/python3.XX > /tmp/py3XX.txt
# 更新文件数据库
sudo pacman -Fy
# 获取没有更新Python版本的包
cat /tmp/py3XX.txt | xargs pacman -Fl 2>/tmp/aur3xx.txt | grep -Eo '[^ ]+ usr/lib/python3\.[0-9]+' | uniq | grep 'usr/lib/python3.XX' | cut -d' ' -f1
```
