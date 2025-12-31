#!/bin/sh

set -eu

[ -n "${__included_lib_ar_sh:-}" ] && return 0
__included_lib_ar_sh=1


. lib_assert.sh
. lib_error.sh
. lib_fs.sh
. lib_objects.sh


# $1 - Output static library path.
# $2 - Working directory for ar.
# $3.. - Object file paths.
#
# Archives object files into a static library.
#
createStaticLibraryFromObjects( )
(
	outPath=$1
	workDir=$2
	shift 2

	assert "[ -n \"${outPath:-}\" ]" \
		"createStaticLibraryFromObjects() missing output path"
	assert "[ -n \"${workDir:-}\" ]" \
		"createStaticLibraryFromObjects() missing work dir"
	assert "[ $# -gt 0 ]" \
		"createStaticLibraryFromObjects() missing object files"

	arTool=${AR:-ar}
	command -v "$arTool" >/dev/null 2>&1 \
		|| printErrorAndExit "ar not found: $arTool"

	case "$outPath" in
		*/*) outDir=${outPath%/*} ;;
		*) outDir="." ;;
	esac
	ensure_dir "$outDir"

	workDirAbs=$( abs_dir "$workDir" ) \
		|| printErrorAndExit "Work dir not found: $workDir"
	workDirAbs=$( strip_trailing_slash "$workDirAbs" )

	objArgs=$( collectObjectArgs "$workDirAbs" "$@" )

	eval "set -- $objArgs"
	(
		cd "$workDirAbs"
		"$arTool" rcs "$outPath" "$@"
	)
)
