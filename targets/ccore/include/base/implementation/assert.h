#pragma once

// ============================================================================

void _assertionHasFailed(
	const char * expr,
	const char * msg,
	const char * file,
	int line,
	const char * func );

// ============================================================================

#define _assert_1(cond)                                                  \
    ((cond) ? (void)0                                                    \
		: _assertionHasFailed(#cond, NULL, __FILE__, __LINE__, __func__) \
	)                                                                    \

#define _assert_2(cond, msg)                                              \
    ((cond) ? (void)0                                                     \
		: _assertionHasFailed(#cond, (msg), __FILE__, __LINE__, __func__) \
	)                                                                     \

#define _assert_DISPATCH(n)  _assert_ ## n

#ifdef assert
	#undef assert
#endif

#ifdef NDEBUG
	#define assert( ... )  (void)0
#else
	#define assert(...) \
    	assert_DISPATCH(COUNT_ARGS(__VA_ARGS__))(__VA_ARGS__)
#endif

// ============================================================================

#define _assertFail_0( )           assert(false)
#define _assertFail_1( msg )       assert(false, msg)

#define _assertFail_DISPATCH( n )  _assertFail_##n

#define assertFail( ... )           \
	_assertFail_DISPATCH(COUNT_ARGS(__VA_ARGS__))(__VA_ARGS__)
