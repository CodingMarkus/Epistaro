#!/bin/sh

set -eu

[ -n "${__included_lib_style_parse_sh:-}" ] && return 0
__included_lib_style_parse_sh=1


. lib_error.sh


# $1 - String to trim.
#
# Prints the input without leading whitespace.
#
_style_trim_left( )
{
	printf '%s' "$1" | sed 's/^[[:space:]]*//'
}


# $1 - String to trim.
#
# Prints the input without leading or trailing whitespace.
#
_style_trim( )
{
	printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}


# $1 - Line containing a variable name and optional remainder.
#
# Prints the variable name on the first line and the remainder on the second.
#
_style_split_var_and_rest( )
(
	line=$1

	line=$( _style_trim_left "$line" )
	varName=${line%%[[:space:]]*}
	if [ "$line" = "$varName" ]
	then
		rest=""
	else
		rest=${line#"$varName"}
	fi

	printf '%s\n%s' "$varName" "$rest"
)


# $1 - Input string beginning with a quote.
#
# Prints the quoted content on the first line and the remainder on the second.
#
_style_split_quoted( )
(
	input=$1

	printf '%s' "$input" | awk '
BEGIN { ORS=""; }
{
	str=$0
	if (substr(str,1,1) != "\"") {
		exit 2
	}
	i=2
	out=""
	while (i <= length(str)) {
		ch = substr(str,i,1)
		if (ch == "\"") {
			rest = substr(str, i + 1)
			printf "%s\n%s", out, rest
			exit 0
		}
		if (ch == "\\") {
			if (i == length(str)) {
				out = out "\\"
				i++
				break
			}
			i++
			esc = substr(str,i,1)
			out = out "\\" esc
		} else {
			out = out ch
		}
		i++
	}
	exit 1
}'
)


# $1 - Quoted content without surrounding quotes.
#
# Prints the unescaped string.
#
_style_unescape_quoted( )
(
	input=$1

	printf '%s' "$input" | awk '
BEGIN { ORS=""; }
{
	str=$0
	i=1
	while (i <= length(str)) {
		ch = substr(str,i,1)
		if (ch == "\\") {
			i++
			if (i > length(str)) {
				printf "\\"
				break
			}
			esc = substr(str,i,1)
			if (esc == "n") {
				printf "\n"
			} else if (esc == "r") {
				printf "\r"
			} else if (esc == "t") {
				printf "\t"
			} else if (esc == "\"") {
				printf "\""
			} else if (esc == "\\") {
				printf "\\"
			} else {
				printf "\\" esc
			}
		} else {
			printf "%s", ch
		}
		i++
	}
}'
)


# $1 - Value segment to parse.
# $2 - Style file path for error reporting.
#
# Prints the parsed value.
#
_style_parse_value( )
(
	valueLine=$1
	stylePath=$2

	valueLine=$( _style_trim_left "$valueLine" )
	if [ -z "$valueLine" ]
	then
		printf '%s' ""
		return 0
	fi

	case "$valueLine" in
		\"* )
			split=$( _style_split_quoted "$valueLine" ) || \
				printErrorAndExit "Unterminated quoted value in $stylePath"
			oldIFS=$IFS
			IFS='
'
			set -- $split
			IFS=$oldIFS
			rawValue=${1-}
			leftover=${2-}
			leftover=$( _style_trim "$leftover" )
			if [ -n "$leftover" ]
			then
				printErrorAndExit \
					"Unexpected trailing text after quote in $stylePath"
			fi
			_style_unescape_quoted "$rawValue"
			;;
		*)
			printf '%s' "$( _style_trim "$valueLine" )"
			;;
	esac
)
