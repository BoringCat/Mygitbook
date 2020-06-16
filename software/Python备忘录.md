# Python 备忘录

## 编译依赖 Python 3.8.3
### Centos 7
- openssl-devel
- sqlite-devel  (_sqlite)
- libffi-devel  (_ctype)
- libbz2-devel
- gperftools-devel

## pip
``` sh
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

## 常用包
- gnureadline (Custom Build)
  - ncurses-devel
- ipython (Windows)
- powerline-status (Oh-my-zsh)
- pylint (VsCode)
- virtualenv
- 
## venv 项目配置
### setupenv.sh
```sh
#!/bin/bash

SOURCE=$(command -v source)

[ -z "$SOURCE" ] && echo "You can't use this shell! Please change another one!" && exit 1

cd `dirname $0`

source ./envsetting.sh

PY3_VERSION=$(python3 -V | cut -d' ' -f2| cut -d. -f1-2 | sed 's/\.//g')

create(){
    if [ ! -d "$AIM" ]; then python3 -m virtualenv -p $(command -v python3) --no-download $AIM; fi
}

update(){
    source $AIM/bin/activate
    pip install -U pip wheel setuptools pylint $BACKEND $API $LIBS
    [ $PY3_VERSION -gt 37 ] && venvlib=$(realpath .venv/lib/python3.*/site-packages) || venvlib=$(realpath .venv/lib/python3.*)
    for py in libs/*.py
    do
    ln -rvsf $py ${venvlib}/
    done
    deactivate
}

del(){
    rm -r $AIM
}

COMMAND=$1
AIM=$2
[ -z $COMMAND ] && COMMAND='create'
[ -z $AIM ] && AIM='.venv'

case $COMMAND in
    'create')
        create
        update
    ;;
    'update')
        update
    ;;
    'recreate')
        del
        create
        update
    ;;
esac
```

### envsetting.sh
```sh
BACKEND=''
API=''
LIBS=''
```