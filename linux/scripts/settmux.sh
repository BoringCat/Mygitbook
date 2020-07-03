#!/bin/sh

_FIND_=$(command -v find)

find_powerline_config() {
    command -v powerline-config 2>/dev/null
    [ $? -ne 0 ] && \
    echo "powerline-config not found, Please use: '`basename $0` /path/to/powerline-config' to create ~/.tmux.conf" >&2 && \
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

set_tmux() {
    echo "source $1" > $HOME/.tmux.conf
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

set_tmux $(if_config_in_home $(find_configs ${powerline_path} tmux powerline.conf))