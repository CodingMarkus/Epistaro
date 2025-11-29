#ifdef _beginHeaderActive
	#error begin_header.h included twice without including end_header.h first
#endif
#define _beginHeaderActive

// ============================================================================

#include "base/common/begin_common.h"

// ============================================================================

#define begin_header \
	_Pragma("clang assume_nonnull begin")

#define end_header \
	_Pragma("clang assume_nonnull end")

// ============================================================================

#define public __attribute__((visibility("default")))
