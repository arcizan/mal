[[ -n "$__types_zsh" ]] && return

typeset -r __types_zsh='true'
typeset -r obj_magic="__zlisp_${$}"
typeset -i obj_hash_code=${obj_hash_code:-0}
typeset -r keyword_prefix=$'\u029E'
typeset -A ast

source ${0:h}/debug.zsh

function new_obj_hash_code(){
	emulate -L zsh

	REPLY=$((++obj_hash_code))
}

function new_obj(){
	emulate -L zsh

	new_obj_hash_code
	REPLY="${1}_${REPLY}"
}

error=

function error(){
	emulate -L zsh

	String "$1"
	error=$REPLY
	REPLY=
}

function obj_type(){
	emulate -L zsh

	case "${1:0:4}" in
		(_nil)	REPLY='nil';;
		(true)	REPLY='true';;
		(fals)	REPLY='false';;
		(symb)	REPLY='symbol';;
		(numb)	REPLY='number';;
		(strn)	REPLY='string'; [[ "${1:0:1}" == "$keyword_prefix" || "${1:0:2}" == "$keyword_prefix" ]] && REPLY='keyword';;
		(list)	REPLY='list';;
		(vect)	REPLY='vector';;
		(hash)	REPLY='hash';;
		(atom)	REPLY='atom';;
		(func)	REPLY='function';;
		(undf)	REPLY='undefined';;
		(*)		REPLY='zsh';;
	esac
}

typeset -r nil='_nil_0'
typeset -r true='true_0'
typeset -r false='fals_0'

function Symbol(){
	emulate -L zsh

	debug_log "arg: [$1]"

	new_obj 'symb'
	ast[${REPLY}]=$1

	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

function Number(){
	emulate -L zsh

	debug_log "arg: [$1]"

	new_obj 'number'
	ast[${REPLY}]=$1

	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

function String(){
	emulate -L zsh

	debug_log "arg: [$1]"

	new_obj 'strn'
	ast[${REPLY}]=$1

	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

function Keyword(){
	emulate -L zsh

	debug_log "arg: [$1]"

	new_obj 'strn'

	local k=$1
	[[ "${k:0:1}" != "$keyword_prefix" && "${k:0:2}" != "$keyword_prefix" ]] && k="${keyword_prefix}${k}"

	ast[${REPLY}]=$k

	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

function Seq(){
	emulate -L zsh

	debug_log "args: [$@]"

	new_obj "$1"
	local seq="${obj_magic}_${REPLY}"

	typeset -ag $seq
	eval "${seq}"'=( "${@[2,-1]}" )'

	ast[${REPLY}]=$seq

	debug_log "ast[$REPLY]: [${ast[$REPLY]}], ${ast[$REPLY]}: [${(P)ast[$REPLY]}]"
}

function car(){
	emulate -L zsh

	debug_log "arg: [$1], ast[$1]: [${ast[$1]}], ${ast[$1]}: [${(P)ast[$1]}]"

	REPLY=${${(P)ast[${1}][1]}:-$nil}

	debug_log "REPLY: [$REPLY]"
}

function cdr(){
	emulate -L zsh

	debug_log "arg: [$1], ast[$1]: [${ast[$1]}], ${ast[$1]}: [${(P)ast[$1]}]"

	List "${(@P)ast[${1}][2,-1]}"
}

function nth(){
	emulate -L zsh

	debug_log "args: [$@], ast[$1]: [${ast[$1]}], ${ast[$1]}: [${(P)ast[$1]}]"

	REPLY=${(P)ast[${1}][$(($2 + 1))]}

	debug_log "REPLY: [$REPLY]"
}

function add_to_seq(){
	emulate -L zsh

	debug_log "args: [$@], ast[$1]: [${ast[$1]}], ${ast[$1]}: [${(P)ast[$1]}]"

	eval "${ast[${1}]}"'+=( "${@[2,-1]}" )'
	REPLY=$1

	debug_log "ast[$REPLY]: [${ast[$REPLY]}], ${ast[$REPLY]}: [${(P)ast[$REPLY]}]"
}

function map(){
	emulate -L zsh

	debug_log "args: [$@], ast[$1]: [${ast[$1]}], ${ast[$1]}: [${(P)ast[$1]}]"

	Seq "${1%%_*}"
	local new_seq=$REPLY seq=${ast[${1}]} f=$2 v
	shift 2

	for v in "${(@P)seq}"; do
		"${f%%@*}" "$v" "$@" || { REPLY=; return 1; }
		add_to_seq "$new_seq" "$REPLY"
	done

	REPLY=$new_seq

	debug_log "ast[$REPLY]: [${ast[$REPLY]}], ${ast[$REPLY]}: [${(P)ast[$REPLY]}]"
}

function List(){
	emulate -L zsh

	Seq 'list' "$@"
}

function Vector(){
	emulate -L zsh

	Seq 'vect' "$@"
}

function Hash(){
	emulate -L zsh

	debug_log "args: [$@]"

	new_obj 'hash'
	local hash="${obj_magic}_${REPLY}" k v

	typeset -Ag $hash
	eval "${hash}=()"

	ast[${REPLY}]=$hash

	for k v in "$@"; do
		eval "${hash}"'[${ast[${k}]}]=$v'
	done

	debug_log "ast[$REPLY]: [${ast[$REPLY]}], ${ast[$REPLY]}: [${(Pkv)ast[$REPLY]}]"
}

function contains(){
	emulate -L zsh

	debug_log "args: [$@], keys: [${(Pk)ast[$1]}], key: [$2]"

	[[ -n "${(@MPk)ast[${1}]:#$2}" ]]
}

function add_to_hash(){
	emulate -L zsh

	debug_log "args: [$@], ast[$1]: [${ast[$1]}], ${ast[$1]}: [${(Pkv)ast[$1]}]"

	local REPLY=$1 hash=${ast[${1}]} k v # REPLY is a local variable
	shift

	for k v in "$@"; do
		eval "${hash}"'[${k}]=$v'
	done

	debug_log "ast[$REPLY]: [${ast[$REPLY]}], ${ast[$REPLY]}: [${(Pkv)ast[$REPLY]}]"
}

function hash_map(){
	emulate -L zsh

	debug_log "args: [$@], ast[$1]: [${ast[$1]}], ${ast[$1]}: [${(Pkv)ast[$1]}]"

	local -A hash
	hash=( "${(@Pkv)ast[${1}]}" )

	Hash
	local new_hash=$REPLY f=$2 k
	shift 2

	for k in ${(k)hash}; do
		"${f%%@*}" "${hash[${k}]}" "$@" || { REPLY=; return 1; }
		add_to_hash "$new_hash" "$k" "$REPLY"
	done

	REPLY=$new_hash

	debug_log "ast[$REPLY]: [${ast[$REPLY]}], ${ast[$REPLY]}: [${(Pkv)ast[$REPLY]}]"
}

function Atom(){
	emulate -L zsh

	debug_log "arg: [$1]"

	new_obj 'atom'
	ast[${REPLY}]=$1

	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

######################################################################
### Local Variables:
### mode: shell-script
### coding: utf-8-unix
### tab-width: 4
### End:
######################################################################
