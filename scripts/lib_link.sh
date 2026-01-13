#!/bin/sh

set -eu

[ -n "${__included_lib_link_sh:-}" ] && return 0
__included_lib_link_sh=1


. lib_platform.sh
. lib_quote.sh
. lib_sanitize.sh
. lib_error.sh
. lib_clang.sh
. lib_fs.sh
. lib_outdated.sh
. lib_build_settings.sh


# Prints the dynamic library extension for the current platform.
#
dynamicLibExtension( )
{
	if platformTargetIsApple
	then
		printf '%s\n' ".dylib"
	elif platformTargetIsWindows
	then
		printf '%s\n' ".dll"
	else
		printf '%s\n' ".so"
	fi
}


# Prints linker flags for deploy post-processing.
#
_deployPostprocessFlags( )
{
	if platformTargetIsApple
	then
		printf '%s\n' "-Wl,-dead_strip"
	else
		printf '%s\n' "-Wl,--gc-sections"
	fi
}


# ($1) - Force deploy processing when set to 1.
#
# Returns success if deploy processing should be applied.
#
deployProcessingEnabled( )
{
	_dpe_force=${1:-0}

	if [ -n "${__style_set_DEPLOY_PROCESSING+x}" ] \
		|| [ "$_dpe_force" -eq 1 ]
	then
		return 0
	fi
	return 1
}


# $1 - Output path.
#
# Prints the unstripped output path for deploy processing.
#
deployUnstrippedPath( )
(
	_dup_path=$1

	case "$_dup_path" in
		*/*)
			_dup_dir=${_dup_path%/*}
			_dup_file=${_dup_path##*/}
			;;
		*)
			_dup_dir=""
			_dup_file=$_dup_path
			;;
	esac

	case "$_dup_file" in
		*.*)
			_dup_base=${_dup_file%.*}
			_dup_ext=.${_dup_file##*.}
			;;
		*)
			_dup_base=$_dup_file
			_dup_ext=""
			;;
	esac

	_dup_unstripped=${_dup_base}_unstripped${_dup_ext}
	if [ -n "$_dup_dir" ]
	then
		printf '%s/sym/%s\n' "$_dup_dir" "$_dup_unstripped"
	else
		printf '%s\n' "$_dup_unstripped"
	fi
)


# $1 - Output path.
#
# Prints the deploy symbols directory for the output path.
#
deploySymbolsDirFromPath( )
(
	_dsd_path=$1

	case "$_dsd_path" in
		*/*) _dsd_dir=${_dsd_path%/*} ;;
		*) _dsd_dir="." ;;
	esac

	case "$_dsd_dir" in
		*/sym) printf '%s\n' "$_dsd_dir" ;;
		*) printf '%s/sym\n' "$_dsd_dir" ;;
	esac
)


# $1 - Stripped output path.
#
# Prints the debug symbols path for deploy processing.
#
deployDebugSymbolsPath( )
(
	_ddp_stripped=$1

	if platformTargetIsApple
	then
		_ddp_ext=".dSYM"
	else
		_ddp_ext=".debug"
	fi

	case "$_ddp_stripped" in
		*/*)
			_ddp_dir=${_ddp_stripped%/*}
			_ddp_file=${_ddp_stripped##*/}
			;;
		*)
			_ddp_dir=""
			_ddp_file=$_ddp_stripped
			;;
	esac

	if [ -n "$_ddp_dir" ]
	then
		printf '%s/sym/%s%s\n' "$_ddp_dir" "$_ddp_file" "$_ddp_ext"
	else
		printf '%s%s\n' "$_ddp_file" "$_ddp_ext"
	fi
)


# $1 - Quoted clang flags string.
#
# Returns success if LTO flags are present.
#
_linkFlagsContainLto( )
{
	_lfcl_flags=$1

	[ -n "$_lfcl_flags" ] || return 1

	eval "set -- $_lfcl_flags"
	while [ "$#" -gt 0 ]
	do
		case "$1" in
			-flto|-flto=*) return 0 ;;
		esac
		shift
	done

	return 1
}


