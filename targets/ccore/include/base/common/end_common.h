#ifdef STRICT_INCLUDE_CHECKS
	#ifndef _beginCommonActive
		#error end_common.h included without including begin_common.h first
	#endif
#endif
#undef _beginCommonActive

// ============================================================================

#include "always/end_cpp.h"

// ============================================================================

#ifdef _targetsActive
	#include "optional/end_targets.h"
#endif

// ============================================================================

#undef nil

// ============================================================================

#undef _opt
#undef _req
#undef Opt

// ============================================================================

#undef defEnum
#undef defOpenEnum
#undef defOptions

// ============================================================================

#undef int8
#undef int16
#undef int32
#undef int64

#undef uint8
#undef uint16
#undef uint32
#undef uint64

#undef sint8
#undef sint16
#undef sint32
#undef sint64

#undef uint8e
#undef uint16e
#undef uint32e
#undef uint64e

#undef sint8e
#undef sint16e
#undef sint32e
#undef sint64e
