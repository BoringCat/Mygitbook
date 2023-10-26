#!/bin/sh

[ -z "$1" ] && echo "使用方法: `basename $0` 网卡名" && exit 1
nic=$1
ip link show ${nic} > /dev/null
code=$?
[ ${code} -ne 0 ] && exit ${code}
HOST=$(ip addr show dev ${nic} | grep -Po "inet[ ]*(\d{1,3}\.){3}.(\d{1,3})"  | cut -d' ' -f2 | head -1)
echo "网卡 ${nic} 的IP地址是: ${HOST}"
read -n 1 -p "继续? [Y/n]" confirm
[ "${confirm}" == "" ] || echo 
[ "${confirm}" != "Y" ] && [ "${comfirm}" != "y" ] && echo No! && exit 1

confirm=''
if [ -f "/etc/docker/ca.pem" ] || \
[ -f "/etc/docker/server-cert.pem" ] || \
[ -f "/etc/docker/server-key.pem" ]; then
echo "检测到以下文件已存在:"
find /etc/docker/ca.pem /etc/docker/server-cert.pem /etc/docker/server-key.pem 2>/dev/null
read -n 1 -p "继续? [Y/n]" confirm
[ "${confirm}" == "" ] || echo 
[ "${confirm}" != "Y" ] && [ "${comfirm}" != "y" ] && echo No! && exit 1
fi

mkdir -p /tmp/dockertls
pushd /tmp/dockertls > /dev/null

echo "开始创建ca-key.pem，这需要输入一个密码，请在流程中牢记"
openssl genrsa -aes256 -out ca-key.pem 2048
echo "开始创建ca.pem，这需要输入ca-key.pem的密码"
echo "下面的任何问题都可以直接回车"
openssl req -new -x509 -days 3650 -key ca-key.pem -sha256 -out ca.pem
openssl genrsa -out server-key.pem 4096
# 创建服务器密钥和证书签名请求
openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
cat /dev/null > extfile.cnf
echo subjectAltName = DNS:$HOST,IP:$HOST >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
echo "开始创建server-cert.pem，这需要输入ca-key.pem的密码"
openssl x509 -req -days 3650 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf
# 创建客户端密钥和证书签名请求
openssl genrsa -out key.pem 2048
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
echo extendedKeyUsage = clientAuth > extfile-client.cnf
echo "开始创建cert.pem，这需要输入ca-key.pem的密码"
openssl x509 -req -days 3650 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile-client.cnf

echo 开始复制文件到 /etc/docker/ ，这可能需要你输入登录密码
if [ "$(id -u)" -eq 0 ]; then
    cp ca.pem server-cert.pem server-key.pem /etc/docker/
else
    sudo cp ca.pem server-cert.pem server-key.pem /etc/docker/
fi
echo
echo "你需要设置dockerd的参数: "
echo "    -H tcp://$HOST:2376"
echo "    --tlsverify \\"
echo "    --tlscacert=/etc/docker/ca.pem \\"
echo "    --tlscert=/etc/docker/server-cert.pem \\"
echo "    --tlskey=/etc/docker/server-key.pem"
echo
echo "你需要设置client的环境变量"
echo "DOCKER_HOST: tcp://$HOST:2376"
echo "DOCKER_TLS_VERIFY: 1"
echo
echo "你需要传输到client用户家目录下 .docker 中的文件:"
realpath ca.pem
realpath cert.pem
realpath key.pem
