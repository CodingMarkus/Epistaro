#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

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
		fprintf(stderr, "Message: ");
		va_start(args, msg);
		vfprintf(stderr, msg, args);
		va_end(args);
		fputc('\n', stderr);
	}
    fprintf(stderr, "Location: %s:%d (%s)\n", file, line, func);
    abort();
}
