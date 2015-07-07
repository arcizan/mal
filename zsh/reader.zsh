[[ -n "$__reader_zsh" ]] && return

typeset -r __reader_zsh='true'

source ${0:h}/types.zsh
source ${0:h}/debug.zsh

function read_str(){
	emulate -L zsh

	local -a read_tokens
	local -i read_idx

	debug_log "args: [$*]"

	tokenize "$*" || return $?

	debug_log "read_tokens: [$read_tokens]"

	[[ -z "$read_tokens" ]] && { REPLY=; return 1; }

	read_form || return $?

	debug_log "REPLY: [$REPLY]"
}

function tokenize(){
	emulate -L zsh

	setopt rematch_pcre # rc_quotes option doesn't work in regexp?

	debug_log "args: [$*]"

	local str="$*" token match
	local -i idx

	read_tokens=()
	read_idx=1

	while ((${#str} > 0)); do
		debug_log "str: [$str]"

		if [[ ! "$str" =~ '^([\s,]*)(~@|[\[\]{}()'\''`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}()'\''"`,;]*)' || -z "${(j::)match}" ]]; then
			error "tokenize error at $str"
			return 1
		fi

		str=${str#${(j::)match}}
		token=${match[2]}

		debug_log "token: [$token]"

		[[ "$token" =~ '^\s*(?:;.*)?$' ]] && continue

		read_tokens[$((++idx))]=$token
	done

	return 0
}

function read_form(){
	emulate -L zsh

	debug_log "token: [${read_tokens[$read_idx]}]"

	case "${read_tokens[${read_idx}]}" in
		(\')	read_symbol 'quote'          || return $?;;
		(\`)	read_symbol 'quasiquote'     || return $?;;
		(\~)	read_symbol 'unquote'        || return $?;;
		(\~\@)	read_symbol 'splice-unquote' || return $?;;
		(\^)	read_symbol 'with-meta'      || return $?;;
		(\@)	read_symbol 'deref'          || return $?;;
		(\()	read_seq 'List' '(' ')'      || return $?;;
		(\))	error "unexpected ')'";         return 1;;
		(\[)	read_seq 'Vector' '[' ']'    || return $?;;
		(\])	error "unexpected ']'";         return 1;;
		(\{)	read_seq 'Hash' '{' '}'      || return $?;;
		(\})	error "unexpected '}'";         return 1;;
		(*)		read_atom                    || return $?;;
	esac

	debug_log "REPLY: [$REPLY]"
}

function read_symbol(){
	emulate -L zsh

	debug_log "arg: [$1]"

	Symbol "$1"
	local s=$REPLY

	((read_idx++))

	case "$1" in
		(with-meta)
			read_form || return $?
			local meta=$REPLY
			read_form || return $?
			List "$s" "$REPLY" "$meta"
			;;
		(*)
			read_form || return $?
			List "$s" "$REPLY"
			;;
	esac

	debug_log "REPLY: [$REPLY]"
}

function read_seq(){
	emulate -L zsh

	debug_log "args: [$@]"

	local type=$1 start=$2 end=$3 items token

	if [[ "${read_tokens[${read_idx}]}" != "$start" ]]; then
		reply=()
		error "expected '$start'"
		return 1
	fi

	items=()
	token=${read_tokens[$((++read_idx))]}

	debug_log "token: [$token]"

	while [[ "$token" != "$end" ]]; do
		if [[ -z "$token" ]]; then
			reply=()
			error "expected '$end', got EOF"
			return 1
		fi

		read_form
		items+=$REPLY
		token=${read_tokens[${read_idx}]}

		debug_log "items: [$items]"
		debug_log "token: [$token]"
	done

	((read_idx++))

	$type "${(@)items}"

	debug_log "REPLY: [$REPLY]"
}

function read_atom(){
	emulate -L zsh

	local token=${read_tokens[$((read_idx++))]}

	debug_log "token: [$token]"

	case "$token" in
		(nil)		REPLY=$nil;;
		(true)		REPLY=$true;;
		(false)		REPLY=$false;;
		([0-9]*)	Number "$token";;
		(\"*)		String "${${token:1:-1}//\\\"/\"}";;
		(:*)		Keyword "${token:1}";;
		(*)			Symbol "$token";;
	esac

	debug_log "REPLY: [$REPLY]"
}

######################################################################
### Local Variables:
### mode: shell-script
### coding: utf-8-unix
### tab-width: 4
### End:
######################################################################
