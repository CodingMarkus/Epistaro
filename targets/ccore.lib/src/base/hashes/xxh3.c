#define XXH_STATIC_LINKING_ONLY
#define XXH_IMPLEMENTATION
#define XXH_NAMESPACE XXH3REF_
#include "xxhash_ref.h"

#undef XXH_PUBLIC_API
#undef XXH_STATIC_LINKING_ONLY
#undef XXH_IMPLEMENTATION
#undef XXH_NAMESPACE

#undef XXH_OK
#undef XXH_ERROR
#undef XXH_errorcode
#undef XXH3_state_s
#undef XXH3_state_t
#undef XXH3_64bits
#undef XXH3_64bits_withSecret
#undef XXH3_64bits_withSeed
#undef XXH3_64bits_withSecretandSeed
#undef XXH3_createState
#undef XXH3_freeState
#undef XXH3_copyState
#undef XXH3_64bits_reset
#undef XXH3_64bits_reset_withSeed
#undef XXH3_64bits_reset_withSecret
#undef XXH3_64bits_reset_withSecretandSeed
#undef XXH3_64bits_update
#undef XXH3_64bits_digest
#undef XXH3_generateSecret
#undef XXH3_generateSecret_fromSeed
#undef XXH128
#undef XXH3_128bits
#undef XXH3_128bits_withSeed
#undef XXH3_128bits_withSecret
#undef XXH3_128bits_withSecretandSeed
#undef XXH3_128bits_reset
#undef XXH3_128bits_reset_withSeed
#undef XXH3_128bits_reset_withSecret
#undef XXH3_128bits_reset_withSecretandSeed
#undef XXH3_128bits_update
#undef XXH3_128bits_digest
#undef XXH128_isEqual
#undef XXH128_cmp
#undef XXH128_canonicalFromHash
#undef XXH128_hashFromCanonical
#undef XXH128_hash_t
#undef XXH128_canonical_t

#define XXH64_HASH_T_DEFINED
#include "xxh3.h"
#undef XXH64_HASH_T_DEFINED

#include "base/begin_impl.h"
begin_impl
// ============================================================================

static
XXH128_hash_t toInternal_XXH128( XXH128_hash_t hash )
{
	return (XXH128_hash_t){
		.low64 = hash.low64,
		.high64 = hash.high64,
	};
}


static
XXH128_hash_t fromInternal_XXH128( XXH128_hash_t hash )
{
	return (XXH128_hash_t){
		.low64 = hash.low64,
		.high64 = hash.high64,
	};
}


XXH64_hash_t XXH3_64bits( const void * data, size_t len )
{
	return XXH3REF_XXH3_64bits(data, len);
}


XXH64_hash_t XXH3_64bits_withSeed(
	const void * data, size_t len, XXH64_hash_t seed )
{
	return XXH3REF_XXH3_64bits_withSeed(data, len, seed);
}


XXH64_hash_t XXH3_64bits_withSecret(
	const void * data, size_t len, const void * secret, size_t secretSize )
{
	return XXH3REF_XXH3_64bits_withSecret(data, len, secret, secretSize);
}


XXH64_hash_t XXH3_64bits_withSecretandSeed(
	const void * data,
	size_t len,
	const void * secret,
	size_t secretSize,
	XXH64_hash_t seed )
{
	return XXH3REF_XXH3_64bits_withSecretandSeed(
		data,
		len,
		secret,
		secretSize,
		seed
	);
}


XXH_errorcode XXH3_generateSecret(
	void * secretBuffer,
	size_t secretSize,
	const void * customSeed,
	size_t customSeedSize )
{
	return (XXH_errorcode)XXH3REF_XXH3_generateSecret(
		secretBuffer,
		secretSize,
		customSeed,
		customSeedSize
	);
}


void XXH3_generateSecret_fromSeed( void * secretBuffer, XXH64_hash_t seed )
{
	XXH3REF_XXH3_generateSecret_fromSeed(secretBuffer, seed);
}


XXH3_state_t * XXH3_createState( void )
{
	return (XXH3_state_t *)XXH3REF_XXH3_createState();
}


XXH_errorcode XXH3_freeState( XXH3_state_t * statePtr )
{
	return (XXH_errorcode)XXH3REF_XXH3_freeState(
		(XXH3_state_t *)statePtr
	);
}


