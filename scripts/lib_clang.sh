#!/bin/sh

set -eu

[ -n "${__included_lib_clang_sh:-}" ] && return 0
__included_lib_clang_sh=1

. lib_assert.sh
. lib_error.sh

# $1 - C source file path.
# $2 - Dependency file path to generate (.dep).
# $3 - Working directory for clang.
# $4 - clang flags string, already quoted for eval.
#
# Generates a dependency file with one path per line, relative to the source
# file directory.
#
generateDepFile( )
(
	srcPath=$1
	depPath=$2
	workDir=$3
	flags=$4

	assert "[ -n \"${srcPath:-}\" ]" "generateDepFile() missing source path"
	assert "[ -n \"${depPath:-}\" ]" "generateDepFile() missing dep path"
	assert "[ -n \"${workDir:-}\" ]" "generateDepFile() missing work dir"
	assert "[ -n \"${flags:-}\" ]" "generateDepFile() missing flags"

	[ -f "$srcPath" ] || printErrorAndExit "Source file not found: $srcPath"

	clang=${CLANG:-${CC:-clang}}
	command -v "$clang" >/dev/null 2>&1 \
		|| printErrorAndExit "clang not found: $clang"

	case "$srcPath" in
		*/*) srcDir=${srcPath%/*}; srcBase=${srcPath##*/} ;;
		*) srcDir="."; srcBase="$srcPath" ;;
	esac

	case "$srcDir" in
		/*) srcDirAbs=$srcDir ;;
		*)
			srcDirAbs=$(
				CDPATH='' cd -- "$srcDir" 2>/dev/null && pwd -P
			) || printErrorAndExit "Source dir not found: $srcDir"
			;;
	esac

	case "$workDir" in
		/*) workDirAbs=$workDir ;;
		*)
			workDirAbs=$(
				CDPATH='' cd -- "$workDir" 2>/dev/null && pwd -P
			) || printErrorAndExit "Work dir not found: $workDir"
			;;
	esac

	case "$srcPath" in
		/*) srcPathAbs=$srcPath ;;
		*) srcPathAbs=$srcDirAbs/$srcBase ;;
	esac

	case "$depPath" in
		*/*) depDir=${depPath%/*} ;;
		*) depDir="." ;;
	esac

	[ -d "$depDir" ] || mkdir -p "$depDir"

	case "$depPath" in
		/*) depPathAbs=$depPath ;;
		*) depPathAbs=$( pwd -P )/$depPath ;;
	esac

	case "$srcDirAbs" in
		*/) srcDirAbs=${srcDirAbs%/} ;;
	esac

	case "$workDirAbs" in
		*/) workDirAbs=${workDirAbs%/} ;;
	esac

	tmpPath=$depPathAbs.tmp.$$
	trap 'rm -f "$tmpPath"' EXIT INT TERM

	eval "set -- $flags"
	(
		cd "$workDirAbs"
		"$clang" -MM -MG -MF "$tmpPath" "$@" "$srcPathAbs"
	)

	# clang -MM emits Makefile-style deps with:
	# - backslash-newline continuations
	# - backslash-escaped spaces within paths
	# This awk collapses continuations, unescapes tokens, and normalizes to
	# absolute paths (relative deps are rooted at workDir).
	awk -v workdir="$workDirAbs" '
		function normpath(path,  parts, stack, n, i, part, out, stackn) {
			n = split(path, parts, "/")
			stackn = 0
			for (i = 1; i <= n; i++) {
				part = parts[i]
				if (part == "" || part == ".") continue
				if (part == "..") {
					if (stackn > 0) stackn--
					continue
				}
				stack[++stackn] = part
			}
			out = "/"
			for (i = 1; i <= stackn; i++) {
				out = out stack[i]
				if (i < stackn) out = out "/"
			}
			return out
		}
		function emit_dep(dep, depAbs) {
			if (dep == "") return
			if (dep ~ /^\//) depAbs = dep
			else depAbs = workdir "/" dep
			print normpath(depAbs)
		}
		function emit_deps(line, i, c, dep, esc) {
			sub(/^[^:]*:[[:space:]]*/, "", line)
			dep = ""
			esc = 0
			for (i = 1; i <= length(line); i++) {
				c = substr(line, i, 1)
				if (esc) {
					dep = dep c
					esc = 0
					continue
				}
				if (c == "\\") {
					esc = 1
					continue
				}
				if (c ~ /[[:space:]]/) {
					if (dep != "") {
						emit_dep(dep)
						dep = ""
					}
					continue
				}
				dep = dep c
			}
			if (esc) dep = dep "\\"
			if (dep != "") emit_dep(dep)
		}
		{
			if ($0 ~ /\\$/) {
				sub(/\\$/, "", $0)
				acc = acc $0 " "
				next
			}
			acc = acc $0
			emit_deps(acc)
			acc = ""
		}
		END {
			if (acc != "") emit_deps(acc)
		}
	' "$tmpPath" > "$depPathAbs"
)


# $1 - C source file path.
# $2 - Object file output path.
# $3 - Working directory for clang.
# $4 - clang flags string, already quoted for eval.
#
# Compiles a single source file into an object file.
#
buildFile( )
(
	srcPath=$1
	objPath=$2
	workDir=$3
	flags=$4

	assert "[ -n \"${srcPath:-}\" ]" "buildFile() missing source path"
	assert "[ -n \"${objPath:-}\" ]" "buildFile() missing object path"
	assert "[ -n \"${workDir:-}\" ]" "buildFile() missing work dir"
	assert "[ -n \"${flags:-}\" ]" "buildFile() missing flags"

	[ -f "$srcPath" ] || printErrorAndExit "Source file not found: $srcPath"

	clang=${CLANG:-${CC:-clang}}
	command -v "$clang" >/dev/null 2>&1 \
		|| printErrorAndExit "clang not found: $clang"

	case "$objPath" in
		*/*) objDir=${objPath%/*} ;;
		*) objDir="." ;;
	esac
	[ -d "$objDir" ] || mkdir -p "$objDir"

	case "$srcPath" in
		*/*) srcDir=${srcPath%/*}; srcBase=${srcPath##*/} ;;
		*) srcDir="."; srcBase="$srcPath" ;;
	esac

	case "$srcDir" in
		/*) srcDirAbs=$srcDir ;;
		*)
			srcDirAbs=$(
				CDPATH='' cd -- "$srcDir" 2>/dev/null && pwd -P
			) || printErrorAndExit "Source dir not found: $srcDir"
			;;
	esac

	case "$workDir" in
		/*) workDirAbs=$workDir ;;
		*)
			workDirAbs=$(
				CDPATH='' cd -- "$workDir" 2>/dev/null && pwd -P
			) || printErrorAndExit "Work dir not found: $workDir"
			;;
	esac

	case "$srcPath" in
		/*) srcPathAbs=$srcPath ;;
		*) srcPathAbs=$srcDirAbs/$srcBase ;;
	esac

	eval "set -- $flags"
	(
		cd "$workDirAbs"
		"$clang" -c -o "$objPath" "$@" "$srcPathAbs"
	)
)
