[[ -n "$__debug_zsh" ]] && return

typeset -r __debug_zsh='true'

debug="${ZLISP_DEBUG:-false}"

function debug_log(){
	emulate -L zsh

	setopt extended_glob

	[[ "$debug" == (#i)(true|on|yes|<1->) ]] || return 0

	print -lr -- $@
}

alias debug_log='debug_log ${0:t}:${LINENO}:'

######################################################################
### Local Variables:
### mode: shell-script
### coding: utf-8-unix
### tab-width: 4
### End:
######################################################################
