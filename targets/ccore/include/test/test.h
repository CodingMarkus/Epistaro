#include <stdio.h>

#include "../base/implementation/assert.h" // IWYU pragma: keep

#include "../base/begin_header.h"
begin_header
// ============================================================================

#define expect( cond, ... )  _expect((cond), ##__VA_ARGS__, NULL)

#define _expect( cond, msg, ... )                                   \
	({                                                              \
		if (!(cond)) {                                              \
			fprintf(stderr, "Failed expectation: %s\n", STR(cond)); \
			if (msg) {                                              \
				fprintf(stderr, "--> %s\n", msg);                   \
			}                                                       \
			fprintf(                                                \
				stderr, "%s:%d in %s\n",                            \
				__FILE__, __LINE__, __func__                        \
			);                                                      \
			abort();                                                \
		}                                                           \
	})

// ----------------------------------------------------------------------------

#define _expect_assert_1( codeBlock )                        \
	({                                                       \
		if (_armAssertTrap(NULL) == 0) {                     \
			codeBlock;                                       \
			fprintf(                                         \
				stderr,                                      \
				"Expected an assertion, but none happened\n" \
			);                                               \
			abort();                                         \
		}                                                    \
	})

#define _expect_assert_2( exprString, codeBlock )             \
	({                                                        \
		if (_armAssertTrap((exprString)) == 0) {              \
			codeBlock;                                        \
			fprintf(                                          \
				stderr,                                       \
				"Expected assertion was not triggered: %s\n", \
				exprString                                    \
			);                                                \
			abort();                                          \
		}                                                     \
	})

#define _expect_assert_expand( count, ... ) \
	CONCAT(_expect_assert_, count)(__VA_ARGS__)

#define expect_assert( ... ) \
	_expect_assert_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)

// ============================================================================
end_header
#include "../base/end_header.h"
