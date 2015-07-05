#!/usr/bin/env zsh

source ${0:h}/reader.zsh
source ${0:h}/printer.zsh

function READ(){
	read -r "?${1:-user>} "
	read_str "$REPLY"
}

function EVAL(){
	:
}

function PRINT(){
	if [[ -n "$error" ]]; then
		pr_str "$error" 'yes'
		REPLY="Error: $REPLY"
		error=
	else
		pr_str "$1" 'yes'
	fi
}

function rep(){
	READ "$1"
	EVAL "$REPLY"
	PRINT "$REPLY"
}

while true; do
	rep && print -r -- "$REPLY"
done

######################################################################
### Local Variables:
### mode: shell-script
### coding: utf-8-unix
### tab-width: 4
### End:
######################################################################
