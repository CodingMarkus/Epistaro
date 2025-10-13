C CODING STYLE GUIDE — CHEAT SHEET
==================================

1. General Rules
----------------
- Comments, function names, variable names in English.
- Tabs for indentation (tab = 4 spaces). Spaces for alignment only.

2. Includes and Header Structure
--------------------------------
- Use "#pragma once".
- Project headers → external headers → system headers.
- Blank line between groups.

3. Line Breaking
----------------
- Max 80 characters (line break counts).
- Indent continuation lines.
- If break spans >1 line, wrap whole expression in ( ).
- Break before operators (+, -, *, /, %, &&, ||, &, |, ^, <<, >>).
- Break after assignment (=).
- Break line before comparison (==).
- Break after (, [, { if required — closing symbol alone on line.

4. Preprocessor Macros
----------------------
- Directives start at column 0.
- Indent nested #if/#ifdef like code.
- Function-like macros use function spacing.
- Align backslashes, add at least one space before each, ignore last line.

5. Types, Variables, and Constants
----------------------------------
- const instead of #define for true constants (file scope only).
- Constants ALL_CAPS, variables camelCase.
- Use size_t for array indices and counters.
- Avoid signed unless needed.
- Use stdint.h types.
- char only for characters; use (u)int8_t for bytes.
- Enums/structs start uppercase, { on same line, one field per line.
- Enum values prefixed with enum name.
- Do not typedef everything; typedef only if clarity improves.

6. Pointers and Arrays
----------------------
- Space around * in declarations, not in dereference.
- Function pointers must use & when assigned.
- Arrays: space inside [] and {} when size omitted or initializer used.
- Parameters: “int * a” is pointer; “int a[]” is array pointer.

7. Functions
------------
- External linkage: Uppercase. File-local: lowercase.
- Namespaced as submodule_function.
- No space between call name and ( ).
- Space inside ( ) in declarations/definitions.
- { on own line in definitions.
- Attributes on line above function.
- Two blank lines after function, three between groups.
- One blank line between instruction groups inside functions.
- Declarations/definitions/calls break: one line if fits, grouped if two lines, one per line if more.

8. Control Flow
---------------
- { on same line as if/for/while.
- No braces for single-statement branches (unless broken).
- Use braces for multi-statement branches.
- Multi-line conditions: ) on last line, { on next line.
- do { } while — break while like function call.
- One line may contain two statements only if second is control flow.
- Prefer early returns.
- goto only for cleanup.
- switch: indent case and body. Use { } unless simple single-line.
- Each case ends with break/return/goto. Fallthrough requires comment.
- return only one value; if expression, wrap in ( ).

9. Expressions and Operators
----------------------------
- Parentheses around ==, <, >, <=, >= if part of larger expression.
- Add parentheses for clarity even if not required.
- Ternary (?:) only if clear. Break after ? and before : if needed.
- Parenthesize ternary if inside larger expression.

10. Strings
-----------
- Break strings before line break, space at end of line.

11. Comments
------------
- Use //, /* ... */ only mid-line.
- Prefer comments above a line if referring to the line as a whole.
- Prefer end-of-line comments if explaining an assigned value.
- Documentation: /** ... */ before functions, indented, no * prefix per line.
- Normal comments: do not need full sentences.
- Doc comments: must be full sentences.
- Single-sentence normal comment: omit final punctuation.
- Multi-sentence normal comment: end each with punctuation.
