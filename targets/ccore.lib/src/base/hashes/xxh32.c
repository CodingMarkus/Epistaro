#define XXH_PUBLIC_API
#define XXH_STATIC_LINKING_ONLY
#define XXH_IMPLEMENTATION
#define XXH_NO_LONG_LONG
#define XXH_NO_XXH3
#include "xxhash_ref.h"

#undef XXH_PUBLIC_API
#undef XXH_STATIC_LINKING_ONLY
#undef XXH_IMPLEMENTATION
#undef XXH_NO_LONG_LONG
#undef XXH_NO_XXH3

#define XXH_ERRORCODE_DEFINED
#define XXH32_HASH_T_DEFINED
#define XXH32_STATE_T_DEFINED
#define XXH32_CANONICAL_T_DEFINED
#include "xxh32.h"

#undef XXH_ERRORCODE_DEFINED
#undef XXH32_HASH_T_DEFINED
#undef XXH32_STATE_T_DEFINED
#undef XXH32_CANONICAL_T_DEFINED

#include "base/begin_impl.h"
begin_impl
// ============================================================================

struct XXH32Hasher {
	XXH32_state_t * state;
};


static
void * alignPtr_XXH32( void * ptr, size_t alignment )
{
	const uintptr_t addr = (uintptr_t)ptr;
	const uintptr_t aligned =
		(addr + alignment - 1u) & ~(uintptr_t)(alignment - 1u);
	return (void *)aligned;
}


static
intS getRequiredSize_XXH32Hasher( void )
{
	const size_t hasherAlignment = _Alignof(struct XXH32Hasher);
	const size_t stateAlignment = _Alignof(XXH32_state_t);
	return (intS)(
		hasherAlignment - 1u
		+ sizeof(struct XXH32Hasher)
		+ stateAlignment - 1u
		+ sizeof(XXH32_state_t)
	);
}


static
Hasher * init_XXH32Hasher( void * hasherStorage )
{
	def hasher = (struct XXH32Hasher *)alignPtr_XXH32(
		hasherStorage,
		_Alignof(struct XXH32Hasher)
	);
	*hasher = (struct XXH32Hasher){ 0 };

	def stateStorage = (unsigned char *)hasher
		+ sizeof(struct XXH32Hasher);
	hasher->state = (XXH32_state_t *)alignPtr_XXH32(
		stateStorage,
		_Alignof(XXH32_state_t)
	);
	(void)XXH32_reset(hasher->state, 0);
	return (Hasher *)hasher;
}


static
HashValue_Hasher finalize_XXH32Hasher( Hasher * hasher )
{
	def state = ((struct XXH32Hasher *)hasher)->state;
	return (HashValue_Hasher)XXH32_digest(state);
}


static
void addBytes_XXH32Hasher(
	Hasher * hasher, Opt(const void *) bytes, intS size )
{
	return_unless(no_value, data, bytes);
	if (size == 0) return;

	def xxh = (struct XXH32Hasher *)hasher;
	(void)XXH32_update(xxh->state, data, (size_t)size);
}


static const HasherInterface xxh32HasherInterface = {
	.getRequiredSize = getRequiredSize_XXH32Hasher,
	.initStorage = init_XXH32Hasher,
	.finalize = finalize_XXH32Hasher,
	.addBytes = addBytes_XXH32Hasher,
};


const HasherInterface * getHasherInterface_XXH32( void )
{
	return &xxh32HasherInterface;
}


public
const HasherInterface * getDefaultHasherInterface_Hasher( void )
{
	return getHasherInterface_XXH32();
}


// ============================================================================
end_impl
