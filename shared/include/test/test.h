#include <stdio.h>

#include "../begin_header.h"
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


// ============================================================================
end_header
#include "../end_header.h"