# $1 - Quoted clang flags string.
# $2 - Output path.
#
# Prints updated flags with the LTO object path appended when needed.
#
_linkFlagsWithLtoObjectPath( )
(
	_lflop_flags=$1
	_lflop_out=$2

	if platformTargetIsApple && _linkFlagsContainLto "$_lflop_flags"
	then
		_lflop_sym_dir=$( deploySymbolsDirFromPath "$_lflop_out" )
		ensureDir "$_lflop_sym_dir"
		case "$_lflop_out" in
			*/*) _lflop_file=${_lflop_out##*/} ;;
			*) _lflop_file=$_lflop_out ;;
		esac
		_lflop_lto_path=$_lflop_sym_dir/${_lflop_file}.lto
		_lflop_settings="-Wl,-object_path_lto,$_lflop_lto_path"
		_lflop_extra=$( quoteSettings "$_lflop_settings" )
		appendQuotedSettings "$_lflop_flags" "$_lflop_extra"
		return 0
	fi

	printf '%s' "$_lflop_flags"
)


_resolveObjcopyTool( )
{
	if [ -n "${OBJCOPY:-}" ]
	then
		command -v "$OBJCOPY" >/dev/null 2>&1 \
			|| printErrorAndExit "objcopy not found: $OBJCOPY"
		printf '%s\n' "$OBJCOPY"
		return 0
	fi

	if command -v objcopy >/dev/null 2>&1
	then
		printf '%s\n' "objcopy"
		return 0
	fi
	if command -v llvm-objcopy >/dev/null 2>&1
	then
		printf '%s\n' "llvm-objcopy"
		return 0
	fi

	printErrorAndExit "objcopy not found"
}


_resolveStripTool( )
{
	if [ -n "${STRIP:-}" ]
	then
		command -v "$STRIP" >/dev/null 2>&1 \
			|| printErrorAndExit "strip not found: $STRIP"
		printf '%s\n' "$STRIP"
		return 0
	fi

	if command -v strip >/dev/null 2>&1
	then
		printf '%s\n' "strip"
		return 0
	fi
	if command -v llvm-strip >/dev/null 2>&1
	then
		printf '%s\n' "llvm-strip"
		return 0
	fi

	printErrorAndExit "strip not found"
}


# $1 - Unstripped output path.
# $2 - Stripped output path.
#
# Extracts debug symbols and writes a stripped output.
#
deployPostprocessTarget( )
(
	_dpt_unstripped=$1
	_dpt_stripped=$2

	[ -e "$_dpt_unstripped" ] || printErrorAndExit \
		"Output not found: $_dpt_unstripped"

	if platformTargetIsApple
	then
		command -v dsymutil >/dev/null 2>&1 \
			|| printErrorAndExit "dsymutil not found"
		_dpt_strip=$( _resolveStripTool )
		_dpt_dsym=$( deployDebugSymbolsPath "$_dpt_stripped" )
		case "$_dpt_dsym" in
			*/*) ensureDir "${_dpt_dsym%/*}" ;;
		esac
		buildDebugPrintCommand dsymutil "$_dpt_unstripped" \
			-o "$_dpt_dsym"
		dsymutil "$_dpt_unstripped" -o "$_dpt_dsym"
		cp "$_dpt_unstripped" "$_dpt_stripped"
		buildDebugPrintCommand "$_dpt_strip" -S "$_dpt_stripped"
		"$_dpt_strip" -S "$_dpt_stripped"
		return 0
	fi

	_dpt_objcopy=$( _resolveObjcopyTool )
	_dpt_strip=$( _resolveStripTool )
	_dpt_debug=$( deployDebugSymbolsPath "$_dpt_stripped" )
	case "$_dpt_debug" in
		*/*) ensureDir "${_dpt_debug%/*}" ;;
	esac
	buildDebugPrintCommand "$_dpt_objcopy" --only-keep-debug \
		"$_dpt_unstripped" "$_dpt_debug"
	"$_dpt_objcopy" --only-keep-debug "$_dpt_unstripped" \
		"$_dpt_debug"
	cp "$_dpt_unstripped" "$_dpt_stripped"
	buildDebugPrintCommand "$_dpt_strip" --strip-debug \
		"$_dpt_stripped"
	"$_dpt_strip" --strip-debug "$_dpt_stripped"
	buildDebugPrintCommand "$_dpt_objcopy" --add-gnu-debuglink=\
