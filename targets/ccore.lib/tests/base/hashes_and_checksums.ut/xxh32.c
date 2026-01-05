#include "test/test.h"

#include "base/hashes/xxh32.h"

#include "base/begin_impl.h"
begin_impl
// ============================================================================

static
void test_xxh32BasicVectors( void )
{
	const char * quick = "The quick brown fox jumps over the lazy dog";

	expect(XXH32("", 0, 0) == 0x02cc5d05u);
	expect(XXH32("hello", 5, 0) == 0xfb0077f9u);
	expect(XXH32(quick, strlen(quick), 0) == 0xe85ea4deu);
	expect(XXH32(quick, strlen(quick), 1) == 0x234f8471u);
}


static
void test_xxh32Streaming( void )
{
	const char * quick = "The quick brown fox jumps over the lazy dog";
	const size_t len = strlen(quick);

	XXH32_state_t * state = XXH32_createState();
	expect(state != NULL, "XXH32_createState failed");
	expect(XXH32_reset(state, 0) == XXH_OK);

	expect(XXH32_update(state, quick, 10) == XXH_OK);
	expect(XXH32_update(state, quick + 10, len - 10) == XXH_OK);

	XXH32_hash_t hash = XXH32_digest(state);
	expect(hash == 0xe85ea4deu);

	expect(XXH32_freeState(state) == XXH_OK);
}


public
void runAllTests_xxh32( void )
{
	test_xxh32BasicVectors();
	test_xxh32Streaming();
}

// ============================================================================
end_impl
