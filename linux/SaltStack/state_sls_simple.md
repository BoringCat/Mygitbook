# 对SaltStack state.sls的理解
## 1. 简单环境
### 1. 初始化
#### /etc/salt/master
1. 找到下列行
   ```yaml
   # file_roots:
   #   base:
   #     - /srv/salt/
   ```
2. 取消注释即可

   注： 可指定多目录，每个根目录下需要有 `top.sls`

3. 修改后需要重启 `salt-master` (在 systemd 环境下没有发现 ExecReload)

#### /srv/salt/top.sls
官方文档: [THE TOP FILE](https://docs.saltstack.com/en/master/ref/states/top.html)

1. 基础配置（最简单方便的配置）
   ```yaml
   base:
     '*':
       - cpfile
       - cmd.dfh
       - .....(这里跟模块名)
   ```

   修改此文件和模块文件均不需要重启 `salt-master`

   模块名格式为: `文件夹名.文件名` 或 `文件夹名` （匹配该文件夹下所有模块）

2. 高级配置（差异化运行模块）  
   以以下示例文件为例（为了方便给出具体文件名）：
   ```yaml
   base:
     '*':
       - cmd
     'webserver*':
       - nginx
       - apache2
       - caddy
     'db*':
       - mysql
       - mongodb
   ```

   现在假设有以下机器，给出机器可以执行的命令：
   ||manager|webserver_proxy|webserver_tomcat1|db_data|db_config|db_logs|
   |-:|:-:|:-:|:-:|:-:|:-:|:-:|
   |cmd|✔|✔|✔|✔|✔|✔|
   |nginx|❌|✔|✔|❌|❌|❌|
   |apache2|❌|✔|✔|❌|❌|❌|
   |caddy|❌|✔|✔|❌|❌|❌|
   |mysql|❌|❌|❌|✔|✔|✔|
   |mongodb|❌|❌|❌|✔|✔|✔|

   这样子就避免了手贱执行 `salt '*' state.sls mysql.install` 的时候帮所有机子装上mysql了

   当然你也可以通过这种方式来指定哪种服务器可以运行什么模块（不过这一般不是用 `pillar` + jinja2模板 判断吗？）
   ```yaml
   base:
     'webserver*':
       'proxy':
         - nginx
       'tomcat*':
         - apache2
       '*-text':
         - caddy
   ```

