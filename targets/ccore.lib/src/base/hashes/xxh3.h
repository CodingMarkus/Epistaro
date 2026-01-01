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

#ifndef XXH64_HASH_T_DEFINED
#define XXH64_HASH_T_DEFINED
typedef uint64_t XXH64_hash_t;
#endif

#ifndef XXH3_SECRET_SIZE_MIN
#define XXH3_SECRET_SIZE_MIN 136
#endif

/** XXH3 streaming state (opaque). */
typedef struct XXH3_state_s XXH3_state_t;

// ----------------------------------------------------------------------------

XXH64_hash_t XXH3_64bits( const void * data, size_t len );

XXH64_hash_t XXH3_64bits_withSeed(
	const void * data, size_t len, XXH64_hash_t seed
);

XXH64_hash_t XXH3_64bits_withSecret(
	const void * data, size_t len, const void * secret, size_t secretSize
);

XXH64_hash_t XXH3_64bits_withSecretandSeed(
	const void * data,
	size_t len,
	const void * secret,
	size_t secretSize,
	XXH64_hash_t seed
);

XXH_errorcode XXH3_generateSecret(
	void * secretBuffer,
	size_t secretSize,
	const void * customSeed,
	size_t customSeedSize
);

void XXH3_generateSecret_fromSeed( void * secretBuffer, XXH64_hash_t seed );

// ----------------------------------------------------------------------------

XXH3_state_t * XXH3_createState( void );

XXH_errorcode XXH3_freeState( XXH3_state_t * statePtr );

void XXH3_copyState(
	XXH3_state_t * dst_state, const XXH3_state_t * src_state
);

XXH_errorcode XXH3_64bits_reset( XXH3_state_t * statePtr );

XXH_errorcode XXH3_64bits_reset_withSeed(
	XXH3_state_t * statePtr, XXH64_hash_t seed
);

XXH_errorcode XXH3_64bits_reset_withSecret(
	XXH3_state_t * statePtr,
	const void * secret,
	size_t secretSize
);

XXH_errorcode XXH3_64bits_reset_withSecretandSeed(
	XXH3_state_t * statePtr,
	const void * secret,
	size_t secretSize,
	XXH64_hash_t seed
);

XXH_errorcode XXH3_64bits_update(
	XXH3_state_t * statePtr, const void * input, size_t length
);

XXH64_hash_t XXH3_64bits_digest( const XXH3_state_t * statePtr );

// ----------------------------------------------------------------------------

typedef struct {
	XXH64_hash_t low64;
	XXH64_hash_t high64;
} XXH128_hash_t;

XXH128_hash_t XXH3_128bits( const void * data, size_t len );

XXH128_hash_t XXH3_128bits_withSeed(
	const void * data, size_t len, XXH64_hash_t seed
);

XXH128_hash_t XXH3_128bits_withSecret(
	const void * data,
	size_t len,
	const void * secret,
	size_t secretSize
);

XXH128_hash_t XXH3_128bits_withSecretandSeed(
	const void * data,
	size_t len,
	const void * secret,
	size_t secretSize,
	XXH64_hash_t seed
);

XXH_errorcode XXH3_128bits_reset( XXH3_state_t * statePtr );

XXH_errorcode XXH3_128bits_reset_withSeed(
	XXH3_state_t * statePtr, XXH64_hash_t seed
);

XXH_errorcode XXH3_128bits_reset_withSecret(
	XXH3_state_t * statePtr,
	const void * secret,
	size_t secretSize
);

XXH_errorcode XXH3_128bits_reset_withSecretandSeed(
	XXH3_state_t * statePtr,
	const void * secret,
	size_t secretSize,
	XXH64_hash_t seed
);

XXH_errorcode XXH3_128bits_update(
	XXH3_state_t * statePtr, const void * input, size_t length
);

XXH128_hash_t XXH3_128bits_digest( const XXH3_state_t * statePtr );

int XXH128_isEqual( XXH128_hash_t h1, XXH128_hash_t h2 );

int XXH128_cmp( const void * h128_1, const void * h128_2 );

typedef struct {
	unsigned char digest[sizeof(XXH128_hash_t)];
} XXH128_canonical_t;

void XXH128_canonicalFromHash( XXH128_canonical_t * dst, XXH128_hash_t hash );

XXH128_hash_t XXH128_hashFromCanonical( const XXH128_canonical_t * src );

// ----------------------------------------------------------------------------

const HasherInterface * geHasherInterface_XXH3( void );

// ============================================================================
end_header
#include "base/end_header.h"
