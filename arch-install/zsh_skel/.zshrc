pm() {
  if command -v pacman &> /dev/null; then
    if [ $1 = 'check' ]; then
    pacman -Qtdq
      return
    fi
    if [ $1 = 'clean' ]; then
      pacman -Qtdq | sudo pacman -Rns -
      return
    fi
    sudo pacman $@
  fi
}

gh() {
  if [ $1 = 'bare' ]; then
    if [[ ! -z $2 ]]; then
      paths=("${(@s|/|)2}")
      if [ ${#paths} -eq 2 ]; then
        dir=${paths[2]}
        git clone --bare git@github.com:$2 ${dir} &&
          cd $dir && echo "Fetching remote branches" && git tup &> /dev/null && cd ..
      fi
    fi
    return
  fi

  if [[ ! -z $1 ]]; then
    git clone git@github.com:$1
  fi
}

yk() {
  SO_PATH=""
  if [[ -f "/usr/lib/opensc-pkcs11.so" ]]; then
    SO_PATH="/usr/lib/opensc-pkcs11.so"
  elif [[ -f "/usr/local/lib/opensc-pkcs11.so" ]]; then
    SO_PATH="/usr/local/lib/opensc-pkcs11.so"
  fi
  if [ $1 = "e" ]; then
    ssh-add -e $SO_PATH
  else
    ssh-add -s $SO_PATH
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
git_prompt=""

precmd() {
  git_prompt=""
  aheadbehind=""
  git_status=""
  ahead=""
  behind=""
  local repo_info rev_parse_exit_code
	repo_info="$(git rev-parse \
		--is-bare-repository --is-inside-work-tree \
		--abbrev-ref HEAD 2>/dev/null)"
	rev_parse_exit_code="$?"

	if [ -z "$repo_info" ]; then
		return $exit
	fi
  
  local short_sha=""
  local branch_name=""
  local branch_sha=""
	if [ "$rev_parse_exit_code" = "0" ]; then
    branch_name="${repo_info##*$'\n'}"
    repo_info="${repo_info%$'\n'*}"
    short_sha="$(git rev-parse --short HEAD 2>/dev/null)"
    branch_sha="$branch_name [$short_sha]"
	fi

  local inside_worktree="${repo_info##*$'\n'}"
	repo_info="${repo_info%$'\n'*}"
	local bare_repo="${repo_info##*$'\n'}"

  if [ "true" = "$inside_worktree" ]; then
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
    git_prompt="%B%F{cyan}(%F{cyan}$branch_sha$git_status$aheadbehind%F{cyan})%f%b"
  fi
  if [ "true" = "$bare_repo" ]; then
    git_prompt="%B%F{cyan}(%F{cyan}%b[bare]%B%F{cyan})%f%b"
  fi
}

setopt prompt_subst

PROMPT="
%F{blue}# \
%F{cyan}%n%F{white}@%F{green}%m \
%B%F{yellow}[%~]%b%f \${git_prompt}
%B%F{red}>%f%b "

RPROMPT="%(?..[%F{red}%?%f])"
