#include "type.h"

#include "base/begin_impl.h"
begin_impl
// ============================================================================

static_assert(
	sizeof(struct TypeHeader) == sizeof(int8e),
	"TypeHeader has incorrect size"
);

// ============================================================================
end_impl