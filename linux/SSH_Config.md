# SSH Config 常用配置翻译

## Host
**主机别名**  
可以使用通配符：`*` 代表0～n个非空白字符，`?` 代表一个非空白字符，`!`表示例外通配
### 配置项
|                    名称 |     中文解释     |                                     |
| ----------------------: | :--------------: | :---------------------------------- |
|              `HostName` |    主机名/IP     |                                     |
|                  `Port` |     主机端口     | 1-65535                             |
|                  `User` |  登录用的用户名  |                                     |
|          `IdentityFile` | 登录用的私钥文件 |                                     |
|          `ProxyCommand` |     代理命令     | Socks: `nc -x 127.0.0.1:1080 %h %p` |
|    `UserKnownHostsFile` | 认证主机缓存文件 |                                     |
| `StrictHostKeyChecking` | 是否确认主机密钥 |                                     |
|          `LocalForward` |     端口转发     |                                     |
|              `LogLevel` |     日志等级     |                                     |