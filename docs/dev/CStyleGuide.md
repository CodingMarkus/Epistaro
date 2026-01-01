C CODING STYLE GUIDE
====================

1. General Rules
----------------
All comments must be in English. Function and variable names must also be in English.

Indentation uses tabs. A tab counts as 4 spaces.

Tabs are used strictly for indentation. For alignment, use spaces.


2. Includes and Header Structure
--------------------------------
Use "#pragma once" to avoid duplicate includes.

Include project headers before external library headers, and external headers before system headers. Leave one blank line between those sections.

Examples:

	#include "data.h" // Project
	#include "config.h" // Project

	#include "moduleA/file.h" // External lib
	#include "moduleB/array.h" // External lib

	#include <stdint.h> // System
	#include <stdlib.h> // System


3. Line Breaking
----------------
Lines must not exceed 80 characters. The line break itself counts as a character, so the last visible character may only occupy column 79.

When a single expression must be broken, indent the continuation line. When broken again, do not indent again, unless this time a sub-expression is broken.

Break before mathematical operators (+, -, *, /, %) and logical operators (&&, ||, &, |, ^, <<, >>).

Break after assignment operators (=).

Break before comparison operators (==, !=, <, >).

Break before reference operators (. and ->).

Break directly after (, [, or {.

The closing delimiters ), ], or } appear on an own, unindented line, unless that same line starts a new code block with {, in which case they appear on the last intended line.

Examples:

	a = b
		+ c
		+ d;

	a = x + (
		a + b
		+ c
	);

	a = fetchValue(
		source, type,
		style
	);

	a = fetchValue(
		source, getType(
			Argument
		),
		style
	);

	veryLongName =
		very long expression;

	isEqual = (
		value1 == value2
	);

	value = ptr
		->subPtr
		->subPtr2;

	value = otherValue
		.field
		.subField;

	a = fetchValue(
		source
	) + c;

	a = fetchValue(
		getSource(
			srcPtr
		).value
	);

	if (
		a == b
		&& c == d
		&& (
			e || someFunction(
				someArgument
			)
		))
	{
		// code
	}


4. Preprocessor Macros
----------------------
Preprocessor directives always start at zero indentation, regardless of surrounding code.

Nested #if/#ifdef blocks are indented like code.

Examples:

			statement;
	#if XXX
			statement;
		#if XYZ
			statement;
		#endif
	#endif

Function-like macros must be defined and invoked with the same spacing conventions as regular functions.

When breaking macros across multiple lines, align the backslashes. Place at least one space before each backslash. Ignore the last line.

Examples:

	#define XXX              \
		statement;           \
		very_long_statement; \
		last_statement_even_longer;


5. Types, Variables, and Constants
----------------------------------
Use const for true constant values instead of preprocessor defines. Constant names must be all uppercase with underscores between words. True constants must be defined at file scope, never inside functions.

Also use const wherever possible for variables, but those use camel case.

Examples:

	const int MAX_USERS = 1024; // True constant

	const time_t timeNow = time(NULL);

	for (size_t tableIndex = 0; tableIndex < MAX_USERS; tableIndex++) {

Do not expose variables and constants outside the current module (no extern). Use getter functions so external code can only obtain those values through function calls.

Avoid signed types unless negative values are required.

Only use char for character values, not for byte sized ints. Do not assume whether char is signed or unsigned; for character data this does not matter.

Enum names and structure names start with uppercase.

Place { on the same line as the enum/structure definition. Put each enum value or structure field on its own line.

Prefix enum values with enum name and underscore. The last enum value must also end with a comma.

Examples:

	enum EName {
		EName_Value1 = 1,
		EName_Value2,
		EName_Value3,
	};

Structures can be defined on a single line if they are simple (no pointers, no nested structures/unions) and short (at most 5 fields) and still fit within the line length limit.

Examples:

	struct Coordinate { float x; float y; };

	struct Complex {
		// many fields
	};

When initializing simple structs, fields don't need to be named. For complex structs, name fields and place a trailing comma after the last field. Fields that should be zero/NULL may be omitted.

Examples:

	struct Coordinate coord = { 0 };

	struct Coordinate coord = { 1, 2 };

	struct Complex cmplx = {
		.field1 = value1,
		.field2 = value2,
		.field3 = value3,
		// All other fields are zero/NULL
	};

Do not typedef every structure and enum into the global namespace. Only typedef opaque types and enums used as options; keeping namespaces separate is often advantageous.


6. Pointers and Arrays
----------------------
Place spaces around * when used as multiplication or in pointer declarations, but not when used for dereferencing.

Examples:

	int a = b * c;
	uint8_t * ptr = ...;
	uint8_t value = *ptr;

Function pointers must always be assigned using the & operator.

	funcPtr = &func;

When defining an array without fixed bounds, place a space between [ and ]. Also place a space between { and } in initializers.

Examples:

	int a[ ] = { 1, 2, 3, 4, 5 };

When declaring function parameters:
- int * a means that a is a pointer to an int.
- int a[] means that a is a pointer to the first element of an int array.


7. Functions
------------
Functions with external linkage start with an uppercase letter. File-local functions start with a lowercase letter.

There is no space between a function name and its parentheses when calling it.

There is a space inside parentheses when declaring or defining functions.

Examples:

	int GetValue( );

	void addValue( struct Array * ar, const void * value );

	int sumUp( int values[], size_t count );

	void func1( int a, int b );

	inline
	int func2( int a, int b )
	{
		// body
	}

	int c = func2(20, 30);

In function definitions the opening brace { is on its own line.

Function attributes are placed on their own line above the function definition.

Between the closing brace of a function and the next statement there are two blank lines. Three blank lines separate groups of functions. Inside functions there is at most one blank line to group instructions. If you need to group multiple instructions groups, use grouping comments.

Function declarations, definitions and calls may be broken along their parameters. There may be up to three parameters per line for up to two lines. If more than two lines are required, there is one parameter per line.


Examples:

	void func1( param1, param2 );

	void func1(
		param1, param2, param3
	);

	void func1(
		param1, param2, param3,
		param4, param5, param6
	);

	void func1(
		param1,
		param2,
		param3,
		param4,
		param5,
		param6,
		param7,
		param8
	);


8. Control Flow
---------------
Place { on the same line as if, for, while, etc. whenever possible.

Do not use braces for single-statement branches unless the statement is broken across lines.

Use braces for multi-statement branches.

If a control structure must be broken across lines, the closing parenthesis is on the last condition line, not on its own line. The brace { starts on the next line.

Examples:

	if (cond) singleStatement;

	if (condition1
		&& condition2
		&& condition3)
	{
		singleStatement;
	}

	if (cond) {
		// multiple statements
	}

	for (init; test; each) singleStatement;

	for (init; test; each) {
		// ...
	}

	for (
		init;
		test;
		each)
	{
		// ...
	}

Break while at the end of a do-while loop just as you would break a function call.

Exception: a single line may contain two statements only if the second is a control flow statement (break, return, goto).

Examples:

	if (cond) { doSomething(); break; }

Prefer early returns if possible.

Avoid goto except for clean up purposes.

Switch statements:

Indent every case as well as every case body. Always use { and }, unless the statement fits a single line and doesn't require new stack variables.

Each case must end with break, return, or goto. If fallthrough is intended, it must be documented with a comment, unless using a fallthrough statement is already required.

Examples:

	switch (x) {
		case 1: statement; statement; break;
		case 2: statement; statement; // fallthrough
		case 3: statement; statement; return;
	}

	switch (x) {
		case 1: {
			statement;
			statement;
			break;
		}

		case 4:
		case 2: {
			statement;
			statement;
			// fallthrough
		}

		case 3: {
			statement;
			statement;
			return;
		}
	}

Return may contain only a single value. If it contains an expression, wrap the expression in parentheses.

Examples:

	return 10;

	return a;

	return getValueFrom(x);

	return (a + b);

	return (getValueFrom(x) >> 3);



9. Expressions and Operators
----------------------------
Always use parentheses around ==, <, >, <=, >= when its result is part of a larger expression, but omit them if the expression is already enclosed in braces.

Examples:

	b = (a == b);
	b = x && (a == b);
	if (a == b) { // ...

Use parentheses to clarify operator precedence, even if not strictly necessary.

Examples:

	a = (b * c) + d;
	a = d || (b && c);
	if ((a == b) && (c == d)) { // ...

Ternary operators:
- If you need to break, break after ? and before : but only if necessary.
- Use the ternary operator ?: when you can.
- If you use a ternary within a complex statement, enclose it in parentheses.

Examples:

	x = testSomething() ? valueIfTrue : valueIfFalse;

	x = testSomething() ?
		valueIfTrue : valueIfFalse;

	x = testSomething() ?
		valueIfTrue
		: valueIfFalse;

	doSomething(a, b, ( c > d ? c : d ));


10. Strings
-----------
When breaking string literals, place the space before the line break.

Examples:

	"abc def "
		"hij klm"


11. Comments
------------
Use // for comments. Use /* ... */ only when a comment must be mid-line.

Prefer comments above code lines to comments at the end of a line if the comment refers the line as a whole. Prefer comments at the end of line if the comment refers to an assigned value.

Documentation comments use /** ... */ and are placed before functions. Lines inside documentation comments are not prefixed with * but are indented.

Examples:

	// Prefer this
	statement; // over that

	// That is, unless comment explains assigned value
	speed = 100; // 100 Mbit/s

	/**
		This is a documentation comment for the function below.
	*/
	static
	void function( ... )
	{
	}

Normal comments do not need to form full sentences. Documentation comments must always form full sentences.

If a normal comment is a single sentence, omit the final punctuation. If it consists of multiple sentences, end each sentence with a punctuation character, including the last one.

Use grouping comments to group blocks of code if this is required for better readability.


12. Consistency and Readably Always Win
---------------------------------------

Sometimes two or more adjacent blocks of code are closely related or perform the same operations but, due to different identifiers, would be formatted differently under the rules. In these cases, consistency takes priority, so the code forms a clear visual pattern.

For example, it is acceptable to add line breaks or adjust formatting, even when not strictly required, to keep similar statements aligned or to have the same line layout across multiple blocks.

Readability outweighs strict rule-following!
