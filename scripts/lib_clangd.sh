#!/bin/sh

set -eu

[ -n "${__included_lib_clangd_sh:-}" ] && return 0
__included_lib_clangd_sh=1


. lib_error.sh
. lib_build_settings.sh


# $1 - .clangd path.
# $2 - Default build style file path.
#
# Expands the style and replaces the managed section in .clangd.
#
updateClangd( )
(
	clangdPath=$1
	stylePath=$2
	markerText="MARK: DEFAULT FLAGS"
	defaultIndent="    "

	[ -n "${clangdPath:-}" ] \
		|| printErrorAndExit "updateClangd() missing .clangd path"
	[ -n "${stylePath:-}" ] \
		|| printErrorAndExit "updateClangd() missing style path"

	[ -f "$stylePath" ] || printErrorAndExit "Style not found: $stylePath"

	tmpPath=$clangdPath.tmp.$$
	trap 'rm -f "$tmpPath"' EXIT INT TERM

	if [ -f "$clangdPath" ]
	then
		markerLine=$( awk -v marker="$markerText" \
			'index($0, marker) { print; exit }' "$clangdPath" )
		if [ -n "$markerLine" ]
		then
			indent=$( printf '%s' "$markerLine" | sed 's/[^[:space:]].*$//' )
			awk -v marker="$markerText" \
				'index($0, marker) { print; exit } { print }' \
				"$clangdPath" > "$tmpPath"
		else
			indent=$( awk '/^[[:space:]]*-[[:space:]]/ { print; exit }' \
				"$clangdPath" | sed 's/[^[:space:]].*$//' )
			[ -n "$indent" ] || indent=$defaultIndent
			cat "$clangdPath" > "$tmpPath"
			printf '\n' >> "$tmpPath"
			printf '%s%s\n' "$indent" \
				"# ------ $markerText ------" >> "$tmpPath"
		fi
	else
		indent=$defaultIndent
		cat <<'EOF' > "$tmpPath"
CompileFlags:
  Add:
    # Assume DEVELOPING, TESTING, DEBUGGING, and PROFILING by default.
    # Compile scripts can later on override that.
    - -DDEVELOPING
    - -DTESTING
    - -DDEBUGGING
    - -DPROFILING

EOF
		printf '%s%s\n' "$indent" \
			"# ------ $markerText ------" >> "$tmpPath"
	fi

	printf '%s\n' "${indent}#" >> "$tmpPath"
	printf '%s\n' "${indent}# Do not remove marker above!" >> "$tmpPath"
	printf '%s\n' "${indent}# Settings below are managed by update script." \
		>> "$tmpPath"

	settings=$( expandStyle "$stylePath" )
	if [ -n "$settings" ]
	then
		printf '%s\n' "$settings" | while IFS= read -r line || [ -n "$line" ]
		do
			[ -n "$line" ] || continue
			printf '%s- %s\n' "$indent" "$line"
		done >> "$tmpPath"
	fi

	mv "$tmpPath" "$clangdPath"
	trap - EXIT INT TERM
)
