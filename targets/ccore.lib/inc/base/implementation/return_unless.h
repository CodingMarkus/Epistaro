#pragma once

// ============================================================================

#define _return_unless_assign( returnValue, var, expr ) \
	def var = (typeof(*(expr)) * _Nonnull)(expr);       \
	if(!(var)) return (returnValue)



// No arguments: return_unless() is invalid
#define _return_unless_0( ... ) \
	ERROR_return_unless_requires_at_least_2_arguments


// Single argument: return_unless() is invalid
#define _return_unless_1( ... ) \
	ERROR_return_unless_requires_at_least_2_arguments


// Condition only: return_unless(returnValue, cond)
#define _return_unless_2( returnValue, cond ) \
	if(!(cond)) return (returnValue)


// 1 assignment: return_unless(returnValue, v1, e1)
#define _return_unless_3( returnValue, v1, e1 ) \
	_return_unless_assign(returnValue, v1, e1)


// 1 assignment + condition
#define _return_unless_4( returnValue, v1, e1, cond ) \
	_return_unless_3(returnValue, v1, e1);            \
	_return_unless_2(returnValue, cond)


// 2 assignments
#define _return_unless_5( returnValue, v1, e1, v2, e2 ) \
	_return_unless_3(returnValue, v1, e1);              \
	_return_unless_assign(returnValue, v2, e2)


// 2 assignments + condition
#define _return_unless_6( returnValue, v1, e1, v2, e2, cond ) \
	_return_unless_5(returnValue, v1, e1, v2, e2);            \
	_return_unless_2(returnValue, cond)


// 3 assignments
#define _return_unless_7( returnValue, v1, e1, v2, e2, v3, e3 ) \
	_return_unless_5(returnValue, v1, e1, v2, e2);              \
	_return_unless_assign(returnValue, v3, e3)


// 3 assignments + condition
#define _return_unless_8(                              \
	returnValue,                                       \
	v1, e1, v2, e2, v3, e3, v4, e4, cond )             \
_return_unless_7(returnValue, v1, e1, v2, e2, v3, e3); \
_return_unless_2(returnValue, cond)


// 4 assignments
#define _return_unless_9(                              \
	returnValue,                                       \
	v1, e1, v2, e2, v3, e3, v4, e4 )                   \
_return_unless_7(returnValue, v1, e1, v2, e2, v3, e3); \
_return_unless_assign(returnValue, v4, e4)


// 4 assignments + condition
#define _return_unless_10(                                     \
	returnValue,                                               \
	v1, e1, v2, e2, v3, e3, v4, e4, cond )                     \
_return_unless_9(returnValue, v1, e1, v2, e2, v3, e3, v4, e4); \
_return_unless_2(returnValue, cond)


// 5 assignments
#define _return_unless_11(                                     \
	returnValue,                                               \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5 )                   \
_return_unless_9(returnValue, v1, e1, v2, e2, v3, e3, v4, e4); \
_return_unless_assign(returnValue, v5, e5)


// 5 assignments + condition
#define _return_unless_12(                         \
	returnValue,                                   \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, cond ) \
_return_unless_11(                                 \
	returnValue,                                   \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5);       \
_return_unless_2(returnValue, cond)


// 6 assignments
#define _return_unless_13(                           \
	returnValue,                                     \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6 ) \
_return_unless_11(                                   \
	returnValue,                                     \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5);         \
_return_unless_assign(returnValue, v6, e6)


// 6 assignments + condition
#define _return_unless_14(                                 \
	returnValue,                                           \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, cond ) \
_return_unless_13(                                         \
	returnValue,                                           \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6);       \
_return_unless_2(returnValue, cond)


// 7 assignments
#define _return_unless_15(                                   \
	returnValue,                                             \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, v7, e7 ) \
_return_unless_13(                                           \
	returnValue,                                             \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6);         \
_return_unless_assign(returnValue, v7, e7)


// 7 assignments + condition
#define _return_unless_16(                                         \
	returnValue,                                                   \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, v7, e7, cond ) \
_return_unless_15(                                                 \
	returnValue,                                                   \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, v7, e7);       \
_return_unless_2(returnValue, cond)


// 8 assignments
#define _return_unless_17(                                          \
	returnValue,                                                    \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, v7, e7, v8, e8) \
_return_unless_15(                                                  \
	returnValue,                                                    \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, v7, e7);        \
_return_unless_assign(returnValue, v8, e8)


// 8 assignments + condition
#define _return_unless_18(                                          \
	returnValue,                                                    \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, v7, e7, v8, e8, \
	cond )                                                          \
_return_unless_17(                                                  \
	returnValue,                                                    \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, v7, e7,         \
	v8, e8);                                                        \
_return_unless_2(returnValue, cond)



#define _return_unless_expand( count, ... ) \
	CONCAT(_return_unless_, count)(__VA_ARGS__)


/**
	@fn void return_unless(returnValue, ...)
	`return_unless` exits the current function with a value unless inputs
	pass.

	- `return_unless(return_value, cond)` returns `return_value` when
	  `cond` is false.
	- `return_unless(return_value, v1, expr1 [, v2, expr2 ...][, cond])`
	  assigns each `exprN` to `vN` (left-to-right) and returns
	  `return_value` if any evaluates to false/null, optionally checking a
	  trailing condition.
	- Each `return_unless` assignment uses `def` so the named variables stay
	  in scope after the macro.
 */
#define return_unless( ... ) \
	_return_unless_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)
