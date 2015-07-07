[[ -n "$__env_zsh" ]] && return 1

typeset -r __env_zsh='true'

source ${0:h}/types.zsh
source ${0:h}/debug.zsh

function Env(){
	emulate -L zsh

	debug_log "args: [$@]"

	Hash
	local env=$REPLY

	if [[ -n "$1" ]]; then
		add_to_hash "$env" '__outer__' "$1"
		shift
	else
		add_to_hash "$env" '__outer__' "$nil"
	fi

	debug_log "REPLY: [$REPLY], ast[$REPLY]: [${ast[$REPLY]}], ${ast[$REPLY]}: [${(Pkv)ast[$REPLY]}]"
}

function env_set(){
	emulate -L zsh

	debug_log "args: [$@]"

	add_to_hash "$1" "${ast[${2}]}" "$3"

	debug_log "ast[$1]: [${ast[$1]}], ${ast[$1]}: [${(Pkv)ast[$1]}]"
}

function env_get(){
	emulate -L zsh

	debug_log "args: [$@]"

	if ! env_find "$@"; then
		error "'${ast[${2}]}' not found"
		return 1
	fi

	debug_log "REPLY: [$REPLY], ast[$REPLY]: [${ast[$REPLY]}], ${ast[$REPLY]}: [${(Pkv)ast[$REPLY]}]"

	local -A env
	env=( "${(@Pkv)ast[${REPLY}]}" )
	REPLY=${env[${ast[${2}]}]}

	debug_log "REPLY: [$REPLY]"
}

function env_find(){
	emulate -L zsh

	debug_log "args: [$@]"

	REPLY=
	local -i ret=1

	if contains "$1" "${ast[${2}]}"; then
		REPLY=$1
		ret=0
	else
		local -A env
		env=( "${(@Pkv)ast[${1}]}" )
		local outer=${env[__outer__]}
		[[ -n "$outer" && "$outer" != "$nil" ]] && env_find "$outer" "$2" && ret=0
	fi

	debug_log "REPLY: [$REPLY]"

	return ret
}

######################################################################
### Local Variables:
### mode: shell-script
### coding: utf-8-unix
### tab-width: 4
### End:
######################################################################
