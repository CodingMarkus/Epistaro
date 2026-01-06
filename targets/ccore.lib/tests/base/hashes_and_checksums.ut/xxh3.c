#include "test/test.h"

#include "base/hashes/xxh3.h"

#include "base/begin_impl.h"
begin_impl
// ============================================================================

static
void test_64Vectors( void )
{
	const char * longer =
		"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

	expect(XXH3_64bits("", 0) == 0x2d06800538d394c2ull);
	expect(XXH3_64bits("hello", 5) == 0x9555e8555c62dcfdull);
	expect(XXH3_64bits(longer, strlen(longer)) == 0xaff14504ea56c3e2ull);
}


static
void test_128Vectors( void )
{
	const char * longer =
		"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

	XXH128_hash_t hash = XXH3_128bits("", 0);
	expect(hash.low64 == 0x6001c324468d497full);
	expect(hash.high64 == 0x99aa06d3014798d8ull);

	hash = XXH3_128bits("hello", 5);
	expect(hash.low64 == 0xc779cfaa5e523818ull);
	expect(hash.high64 == 0xb5e9c1ad071b3e7full);

	hash = XXH3_128bits(longer, strlen(longer));
	expect(hash.low64 == 0x62e570ca0b21a3a0ull);
	expect(hash.high64 == 0x01746088f2699e52ull);
}


static
void test_64Streaming( void )
{
	const char * hello = "hello";

	XXH3_state_t * state = XXH3_createState();
	expect(state != NULL, "XXH3_createState failed");
	expect(XXH3_64bits_reset(state) == XXH_OK);

	expect(XXH3_64bits_update(state, hello, 2) == XXH_OK);
	expect(XXH3_64bits_update(state, hello + 2, 3) == XXH_OK);

	XXH64_hash_t hash = XXH3_64bits_digest(state);
	expect(hash == 0x9555e8555c62dcfdull);

	expect(XXH3_freeState(state) == XXH_OK);
}


static
void test_128Streaming( void )
{
	const char * longer =
		"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

	const size_t len = strlen(longer);

	XXH3_state_t * state = XXH3_createState();
	expect(state != NULL, "XXH3_createState failed");
	expect(XXH3_128bits_reset(state) == XXH_OK);

	expect(XXH3_128bits_update(state, longer, 33) == XXH_OK);
	expect(XXH3_128bits_update(state, longer + 33, len - 33) == XXH_OK);

	XXH128_hash_t hash = XXH3_128bits_digest(state);
	expect(hash.low64 == 0x62e570ca0b21a3a0ull);
	expect(hash.high64 == 0x01746088f2699e52ull);

	expect(XXH3_freeState(state) == XXH_OK);
}


public
void runAllTests_xxh3( void )
{
	test_64Vectors();
	test_128Vectors();
	test_64Streaming();
	test_128Streaming();
}

// ============================================================================
end_impl
