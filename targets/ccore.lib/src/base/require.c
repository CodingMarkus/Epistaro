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
} requirementTrap;

__attribute__((visibility("default")))
int _armRequireTrap( const char * expectedExpr )
{
	requirementTrap.armed = true;
	requirementTrap.expectedExpr = expectedExpr;
	return setjmp(requirementTrap.env);
}

__attribute__((visibility("default")))
void _disarmRequireTrap( void )
{
	requirementTrap.armed = false;
	requirementTrap.expectedExpr = NULL;
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
		if (!requirementTrap.expectedExpr
			|| strcmp(requirementTrap.expectedExpr, expr) == 0)
		{
			requirementTrap.armed = false;
			longjmp(requirementTrap.env, 1);
		}

		fprintf(
			stderr, "Expected requirement: %s\n",
			(requirementTrap.expectedExpr ?
				requirementTrap.expectedExpr : "(any)"
			)
		);
	}
#endif
	abort();
}
