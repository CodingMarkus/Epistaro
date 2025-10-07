#include <stddef.h> // IWYU pragma: keep
#include <stdint.h>  // IWYU pragma: keep
#include <stdbool.h>  // IWYU pragma: keep

#pragma clang visibility push(hidden)

#define nil  NULL

#define _nil      _Nullable
#define _not_nil  _Nonnull


#define _STR(x)  #x
#define STR(x)   _STR(x)