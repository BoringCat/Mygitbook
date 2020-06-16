#!/bin/sh

_FIND_=$(command -v find)

[ ! -f "$HOME/.zshrc" ] && echo "~/.zshrc not found" && exit 1

find_powerline_config() {
    local configname=$1
    local configfile=$2
    local dir
    local file
    dir=$($_FIND_ $(dirname `dirname $(which powerline-config)`)/lib* -type d -name "${configname}" -print0 | grep -FzZ "powerline/bindings/${configname}")
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

set_vimrc() {
    local powerline_path=$1
    local out_to_file=$HOME/.vimrc
    [ -f "$HOME/.vimrc" ] && \
    echo "~/.vimrc existed! Please checked." && \
    echo "We will output configs in console instand ~/.vimrc" && \
    out_to_file=/dev/stdout
    echo "\" powerline配置
    set rtp+=${powerline_path}
    set laststatus=2
    set t_Co=256

    set encoding=utf-8
    \" 开启文件类型侦测
    filetype on
    \" 开启实时搜索功能
    set incsearch
    \" 搜索时大小写不敏感
    set ignorecase
    \" 关闭兼容模式
    set nocompatible
    \" vim 自身命令行模式智能补全
    set wildmenu
    \" 禁止光标闪烁
    set gcr=a:block-blinkon0
    \" 显示光标当前位置
    set ruler
    \" 高亮显示当前行/列
    set cursorline
    set cursorcolumn
    \" 禁止折行
    set nowrap
    \" 开启语法高亮功能
    syntax enable
    \" 允许用指定语法高亮配色方案替换默认方案
    syntax on
    \" 自适应不同语言的智能缩进
    filetype indent on
    \" 将制表符扩展为空格
    set expandtab
    \" 设置编辑时制表符占用空格数
    set tabstop=4
    \" 设置格式化时制表符占用空格数
    set shiftwidth=4
    \" 让 vim 把连续数量的空格视为一个制表符
    set softtabstop=4
    \" 取消换行后自动注释
    set paste" | sed 's/^[ ]*//g' > ${out_to_file} 
}

set_vimrc $(if_config_in_home $(find_powerline_config vim))
