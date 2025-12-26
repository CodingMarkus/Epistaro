#pragma once

// ============================================================================

// Multi-assignment guard macros
#define _guardTmp1( n )  CONCAT(_guardTmp1Value, n)
#define _guardTmp2( n )  CONCAT(_guardTmp2Value, n)
#define _guardTmp3( n )  CONCAT(_guardTmp3Value, n)
#define _guardTmp4( n )  CONCAT(_guardTmp4Value, n)
#define _guardTmp5( n )  CONCAT(_guardTmp5Value, n)
#define _guardTmp6( n )  CONCAT(_guardTmp6Value, n)
#define _guardTmp7( n )  CONCAT(_guardTmp7Value, n)
#define _guardTmp8( n )  CONCAT(_guardTmp8Value, n)


#define _guard_def_var( var, tmp ) \
	def var = (typeof(*(tmp)) * _Nonnull)(tmp)


#define _guard_0( n, ... ) \
	ERROR_guard_requires_at_least_one_assignment

#define _guard_1( n, ... ) \
	ERROR_guard_requires_at_least_one_assignment


// 1 assignment, no extra condition: guard(v1, e1)
#define _guard_2(             \
	n, v1, e1 )               \
{                             \
	def _guardTmp1(n) = (e1); \
	if (_guardTmp1(n))        \
	{                         \
		_guard_def_var(v1, _guardTmp1(n));


// 1 assignment + condition: guard(v1, e1, cond)
#define _guard_3(             \
	n, v1, e1, cond )         \
{                             \
	def _guardTmp1(n) = (e1); \
	if (_guardTmp1(n)         \
		&& (cond) )           \
	{                         \
		_guard_def_var(v1, _guardTmp1(n));


// 2 assignments: guard(v1, e1, v2, e2)
#define _guard_4(                          \
	n, v1, e1, v2, e2 )                    \
{                                          \
	def _guardTmp1(n) = (e1);              \
	def _guardTmp2(n) = (e2);              \
	if (_guardTmp1(n)                      \
		&& _guardTmp2(n) )                 \
	{                                      \
		_guard_def_var(v1, _guardTmp1(n)); \
		_guard_def_var(v2, _guardTmp2(n));


// 2 assignments + condition
#define _guard_5(                          \
	n, v1, e1, v2, e2, cond )              \
{                                          \
	def _guardTmp1(n) = (e1);              \
	def _guardTmp2(n) = (e2);              \
	if (_guardTmp1(n)                      \
		&& _guardTmp2(n)                   \
		&& (cond) )                        \
	{                                      \
		_guard_def_var(v1, _guardTmp1(n)); \
		_guard_def_var(v2, _guardTmp2(n));


// 3 assignments
#define _guard_6(                          \
	n, v1, e1, v2, e2, v3, e3 )            \
{                                          \
	def _guardTmp1(n) = (e1);              \
	def _guardTmp2(n) = (e2);              \
	def _guardTmp3(n) = (e3);              \
	if (_guardTmp1(n)                      \
		&& _guardTmp2(n)                   \
		&& _guardTmp3(n) )                 \
	{                                      \
		_guard_def_var(v1, _guardTmp1(n)); \
		_guard_def_var(v2, _guardTmp2(n)); \
		_guard_def_var(v3, _guardTmp3(n));


// 3 assignments + condition
#define _guard_7(                          \
	n, v1, e1, v2, e2, v3, e3, cond )      \
{                                          \
	def _guardTmp1(n) = (e1);              \
	def _guardTmp2(n) = (e2);              \
	def _guardTmp3(n) = (e3);              \
	if (_guardTmp1(n)                      \
		&& _guardTmp2(n)                   \
		&& _guardTmp3(n)                   \
		&& (cond) )                        \
	{                                      \
		_guard_def_var(v1, _guardTmp1(n)); \
		_guard_def_var(v2, _guardTmp2(n)); \
		_guard_def_var(v3, _guardTmp3(n));


// 4 assignments
#define _guard_8(                          \
	n, v1, e1, v2, e2, v3, e3, v4, e4 )    \
{                                          \
	def _guardTmp1(n) = (e1);              \
	def _guardTmp2(n) = (e2);              \
	def _guardTmp3(n) = (e3);              \
	def _guardTmp4(n) = (e4);              \
	if (_guardTmp1(n)                      \
		&& _guardTmp2(n)                   \
		&& _guardTmp3(n)                   \
		&& _guardTmp4(n) )                 \
	{                                      \
		_guard_def_var(v1, _guardTmp1(n)); \
		_guard_def_var(v2, _guardTmp2(n)); \
		_guard_def_var(v3, _guardTmp3(n)); \
		_guard_def_var(v4, _guardTmp4(n));


// 4 assignments + condition
#define _guard_9(                             \
	n, v1, e1, v2, e2, v3, e3, v4, e4, cond ) \
{                                             \
	def _guardTmp1(n) = (e1);                 \
	def _guardTmp2(n) = (e2);                 \
	def _guardTmp3(n) = (e3);                 \
	def _guardTmp4(n) = (e4);                 \
	if (_guardTmp1(n)                         \
		&& _guardTmp2(n)                      \
		&& _guardTmp3(n)                      \
		&& _guardTmp4(n)                      \
		&& (cond) )                           \
	{                                         \
		_guard_def_var(v1, _guardTmp1(n));    \
		_guard_def_var(v2, _guardTmp2(n));    \
		_guard_def_var(v3, _guardTmp3(n));    \
		_guard_def_var(v4, _guardTmp4(n));


// 5 assignments
#define _guard_10(                               \
	n,  v1, e1, v2, e2, v3, e3, v4, e4, v5, e5 ) \
{                                                \
	def _guardTmp1(n) = (e1);                    \
	def _guardTmp2(n) = (e2);                    \
	def _guardTmp3(n) = (e3);                    \
	def _guardTmp4(n) = (e4);                    \
	def _guardTmp5(n) = (e5);                    \
	if (_guardTmp1(n)                            \
		&& _guardTmp2(n)                         \
		&& _guardTmp3(n)                         \
		&& _guardTmp4(n)                         \
		&& _guardTmp5(n) )                       \
	{                                            \
		_guard_def_var(v1, _guardTmp1(n));       \
		_guard_def_var(v2, _guardTmp2(n));       \
		_guard_def_var(v3, _guardTmp3(n));       \
		_guard_def_var(v4, _guardTmp4(n));       \
		_guard_def_var(v5, _guardTmp5(n));


// 5 assignments + condition
#define _guard_11(                              \
	n,  v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, \
	cond )                                      \
{                                               \
	def _guardTmp1(n) = (e1);                   \
	def _guardTmp2(n) = (e2);                   \
	def _guardTmp3(n) = (e3);                   \
	def _guardTmp4(n) = (e4);                   \
	def _guardTmp5(n) = (e5);                   \
	if (_guardTmp1(n)                           \
		&& _guardTmp2(n)                        \
		&& _guardTmp3(n)                        \
		&& _guardTmp4(n)                        \
		&& _guardTmp5(n)                        \
		&& (cond) )                             \
	{                                           \
		_guard_def_var(v1, _guardTmp1(n));      \
		_guard_def_var(v2, _guardTmp2(n));      \
		_guard_def_var(v3, _guardTmp3(n));      \
		_guard_def_var(v4, _guardTmp4(n));      \
		_guard_def_var(v5, _guardTmp5(n));


// 6 assignments
#define _guard_12(                                       \
	n,  v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6 ) \
{                                                        \
	def _guardTmp1(n) = (e1);                            \
	def _guardTmp2(n) = (e2);                            \
	def _guardTmp3(n) = (e3);                            \
	def _guardTmp4(n) = (e4);                            \
	def _guardTmp5(n) = (e5);                            \
	def _guardTmp6(n) = (e6);                            \
	if (_guardTmp1(n)                                    \
		&& _guardTmp2(n)                                 \
		&& _guardTmp3(n)                                 \
		&& _guardTmp4(n)                                 \
		&& _guardTmp5(n)                                 \
		&& _guardTmp6(n) )                               \
	{                                                    \
		_guard_def_var(v1, _guardTmp1(n));               \
		_guard_def_var(v2, _guardTmp2(n));               \
		_guard_def_var(v3, _guardTmp3(n));               \
		_guard_def_var(v4, _guardTmp4(n));               \
		_guard_def_var(v5, _guardTmp5(n));               \
		_guard_def_var(v6, _guardTmp6(n));


// 6 assignments + condition
#define _guard_13(                                      \
	n,  v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, \
	cond )                                              \
{                                                       \
	def _guardTmp1(n) = (e1);                           \
	def _guardTmp2(n) = (e2);                           \
	def _guardTmp3(n) = (e3);                           \
	def _guardTmp4(n) = (e4);                           \
	def _guardTmp5(n) = (e5);                           \
	def _guardTmp6(n) = (e6);                           \
	if (_guardTmp1(n)                                   \
		&& _guardTmp2(n)                                \
		&& _guardTmp3(n)                                \
		&& _guardTmp4(n)                                \
		&& _guardTmp5(n)                                \
		&& _guardTmp6(n)                                \
		&& (cond) )                                     \
	{                                                   \
		_guard_def_var(v1, _guardTmp1(n));              \
		_guard_def_var(v2, _guardTmp2(n));              \
		_guard_def_var(v3, _guardTmp3(n));              \
		_guard_def_var(v4, _guardTmp4(n));              \
		_guard_def_var(v5, _guardTmp5(n));              \
		_guard_def_var(v6, _guardTmp6(n));


// 7 assignments
#define _guard_14(                                      \
	n,  v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, \
	v7, e7 )                                            \
{                                                       \
	def _guardTmp1(n) = (e1);                           \
	def _guardTmp2(n) = (e2);                           \
	def _guardTmp3(n) = (e3);                           \
	def _guardTmp4(n) = (e4);                           \
	def _guardTmp5(n) = (e5);                           \
	def _guardTmp6(n) = (e6);                           \
	def _guardTmp7(n) = (e7);                           \
	if (_guardTmp1(n)                                   \
		&& _guardTmp2(n)                                \
		&& _guardTmp3(n)                                \
		&& _guardTmp4(n)                                \
		&& _guardTmp5(n)                                \
		&& _guardTmp6(n)                                \
		&& _guardTmp7(n) )                              \
	{                                                   \
		_guard_def_var(v1, _guardTmp1(n));              \
		_guard_def_var(v2, _guardTmp2(n));              \
		_guard_def_var(v3, _guardTmp3(n));              \
		_guard_def_var(v4, _guardTmp4(n));              \
		_guard_def_var(v5, _guardTmp5(n));              \
		_guard_def_var(v6, _guardTmp6(n));              \
		_guard_def_var(v7, _guardTmp7(n));


// 7 assignments + condition
#define _guard_15(                                      \
	n,  v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, \
	v7, e7, cond )                                      \
{                                                       \
	def _guardTmp1(n) = (e1);                           \
	def _guardTmp2(n) = (e2);                           \
	def _guardTmp3(n) = (e3);                           \
	def _guardTmp4(n) = (e4);                           \
	def _guardTmp5(n) = (e5);                           \
	def _guardTmp6(n) = (e6);                           \
	def _guardTmp7(n) = (e7);                           \
	if (_guardTmp1(n)                                   \
		&& _guardTmp2(n)                                \
		&& _guardTmp3(n)                                \
		&& _guardTmp4(n)                                \
		&& _guardTmp5(n)                                \
		&& _guardTmp6(n)                                \
		&& _guardTmp7(n)                                \
		&& (cond) )                                     \
	{                                                   \
		_guard_def_var(v1, _guardTmp1(n));              \
		_guard_def_var(v2, _guardTmp2(n));              \
		_guard_def_var(v3, _guardTmp3(n));              \
		_guard_def_var(v4, _guardTmp4(n));              \
		_guard_def_var(v5, _guardTmp5(n));              \
		_guard_def_var(v6, _guardTmp6(n));              \
		_guard_def_var(v7, _guardTmp7(n));


// 8 assignments
#define _guard_16(                                      \
	n,  v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, \
	v7, e7, v8, e8 )                                    \
{                                                       \
	def _guardTmp1(n) = (e1);                           \
	def _guardTmp2(n) = (e2);                           \
	def _guardTmp3(n) = (e3);                           \
	def _guardTmp4(n) = (e4);                           \
	def _guardTmp5(n) = (e5);                           \
	def _guardTmp6(n) = (e6);                           \
	def _guardTmp7(n) = (e7);                           \
	def _guardTmp8(n) = (e8);                           \
	if (_guardTmp1(n)                                   \
		&& _guardTmp2(n)                                \
		&& _guardTmp3(n)                                \
		&& _guardTmp4(n)                                \
		&& _guardTmp5(n)                                \
		&& _guardTmp6(n)                                \
		&& _guardTmp7(n)                                \
		&& _guardTmp8(n) )                              \
	{                                                   \
		_guard_def_var(v1, _guardTmp1(n));              \
		_guard_def_var(v2, _guardTmp2(n));              \
		_guard_def_var(v3, _guardTmp3(n));              \
		_guard_def_var(v4, _guardTmp4(n));              \
		_guard_def_var(v5, _guardTmp5(n));              \
		_guard_def_var(v6, _guardTmp6(n));              \
		_guard_def_var(v7, _guardTmp7(n));              \
		_guard_def_var(v8, _guardTmp8(n));


// 8 assignments + condition
#define _guard_17(                                      \
	n,  v1, e1, v2, e2, v3, e3, v4, e4, v5, e5, v6, e6, \
	v7, e7, v8, e8, cond )                              \
{                                                       \
	def _guardTmp1(n) = (e1);                           \
	def _guardTmp2(n) = (e2);                           \
	def _guardTmp3(n) = (e3);                           \
	def _guardTmp4(n) = (e4);                           \
	def _guardTmp5(n) = (e5);                           \
	def _guardTmp6(n) = (e6);                           \
	def _guardTmp7(n) = (e7);                           \
	def _guardTmp8(n) = (e8);                           \
	if (_guardTmp1(n)                                   \
		&& _guardTmp2(n)                                \
		&& _guardTmp3(n)                                \
		&& _guardTmp4(n)                                \
		&& _guardTmp5(n)                                \
		&& _guardTmp6(n)                                \
		&& _guardTmp7(n)                                \
		&& _guardTmp8(n)                                \
		&& (cond) )                                     \
	{                                                   \
		_guard_def_var(v1, _guardTmp1(n));              \
		_guard_def_var(v2, _guardTmp2(n));              \
		_guard_def_var(v3, _guardTmp3(n));              \
		_guard_def_var(v4, _guardTmp4(n));              \
		_guard_def_var(v5, _guardTmp5(n));              \
		_guard_def_var(v6, _guardTmp6(n));              \
		_guard_def_var(v7, _guardTmp7(n));              \
		_guard_def_var(v8, _guardTmp8(n));


#define _guard_expand( count, n, ... ) \
	CONCAT(_guard_, count)(n, __VA_ARGS__)


/**
	@fn void guard(...)
	`guard` opens a block that runs only when its assignments (and optional
	condition) succeed.

	- Use as `guard(v1, expr1 [, v2, expr2 ...][, cond]) { ... } endguard`.
	- An `else` block is supported: `guard(...) { ... } else { ... } endguard`.
	- `guard` always requires at least one `var, expr` pair; each expression
	  is evaluated once, stored in a unique temporary, and then exposed as a
	  `def`-ined variable inside the block when all expressions (and any
	  trailing condition) are truthy.
	- Close every `guard` with the matching `endguard` macro to emit the
	  closing braces.
 */
#define guard( ... ) \
	_guard_expand(COUNT_ARGS(__VA_ARGS__), __COUNTER__, __VA_ARGS__)


#define endguard \
	} }
