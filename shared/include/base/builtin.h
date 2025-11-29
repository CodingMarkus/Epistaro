#pragma once

// ============================================================================

#define likely_true(x)   __builtin_expect(!!(x), 1)
#define likely_false(x)  __builtin_expect(!!(x), 0)

// ============================================================================

#define MIN(a, b) \
    ({ __auto_type _a = (a); __auto_type _b = (b); \
       __builtin_elementwise_min(_a, _b); })

#define MAX(a, b) \
    ({ __auto_type _a = (a); __auto_type _b = (b); \
       __builtin_elementwise_max(_a, _b); })

#define CLAMP(x, lo, hi) MIN(MAX(x, lo), hi)

// ============================================================================

/// Rotate left
#define ROTL(x, r)                        \
	_Generic((x),                         \
		uint8_t:  __builtin_rotateleft8,  \
		uint16_t: __builtin_rotateleft16, \
		uint32_t: __builtin_rotateleft32, \
		uint64_t: __builtin_rotateleft64, \
		int8_t:   __builtin_rotateleft8,  \
		int16_t:  __builtin_rotateleft16, \
		int32_t:  __builtin_rotateleft32, \
		int64_t:  __builtin_rotateleft64  \
	)(x, (unsigned)(r))

/// Rotate right
#define ROTR(x, r)                         \
	_Generic((x),                          \
		uint8_t:  __builtin_rotateright8,  \
		uint16_t: __builtin_rotateright16, \
		uint32_t: __builtin_rotateright32, \
		uint64_t: __builtin_rotateright64, \
		int8_t:   __builtin_rotateright8,  \
		int16_t:  __builtin_rotateright16, \
		int32_t:  __builtin_rotateright32, \
		int64_t:  __builtin_rotateright64  \
	)(x, (unsigned)(r))


// ============================================================================

#define HOST_TO_BE16(x) \
    (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__ ? __builtin_bswap16(x) : (x))

#define HOST_TO_BE32(x) \
    (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__ ? __builtin_bswap32(x) : (x))

#define HOST_TO_BE64(x) \
    (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__ ? __builtin_bswap64(x) : (x))

#define HOST_TO_LE16(x) \
    (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__ ? __builtin_bswap16(x) : (x))

#define HOST_TO_LE32(x) \
    (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__ ? __builtin_bswap32(x) : (x))

#define HOST_TO_LE64(x) \
    (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__ ? __builtin_bswap64(x) : (x))