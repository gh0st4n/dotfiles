#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Feth & Auto Config
~/.config/fetch/auto.sh

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fetch='~/.config/fetch/script/fetch.sh'
#PS1='[\u@\h \W]\$ '

# First Prompt Line
PS1='\n\[\e[1;31m\]┌──>\[\e[0m\] [ \u @ \h ] <<|= User Mode =|>> [ \d ] [ \w ] \n\[\e[1;31m\]└{₿}->>\[\e[0m\] '

#PATH
export PATH="$PATH:/opt/zig/zig-0.15.2:$PATH"
