#pragma once

// ============================================================================

__attribute__((visibility("default")))
void _assertionHasFailed(
	const char * expr,
	const char * file,
	int line,
	const char * func,
	const char * msg,
	...
);

// ============================================================================

// Single argument: assert(cond)
#define _assert_1( cond )                        \
	((cond) ? (void)0                            \
		: _assertionHasFailed(                   \
			#cond, __FILE__, __LINE__, __func__, \
			NULL                                 \
		)                                        \
	)

// 2 arguments: assert(cond, msg)
#define _assert_2( cond, msg )                   \
	((cond) ? (void)0                            \
		: _assertionHasFailed(                   \
			#cond, __FILE__, __LINE__, __func__, \
			"%s", msg                            \
		)                                        \
	)

// 3 arguments: assert(cond, msg, a1)
#define _assert_3( cond, msg, a1 )               \
	((cond) ? (void)0                            \
		: _assertionHasFailed(                   \
			#cond, __FILE__, __LINE__, __func__, \
			msg, a1                              \
		)                                        \
	)

// 4 arguments: assert(cond, msg, a1, a2)
#define _assert_4( cond, msg, a1, a2 )           \
	((cond) ? (void)0                            \
		: _assertionHasFailed(                   \
			#cond, __FILE__, __LINE__, __func__, \
			msg, a1, a2                          \
		)                                        \
	)

// 5 arguments: assert(cond, msg, a1, a2, a3)
#define _assert_5( cond, msg, a1, a2, a3 )       \
	((cond) ? (void)0                            \
		: _assertionHasFailed(                   \
			#cond, __FILE__, __LINE__, __func__, \
			msg, a1, a2, a3                      \
		)                                        \
	)

// 6 arguments: assert(cond, msg, a1, a2, a3, a4)
#define _assert_6( cond, msg, a1, a2, a3, a4 )   \
	((cond) ? (void)0                            \
		: _assertionHasFailed(                   \
			#cond, __FILE__, __LINE__, __func__, \
			msg, a1, a2, a3, a4                  \
		)                                        \
	)

// 7 arguments: assert(cond, msg, a1, a2, a3, a4, a5)
#define _assert_7( cond, msg, a1, a2, a3, a4, a5 ) \
	((cond) ? (void)0                              \
		: _assertionHasFailed(                     \
			#cond, __FILE__, __LINE__, __func__,   \
			msg, a1, a2, a3, a4, a5                \
		)                                          \
	)

// 8 arguments: assert(cond, msg, a1, a2, a3, a4, a5, a6)
#define _assert_8( cond, msg, a1, a2, a3, a4, a5, a6 ) \
	((cond) ? (void)0                                  \
		: _assertionHasFailed(                         \
			#cond, __FILE__, __LINE__, __func__,       \
			msg, a1, a2, a3, a4, a5, a6                \
		)                                              \
	)

#define _assert_expand( count, ... ) \
	CONCAT(_assert_, count)(__VA_ARGS__)

#ifdef assert
	#undef assert
#endif

#ifdef NDEBUG
	#define assert( ... )  (void)0
#else
	/**
		@fn void assert(...)
		`assert` aborts if `cond` is false.

		- `assert(cond)` triggers on false `cond`.
		- `assert(cond, msg)` prints a static message.
		- `assert(cond, format, ...)` prints a formatted message.
	*/
	#define assert( ... ) \
		_assert_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)
#endif

// ============================================================================

#define _assertFail_0( ) \
	assert(false)

#define _assertFail_1( msg ) \
	assert(false, msg)

#define _assertFail_2( msg, a1 ) \
	assert(false, msg, a1)

#define _assertFail_3( msg, a1, a2 ) \
	assert(false, msg, a1, a2)

#define _assertFail_4( msg, a1, a2, a3 ) \
	assert(false, msg, a1, a2, a3)

#define _assertFail_5( msg, a1, a2, a3, a4 ) \
	assert(false, msg, a1, a2, a3, a4)

#define _assertFail_6( msg, a1, a2, a3, a4, a5 ) \
	assert(false, msg, a1, a2, a3, a4, a5)

#define _assertFail_7( msg, a1, a2, a3, a4, a5, a6 ) \
	assert(false, msg, a1, a2, a3, a4, a5, a6)

#define _assertFail_expand( count, ... ) \
	CONCAT(_assertFail_, count)(__VA_ARGS__)

#ifdef NDEBUG
	#define assertFail( ... )  (void)0
#else
	/**
		@fn void assertFail(...)
		`assertFail` is a convenience wrapper around `assert(false, ...)`.

		- `assertFail()` triggers without a message.
		- `assertFail(msg)` prints a static message.
		- `assertFail(format, ...)` prints a formatted message.
	*/
	#define assertFail( ... ) \
		_assertFail_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)
#endif