void XXH3_copyState(
	XXH3_state_t * dst_state, const XXH3_state_t * src_state )
{
	XXH3REF_XXH3_copyState(
		(XXH3_state_t *)dst_state,
		(const XXH3_state_t *)src_state
	);
}


XXH_errorcode XXH3_64bits_reset( XXH3_state_t * statePtr )
{
	return (XXH_errorcode)XXH3REF_XXH3_64bits_reset(
		(XXH3_state_t *)statePtr
	);
}


XXH_errorcode XXH3_64bits_reset_withSeed(
	XXH3_state_t * statePtr, XXH64_hash_t seed )
{
	return (XXH_errorcode)XXH3REF_XXH3_64bits_reset_withSeed(
		(XXH3_state_t *)statePtr,
		seed
	);
}


XXH_errorcode XXH3_64bits_reset_withSecret(
	XXH3_state_t * statePtr,
	const void * secret,
	size_t secretSize )
{
	return (XXH_errorcode)XXH3REF_XXH3_64bits_reset_withSecret(
		(XXH3_state_t *)statePtr,
		secret,
		secretSize
	);
}


XXH_errorcode XXH3_64bits_reset_withSecretandSeed(
	XXH3_state_t * statePtr,
	const void * secret,
	size_t secretSize,
	XXH64_hash_t seed )
{
	return (XXH_errorcode)XXH3REF_XXH3_64bits_reset_withSecretandSeed(
		(XXH3_state_t *)statePtr,
		secret,
		secretSize,
		seed
	);
}


XXH_errorcode XXH3_64bits_update(
	XXH3_state_t * statePtr, const void * input, size_t length )
{
	return (XXH_errorcode)XXH3REF_XXH3_64bits_update(
		(XXH3_state_t *)statePtr,
		input,
		length
	);
}


XXH64_hash_t XXH3_64bits_digest( const XXH3_state_t * statePtr )
{
	return XXH3REF_XXH3_64bits_digest(
		(const XXH3_state_t *)statePtr
	);
}


XXH128_hash_t XXH3_128bits( const void * data, size_t len )
{
	return fromInternal_XXH128(XXH3REF_XXH3_128bits(data, len));
}


XXH128_hash_t XXH3_128bits_withSeed(
	const void * data, size_t len, XXH64_hash_t seed )
{
	return fromInternal_XXH128(
		XXH3REF_XXH3_128bits_withSeed(data, len, seed)
	);
}


XXH128_hash_t XXH3_128bits_withSecret(
	const void * data,
	size_t len,
	const void * secret,
	size_t secretSize )
{
	return fromInternal_XXH128(
		XXH3REF_XXH3_128bits_withSecret(data, len, secret, secretSize)
	);
}


XXH128_hash_t XXH3_128bits_withSecretandSeed(
	const void * data,
	size_t len,
	const void * secret,
	size_t secretSize,
	XXH64_hash_t seed )
{
	return fromInternal_XXH128(
		XXH3REF_XXH3_128bits_withSecretandSeed(
			data,
			len,
			secret,
			secretSize,
			seed
		)
	);
}


XXH_errorcode XXH3_128bits_reset( XXH3_state_t * statePtr )
{
	return (XXH_errorcode)XXH3REF_XXH3_128bits_reset(
		(XXH3_state_t *)statePtr
	);
}


XXH_errorcode XXH3_128bits_reset_withSeed(
	XXH3_state_t * statePtr, XXH64_hash_t seed )
{
	return (XXH_errorcode)XXH3REF_XXH3_128bits_reset_withSeed(
		(XXH3_state_t *)statePtr,
		seed
	);
}


XXH_errorcode XXH3_128bits_reset_withSecret(
	XXH3_state_t * statePtr,
	const void * secret,
	size_t secretSize )
{
	return (XXH_errorcode)XXH3REF_XXH3_128bits_reset_withSecret(
		(XXH3_state_t *)statePtr,
		secret,
		secretSize
	);
}


XXH_errorcode XXH3_128bits_reset_withSecretandSeed(
	XXH3_state_t * statePtr,
	const void * secret,
	size_t secretSize,
	XXH64_hash_t seed )
{
	return (XXH_errorcode)XXH3REF_XXH3_128bits_reset_withSecretandSeed(
		(XXH3_state_t *)statePtr,
		secret,
		secretSize,
		seed
	);
}


