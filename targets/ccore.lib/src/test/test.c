#include "test/test.h"

#include "base/begin_impl.h"
begin_impl
// ============================================================================

#if TESTING

public
void _expectationHasFailed(
	const char * expr,
	const char * file,
	int line,
	const char * func,
	const char *_Nullable msg,
	... )
{
	va_list args;
    fprintf(stderr, "Expectation failed: %s\n", expr);
    if (msg) {
		fprintf(stderr, "--> ");
		va_start(args, msg);
		vfprintf(stderr, msg, args);
		va_end(args);
		fputc('\n', stderr);
	}
    fprintf(stderr, "Location: %s:%d (%s)\n", file, line, func);
	exit(EXIT_FAILURE);
}

#endif // TESTING

// ============================================================================
end_impl