#pragma once

#include "base/begin_header.h"
begin_header
// ============================================================================

defEnum( BaseType, int8e ) {
	BaseType_Intf_Native = 0,

	BaseType_Value_Native = 1,

	BaseType_Reserved = 7,
};


struct TypeHeader {
	int8e type:3;
	int8e reserved:5;
};

// ============================================================================
end_header
#include "base/end_header.h"