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
} requirementTrap;

// ---------------------------------------------------------

__attribute__((visibility("default")))
int _armRequireTrap( void )
{
	requirementTrap.armed = true;
	requirementTrap.lastExpr = NULL;
	return setjmp(requirementTrap.env);
}

__attribute__((visibility("default")))
void _disarmRequireTrap( void )
{
	requirementTrap.armed = false;
	requirementTrap.lastExpr = NULL;
}

__attribute__((visibility("default")))
void _testFailExpectedRequirement( void )
{
	fprintf(
		stderr,
		"Expected a requirement, but none happened\n"
	);
	exit(EXIT_FAILURE);
}

__attribute__((visibility("default")))
void _testVerifyRequirementExpr( const char * expectedExpr )
{
	const char * actualExpr;

	actualExpr = requirementTrap.lastExpr;
	if (!actualExpr
		|| strcmp(actualExpr, expectedExpr) != 0)
	{
		fprintf(
			stderr,
			"Expected requirement was not triggered: %s\n",
			expectedExpr
		);
		fprintf(
			stderr,
			"Expected requirement: %s\n",
			expectedExpr
		);
		if (actualExpr) {
			fprintf(
				stderr,
				"Actual requirement: %s\n",
				actualExpr
			);
		}
		exit(EXIT_FAILURE);
	}
}

#endif // TESTING

// ============================================================================

__attribute__((visibility("default")))
void _requirementHasFailed(
	const char * expr,
	const char * file,
	int line,
	const char * func,
	const char *_Nullable msg,
	... )
{
	va_list args;

	fprintf(stderr, "Requirement failed: %s\n", expr);
	if (msg) {
		fprintf(stderr, "--> ");
		va_start(args, msg);
		vfprintf(stderr, msg, args);
		va_end(args);
		fputc('\n', stderr);
	}
	if (file && func) {
		fprintf(stderr, "Location: %s:%d (%s)\n", file, line, func);
	}
#if TESTING
	if (requirementTrap.armed) {
		requirementTrap.lastExpr = expr;
		requirementTrap.armed = false;
		longjmp(requirementTrap.env, 1);
	}
#endif
	abort();
}