"$_dpt_debug" "$_dpt_stripped"
	"$_dpt_objcopy" --add-gnu-debuglink="$_dpt_debug" \
		"$_dpt_stripped"
)


# $1 - Output library path.
# $2 - Working directory for clang.
# $3 - clang flags string, already quoted for eval.
# $4 - Print leading spacing when set to 1.
# ($5) - Force deploy processing when set to 1.
# $6.. - Object file paths.
#
# Links a dynamic library and runs deploy processing when enabled.
#
linkDynamicLibraryFinal( )
(
	_ldlf_out=$1
	_ldlf_work=$2
	_ldlf_flags=$3
	_ldlf_spacing=${4:-0}
	_ldlf_force=${5:-0}
	shift 5

	_ldlf_deploy=0
	if deployProcessingEnabled "$_ldlf_force"
	then
		_ldlf_deploy=1
	fi

	_ldlf_link_out=$_ldlf_out
	_ldlf_link_flags=$_ldlf_flags
	if [ "$_ldlf_deploy" -eq 1 ]
	then
		_ldlf_link_out=$( deployUnstrippedPath "$_ldlf_out" )
		_ldlf_link_flags=$( _linkFlagsWithLtoObjectPath \
			"$_ldlf_flags" "$_ldlf_link_out" )
	fi

	if [ "$_ldlf_deploy" -eq 1 ]
	then
		if isOutdated "$_ldlf_link_out" "$@"
		then
			if [ "$_ldlf_spacing" -eq 1 ]
			then
				printf '\n'
				_ldlf_spacing=0
			fi
			printf 'Linking %s...\n' "${_ldlf_link_out##*/}"
			linkDynamicLibrary "$_ldlf_link_out" \
				"$_ldlf_work" "$_ldlf_link_flags" "$@"
			printf '\n'
		fi

		_ldlf_debug=$( deployDebugSymbolsPath "$_ldlf_out" )
		if isOutdated "$_ldlf_out" "$_ldlf_link_out" \
			|| isOutdated "$_ldlf_debug" "$_ldlf_link_out"
		then
			if [ "$_ldlf_spacing" -eq 1 ]
			then
				printf '\n'
				_ldlf_spacing=0
			fi
			printf 'Post-processing %s...\n' "${_ldlf_out##*/}"
			deployPostprocessTarget \
				"$_ldlf_link_out" "$_ldlf_out"
			printf '\n'
		fi
		return 0
	fi

	if isOutdated "$_ldlf_out" "$@"
	then
		if [ "$_ldlf_spacing" -eq 1 ]
		then
			printf '\n'
		fi
		printf 'Linking %s...\n' "${_ldlf_out##*/}"
		linkDynamicLibrary "$_ldlf_out" "$_ldlf_work" \
			"$_ldlf_link_flags" "$@"
		printf '\n'
	fi
)


