# zshrc

## 一键
[setzshrc.sh](scripts/setzshrc.sh)

## 通用
``` sh
ZSH_THEME="agnoster"
export DEFAULT_USER="root"
zstyle ':completion:*' rehash true
DISABLE_UPDATE_PROMPT=true

DISABLE_AUTO_UPDATE="true"
COMPLETION_WAITING_DOTS="true"
```

## powerline
必须在 `source $ZSH/oh-my-zsh.sh` 后面
### fedora
``` sh
powerline-daemon -q         # 可能不需要？
. /usr/share/powerline/zsh/powerline.zsh
```

### archlinux
``` sh
powerline-daemon -q         # 可能不需要？
. /usr/share/powerline/bindings/zsh/powerline.zsh
```

## aliases
``` sh
alias mtr='mtr -n'
alias iftop='iftop -B'
alias dds='dd status=progress'
alias dua='du -ah --max-depth=1'
alias l='ls -alhF --color=auto'
alias ll='ls -l'
alias cls='clear'
alias docker-runrm='docker run --rm -it'
```
### fedora
``` sh
alias dnfuda='dnf update'
alias dnfget='dnf install'
alias dnfrm='dnf remove'
```
### centos
``` sh
alias yumuda='yum update'
alias yumget='yum install'
alias yumrm='yum remove'
```

### archlinux
``` sh
alias pacuda='pacman -Syu'
alias pacget='pacman -S'
alias pacsea='pacman -Ss'
alias pacrm='pacman -Rns'
alias pacjrm='pacman -R'
```

