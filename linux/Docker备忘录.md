# Docker备忘录 <!-- omit in toc -->

## daemon.json
''' json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "registry-mirrors": [

    ],
    "storage-driver": "overlay2"
}
'''

## systemd tcp
``` systemd
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375 --containerd=/run/containerd/containerd.sock
```

## tls
``` sh
openssl genrsa -aes256 -out ca-key.pem 2048
openssl req -new -x509 -days 3650 -key ca-key.pem -sha256 -out ca.pem
openssl genrsa -out server-key.pem 2048
# 创建服务器密钥和证书签名请求
HOST=""
openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
cat /dev/null > extfile.cnf
echo subjectAltName = DNS:$HOST,IP:$HOST:127.0.0.1 >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
openssl x509 -req -days 3650 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf
# 创建客户端密钥和证书签名请求
openssl genrsa -out key.pem 2048
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
echo extendedKeyUsage = clientAuth > extfile-client.cnf
openssl x509 -req -days 3650 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile-client.cnf
```
``` systemd
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --tlsverify --tlscacert=/etc/docker/ca.pem --tlscert=/etc/docker/server-cert.pem --tlskey=/etc/docker/server-key.pem -H fd:// -H tcp://0.0.0.0:2376 --containerd=/run/containerd/containerd.sock
```