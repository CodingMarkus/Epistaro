#include "test/test.h"

#include "base/fletcher32.h"

#include "base/begin_impl.h"
begin_impl
// ============================================================================

static
int32e hashFletcher32( const void * data, size_t len )
{
	struct Fletcher32State state = { 0 };
	state = Fletcher32Update(state, data, len);
	return Fletcher32Finalize(state);
}


static
void test_fletcher32Vectors( void )
{
	const char * quick = "The quick brown fox jumps over the lazy dog";

	expect(hashFletcher32("", 0) == (int32e)0x00000000u);
	expect(hashFletcher32("abcde", 5) == (int32e)0x4ff029c7u);
	expect(hashFletcher32(quick, strlen(quick)) == (int32e)0xcd538d5bu);
}


static
void test_fletcher32Streaming( void )
{
	const char * quick = "The quick brown fox jumps over the lazy dog";
	const size_t len = strlen(quick);

	struct Fletcher32State state = { 0 };
	state = Fletcher32Update(state, quick, 12);
	state = Fletcher32Update(state, quick + 12, len - 12);
	expect(Fletcher32Finalize(state) == (int32e)0xcd538d5bu);
}


public
void runAllTests_fletcher32( void )
{
	test_fletcher32Vectors();
	test_fletcher32Streaming();
}

// ============================================================================
end_impl
