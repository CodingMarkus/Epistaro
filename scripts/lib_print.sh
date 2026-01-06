#!/bin/sh

set -eu

[ -n "${__included_lib_print_sh:-}" ] && return 0
__included_lib_print_sh=1


# Returns success if the terminal supports color diagnostics.
#
supportsColorDiagnostics( )
{
	if [ -n "${__supports_color_diagnostics_cached+x}" ]
	then
		[ "$__supports_color_diagnostics_cached" -eq 1 ]
		return
	fi

	__supports_color_diagnostics_cached=0

	[ -t 2 ] || return 1
	command -v tput >/dev/null 2>&1 || return 1

	_scd_colors=$( tput colors 2>/dev/null || printf '' )
	case "$_scd_colors" in
		''|*[!0-9]*) return 1 ;;
	esac
	[ "$_scd_colors" -gt 0 ] || return 1

	__supports_color_diagnostics_cached=1
	return 0
}


# $1 - Color name (red, green, yellow, reset).
#
# Prints the cached tput sequence for the color, or empty if unsupported.
#
_tputColor( )
{
	_tc_name=$1
	case "$_tc_name" in
		red|green|yellow|reset) ;;
		*) printf '%s' ""; return 0 ;;
	esac

	_tc_var="__tput_color_$_tc_name"
	eval "_tc_is_set=\${$_tc_var+x}"
	if [ -n "${_tc_is_set:-}" ]
	then
		eval "printf '%s' \"\${$_tc_var}\""
		return 0
	fi

	if ! supportsColorDiagnostics
	then
		eval "$_tc_var="
		printf '%s' ""
		return 0
	fi

	case "$_tc_name" in
		red) _tc_seq=$( tput setaf 1 2>/dev/null || printf '' ) ;;
		green) _tc_seq=$( tput setaf 2 2>/dev/null || printf '' ) ;;
		yellow) _tc_seq=$( tput setaf 3 2>/dev/null || printf '' ) ;;
		reset) _tc_seq=$( tput sgr0 2>/dev/null || printf '' ) ;;
	esac

	eval "$_tc_var=\$_tc_seq"
	printf '%s' "$_tc_seq"
}


# $1 - Text to print.
# ($2) - Optional color name (red, green, yellow).
#
# Prints the text, applying the color when supported.
#
_printColored( )
{
	_pc_text=$1
	_pc_color=${2:-}

	if [ -n "$_pc_color" ] && supportsColorDiagnostics
	then
		_pc_start=$( _tputColor "$_pc_color" )
		_pc_reset=$( _tputColor "reset" )
		printf '%s%s%s' "$_pc_start" "$_pc_text" "$_pc_reset"
	else
		printf '%s' "$_pc_text"
	fi
}


# $1 - Header text to print.
#
# Prints a header with blank lines around it.
#
printHeader( )
{
	_ph_text=$1
	printf '\n'
	_printColored "$_ph_text" "yellow"
	printf '\n\n'
}


# $1 - Failure text to print.
#
# Prints the text in red.
#
printFailure( )
{
	_pf_text=$1
	_printColored "$_pf_text" "red"
}


# $1 - Success tag text to print.
#
# Prints the text in green.
#
printTestSuccess( )
{
	_pts_text=$1
	_printColored "$_pts_text" "green"
}


# $1 - Failure tag text to print.
#
# Prints the text in red.
#
printTestFailure( )
{
	_ptf_text=$1
	_printColored "$_ptf_text" "red"
}
