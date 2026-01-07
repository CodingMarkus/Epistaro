DOCUMENTATION SYNTAX GUIDE
==========================

1. Markdown
-----------
Do not manually break Markdown prose; let the editor wrap lines.

If you need a deliberate line break inside a paragraph (a sub-paragraph), end the line with `\`.


2. Shell Scripts
----------------
Document each function with a `#` comment block directly above its definition.

List parameters first because function signature doesn't list them in shell scripts and knowing those are the most important information. List one per line, in order:

- Mandatory parameters
- Optional parameters
- Variadic arguments

E.g.

	# $1 - Mandatory parameter description.
	# ($2) - Optional parameter description.
	# $3..n - Variadic argument description.

Use a single `#` line as a blank line between the parameter list and the summary, and another blank `#` line before the function signature.

Write the description as short, but full sentences, each line prefixed with `#`.


3. Source Code
--------------
Use `/** ... */` doc comments for public APIs, macros, and key types, placed directly above the declaration or definition.

Start with a short summary, then optional paragraphs separated by a blank line. Keep all content tab-indented and do not prefix lines with `*`.

Document parameters but only if not obvious or trivial. Also not all parameters must be documented, only those that require some documentation.

Use tags where applicable:
`@param`, ``@returns`, `@note`, `@warning`, `@see`, `@code`/`@endcode`, and `@fn` (always use `fn` for macros, never for anything else).

For multi-line parameter descriptions, indent continuation lines with an extra tab.

Inline code uses backticks.

Use `*this*` for *italics*, `**this**` for **bold**, and `***this***` for ***bold italics***.

Code examples use `@code`/`@encode` blocks and are surrounded by blank lines.
