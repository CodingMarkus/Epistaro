#ifdef STRICT_INCLUDE_CHECKS
	#ifndef _beginHeaderActive
		#error end_header.h includes without including begin_header.h first
	#endif
#endif
#undef _beginHeaderActive

// ============================================================================

#include "common/end_common.h"

// ============================================================================

#undef begin_header
#undef end_header

// ============================================================================

#undef public