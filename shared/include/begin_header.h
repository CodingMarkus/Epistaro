#include "../src/include/begin_common.h"


#define begin_header \
	_Pragma("clang assume_nonnull begin")

#define end_header \
	_Pragma("clang assume_nonnull end")


#define public __attribute__((visibility("default")))
