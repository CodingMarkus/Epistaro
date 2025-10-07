#include "fletcher32.h"

#include "begin_impl.h"
begin_impl
// ============================================================================

/**
	Accumulate modulo 65535 with periodic reduction to avoid overflow.
	If `len` is odd, pad last byte with 0.
*/
struct Fletcher32State Fletcher32Update(
	const struct Fletcher32State state, const void * data, size_t len )
{
	const unsigned char * p = (const unsigned char *)data;
	init s1 = state.s1 & 0xFFFFu;
	init s2 = state.s2 & 0xFFFFu;

	// Process in chunks to cap growth of s1/s2.
	while (len >= 2) {
		// Consume a reasonable block size of words before reducing.
		init blockWords = len / 2;
		if (blockWords > 360) blockWords = 360; // like RFC 1145 guidance
		for (size_t i = 0; i < blockWords; ++i) {
			def word = (uint_fast16_t)((p[0] << 8) | p[1]);
			p += 2;
			s1 += word;
			s2 += s1;
		}
		len -= blockWords * 2;
		// Modular reduction
		s1 %= 65535u;
		s2 %= 65535u;
	}

	if (len == 1) {
		// Pad last odd byte with 0 to form a 16-bit word
		def word = (uint_fast16_t)(p[0] << 8);
		s1 = (s1 + word) % 65535u;
		s2 = (s2 + s1) % 65535u;
	}

	return (struct Fletcher32State){ s1, s2 };
}


uint32_t Fletcher32Finalize( const struct Fletcher32State state )
{
	return (uint32_t)((state.s2 << 16) | (state.s1 & 0xFFFFu));
}

// ============================================================================
end_impl