#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

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
	abort();
}
