# SSH Config 常用配置翻译 <!-- omit in toc -->

- [Host](#host)
  - [配置项](#配置项)
- [特殊解释](#特殊解释)
  - [LocalForward](#localforward)
  - [RemoteForward](#remoteforward)

## Host
**主机别名**  
可以使用通配符：`*` 代表0～n个非空白字符，`?` 代表一个非空白字符，`!`表示例外通配
### 配置项
|                    名称 |     中文解释     |                                     |
| ----------------------: | :--------------: | :---------------------------------- |
|              `HostName` |    主机名/IP     | - |
|                  `Port` |     主机端口     | 1-65535                             |
|                  `User` |  登录用的用户名  | - |
|          `IdentityFile` | 登录用的私钥文件 | - |
|          `ProxyCommand` |     代理命令     | Socks: `nc -x 127.0.0.1:1080 %h %p` |
|    `UserKnownHostsFile` | 认证主机缓存文件 | - |
| `StrictHostKeyChecking` | 是否确认主机密钥 | - |
|          `LocalForward` | 远程端口转发到本地 | `本地主机的端口 远程主机的地址/IP:远程主机的端口` |
|         `RemoteForward` | 本地端口转发到远程 | `远程主机的端口 目的主机的地址/IP:目的主机的端口` |
|              `LogLevel` |     日志等级     | - |

## 特殊解释
### LocalForward
```
18080 127.0.0.1:8080
-------------         -------------
|  本地主机  |   ssh   |  远程主机  |
|   18080   | ------> |    8080   |
-------------         -------------
```
访问本地主机的18080相当于访问远程主机的8080

```
18080 172.17.0.2:80
-------------         -------------         -------------
|  本地主机  |   ssh   |  远程主机  |   TCP   |  远程主机2 |
|   18080   | ------> |           | ------> |     80    |
-------------         -------------         -------------
```
访问本地主机的18080相当于访问远程主机2 的 80

### RemoteForward
```
18080 127.0.0.1:8080
-------------         -------------
|  本地主机  |   ssh   |  远程主机  |
|    8080   | ------> |   18080   |
-------------         -------------
```
访问远程主机的18080相当于访问本地主机的8080

```
18080 172.17.0.2:80
-------------         -------------
|  本地主机  |   ssh   |  远程主机  |
|           | ------> |   18080   |
-------------         -------------
      | TCP
      v
-------------
|  远程主机2 |
|     80    |
-------------
```
访问远程主机的18080相当于访问远程主机2 的 80