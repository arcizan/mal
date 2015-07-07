#!/usr/bin/env zsh

source ${0:h}/reader.zsh
source ${0:h}/printer.zsh
source ${0:h}/env.zsh

function READ(){
	read -r "?${1:-user>} "
	read_str "$REPLY"
}

function EVAL(){
	[[ -n "$error" ]] && return 1

	obj_type "$1"
	local obj_type=$REPLY

	if [[ "$obj_type" != 'list' ]]; then
		eval_ast "$@"
		return $?
	fi

	nth "$1" 0
	local a0=$REPLY
	nth "$1" 1
	local a1=$REPLY
	nth "$1" 2
	local a2=$REPLY

	case "${ast[${a0}]}" in
		(def\!)
			EVAL "$a2" "$2"
			[[ -n "$error" ]] && return 1
			env_set "$2" "$a1" "$REPLY"
			;;
		(let\*)
			Env "$2"
			local env=$REPLY pairs
			pairs=( "${(@P)ast[${a1}]}" )
			local -i idx

			for ((idx = 1; idx <= ${#pairs}; idx += 2)); do
				EVAL "${pairs[$((idx + 1))]}" "$env"
				env_set "$env" "${pairs[${idx}]}" "$REPLY"
			done

			EVAL "$a2" "$env"
			;;
		(*)
			eval_ast "$@"
			[[ -n "$error" ]] && return 1
			"${(@P)ast[${REPLY}]}"
			;;
	esac
}

function eval_ast(){
	obj_type "$1"
	local obj_type=$REPLY

	case "$obj_type" in
		(symbol)		env_get "$2" "$1";;
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
	EVAL "$REPLY" "$repl_env"
	PRINT "$REPLY"
}

Env
repl_env=$REPLY

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

for k v in '+' 'plus' '-' 'minus' '*' 'multiply' '/' 'divide'; do
	Symbol "$k"
	env_set "$repl_env" "$REPLY" "$v"
done

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
