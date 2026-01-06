#include <setjmp.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ============================================================================

#if TESTING

static
struct {
	bool armed;
	const char * expectedExpr;
	jmp_buf env;
} assertionTrap;

__attribute__((visibility("default")))
int _armAssertTrap( const char * expectedExpr )
{
	assertionTrap.armed = true;
	assertionTrap.expectedExpr = expectedExpr;
	return setjmp(assertionTrap.env);
}

__attribute__((visibility("default")))
void _disarmAssertTrap( void )
{
	assertionTrap.armed = false;
	assertionTrap.expectedExpr = NULL;
}

#endif // TESTING

// ============================================================================

__attribute__((visibility("default")))
void _assertionHasFailed(
	const char * expr,
	const char * file,
	int line,
	const char * func,
	const char *_Nullable msg,
	... )
{
	va_list args;
    fprintf(stderr, "Assertion failed: %s\n", expr);
    if (msg) {
		fprintf(stderr, "--> ");
		va_start(args, msg);
		vfprintf(stderr, msg, args);
		va_end(args);
		fputc('\n', stderr);
	}
    fprintf(stderr, "Location: %s:%d (%s)\n", file, line, func);

#if TESTING
	if (assertionTrap.armed) {
		if (!assertionTrap.expectedExpr
			|| strcmp(assertionTrap.expectedExpr, expr) == 0)
		{
			assertionTrap.armed = false;
			longjmp(assertionTrap.env, 1);
		}

		// Wrong assertion while a trap is armed, fail hard
		fprintf(
			stderr, "Expected assertion: %s\n",
			(assertionTrap.expectedExpr ?
				assertionTrap.expectedExpr : "(any)"
			)
		);
	}

	// No trap armed, treat as unexpected assertion
#endif
	abort();
}
