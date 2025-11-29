#ifdef _beginCommonActive
	#error begin_common.h included twice without including end_common.h first
#endif
#define _beginCommonActive

// ============================================================================

#include <stddef.h> // IWYU pragma: keep
#include <stdint.h>  // IWYU pragma: keep
#include <stdbool.h>  // IWYU pragma: keep

// ============================================================================

#include "always/begin_cpp.h"

// ============================================================================

#define nil  NULL

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
    enum __attribute__((flag_enum, enum_extensibility(closed))) name : type

// ============================================================================

/*
Integer aliases: pick based on goal.

fast:    Prioritize speed. Width may exceed N if the CPU prefers it.
         Often maps to native register size. Good for hot loops, counters,
         indexes, math where exact width does not matter. Prefer those types
         by default.

exact:   Fixed width. Required for on-disk formats, wire protocols,
         SIMD masks, bit packing, ABI boundaries. May be emulated and slow
         on some targets. Avoid unless required.

minimum: At least N bits. Width may exceed N if the target benefits.
         Balances size and speed. Useful for compact data structures
         where exact width is unimportant, but extreme slowness is unwanted.
*/

// Fast Ints

// Fast Unsigned Ints
#define int8  uint_fast8_t
#define int16 uint_fast16_t
#define int32 uint_fast32_t
#define int64 uint_fast64_t

// Fast Signed Ints
#define sint8  int_fast8_t
#define sint16 int_fast16_t
#define sint32 int_fast32_t
#define sint64 int_fast64_t


// Exakt Ints

// Exact Unsigned Ints
#define int8e  uint8_t
#define int16e uint16_t
#define int32e uint32_t
#define int64e uint64_t

// Exact Singed Ints
#define sint8e  int8_t
#define sint16e int16_t
#define sint32e int32_t
#define sint64e int64_t


// Minimum Ints

// Minimum Unsigned Ints
#define int8m  uint_least8_t
#define int16m uint_least16_t
#define int32m uint_least32_t
#define int64m uint_least64_t

// Minimum Signed Ints
#define sint8m  int_least8_t
#define sint16m int_least16_t
#define sint32m int_least32_t
#define sint64m int_least64_t
