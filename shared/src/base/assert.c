#include <stdio.h>
#include <stdlib.h>

void _assertionHasFailed(
	const char * expr,
	const char * msg,
	const char * file,
	int line,
	const char * func )
{
    fprintf(stderr, "Assertion failed: %s\n", expr);
    if (msg) fprintf(stderr, "Message: %s\n", msg);
    fprintf(stderr, "Location: %s:%d (%s)\n", file, line, func);
    abort();
}