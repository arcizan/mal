[[ -n "$__printer_zsh" ]] && return

typeset -r __printer_zsh='true'

source ${0:h}/types.zsh
source ${0:h}/debug.zsh

function pr_str(){
	emulate -L zsh

	debug_log "args: [$@]"

	obj_type "$1"
	local obj_type=$REPLY

	debug_log "obj_type: [$obj_type]"

	if [[ -z "$obj_type" ]]; then
		error "${0:t}: failed on '$1'"
		REPLY="<${1}>"
		return 1
	fi

	${obj_type}_pr_str "$@"
}

function nil_pr_str(){
	emulate -L zsh

	REPLY='nil'
}

function true_pr_str(){
	emulate -L zsh

	REPLY='true'
}

function false_pr_str(){
	emulate -L zsh

	REPLY='false'
}

function symbol_pr_str(){
	emulate -L zsh

	REPLY=${ast[${1}]}
}

function number_pr_str(){
	emulate -L zsh

	REPLY=${ast[${1}]}
}

function string_pr_str(){
	emulate -L zsh

	raw_string_pr_str "${ast[${1}]}" "$2"
}

function raw_string_pr_str(){
	emulate -L zsh

	debug_log "args: [$@]"

	if [[ "${1:0:1}" == "$keyword_prefix" ]]; then
		REPLY=":${1:1}"
	elif [[ "${1:0:2}" == "$keyword_prefix" ]]; then
		REPLY=":${1:2}"
	elif [[ "$2" == "yes" ]]; then
		REPLY="\"${${1//\\/\\\\}//\"/\\\"}\""
	else
		REPLY=$1
	fi

	debug_log "REPLY: [$REPLY]"
}

function keyword_pr_str(){
	emulate -L zsh

	string_pr_str "$1"
}

function seq_pr_str(){
	emulate -L zsh

	local x res
	res=()

	for x in "${(@P)ast[${3}]}"; do
		pr_str "$x" "$4"
		res+=$REPLY
	done

	REPLY="${1}${res}${2}"
}

function list_pr_str(){
	emulate -L zsh

	seq_pr_str '(' ')' "$@"
}

function vector_pr_str(){
	emulate -L zsh

	seq_pr_str '[' ']' "$@"
}

function hash_pr_str(){
	emulate -L zsh

	local -A hash
	hash=( "${(@Pkv)ast[${1}]}" )
	local k res
	res=()

	debug_log "${ast[$1]}: [$hash]"

	for k in ${(k)hash}; do
		debug_log "${ast[$1]}[$k]: [${hash[$k]}]"

		raw_string_pr_str "$k" "$2"
		res+=$REPLY
		pr_str "${hash[${k}]}" "$2"
		res+=$REPLY
	done

	REPLY="{${res}}"
}

function atom_pr_str(){
	emulate -L zsh

	pr_str "${ast[${1}]}" "$2"
	REPLY="(atom $REPLY)"
}

function function_pr_str(){
	emulate -L zsh

	REPLY=${ast[${1}]}
}

function zsh_pr_str(){
	emulate -L zsh

	REPLY=$(where "$1")
}

######################################################################
### Local Variables:
### mode: shell-script
### coding: utf-8-unix
### tab-width: 4
### End:
######################################################################
