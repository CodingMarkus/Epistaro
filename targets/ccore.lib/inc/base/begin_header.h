#ifdef _beginHeaderActive
	#error begin_header.h included twice without including end_header.h first
#endif
#define _beginHeaderActive

// ============================================================================

#include "common/begin_common.h"
#include "common/always/begin_ptr.h"

// ============================================================================

#define begin_header \
	_Pragma("clang assume_nonnull begin")

#define end_header \
	_Pragma("clang assume_nonnull end")
