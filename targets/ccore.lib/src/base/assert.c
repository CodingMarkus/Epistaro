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
	const char * lastExpr;
	jmp_buf env;
} assertionTrap;

// ---------------------------------------------------------

__attribute__((visibility("default")))
int _armAssertTrap( void )
{
	assertionTrap.armed = true;
	assertionTrap.lastExpr = NULL;
	return setjmp(assertionTrap.env);
}

__attribute__((visibility("default")))
void _disarmAssertTrap( void )
{
	assertionTrap.armed = false;
	assertionTrap.lastExpr = NULL;
}

__attribute__((visibility("default")))
void _testFailExpectedAssertion( void )
{
	fprintf(
		stderr,
		"Expected an assertion, but none happened\n"
	);
	exit(EXIT_FAILURE);
}

__attribute__((visibility("default")))
void _testVerifyAssertionExpr( const char * expectedExpr )
{
	const char * actualExpr;

	actualExpr = assertionTrap.lastExpr;
	if (!actualExpr
		|| strcmp(actualExpr, expectedExpr) != 0)
	{
		fprintf(
			stderr,
			"Expected assertion was not triggered: %s\n",
			expectedExpr
		);
		fprintf(
			stderr,
			"Expected assertion: %s\n",
			expectedExpr
		);
		if (actualExpr) {
			fprintf(
				stderr,
				"Actual assertion: %s\n",
				actualExpr
			);
		}
		exit(EXIT_FAILURE);
	}
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
		assertionTrap.lastExpr = expr;
		assertionTrap.armed = false;
		longjmp(assertionTrap.env, 1);
	}

	// No trap armed, treat as unexpected assertion
#endif
	abort();
}
