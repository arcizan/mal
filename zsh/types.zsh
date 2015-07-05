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

	new_obj 'symb'
	ast[${REPLY}]=$1

	debug_log "arg: [$1]"
	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

function Number(){
	emulate -L zsh

	new_obj 'number'
	ast[${REPLY}]=$1

	debug_log "arg: [$1]"
	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

function String(){
	emulate -L zsh

	new_obj 'strn'
	ast[${REPLY}]=$1

	debug_log "arg: [$1]"
	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

function Keyword(){
	emulate -L zsh

	new_obj 'strn'

	local k=$1
	[[ "${k:0:1}" != "$keyword_prefix" && "${k:0:2}" != "$keyword_prefix" ]] && k="${keyword_prefix}${k}"

	ast[${REPLY}]=$k

	debug_log "arg: [$1]"
	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

function Seq(){
	emulate -L zsh

	new_obj "$1"
	local seq="${obj_magic}_${REPLY}"

	typeset -ag $seq
	eval "${seq}=( ${(q)@[2,-1]} )"

	ast[${REPLY}]=$seq

	debug_log "args: [$@]"
	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

function car(){
	emulate -L zsh

	REPLY=${${(P)ast[${1}][1]}:-$nil}
}

function cdr(){
	emulate -L zsh

	List "${(@P)ast[${1}][2,-1]}"
}

function add_to_seq(){
	emulate -L zsh

	eval "${ast[${1}]}+=( ${(q)@[2,-1]} )"
	REPLY=$1
}

function map(){
	emulate -L zsh

	Seq "${1%%_*}"
	local new_seq=$REPLY seq=${ast[${1}]} f=$2 v
	shift 2

	for v in "${(@P)seq}"; do
		eval "${f%%@*} ${(q)v} ${(q)@}" || { REPLY=; return 1; }
		add_to_seq "$new_seq" "$REPLY"
	done

	REPLY=$new_seq
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

	new_obj 'hash'
	local hash="${obj_magic}_${REPLY}" k v

	typeset -Ag $hash
	eval "${hash}=()"

	ast[${REPLY}]=$hash

	debug_log "args: [$@]"
	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"

	for k v in "$@"; do
		eval "${hash}[${ast[${k}]}]=${(q)v}"
	done

	debug_log "${hash}: [${(Pkv)hash}]"
}

function add_to_hash(){
	emulate -L zsh

	local hash=${ast[${1}]} k v
	shift

	for k v in "$@"; do
		eval "${hash}[${k}]=${(q)v}"
	done
}

function hash_map(){
	emulate -L zsh

	local -A hash
	hash=( "${(@Pkv)ast[${1}]}" )

	Hash
	local new_hash=$REPLY f=$2 k
	shift 2

	for k in ${(k)hash}; do
		eval "${f%%@*} ${(q)hash[${k}]} ${(q)@}" || { REPLY=; return 1; }
		add_to_hash "$new_hash" "$k" "$REPLY"
	done

	REPLY=$new_hash
}

function Atom(){
	emulate -L zsh

	new_obj 'atom'
	ast[${REPLY}]=$1

	debug_log "arg: [$1]"
	debug_log "ast[$REPLY]: [${ast[$REPLY]}]"
}

######################################################################
### Local Variables:
### mode: shell-script
### coding: utf-8-unix
### tab-width: 4
### End:
######################################################################
