#!/bin/sh

set -eu

origDir=$( pwd -P )
scriptDir=$( CDPATH='' cd -- "$( dirname -- "$0" )" && pwd -P )
projDir=$( CDPATH='' cd -- "$scriptDir/.." && pwd -P )

cd "$scriptDir"

. lib_error.sh
. lib_build_settings.sh


printHelp( )
{
	helpText="
  update

      Update project configuration and generated files.


  update -h[elp]

      Show this help screen.
"
	printf '%s' "$helpText"
}


printHelpAndExit( )
{
	printHelp >&2
	exit 1
}


updateClangd( )
(
	clangdPath=$1
	stylePath=$2

	[ -n "${clangdPath:-}" ] \
		|| printErrorAndExit "updateClangd() missing .clangd path"
	[ -n "${stylePath:-}" ] \
		|| printErrorAndExit "updateClangd() missing style path"

	[ -f "$clangdPath" ] || printErrorAndExit ".clangd not found: $clangdPath"
	[ -f "$stylePath" ] || printErrorAndExit "Style not found: $stylePath"

	markerLine=$( awk '/MARK:/ { print; exit }' "$clangdPath" )
	[ -n "$markerLine" ] || printErrorAndExit "Marker not found in: $clangdPath"

	indent=$( printf '%s' "$markerLine" | sed 's/[^[:space:]].*$//' )
	tmpPath=$clangdPath.tmp.$$
	trap 'rm -f "$tmpPath"' EXIT INT TERM

	awk '/MARK:/ { print; exit } { print }' "$clangdPath" > "$tmpPath"

	printf '%s\n' "${indent}#" >> "$tmpPath"
	printf '%s\n' "${indent}# Do not remove marker above!" >> "$tmpPath"
	printf '%s\n' "${indent}# Settings below are managed by update script." \
		>> "$tmpPath"
	printf '\n' >> "$tmpPath"

	settings=$( expandStyle "$stylePath" )
	if [ -n "$settings" ]
	then
		printf '%s\n' "$settings" \
		| while IFS= read -r line || [ -n "$line" ]
		do
			[ -n "$line" ] || continue
			printf '%s- %s\n' "$indent" "$line"
		done >> "$tmpPath"
	fi

	mv "$tmpPath" "$clangdPath"
	trap - EXIT INT TERM
)


case "${1:-}" in
	-help|-h)
		[ "$#" -eq 1 ] || printHelpAndExit
		printHelp
		exit 0
		;;

	-*)
		printHelpAndExit
		;;
esac

defaultStylePath=$projDir/styles/_defaults/_default.cfg
updateClangd "$projDir/.clangd" "$defaultStylePath"

printf '\n====== All Done ======\n'
