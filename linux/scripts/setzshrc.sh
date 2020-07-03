#!/bin/sh

_FIND_=$(command -v find)

find_powerline_config() {
    command -v powerline-config 2>/dev/null
    [ $? -ne 0 ] && \
    echo "powerline-config not found, Please use: '`basename $0` /path/to/powerline-config' to create ~/.zshrc" >&2 && \
    exit 1
}

find_configs() {
    local powerline_path=$1
    local configname=$2
    local configfile=$3
    local dir
    local file
    dir=$($_FIND_ $(dirname ${powerline_path})/lib* -type d -name "${configname}" -print0 | grep -FzZ "powerline/bindings/${configname}")
    [ -z "${dir}" ] && echo "powerline/bindings not found!" && exit 1
    [ ! -z "${configfile}" ] && \
        file=$($_FIND_ $dir -type f -name "${configfile}")
    [ -z "${file}" ] && echo ${dir} || echo ${file}
    return 0
}

if_config_in_home() {
    local confdir=$1
    local inhome=$(echo $confdir | grep $HOME)
    [ ! -z "${inhome}" ] && \
    echo $confdir | sed "s+$HOME+\$HOME+g" || \
    echo $confdir
}

get_aliases() {
    local systemtype=$1
    local useridroot=0
    local alias_addon=''
    for ugid in `id -G`
    do
        [ "$ugid" -eq "0" ] && useridroot=1
    done
    [ "$useridroot" -eq "0" ] && alias_addon='sudo '
    case "${systemtype}" in
        arch)
        echo "alias pacuda='${alias_addon}pacman -Syu'
              alias pacget='${alias_addon}pacman -S'
              alias pacsea='${alias_addon}pacman -Ss'
              alias pacrm='${alias_addon}pacman -Rns'
              alias pacjrm='${alias_addon}pacman -R'" | \
        sed 's/^[ ]*//g'
        ;;
        fedora)
        echo "alias dnfuda='${alias_addon}dnf update'
              alias dnfget='${alias_addon}dnf install'
              alias dnfrm='${alias_addon}dnf remove'" | \
        sed 's/^[ ]*//g'
        ;;
        centos)
        echo "alias yumuda='${alias_addon}yum update'
              alias yumget='${alias_addon}yum install'
              alias yumrm='${alias_addon}yum remove'" | \
        sed 's/^[ ]*//g'
        ;;
    esac
}

config_zshrc() {
    local powerline_zsh=$1
    local add_path=$(if_config_in_home `realpath ${powerline_path}`)
    sed -e "s/^ZSH_THEME=\".*\"/ZSH_THEME=\"agnoster\"/g" \
        -e "/^ZSH_THEME/a export DEFAULT_USER=\"`whoami`\"\nzstyle ':completion:*' rehash true" \
        -e "/DISABLE_UPDATE_PROMPT/s/.*/DISABLE_UPDATE_PROMPT=\"true\"/g" \
        -e "/DISABLE_AUTO_UPDATE/s/.*/DISABLE_AUTO_UPDATE=\"true\"/g" \
        -e "/COMPLETION_WAITING_DOTS/s/.*/COMPLETION_WAITING_DOTS=\"true\"/g" \
        -e "/source \$ZSH\/oh-my-zsh.sh/a\\\n. ${powerline_zsh}" \
        -i $HOME/.zshrc
    [ ${custom_path} -eq 1 ] && \
        sed -e "/export PATH/a\\export PATH=\$PATH:${add_path}" -i $HOME/.zshrc
    echo "
          alias mtr='mtr -n'
          alias iftop='iftop -B'
          alias dds='dd status=progress'
          alias dua='du -ah --max-depth=1'
          alias l='ls -alhF --color=auto'
          alias ll='ls -l'
          alias cls='clear'
          alias docker-runrm='docker run --rm -it'" | sed 's/^[ ]*//g' >> $HOME/.zshrc
    echo >> $HOME/.zshrc
    local systemID=`grep -E '^ID=' /etc/os-release | cut -d= -f2`
    get_aliases ${systemID//\"/} >> $HOME/.zshrc
}
custom_path=1
if [ -z "$1" ]; then
    powerline_path=$(find_powerline_config)
    custom_path=0 
else
    powerline_path=$1
    custom_path=1
fi
[ -z "${powerline_path}" ] && exit 1
powerline_path=$(realpath `dirname ${powerline_path}`)

cd $HOME
ZSH="$HOME/.oh-my-zsh"
[ ! -d "$ZSH" ] && echo "Oh-my-zsh not found! Please install it first" && exit 1
mv .zshrc .zshrc.bak 2>/dev/null
cp $ZSH/templates/zshrc.zsh-template .zshrc

config_zshrc $(if_config_in_home $(find_configs ${powerline_path} zsh powerline.zsh))
