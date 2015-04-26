bindkey -e
setopt correct
setopt nohup

setopt auto_cd
setopt multios

# Automatycznie wrzuca listê katalogów w których by³em
# Bardzo wygodne z dirs -v
setopt auto_pushd
setopt pushd_ignore_dups

# bash-style line editing
autoload -U select-word-style
select-word-style bash
# ctrl-litera porusza siê po ca³ym wyrazie.
bindkey "^f" emacs-forward-word
bindkey "^b" emacs-backward-word
bindkey "^w" backward-delete-word

# to chcê mieæ wszêdzie
alias scx="screen -x"
alias cvsup="cvsup -L2 -g"
alias psaux="ps aux"
alias dv="dirs -v"

# Utilsy do RCS:
alias ciww="ci -u -wzylad"
ciwinit()
{
	if [[ -z "$1" ]]; then
		return 1
	fi

	ci -u -wzylad $1
	rcs -U $1
	chmod u+w $1
}

if [[ $OSTYPE = freebsd* ]]; then
	alias ls="ls -GF"
	alias ll="ls -laGF"
	alias lsmod="kldstat"
	llast() { if [ -n "$1" ]; then for i in ~log/wtmp ~log/archive/wtmp*; do last -f $i $1; done; fi }
	hash -d rcd="/usr/local/etc/rc.d"
	hash -d letc="/usr/local/etc"

elif [[ $OSTYPE = darwin* ]]; then
    alias ll="ls -laGF"

elif [[ $OSTYPE = linux* ]]; then
	alias ls="ls -F --color=auto"
	alias ll="ls -laF --color=auto"
	alias kldstat="lsmod"
fi


alias ssh="ssh -X -o'Protocol 2,1'"

# katalogi smieszne:
hash -d log=/var/log

# na konsoli nie chcê bajerów

PROMPT='%{[01;31m%}[%D{%H:%M}]%{[22;39m%} %m%{[01;37m%}:%{[22;39m%}%{[33m%}%35<...<%{[39m%}%~ %(?..%{[01;31m%}(%?%)%{[22;39m%} )%(2L.%{[01;33m%}.%{[01;37m%})%(!.#.$)%{[22;39m%} '
if [[ $TERM = rxvt || $TERM = *xterm* || $TERM = aterm || $TERM = Eterm ]]; then
	PROMPT='%{]0;%n@%m%}'"$PROMPT"
else
fi

# historia:
HISTFILE=${HOME}/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt hist_ignore_dups
setopt hist_expire_dups_first
setopt hist_ignore_space
setopt hist_no_store
setopt inc_append_history
setopt extended_history
setopt hist_reduce_blanks

# Usuwanie niepotrzebnych slashy i innych takich.
setopt auto_remove_slash

# completion "w ¶rodku" wyrazu
setopt complete_in_word

# zaawansowane globy
setopt extendedglob

##########################################################
#
# completion
zmodload -i zsh/complist

# Je¶li wiêcej ni¿ 4 elementy, to rozwijaæ menu.
zstyle ':completion:*' menu select=4

autoload -U compinit
compinit

# Kolorowa lista.
zstyle ':completion:*' list-colors ''


# completion do ssh po hostach w known_hosts, poprawione
#local _myhosts
#zstyle -s ':completion:*:hosts' hosts _myhosts
#_myhosts+=( ${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[0-9]*}%%\ *}%%,*} )
#zstyle ':completion:*(scp|ssh):*' hosts $_myhosts
#local _myusers
#_myusers=( 'admin' 'zylad' 'dominik' 'root' )
#zstyle ':completion:*:(scp|ssh):*' users $_myusers

##################################################
# rulezujemy
zstyle ':completion:*:*:cvsup:*:*' file-patterns \
	'/etc/*-supfile:global-supfiles' '*-supfile:local-supfiles'

# Dopuszczalna liczba pomy³ek, oryginalny (b³êdny) string te¿ w li¶cie.
zstyle ':completion:*' max-errors 1
zstyle ':completion:*' original true
zstyle ':completion:*' completer _complete _correct _approximate

# nowe bajery:
autoload -U insert-files
zle -N insert-files
bindkey "^Xf" insert-files ## C-x-f

# Predykcja. Jest zajebi¶cie magiczna.
autoload -U predict-on
zle -N predict-on
zle -N predict-off
bindkey "^X^Z" predict-on ## C-x C-z
bindkey "^Z" predict-off ## C-z

autoload -U zmv

# Informuje o czasie pracy procesów, które dzia³aj± d³u¿ej ni¿:
REPORTTIME=10

# Nazwy procesów braæ z 'ps'
zstyle ':completion:*:processes' command 'ps -aux'

# jakie¶ lokalne ¶mieci
if [ -r ${HOME}/.zshrc_local ]; then
	. ${HOME}/.zshrc_local
fi

# vcs_info stuff
setopt prompt_subst
autoload -Uz vcs_info
zstyle ':vcs_info:*' actionformats \
    '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
zstyle ':vcs_info:*' formats       \
    '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f '
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'

zstyle ':vcs_info:*' enable git cvs svn

# or use pre_cmd, see man zshcontrib
vcs_info_wrapper() {
  vcs_info
  if [ -n "$vcs_info_msg_0_" ]; then
    echo "%{$fg[grey]%}${vcs_info_msg_0_}%{$reset_color%}$del"
  fi
}
RPROMPT=$'$(vcs_info_wrapper)'


export EDITOR='vim'
export GIT_AUTHOR_EMAIL=dominik.zyla@gmail.com
export GIT_AUTHOR_NAME='Dominik Zyla'
export GIT_COMMITTER_EMAIL=dominik.zyla@gmail.com
export GIT_COMMITTER_NAME='Dominik Zyla'
export LD_LIBRARY_PATH=~/luit/lib
LSCOLORS="ExGxFxdxCxDxDxhbadExEx"
export LSCOLORS

source /usr/local/share/zsh/site-functions/_aws

export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
export PYTHONSTARTUP=~/.pythonrc
source $HOME/.rvm/scripts/rvm
export GOPATH=$HOME/projects/go
export PATH=$PATH:$GOPATH/bin:$GOROOT/bin/go

alias tmux="TERM=screen-256color-bce tmux"
$(boot2docker shellinit)
