#!/bin/sh

_INSTALL_LIST_='bash-completion binutils curl wget vim git nano man-pages-zh-CN sudo zsh'

_GROUPS_LIST_='minimal compat-libraries core debugging evelopment system-admin-tools'

_EPEL_LIST_='htop iftop jq pv python-pip'

[ "`id -u`" -ne "0" ] && echo "You must run as root!" && exit 1

checkSystemInfo() {
    cat /etc/os-release | grep -Ev '^$' | while read line
    do   
        local "${line//\"/}"
        [ "$ID" = "centos" ] && [ "$VERSION_ID" = "7" ] && return 1
    done 
    [ "$?" -eq "1" ] && return 0 || return 1
}        

checkYumRepos() {
    grep -E "^#baseurl|^mirrorlist" -q /etc/yum.repos.d/CentOS-Base.repo
    return $?
}   

disableFasterMirror() {
    [ -f '/etc/yum/pluginconf.d/fastestmirror.conf' ] && \
    sed -e 's/^enabled=1/enabled=0/g' -i /etc/yum/pluginconf.d/fastestmirror.conf
    return $?
}

changeYumRepos() {
    local mirror_index
    local replace_cmd
    local https_cmd
    /bin/cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
    echo "[1] sjtug"
    echo "[2] tuna"
    echo "[3] aliyun"
    echo "[4] 163"
    read -p "Which mirror do you want to choose? (default: 1) [1-4]: " mirror_index
    case $mirror_index in
        1)
            replace_cmd='s!//mirror\.centos\.org!//mirrors.sjtug.sjtu.edu.cn!g'
            https_cmd='s!http://mirrors\.sjtug!https://mirrors.sjtug!g'
        ;;
        2)
            replace_cmd='s!//mirror\.centos\.org!//mirrors.tuna.tsinghua.edu.cn!g'
            https_cmd='s!http://mirrors\.tuna!https://mirrors.tuna!g'
        ;;
        3)
            replace_cmd='s!//mirror\.centos\.org!//mirrors.aliyun.com!g'
            https_cmd='s!http://mirrors\.aliyun!https://mirrors.aliyun!g'
        ;;
        4)
            replace_cmd='s!//mirror\.centos\.org!//https://mirrors.163.com/!g'
            https_cmd='s!http://mirrors\.163!https://mirrors.163!g'
        ;;
        *)
            return 1
        ;;
    esac
    sed -e 's!^mirrorlist=!#mirrorlist=!g' \
        -e 's!^#baseurl=!baseurl=!g' \
        -e "$replace_cmd" \
        -e "$https_cmd" \
        -i /etc/yum.repos.d/CentOS-Base.repo
}

installBasePackages() {
    yum -y groupinstall $_GROUPS_LIST_
    [ "$?" -ne "0" ] && return 1
    yum -y install $_INSTALL_LIST_
    return $?
}

setupEpel() {
    local mirror_index
    local replace_cmd
    local https_cmd
    yum -y install epel-release
    /bin/cp /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.bak
    echo "[1] sjtug"
    echo "[2] tuna"
    echo "[3] aliyun"
    read -p "Which mirror do you want to choose? (default: 1) [1-3]: " mirror_index
    case $mirror_index in
        1)
            replace_cmd='s!//download\.fedoraproject\.org/pub!//mirrors.sjtug.sjtu.edu.cn/fedora!g'
            https_cmd='s!http://mirrors\.sjtug!https://mirrors.sjtug!g'
        ;;
        2)
            replace_cmd='s!//download\.fedoraproject\.org/pub!//mirrors.tuna.tsinghua.edu.cn!g'
            https_cmd='s!http://mirrors\.tuna!https://mirrors.tuna!g'
        ;;
        3)
            replace_cmd='s!//download\.fedoraproject\.org/pub!//mirrors.aliyun.com!g'
            https_cmd='s!http://mirrors\.aliyun!https://mirrors.aliyun!g'
        ;;
        *)
            return 1
        ;;
    esac
    sed -e 's!^metalink=!#metalink=!g' \
        -e 's!^#baseurl=!baseurl=!g' \
        -e "$replace_cmd" \
        -e "$https_cmd" \
        -i /etc/yum.repos.d/epel.repo
    yum makecache fast
    return $?
}

