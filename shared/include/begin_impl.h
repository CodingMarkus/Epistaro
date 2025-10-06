#pragma once

#include <stdlib.h>   // IWYU pragma: keep
#include <assert.h>   // IWYU pragma: keep
#include <stdarg.h>   // IWYU pragma: keep
#include <string.h>   // IWYU pragma: keep
#include <inttypes.h> // IWYU pragma: keep

#include "../src/include/begin_common.h"


#define begin_impl \
	_Pragma("clang assume_nonnull begin")

#define end_impl \
	_Pragma("clang assume_nonnull end")


#define init  __auto_type
#define def   const __auto_type


#define _assertFail_0( )                         assert(false)
#define _assertFail_1( msg )                     assert(false && msg)
#define _assertFail_x(_1, _2, assertFunc, ...)   assertFunc

#define assertFail( ... )           \
	_assertFail_x(                  \
		_, ##__VA_ARGS__,           \
		_assertFail_1(__VA_ARGS__), \
		_assertFail_0()             \
	)


#define MIN( a, b ) \
	({ def _a = (a); def _b = (b); (_a <= _b ? _a : _b) })

#define MAX( a, b ) \
	({ def _a = (a); def _b = (b); (_a > _b ? _a : _b) })

#define CLAMP( a, min, max ) \
	({ def _a = (a); def _min = (min); def _max = (max); \
		(_a < _min ? _min : (_a > _max ? _max : _a) })


#define guard_def( name, value )                  \
	def name = (typeof(*value) *_Nonnull)(value); \
	if (name)