XXH_errorcode XXH3_128bits_update(
	XXH3_state_t * statePtr, const void * input, size_t length )
{
	return (XXH_errorcode)XXH3REF_XXH3_128bits_update(
		(XXH3_state_t *)statePtr,
		input,
		length
	);
}


XXH128_hash_t XXH3_128bits_digest( const XXH3_state_t * statePtr )
{
	return fromInternal_XXH128(
		XXH3REF_XXH3_128bits_digest(
			(const XXH3_state_t *)statePtr
		)
	);
}


int XXH128_isEqual( XXH128_hash_t h1, XXH128_hash_t h2 )
{
	return XXH3REF_XXH128_isEqual(
		toInternal_XXH128(h1),
		toInternal_XXH128(h2)
	);
}


int XXH128_cmp( const void * h128_1, const void * h128_2 )
{
	return XXH3REF_XXH128_cmp(h128_1, h128_2);
}


void XXH128_canonicalFromHash( XXH128_canonical_t * dst, XXH128_hash_t hash )
{
	XXH128_hash_t internal = toInternal_XXH128(hash);
	XXH3REF_XXH128_canonicalFromHash(
		(XXH128_canonical_t *)dst,
		internal
	);
}


XXH128_hash_t XXH128_hashFromCanonical( const XXH128_canonical_t * src )
{
	return fromInternal_XXH128(
		XXH3REF_XXH128_hashFromCanonical(
			(const XXH128_canonical_t *)src
		)
	);
}


struct XXH3Hasher {
	XXH3_state_t * state;
};


static
void * alignPtr_XXH3( void * ptr, size_t alignment )
{
	const uintptr_t addr = (uintptr_t)ptr;
	const uintptr_t aligned =
		(addr + alignment - 1u) & ~(uintptr_t)(alignment - 1u);
	return (void *)aligned;
}


static
intS getRequiredSize_XXH3Hasher( void )
{
	const size_t hasherAlignment = _Alignof(struct XXH3Hasher);
	const size_t stateAlignment = _Alignof(XXH3_state_t);
	return (intS)(
		hasherAlignment - 1u
		+ sizeof(struct XXH3Hasher)
		+ stateAlignment - 1u
		+ sizeof(XXH3_state_t)
	);
}


static
Hasher * init_XXH3Hasher( void * hasherStorage )
{
	def hasher = (struct XXH3Hasher *)alignPtr_XXH3(
		hasherStorage,
		_Alignof(struct XXH3Hasher)
	);
	*hasher = (struct XXH3Hasher){ 0 };
	def stateStorage = (unsigned char *)hasher
		+ sizeof(struct XXH3Hasher);
	hasher->state = (XXH3_state_t *)alignPtr_XXH3(
		stateStorage,
		_Alignof(XXH3_state_t)
	);
	(void)XXH3REF_XXH3_64bits_reset(hasher->state);
	return (Hasher *)hasher;
}


static
HashValue_Hasher finalize_XXH3Hasher( Hasher * hasher )
{
	def state = ((struct XXH3Hasher *)hasher)->state;
	def hash64 = XXH3REF_XXH3_64bits_digest(state);
	// Fold to 32-bit for the hasher interface.
	return (HashValue_Hasher)(hash64 ^ (hash64 >> 32));
}


static
void addBytes_XXH3Hasher(
	Hasher * hasher, Opt(const void *) bytes, intS size )
{
	return_unless(no_value, data, bytes);
	if (size == 0) return;

	def xxh = (struct XXH3Hasher *)hasher;
	(void)XXH3REF_XXH3_64bits_update(xxh->state, data, (size_t)size);
}


static const HasherInterface xxh3HasherInterface = {
	.getRequiredSize = getRequiredSize_XXH3Hasher,
	.initStorage = init_XXH3Hasher,
	.finalize = finalize_XXH3Hasher,
	.addBytes = addBytes_XXH3Hasher,
};


const HasherInterface * geHasherInterface_XXH3( void )
{
	return &xxh3HasherInterface;
}


// ============================================================================
end_impl
