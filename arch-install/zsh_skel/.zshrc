pm() {
  sudo pacman $@
}

gh() {
  if [[ ! -z $1 ]]; then
    git clone git@github.com:$1
  fi
}

yk() {
  if [[ -f /usr/lib/opensc-pkcs11.so ]]; then
    ssh-add -s /usr/lib/opensc-pkcs11.so
  fi
  if [[ -f /usr/local/lib/opensc-pkcs11.so ]]; then
    ssh-add -s /usr/local/lib/opensc-pkcs11.so
  fi
}

if which dircolors &>/dev/null; then
  alias ls="ls --color=auto"
fi

if [[ -f $HOME/.z.zsh ]]; then
  source $HOME/.z.zsh
fi

# History search
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down
bindkey "^[f" forward-word
bindkey "^[b" backward-word
autoload -U select-word-style
select-word-style bash
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

# Menu style autocompletion
zstyle ':completion:*' menu select
zmodload -i zsh/complist
autoload -U compinit && compinit

# use the vi navigation keys in menu completion
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Git info
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git

precmd() {
  aheadbehind=""
  git_status=""
  ahead=""
  behind=""
  if git rev-parse --git-dir > /dev/null 2>&1; then 
    git_status_sb=$(git status -sb 2>/dev/null)
    if [[ $git_status_sb =~ 'ahead ([0-9]+)' ]]; then
      ahead=" %F{green}↑$match[1]%f"
    fi
    if [[ $git_status_sb =~ 'behind ([0-9]+)' ]]; then
      behind=" %F{red}↓$match[1]%f"
    fi
    aheadbehind="$ahead$behind" 

    if [ "$(git status --porcelain 2>/dev/null)" ]; then 
      git_status=" %F{red}!%f"
    else 
      git_status=""
    fi
  fi
  zstyle ':vcs_info:git*' formats "%%B%F{cyan}(%F{cyan}%b$git_status$aheadbehind%%B%F{cyan})%f%%b "
  zstyle ':vcs_info:git*' actionformats "%%B%F{cyan}(%a:%F{cyan}%b$git_status$aheadbehind%%B%F{cyan})%f%%b"
  vcs_info
}

setopt prompt_subst

PROMPT="
%F{blue}# \
%F{cyan}%n%F{white}@%F{green}%m \
%B%F{yellow}[%~]%b%f \${vcs_info_msg_0_}
%B%F{red}>%f%b "

RPROMPT="%(?..[%F{red}%?%f])"