installEpelPackages() {
    yum -y install $_EPEL_LIST_
    return $?
}

upgrageSystem() {
    yum -y update
    return $?
}

createBoringCat() {
    useradd -m -G wheel boringcat
    passwd boringcat
}

setBoringCat() {
    local user_nopwd='NOPASSWD: '
    local comfirm
    read -p "BoringCat use sudo without password? [Y/n]" comfirm
    [ "$comfirm" != "Y" ] && [ "$comfirm" != "y" ] && user_nopwd=''
    echo -e "boringcat	ALL=(ALL)	${user_nopwd}ALL" > /etc/sudoers.d/boringcat
    su - boringcat << EOF
    ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
    cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
    [ -f '/etc/ssh/ssh_host_ecdsa_key.pub' ] && \
    echo "localhost `cat /etc/ssh/ssh_host_ecdsa_key.pub`" > ~/.ssh/known_hosts
    wget -O install_zsh.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
    chmod +x install_zsh.sh
    ./install_zsh.sh --unattended --skip-chsh
    rm install_zsh.sh
EOF
    comfirm=''
    read -p "Install Powerline-status and set .zshrc for boringcat? [Y/n] " comfirm
    [ "$comfirm" != "Y" ] && [ "$comfirm" != "y" ] && return 0
    pip install powerline-status
    su - boringcat << EOF
    wget https://www.brc.cool/linux/scripts/setzshrc.sh
    sh ./setzshrc.sh
    rm ./setzshrc.sh
EOF
    chsh -s /bin/zsh boringcat
    comfirm=''
    read -p "Set .vimrc for boringcat? [Y/n] " comfirm
    [ "$comfirm" = "Y" ] || [ "$comfirm" = "y" ] && \
    su - boringcat << EOF
    wget https://www.brc.cool/linux/scripts/setvim.sh
    sh ./setvim.sh
    rm ./setvim.sh
EOF
    comfirm=''
    read -p "Set .tmux.conf for boringcat? [Y/n] " comfirm
    [ "$comfirm" = "Y" ] || [ "$comfirm" = "y" ] && \
    su - boringcat << EOF
    wget https://www.brc.cool/linux/scripts/settmux.sh
    sh ./settmux.sh
    rm ./settmux.sh
EOF
}

ifCreateBoringCat() {
    local comfirm
    read -p "Create user boringcat? [Y/n]" comfirm
    [ "$comfirm" != "Y" ] && [ "$comfirm" != "y" ] && return 0
    id boringcat -u 2>/dev/null
    [ "$?" -ne "0" ] && createBoringCat
    setBoringCat
}

ifInstallPowerlineToRoot() {
    comfirm=''
    read -p "Install Powerline-status and set .zshrc for root? [Y/n] " comfirm
    [ "$comfirm" != "Y" ] && [ "$comfirm" != "y" ] && return 0
    pip install powerline-status
    wget -O install_zsh.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
    chmod +x install_zsh.sh
    ./install_zsh.sh --unattended --skip-chsh
    rm install_zsh.sh
    wget https://www.brc.cool/linux/scripts/setzshrc.sh
    sh ./setzshrc.sh
    rm ./setzshrc.sh
    read -p "Set .vimrc for root? [Y/n] " comfirm
    [ "$comfirm" = "Y" ] || [ "$comfirm" = "y" ] && \
    wget https://www.brc.cool/linux/scripts/setvim.sh
    sh ./setvim.sh
    rm ./setvim.sh
    comfirm=''
    read -p "Set .tmux.conf for boringcat? [Y/n] " comfirm
    [ "$comfirm" = "Y" ] || [ "$comfirm" = "y" ] && \
    wget https://www.brc.cool/linux/scripts/settmux.sh
    sh ./settmux.sh
    rm ./settmux.sh
}

checkSystemInfo || echo "System is not Centos 7!">&2 || exit 1

checkYumRepos && changeYumRepos || echo "/etc/yum.repos.d/CentOS-Base.repo have been change!">&2

disableFasterMirror

installBasePackages || exit 1

setupEpel || exit 1

installEpelPackages || exit 1

upgrageSystem || exit 1

ifCreateBoringCat || exit 1

ifInstallPowerlineToRoot || exit 1

