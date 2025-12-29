#ifdef _beginCppActive
	#error begin_cpp.h included twice without including end_cpp.h first
#endif
#define _beginCppActive

// ============================================================================

#define _STR_( x )  #x
#define STR( x )   _STR_(x)

// ============================================================================

#define _CONCAT_( x, y )  x ## y
#define CONCAT( x, y )    _CONCAT_(x, y)

// ============================================================================

#define COUNT_ARGS( ... )  _COUNT_ARGS_(__VA_ARGS__, _COUNT_ARGS_SEQ_)

#define _COUNT_ARGS_(...) _COUNT_ARGS_SELECT_(__VA_ARGS__)

#define _COUNT_ARGS_SELECT_(                \
	_1,  _2,  _3,  _4,  _5,  _6,  _7,  _8,  \
	_9, _10, _11, _12, _13, _14, _15, _16,  \
	_17, _18, _19, _20, _21, _22, _23, _24, \
	_25, _26, _27, _28, _29, _30, _31, _32, \
	N, ... )                                \
	N

#define _COUNT_ARGS_SEQ_                                            \
    32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, \
    16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0