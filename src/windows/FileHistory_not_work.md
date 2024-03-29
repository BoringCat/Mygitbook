## 文件历史记录备份不工作的问题
### 现象
+ 之前有备份，但是某一天突然就不行(指我自己)
+ 备份一直为0，或者点击后迅速完成
+ **保留文件**重置系统
+ **备份文件**重装也不行
+ 在 `事件查看器->应用程序和服务日志->Microsoft->Windows->FileHistory-Engine` 里看到日志

| 级别  | 事件ID |
| :---: | :----: |
| ❗错误 |  201   |

  详细信息：
  ``` txt
  在完成配置 C:\Users\$username\AppData\Local\Microsoft\Windows\FileHistory\Configuration\Config 的备份周期时遇到异常情况
  ```

### 问题原因
原文：<a href="https://answers.microsoft.com/zh-hans/windows/forum/windows_8-security/%E5%8E%86%E5%8F%B2%E6%96%87%E4%BB%B6%E8%AE%B0/d200311e-9329-4355-8383-5c0e4948dbbb?messageId=3eebf5e6-a85b-4818-b0b2-c4bf692d118d" target="_blank">历史文件记录的备份功能为何不能正常使用</a>

很有可能是因为需要备份的某些文件夹中包含的文件或文件夹名称中带有无法支持的字符，导致该功能无法正常工作。

由于无法判断具体是哪个文件夹，因此建议使用文件历史记录功能的排除功能，将需要备份的内容中的每个主文件夹挨个排除，一次排除一个，然后看该功能是否可以恢复正常。如果可以，则继续检查对应的主文件夹中是否有包含特殊字符的子文件夹或文件。

### 解决方案
+ 猜是那个文件夹里面出现特殊字符
+ 一个个排查

### 历史经验(可能的文件夹)
+ Onedrive
+ .atom