#ifdef _beginCommonActive
	#error begin_common.h included twice without including end_common.h first
#endif
#define _beginCommonActive

// ============================================================================

#include <stdlib.h>   // IWYU pragma: keep
#include <stddef.h>   // IWYU pragma: keep
#include <stdint.h>   // IWYU pragma: keep
#include <stdbool.h>  // IWYU pragma: keep

// ============================================================================

#include "always/begin_cpp.h"

// ============================================================================

#define _opt  _Nullable
#define _req  _Nonnull
#define Opt( type ) type _opt

// ============================================================================

#define defEnum( name, type ) \
	enum __attribute__((enum_extensibility(closed))) name : type

#define defOpenEnum( name, type ) \
	enum __attribute__((enum_extensibility(open))) name : type

#define defOptions( name, type )                                          \
	typedef enum __attribute__((flag_enum, enum_extensibility(open)))     \
		name : type name;                                                 \
	enum __attribute__((flag_enum, enum_extensibility(open))) name : type

#define defClosedOptions( name, type )                                    \
	typedef enum __attribute__((flag_enum, enum_extensibility(closed)))   \
		name : type name;                                                 \
	enum __attribute__((flag_enum, enum_extensibility(closed))) name : type


// ============================================================================

/*
	Integer aliases: pick based on goal.

	fast:    Prioritize speed. Width may exceed N if the CPU prefers it.
	         Often maps to native register size. Good for hot loops, counters,
	         indexes, math where exact width does not matter. Prefer those
	         types by default.

	exact:   Fixed width. Required for on-disk formats, wire protocols,
	         SIMD masks, bit packing, ABI boundaries. May be emulated and slow
	         on some targets. Avoid unless required.

	minimum: At least N bits. Width may exceed N if the target benefits.
	         Balances size and speed. Useful for compact data structures
	         where exact width is unimportant, but extreme slowness is
	         unwanted.
*/

// Fast Ints

// Fast Unsigned Ints

/** Fast unsigned integer with at least 8 bits. */
typedef uint_fast8_t int8;
/** Fast unsigned integer with at least 16 bits. */
typedef uint_fast16_t int16;
/** Fast unsigned integer with at least 32 bits. */
typedef uint_fast32_t int32;
/** Fast unsigned integer with at least 64 bits. */
typedef uint_fast64_t int64;

// Fast Signed Ints

/** Fast signed integer with at least 8 bits. */
typedef int_fast8_t sint8;
/** Fast signed integer with at least 16 bits. */
typedef int_fast16_t sint16;
/** Fast signed integer with at least 32 bits. */
typedef int_fast32_t sint32;
/** Fast signed integer with at least 64 bits. */
typedef int_fast64_t sint64;


// Exakt Ints

// Exact Unsigned Ints

/** Exact-width unsigned 8-bit integer. */
typedef uint8_t int8e;
/** Exact-width unsigned 16-bit integer. */
typedef uint16_t int16e;
/** Exact-width unsigned 32-bit integer. */
typedef uint32_t int32e;
/** Exact-width unsigned 64-bit integer. */
typedef uint64_t int64e;

// Exact Singed Ints

/** Exact-width signed 8-bit integer. */
typedef int8_t sint8e;
/** Exact-width signed 16-bit integer. */
typedef int16_t sint16e;
/** Exact-width signed 32-bit integer. */
typedef int32_t sint32e;
/** Exact-width signed 64-bit integer. */
typedef int64_t sint64e;


// Minimum Ints

// Minimum Unsigned Ints

/** Minimum-width unsigned integer with at least 8 bits. */
typedef uint_least8_t int8m;
/** Minimum-width unsigned integer with at least 16 bits. */
typedef uint_least16_t int16m;
/** Minimum-width unsigned integer with at least 32 bits. */
typedef uint_least32_t int32m;
/** Minimum-width unsigned integer with at least 64 bits. */
typedef uint_least64_t int64m;

// Minimum Signed Ints

/** Minimum-width signed integer with at least 8 bits. */
typedef int_least8_t sint8m;
/** Minimum-width signed integer with at least 16 bits. */
typedef int_least16_t sint16m;
/** Minimum-width signed integer with at least 32 bits. */
typedef int_least32_t sint32m;
/** Minimum-width signed integer with at least 64 bits. */
typedef int_least64_t sint64m;


// ============================================================================

/*
	Integer types for size and indexing
*/

/** Size type for byte counts and object sizes. */
typedef size_t intS;
/** Index type for array and buffer indexing. */
typedef size_t intI;
