#!/usr/bin/env zsh

source ${0:h}/reader.zsh
source ${0:h}/printer.zsh

function READ(){
	read -r "?${1:-user>} "
	read_str "$REPLY"
}

function EVAL(){
	[[ -n "$error" ]] && return 1

	obj_type "$1"
	local obj_type=$REPLY

	eval_ast "$@"

	if [[ "$obj_type" == 'list' ]]; then
		[[ -n "$error" ]] && return 1

		"${(@P)ast[${REPLY}]}"
	fi
}

function eval_ast(){
	local -A env
	env=( "${(@Pkv)2}" )

	obj_type "$1"
	local obj_type=$REPLY

	case "$obj_type" in
		(symbol)		[[ -n "${REPLY::=${env[${ast[${1}]}]}}" ]] || Error "'${ast[${1}]}' not found";;
		(list|vector)	map "$1" 'EVAL' "$2";;
		(hash)			hash_map "$1" 'EVAL' "$2";;
		(*)				REPLY=$1;;
	esac
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
	EVAL "$REPLY" 'repl_env'
	PRINT "$REPLY"
}

typeset -A repl_env
repl_env=(
	'+' 'plus'
	'-' 'minus'
	'*' 'multiply'
	'/' 'divide'
)

function plus(){
	Number $((${ast[${1}]} + ${ast[${2}]}))
}

function minus(){
	Number $((${ast[${1}]} - ${ast[${2}]}))
}

function multiply(){
	Number $((${ast[${1}]} * ${ast[${2}]}))
}

function divide(){
	Number $((${ast[${1}]} / ${ast[${2}]}))
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
