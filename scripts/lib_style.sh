#!/bin/sh

set -eu

[ -n "${__included_lib_style_sh:-}" ] && return 0
__included_lib_style_sh=1


. lib_style_parse.sh
. lib_style_vars.sh
. lib_style_include.sh
