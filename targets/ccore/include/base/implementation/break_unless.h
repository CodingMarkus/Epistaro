#pragma once

// ============================================================================

#define _break_unless_assign( var, expr )         \
	def var = (typeof(*(expr)) * _Nonnull)(expr); \
	if(!(var)) break


// No arguments: break_unless() is invalid
#define _break_unless_0( ... ) \
	ERROR_break_unless_requires_at_least_1_argument

// Single argument: break_unless() is invalid
#define _break_unless_1( cond ) \
	if(!(cond)) break

// 1 assignment: break_unless(v1, e1)
#define _break_unless_2( v1, e1 ) \
	_break_unless_assign(v1, e1)

// 1 assignment + condition
#define _break_unless_3( v1, e1, cond ) \
	_break_unless_2(v1, e1);            \
	_break_unless_1(cond)

// 2 assignments
#define _break_unless_4( v1, e1, v2, e2 ) \
	_break_unless_2(v1, e1);              \
	_break_unless_assign(v2, e2)

// 2 assignments + condition
#define _break_unless_5( v1, e1, v2, e2, cond ) \
	_break_unless_4(v1, e1, v2, e2);            \
	_break_unless_1(cond)

// 3 assignments
#define _break_unless_6( v1, e1, v2, e2, v3, e3 ) \
	_break_unless_4(v1, e1, v2, e2);              \
	_break_unless_assign(v3, e3)

// 3 assignments + condition
#define _break_unless_7( v1, e1, v2, e2, v3, e3, cond ) \
	_break_unless_6(v1, e1, v2, e2, v3, e3);            \
	_break_unless_1(cond)

// 4 assignments
#define _break_unless_8( v1, e1, v2, e2, v3, e3, v4, e4 ) \
	_break_unless_6(v1, e1, v2, e2, v3, e3);              \
	_break_unless_assign(v4, e4)

// 4 assignments + condition
#define _break_unless_9( v1, e1, v2, e2, v3, e3, v4, e4, cond ) \
	_break_unless_8(v1, e1, v2, e2, v3, e3, v4, e4);            \
	_break_unless_1(cond)

// 5 assignments
#define _break_unless_10(                            \
		v1, e1, v2, e2, v3, e3, v4, e4, v5, e5 )     \
	_break_unless_8(v1, e1, v2, e2, v3, e3, v4, e4); \
	_break_unless_assign(v5, e5)

// 5 assignments + condition
#define _break_unless_11(                                     \
		v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, cond )        \
	_break_unless_10(v1, e1, v2, e2, v3, e3, v4, e4, v5, e5); \
	_break_unless_1(cond)

// 6 assignments
#define _break_unless_12(                                     \
		v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6 )      \
	_break_unless_10(v1, e1, v2, e2, v3, e3, v4, e4, v5, e5); \
	_break_unless_assign(v6, e6)

// 6 assignments + condition
#define _break_unless_13(                                             \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, cond )            \
	_break_unless_12(v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6); \
	_break_unless_1(cond)

// 7 assignments
#define _break_unless_14(                                    \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, v7, e7 ) \
	_break_unless_12(v1, e1, v2, e2, v3, e3, v4, e4,         \
		v5, e5, v6, e6);                                     \
	_break_unless_assign(v7, e7)

// 7 assignments + condition
#define _break_unless_15(                                          \
	v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, v7, e7, cond ) \
	_break_unless_14(v1, e1, v2, e2, v3, e3, v4, e4,               \
		v5, e5, v6, e6, v7, e7);                                   \
	_break_unless_1(cond)

// 8 assignments
#define _break_unless_16(                            \
	v1, e1, v2, e2, v3, e3, v4, e4,                  \
	v5, e5, v6, e6, v7, e7, v8, e8 )                 \
	_break_unless_14(v1, e1, v2, e2, v3, e3, v4, e4, \
		v5, e5, v6, e6, v7, e7);                     \
	_break_unless_assign(v8, e8)

// 8 assignments + condition
#define _break_unless_17(                            \
	v1, e1, v2, e2, v3, e3, v4, e4,                  \
	v5, e5, v6, e6, v7, e7, v8, e8, cond )           \
	_break_unless_16(v1, e1, v2, e2, v3, e3, v4, e4, \
		v5, e5, v6, e6, v7, e7, v8, e8);             \
	_break_unless_1(cond)


#define _break_unless_expand( count, ... ) \
	CONCAT(_break_unless_, count)(__VA_ARGS__)


/**
	@fn void break_unless(...)
	`break_unless` short-circuits a loop when prerequisites are not met.

	- `break_unless(cond)` breaks when `cond` is false.
	- `break_unless(v1, expr1 [, v2, expr2 ...][, cond])` assigns each
	  `exprN` to `vN` (left-to-right) and breaks if any evaluates to
	  false/null, and can also check a trailing condition.
	- Each `break_unless` assignment uses `def` so the named variables stay
	  in scope after the macro.
 */
#define break_unless( ... ) \
	_break_unless_expand(COUNT_ARGS(__VA_ARGS__), __VA_ARGS__)
