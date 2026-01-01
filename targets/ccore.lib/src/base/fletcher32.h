#pragma once

#include "base/begin_header.h"
begin_header
// ============================================================================

struct Fletcher32State {
	int32 s1;
	int32 s2;
};

// ----------------------------------------------------------------------------

struct Fletcher32State Fletcher32Update(
	const struct Fletcher32State state, const void * data, size_t len
);


int32e Fletcher32Finalize( const struct Fletcher32State state );

// ============================================================================
end_header
#include "base/end_header.h"