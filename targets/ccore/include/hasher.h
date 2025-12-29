#pragma once

#include "base/begin_header.h"
begin_header
// ============================================================================

typedef struct Hasher Hasher;

typedef int32 HashValue_Hasher;

// ----------------------------------------------------------------------------

void addByteValue_Hasher( const void * bytes, intS size );

HashValue_Hasher finalize_Hasher( Hasher * hasher );

// ----------------------------------------------------------------------------

intS getRequiredSize_Hasher( );

Hasher * init_Hasher( void * hasherStorage );

// ============================================================================
end_header
#include "base/end_header.h"