# $1 - Output binary path.
# $2 - Working directory for clang.
# $3 - clang flags string, already quoted for eval.
# $4 - Print leading spacing when set to 1.
# ($5) - Force deploy processing when set to 1.
# $6.. - Object file paths.
#
# Links a binary and runs deploy processing when enabled.
#
linkBinaryFinal( )
(
	_lblf_out=$1
	_lblf_work=$2
	_lblf_flags=$3
	_lblf_spacing=${4:-0}
	_lblf_force=${5:-0}
	shift 5

	_lblf_deploy=0
	if deployProcessingEnabled "$_lblf_force"
	then
		_lblf_deploy=1
	fi

	_lblf_link_out=$_lblf_out
	_lblf_link_flags=$_lblf_flags
	if [ "$_lblf_deploy" -eq 1 ]
	then
		_lblf_link_out=$( deployUnstrippedPath "$_lblf_out" )
		_lblf_link_flags=$( _linkFlagsWithLtoObjectPath \
			"$_lblf_flags" "$_lblf_link_out" )
	fi

	if [ "$_lblf_deploy" -eq 1 ]
	then
		if isOutdated "$_lblf_link_out" "$@"
		then
			if [ "$_lblf_spacing" -eq 1 ]
			then
				printf '\n'
				_lblf_spacing=0
			fi
			printf 'Linking %s...\n' "${_lblf_link_out##*/}"
			linkBinary "$_lblf_link_out" "$_lblf_work" \
				"$_lblf_link_flags" "$@"
			printf '\n'
		fi

		_lblf_debug=$( deployDebugSymbolsPath "$_lblf_out" )
		if isOutdated "$_lblf_out" "$_lblf_link_out" \
			|| isOutdated "$_lblf_debug" "$_lblf_link_out"
		then
			if [ "$_lblf_spacing" -eq 1 ]
			then
				printf '\n'
				_lblf_spacing=0
			fi
			printf 'Post-processing %s...\n' "${_lblf_out##*/}"
			deployPostprocessTarget \
				"$_lblf_link_out" "$_lblf_out"
			printf '\n'
		fi
		return 0
	fi

	if isOutdated "$_lblf_out" "$@"
	then
		if [ "$_lblf_spacing" -eq 1 ]
		then
			printf '\n'
		fi
		printf 'Linking %s...\n' "${_lblf_out##*/}"
		linkBinary "$_lblf_out" "$_lblf_work" \
			"$_lblf_link_flags" "$@"
		printf '\n'
	fi
)




# $1 - Quoted build settings string.
# $2 - Target sanitizer settings list.
#
# Prints quoted sanitizer flags for linking.
#
_linkSanitizeFlagsFromSettings( )
(
	_lsf_build_settings=$1
	_lsf_target_sanitize=$2

	_lsf_build_sanitize=$( sanitizeSettingsFromQuoted \
		"$_lsf_build_settings" )
	_lsf_link_sanitize=$_lsf_build_sanitize
	if [ -n "$_lsf_target_sanitize" ]
	then
		while IFS= read -r _lsf_flag || [ -n "$_lsf_flag" ]
		do
			[ -n "$_lsf_flag" ] || continue
			_lsf_link_sanitize=$(
				addTargetSanitizeSetting \
					"$_lsf_build_sanitize" \
					"$_lsf_link_sanitize" \
					"$_lsf_flag"
			)
		done <<EOF
$_lsf_target_sanitize
EOF
	fi

	if [ -n "$_lsf_link_sanitize" ]
	then
		quoteSettings "$_lsf_link_sanitize"
	fi
)


# $1 - Quoted build settings string.
# $2 - Target sanitizer settings list.
# $3 - Force deploy post-processing flags when set to 1.
#
# Prints quoted link flags.
#
linkFlagsFromSettings( )
(
	_lf_settings=$1
	_lf_target_sanitize=$2
	_lf_include_deploy=${3:-0}

	_lf_flags=""
	_lf_build_link=$( linkBuildFlagsFromSettings "$_lf_settings" )
	if [ -n "$_lf_build_link" ]
	then
		_lf_flags=$( appendQuotedSettings \
			"$_lf_flags" "$_lf_build_link" )
	fi
	_lf_sanitize=$( _linkSanitizeFlagsFromSettings \
		"$_lf_settings" "$_lf_target_sanitize" )
	if [ -n "$_lf_sanitize" ]
	then
		_lf_flags=$( appendQuotedSettings \
			"$_lf_flags" "$_lf_sanitize" )
	fi

	if deployProcessingEnabled "$_lf_include_deploy"
	then
		_lf_post=$( _deployPostprocessFlags )
		if [ -n "$_lf_post" ]
		then
			_lf_post_quoted=$( quoteSettings "$_lf_post" )
			_lf_flags=$( appendQuotedSettings \
				"$_lf_flags" "$_lf_post_quoted" )
		fi
	fi

	[ -n "$_lf_flags" ] || _lf_flags="--"
	printf '%s\n' "$_lf_flags"
)
