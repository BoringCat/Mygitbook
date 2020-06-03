# 让Win7更加好看  <!-- omit in toc -->
## 为什么是Win7？ 这就是社会的毒打  <!-- omit in toc -->
![我草啊垃圾win7](../.gitbook/assets/Windows_GodDamnIt.jpg)

- [1. 背景优化](#1-背景优化)
- [2. 终端优化](#2-终端优化)
- [3. 截屏](#3-截屏)

## 1. 背景优化
- 用你喜欢的背景换
- Wallpaper Engine
  - adwaita 系列 （推荐）（WEB框架巨量内存警告）

## 2. 终端优化
- Cmder
  1. 下载安装  
    去 [Cmder | Console Emulator][1] 下载 Mini 版  
    解压下载到的zip文件到你喜欢的目录下  
    （可选）到解压目录下运行 `cmder.exe /REGISTER ALL` 将 Cmder 注册到右键菜单中

  2. 配置  
    - 语言: General->Interface language -> zh:简体中文  

    - 字体: 通用 -> 字体 (推荐字体: DejaVu Sans Mono(英文)， 文泉驿等宽微米黑(中文)  
    - （可选）符合Linux终端的按键:  
      取消“复制：当前HTML格式的选择”、“选择和粘贴文件路径名”  
      设置“复制：将当前选区复制为普通文本(Ctrl+Shift+C)”、“粘贴剪切板的内容(Ctrl+Shift+V)”、“在活动控制台查找文本(Ctrl+Shift+F)”

    - （可选）默认终端: setting -> 集成 -> 默认项目 -> 强制使用ConEmu作为控制台应用程序的默认终端  

    - （可选）PowerLine(参考["深度定制Cmder#配置-cmd"][2]):  
      前往 [AmrEldib/cmder-powerline-prompt][3] 下载配置文件  
      将配置文件(powerline_*.lua)拷贝到 cmder 目录下的 `config` 文件夹  
      拷贝 `_powerline_config.lua.example` 到cmder 目录下的 `config` 文件夹，并重命名为 `_powerline_config.lua`  
      （可选）修改 _powerline_config.lua 和 powerline_core.lua 类似于  
      _powerline_config.lua:  
      ```
      newLineSymbol = ""
      ```
      powerline_core.lua:  
      ```
      if not newLineSymbol then 
          newLineSymbol = "\n"
      end 
      ```
      使得终端更像Linux
    - （可选）与Visual Studio Code对接:  
      添加这些配置:  
      ```
      "terminal.integrated.shell.windows": "cmd.exe",
      "terminal.integrated.shellArgs.windows": [
          "/k",
          "$(path to cmder)\\vendor\\bin\\vscode_init.cmd"
      ],
      ```


## 3. 截屏
- 微信，QQ，企业微信截屏
- 

[1]: https://cmder.net/
[2]: https://www.thisfaner.com/p/custom-cmder/#配置-cmd
[3]: https://github.com/AmrEldib/cmder-powerline-prompt