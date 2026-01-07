#pragma once

// ============================================================================

void _requirementHasFailed(
	const char * expr,
	const char * file,
	int line,
	const char * func,
	const char * msg,
	...
);

#if TESTING

__attribute__((visibility("default")))
int _armRequireTrap( const char * expectedExpr );

__attribute__((visibility("default")))
void _disarmRequireTrap( void );

#endif // TESTING

// ============================================================================

#ifdef NDEBUG
	#define _require_location NULL, 0, NULL
#else
	#define _require_location __FILE__, __LINE__, __func__
#endif

// Single argument: require(cond)
#define _require_1( cond )                       \
	((cond) ? (void)0                            \
		: _requirementHasFailed(                 \
			#cond, _require_location,            \
			NULL                                 \
		)                                        \
	)

// 2 arguments: require(cond, msg)
#define _require_2( cond, msg )                  \
	((cond) ? (void)0                            \
		: _requirementHasFailed(                 \
			#cond, _require_location,            \
			"%s", msg                            \
		)                                        \
	)

// 3 arguments: require(cond, msg, a1)
#define _require_3( cond, msg, a1 )              \
	((cond) ? (void)0                            \
		: _requirementHasFailed(                 \
			#cond, _require_location,            \
			msg, a1                              \
		)                                        \
	)

// 4 arguments: require(cond, msg, a1, a2)
#define _require_4( cond, msg, a1, a2 )          \
	((cond) ? (void)0                            \
		: _requirementHasFailed(                 \
			#cond, _require_location,            \
			msg, a1, a2                          \
		)                                        \
	)

// 5 arguments: require(cond, msg, a1, a2, a3)
#define _require_5( cond, msg, a1, a2, a3 )      \
	((cond) ? (void)0                            \
		: _requirementHasFailed(                 \
			#cond, _require_location,            \
			msg, a1, a2, a3                      \
		)                                        \
	)

// 6 arguments: require(cond, msg, a1, a2, a3, a4)
#define _require_6( cond, msg, a1, a2, a3, a4 )  \
	((cond) ? (void)0                            \
		: _requirementHasFailed(                 \
			#cond, _require_location,            \
			msg, a1, a2, a3, a4                  \
		)                                        \
	)

// 7 arguments: require(cond, msg, a1, a2, a3, a4, a5)
#define _require_7( cond, msg, a1, a2, a3, a4, a5 ) \
	((cond) ? (void)0                               \
		: _requirementHasFailed(                    \
			#cond, _require_location,               \
			msg, a1, a2, a3, a4, a5                 \
		)                                           \
	)

// 8 arguments: require(cond, msg, a1, a2, a3, a4, a5, a6)
#define _require_8( cond, msg, a1, a2, a3, a4, a5, a6 ) \
	((cond) ? (void)0                                   \
		: _requirementHasFailed(                        \
			#cond, _require_location,                   \
			msg, a1, a2, a3, a4, a5, a6                 \
		)                                               \
	)

#define _require_expand( count, ... ) \
	CONCAT(_require_, count)(__VA_ARGS__)

#ifdef require
	#undef require
#endif

/**
	@fn void require(...)
	`require` aborts if `cond` is false.

	- `require(cond)` triggers on false `cond`.
	- `require(cond, msg)` prints a static message.
	- `require(cond, format, ...)` prints a formatted message.
 */
#define require( ... ) \
	_require_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)

// ============================================================================
