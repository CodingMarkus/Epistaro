#pragma once

#if TESTING

#include "../base/implementation/assert.h" // IWYU pragma: keep
#include "../base/implementation/require.h" // IWYU pragma: keep

#include "../base/begin_header.h"
begin_header
// ============================================================================

void _testFailExpectedAssertion( void );

void _testVerifyAssertionExpr( const char * expectedExpr );

#define _expect_assert_1( codeBlock )     \
	({                                    \
		if (_armAssertTrap() == 0) {      \
			codeBlock;                    \
			_testFailExpectedAssertion(); \
		}                                 \
	})

#define _expect_assert_2( exprString, codeBlock ) \
	({                                            \
		if (_armAssertTrap() == 0) {              \
			codeBlock;                            \
			_testFailExpectedAssertion();         \
		} else {                                  \
			_testVerifyAssertionExpr(exprString); \
		}                                         \
	})

#define _expect_assert_expand( count, ... ) \
	CONCAT(_expect_assert_, count)(__VA_ARGS__)

#define expect_assert( ... ) \
	_expect_assert_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)

// ----------------------------------------------------------------------------

void _testFailExpectedRequirement( void );

void _testVerifyRequirementExpr( const char * expectedExpr );


#define _expect_require_1( codeBlock )      \
	({                                      \
		if (_armRequireTrap() == 0) {       \
			codeBlock;                      \
			_testFailExpectedRequirement(); \
		}                                   \
	})

#define _expect_require_2( exprString, codeBlock )  \
	({                                              \
		if (_armRequireTrap() == 0) {               \
			codeBlock;                              \
			_testFailExpectedRequirement();         \
		} else {                                    \
			_testVerifyRequirementExpr(exprString); \
		}                                           \
	})

#define _expect_require_expand( count, ... ) \
	CONCAT(_expect_require_, count)(__VA_ARGS__)

#define expect_require( ... ) \
	_expect_require_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)

// ============================================================================
end_header
#include "../base/end_header.h"

#endif // TESTING