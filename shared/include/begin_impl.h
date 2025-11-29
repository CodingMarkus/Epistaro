#pragma once

#include "../../targets/core/value.h" // IWYU pragma: keep

#include <stdlib.h>   // IWYU pragma: keep
#include <assert.h>   // IWYU pragma: keep
#include <stdarg.h>   // IWYU pragma: keep
#include <string.h>   // IWYU pragma: keep
#include <inttypes.h> // IWYU pragma: keep

#include "base/common/begin_common.h"


#define begin_impl \
	_Pragma("clang assume_nonnull begin")

#define end_impl \
	_Pragma("clang assume_nonnull end")


#define init  __auto_type
#define def   const __auto_type


#define _guardTmp( n )  CONCAT(_guardTmpValue, n)
#define _guardBegin( var, expr, n )                \
	{                                              \
		def _guardTmp(n) = (expr);                 \
		if (_guardTmp(n)) {                        \
			def var =                              \
				(typeof(*_guardTmp(n)) * _Nonnull) \
				(_guardTmp(n));

#define guard( var, expr )  _guardBegin(var, expr, __COUNTER__)
#define endguard            } }


#define return_unless( returnValue, var, expr ) \
	def var = (typeof(*expr) * _Nonnull)(expr); \
	if (!var) return (returnValue)
