#pragma once

#include "begin_header.h"
begin_header
// ============================================================================

struct Fletcher32State {
	uint_fast32_t s1;
	uint_fast32_t s2;
};

// ----------------------------------------------------------------------------

struct Fletcher32State Fletcher32Update(
	const struct Fletcher32State state, const void * data, size_t len
);


uint32_t Fletcher32Finalize( const struct Fletcher32State state );

// ============================================================================
end_header
#include "end_header.h"