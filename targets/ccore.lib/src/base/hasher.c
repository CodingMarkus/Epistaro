#include "hasher.h"

#include "fletcher32.h"

#include "base/begin_impl.h"
begin_impl
// ============================================================================

struct Fletcher32Hasher {
	struct Fletcher32State state;
};


static
intS getRequiredSize_Fletcher32Hasher( void )
{
	return sizeof(struct Fletcher32Hasher);
}


static
Hasher * init_Fletcher32Hasher( void * hasherStorage )
{
	def hasher = (struct Fletcher32Hasher *)hasherStorage;
	*hasher = (struct Fletcher32Hasher){ 0 };
	return (Hasher *)hasher;
}


static
HashValue_Hasher finalize_Fletcher32Hasher( Hasher * hasher )
{
	def state = ((struct Fletcher32Hasher *)hasher)->state;
	return (HashValue_Hasher)Fletcher32Finalize(state);
}


static
void addBytes_Fletcher32Hasher(
	Hasher * hasher, Opt(const void *) bytes, intS size )
{
	return_unless(no_value, data, bytes);
	if (size == 0) return;

	def fletcher = (struct Fletcher32Hasher *)hasher;
	fletcher->state = Fletcher32Update(fletcher->state, data, (size_t)size);
}


static const HasherInterface defaultHasherInterface = {
	.getRequiredSize = getRequiredSize_Fletcher32Hasher,
	.initStorage = init_Fletcher32Hasher,
	.finalize = finalize_Fletcher32Hasher,
	.addBytes = addBytes_Fletcher32Hasher,
};


public
const HasherInterface * getDefaultHasherInterface_Hasher( void )
{
	return &defaultHasherInterface;
}

// ============================================================================
end_impl
