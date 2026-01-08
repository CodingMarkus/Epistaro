#pragma once

#if TESTING

#include "expect.h"

#include "../base/begin_header.h"
begin_header
// ============================================================================

void _expectationHasFailed(
	const char * expr,
	const char * file,
	int line,
	const char * func,
	const char *_Nullable msg,
	...
);

#define _expect_1( cond )                        \
	((cond) ? (void)0                            \
		: _expectationHasFailed(                 \
			#cond, __FILE__, __LINE__, __func__, \
			NULL                                 \
		)                                        \
	)

#define _expect_2( cond, msg )                   \
	((cond) ? (void)0                            \
		: _expectationHasFailed(                 \
			#cond, __FILE__, __LINE__, __func__, \
			"%s", msg                            \
		)                                        \
	)

#define _expect_3( cond, msg, a1 )               \
	((cond) ? (void)0                            \
		: _expectationHasFailed(                 \
			#cond, __FILE__, __LINE__, __func__, \
			msg, a1                              \
		)                                        \
	)

#define _expect_4( cond, msg, a1, a2 )           \
	((cond) ? (void)0                            \
		: _expectationHasFailed(                 \
			#cond, __FILE__, __LINE__, __func__, \
			msg, a1, a2                          \
		)                                        \
	)

#define _expect_5( cond, msg, a1, a2, a3 )       \
	((cond) ? (void)0                            \
		: _expectationHasFailed(                 \
			#cond, __FILE__, __LINE__, __func__, \
			msg, a1, a2, a3                      \
		)                                        \
	)

#define _expect_6( cond, msg, a1, a2, a3, a4 )   \
	((cond) ? (void)0                            \
		: _expectationHasFailed(                 \
			#cond, __FILE__, __LINE__, __func__, \
			msg, a1, a2, a3, a4                  \
		)                                        \
	)

#define _expect_7( cond, msg, a1, a2, a3, a4, a5 ) \
	((cond) ? (void)0                              \
		: _expectationHasFailed(                   \
			#cond, __FILE__, __LINE__, __func__,   \
			msg, a1, a2, a3, a4, a5                \
		)                                          \
	)

#define _expect_8( cond, msg, a1, a2, a3, a4, a5, a6 ) \
	((cond) ? (void)0                                  \
		: _expectationHasFailed(                       \
			#cond, __FILE__, __LINE__, __func__,       \
			msg, a1, a2, a3, a4, a5, a6                \
		)                                              \
	)

#define _expect_expand( count, ... ) \
	CONCAT(_expect_, count)(__VA_ARGS__)

#define expect( ... ) \
	_expect_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)

// ============================================================================
end_header
#include "../base/end_header.h"

#endif // TESTING