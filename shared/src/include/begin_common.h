#include <stddef.h> // IWYU pragma: keep
#include <stdint.h>  // IWYU pragma: keep
#include <stdbool.h>  // IWYU pragma: keep


#define nil  NULL

#define _nil      _Nullable
#define _not_nil  _Nonnull


#define _STR(x)  #x
#define STR(x)   _STR(x)


#define defEnum( name, type ) \
    enum __attribute__((enum_extensibility(closed))) name : type

#define defOpenEnum( name, type ) \
    enum __attribute__((enum_extensibility(open))) name : type

#define defOptions( name, type )                                          \
    typedef enum __attribute__((flag_enum, enum_extensibility(open)))     \
        name : type name;                                                 \
    enum __attribute__((flag_enum, enum_extensibility(closed))) name : type
