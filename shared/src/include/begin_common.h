#include <stddef.h> // IWYU pragma: keep
#include <stdint.h>  // IWYU pragma: keep
#include <stdbool.h>  // IWYU pragma: keep

#define nil  NULL

#define _opt  _Nullable
#define _req  _Nonnull

#define Opt( type ) type _opt

#define _STR( x )  #x
#define STR( x )   _STR(x)

#define _CONCAT( x, y )  x ## y
#define CONCAT( x, y )   _CONCAT(x, y)

#define defEnum( name, type ) \
    enum __attribute__((enum_extensibility(closed))) name : type

#define defOpenEnum( name, type ) \
    enum __attribute__((enum_extensibility(open))) name : type

#define defOptions( name, type )                                          \
    typedef enum __attribute__((flag_enum, enum_extensibility(open)))     \
        name : type name;                                                 \
    enum __attribute__((flag_enum, enum_extensibility(closed))) name : type
