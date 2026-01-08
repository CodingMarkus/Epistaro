#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../base/implementation/assert.h" // IWYU pragma: keep
#include "../base/implementation/require.h" // IWYU pragma: keep

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

#if TESTING

void _testFailExpectedAssertion( void );
void _testVerifyAssertionExpr( const char * expectedExpr );

void _testFailExpectedRequirement( void );
void _testVerifyRequirementExpr( const char * expectedExpr );

#endif // TESTING

// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------

#define _expect_assert_1( codeBlock ) \
	({                                \
		if (_armAssertTrap() == 0) {   \
			codeBlock;                  \
			_testFailExpectedAssertion(); \
		}                             \
	})

#define _expect_assert_2( exprString, codeBlock ) \
	({                                             \
		if (_armAssertTrap() == 0) {                \
			codeBlock;                               \
			_testFailExpectedAssertion();            \
		} else {                                   \
			_testVerifyAssertionExpr(exprString);    \
		}                                         \
	})

#define _expect_assert_expand( count, ... ) \
	CONCAT(_expect_assert_, count)(__VA_ARGS__)

#define expect_assert( ... ) \
	_expect_assert_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)

// ----------------------------------------------------------------------------

#define _expect_require_1( codeBlock ) \
	({                                  \
		if (_armRequireTrap() == 0) {    \
			codeBlock;                    \
			_testFailExpectedRequirement(); \
		}                               \
	})

#define _expect_require_2( exprString, codeBlock ) \
	({                                               \
		if (_armRequireTrap() == 0) {                  \
			codeBlock;                                  \
			_testFailExpectedRequirement();             \
		} else {                                      \
			_testVerifyRequirementExpr(exprString);     \
		}                                            \
	})

#define _expect_require_expand( count, ... ) \
	CONCAT(_expect_require_, count)(__VA_ARGS__)

#define expect_require( ... ) \
	_expect_require_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)

// ============================================================================
end_header
#include "../base/end_header.h"
