#pragma once

#include "base/begin_header.h"
begin_header
// ============================================================================

typedef void  Hasher;

typedef struct NativeValue  NativeValue;

typedef int32  HashValue_Hasher;

// ----------------------------------------------------------------------------

/**
	@fn addPrimitive_Hasher( prim )

	Add primitive value to hasher.
 */
#define addPrimitive_Hasher( h, p ) addBytes(h, p, sizeof(p))


/** Abstract hasher interface */
typedef struct  {
	/** How much memory that hasher requires on heap or stack. */
	intS (*_req getRequiredSize)( void );

	/** Initialize heap or stack memory. */
	Hasher *_req (*_req initStorage)( void * hasherStorage );

	/** Get fhe final hash value. */
	HashValue_Hasher (*_req finalize)( Hasher * hasher );

	/** Add more bytes to the hasher. */
	void (*_req addBytes)(
		Hasher * hasher, Opt(const void *) bytes, intS size
	);

} HasherInterface;


/**
	Get the default hasher interface used by `hash_NativeValue()`.
*/
const HasherInterface * getDefaultHasherInterface_Hasher( void );

// ============================================================================
end_header
#include "base/end_header.h"
