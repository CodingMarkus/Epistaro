#pragma once

#include "hasher.h"

#include "base/begin_header.h"
begin_header
// ============================================================================

#ifndef XXH_ERRORCODE_DEFINED
#define XXH_ERRORCODE_DEFINED

typedef enum {
	XXH_OK = 0,
	XXH_ERROR = 1
} XXH_errorcode;

#endif

// ----------------------------------------------------------------------------

#ifndef XXH32_HASH_T_DEFINED
#define XXH32_HASH_T_DEFINED
typedef uint32_t XXH32_hash_t;
#endif

/** XXH32 streaming state (opaque). */
#ifndef XXH32_STATE_T_DEFINED
#define XXH32_STATE_T_DEFINED
typedef struct XXH32_state_s XXH32_state_t;
#endif

#ifndef XXH32_CANONICAL_T_DEFINED
#define XXH32_CANONICAL_T_DEFINED
typedef struct {
	unsigned char digest[4];
} XXH32_canonical_t;
#endif

// ----------------------------------------------------------------------------

XXH32_hash_t XXH32( const void * input, size_t length, XXH32_hash_t seed );

XXH32_state_t * XXH32_createState( void );

XXH_errorcode XXH32_freeState( XXH32_state_t * statePtr );

XXH_errorcode XXH32_reset( XXH32_state_t * statePtr, XXH32_hash_t seed );

XXH_errorcode XXH32_update(
	XXH32_state_t * statePtr, const void * input, size_t length
);

XXH32_hash_t XXH32_digest( const XXH32_state_t * statePtr );

void XXH32_copyState(
	XXH32_state_t * dst_state, const XXH32_state_t * src_state
);

void XXH32_canonicalFromHash( XXH32_canonical_t * dst, XXH32_hash_t hash );

XXH32_hash_t XXH32_hashFromCanonical( const XXH32_canonical_t * src );

// ----------------------------------------------------------------------------

const HasherInterface * getHasherInterface_XXH32( void );

// ============================================================================
end_header
#include "base/end_header.h"
