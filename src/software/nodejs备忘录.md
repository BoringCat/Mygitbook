# NodeJs 备忘录

### docker-build
#### docker-build.sh
```sh
#!/bin/sh

cd `dirname $0`

docker build -f debug.dockerfile -t boringcat/node_vue:lts-alpine .
```

#### debug,dockerfile
```dockerfile
FROM node:lts-alpine

ARG apkmirrror=mirrors.sjtug.sjtu.edu.cn

RUN sed -i "s/dl-cdn.alpinelinux.org/${apkmirrror}/g" /etc/apk/repositories && \
    apk add --no-cache --update git && \
    yarn global add @vue/cli

COPY docker-entrypoint.sh /
COPY vue_antdv_create /usr/local/bin/

ENTRYPOINT [ "/docker-entrypoint.sh" ]
```

#### docker-entrypoint.sh
```sh
#!/bin/sh

[ -z "$U_ID" ] && U_ID=0
[ -z "$G_ID" ] && G_ID=0

[ $U_ID -eq 0 ] && exec /bin/sh

grep -E ".*:x:$U_ID:.*" /etc/passwd > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "$U_ID:x:$U_ID:$G_ID::/home/$U_ID:/bin/sh" >> /etc/passwd
else
    sed -i -Ee "s/.*:x:$U_ID:\d+:(.*)/$U_ID:x:$U_ID:$G_ID:\1/g" /etc/passwd
fi

grep -E ".*:x:$U_ID:.*" /etc/passwd > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "$G_ID:x:$G_ID:$U_ID" >> /etc/group
else
    sed -i -Ee "s/.*:x:$G_ID:(.*)/$G_ID:x:$G_ID:\1,$U_ID/g" /etc/group
fi

exec su -s /bin/sh $U_ID
```

#### vue_antdv_create
```sh
#!/bin/sh

pwd

vue create .
yarn add ant-design-vue babel-plugin-import

cat > babel.config.js << EOF
module.exports = {
  presets: [
    '@vue/app'
  ],
  plugins: [
    [
      "import",
      { libraryName: "ant-design-vue", libraryDirectory: "es", style: "css" }
    ]
  ]
}
EOF

sed -i '/"serve": /i \ \ \ \ "start": "vue-cli-service serve --port 3000 --host 0.0.0.0",' package.json
```

### docker-run.sh
```sh
#!/bin/sh
cd `dirname $0`

_DOCKER_BASENAME='vue'
_DOCKER_IMGNAME='boringcat/node_vue'
U_ID=`id -u $USERNAME`
G_ID=`id -g $USERNAME`

case $1 in
    '-l')
        [ -z $2 ] && COMMAND=$1 || LISTEN=$2 && COMMNAD=$3
    ;;
    *)
        COMMNAD=$1
        if [ ! -z $2 ] && [ "$2" = "-l" ]; then
            LISTEN=$3
        fi
    ;;
esac
[ -z "$LISTEN" ] && LISTEN="127.0.0.1"


[ -z "$COMMAND" ] && COMMAND="start"

__FRONTEND__=${PWD##*/}
__DIRNAME__=`dirname $PWD`

create() {
    docker create --name=${_DOCKER_BASENAME}_debug_${__FRONTEND__}\
    -v ${__DIRNAME__}:/app\
    -w /app/${__FRONTEND__}\
    -p $LISTEN:3000:3000\
    -e U_ID=$U_ID\
    -e G_ID=$G_ID\
    -e HOST='0.0.0.0' -it ${_DOCKER_IMGNAME}:lts-alpine
}

start(){
    docker image inspect ${_DOCKER_IMGNAME}:lts-alpine > /dev/null 2>/dev/null
    [ $? -ne 0 ] && ./docker-build.sh
    docker container inspect ${_DOCKER_BASENAME}_debug_${__FRONTEND__} > /dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
        create
    else
        OLDLISTEN=$(docker container inspect ${_DOCKER_BASENAME}_debug_${__FRONTEND__} --format="{{json .HostConfig.PortBindings}}" | jq -r '.[][0].HostIp')
        CHANGEID=$(docker container inspect ${_DOCKER_BASENAME}_debug_${__FRONTEND__} --format="{{json .Config.Env}}" | jq -r '.[]' | grep U_ID=$U_ID)
        UPDATE=$(docker image inspect `docker container inspect vue_debug_frontend --format="{{ .Image }}" | cut -d: -f2` --format="{{json .RepoTags}}" | jq -r '.[]')
        [ "$OLDLISTEN" != "$LISTEN" ] && rm && create
        [ -z "$CHANGEID" ] && rm && create
        [ -z "$UPDATE" ] && rm && create
    fi
    docker start -ia ${_DOCKER_BASENAME}_debug_${__FRONTEND__}
}

rm(){
    docker container rm ${_DOCKER_BASENAME}_debug_${__FRONTEND__}
}

case $COMMAND in
    'start' ) 
        start
    ;;
    'rm' )
        rm
    ;;
    'recreate' )
        rm && start
    ;;
    *)
        echo "Usage: $0 [start|rm|recreate]"
    ;;
esac
```

### ngind_debug.local.sh
```sh
#!/bin/sh

cd `dirname $0`

Container_Name="${PWD##*/}-nginx-debug"
Container_Status=`docker container inspect ${Container_Name} --format "{{.State.Status}}" 2>/dev/null`
[ "${Container_Status}" = "running" ] && exec docker attach ${Container_Name}

exec docker run\
    -v ${PWD}/nginx.local.conf:/etc/nginx/conf.d/debug.conf:ro\
    -v /dev/null:/etc/nginx/conf.d/default.conf:ro\
    --network=host\
    --name="${Container_Name}"\
    --rm -it nginx:alpine nginx -g "daemon off;"
```

#### nginx.local.conf
```conf
server {
    listen 8080;
    location /ncauth/api {
        proxy_pass_request_headers  on;
        proxy_http_version          1.1;
        proxy_set_header            Upgrade $http_upgrade;
        proxy_set_header            Connection "Upgrade";
        proxy_set_header            Host $host;
        proxy_pass                  http://127.0.0.1:5000;
    }
    location / {
        proxy_pass_request_headers  on;
        proxy_set_header            Upgrade $http_upgrade;
        proxy_set_header            Connection "Upgrade";
        proxy_set_header            Host $host;
        proxy_pass                  http://127.0.0.1:3000;
    }
}
```
