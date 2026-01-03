STYLE FILE FORMAT
=================

1. Overview
-----------
Style `.cfg` files define build settings (one per line) and directives for including other styles or setting variables. After expansion, the resulting lines are passed to the compiler/linker as build settings. Includes are expanded in-place, and include cycles are errors.


2. Line Handling
----------------
- Leading whitespace is ignored.
- Blank lines are ignored.
- Lines that start with `#` (after leading whitespace) are comments.
- Inline comments are not supported; `#` is only special at line start.
- Each remaining line becomes a single setting; there is no line continuation.
- Lines starting with `$` must be recognized directives.


3. Directives
-------------
* `$include<path>`
    * Include another style file. Relative paths are resolved against the
    including file's directory.

* `$include?<path>`
    * Optional include. Missing files are ignored.

* `$set <NAME> [VALUE]`
    * Set a style variable. `VALUE` is optional (empty string if omitted).

* `$unset <NAME>`
    * Unset a style variable.

* `$include(condition) <path>` / `$include?(condition) <path>`
    * Conditional include. The condition must be in parentheses and on the same
    line as the directive. There is no space between `$include`/`$include?` and
    the opening `(`.

Unknown directives (any other line starting with `$`) are errors.


4. Conditions
-------------
Conditions are only valid in `$include`/`$include?` lines:

* `if-set NAME`
    * True if `NAME` is set (even if the value is empty).

* `if-not-set NAME`
    * True if `NAME` is not set.

* `if-equal NAME VALUE`
    * True if `NAME` is set and equals `VALUE`.

* `if-not-equal NAME VALUE`
    * True if `NAME` is set and does not equal `VALUE`.

* `if-match NAME /regex/`
    * True if `NAME` is set and its value matches the regex (grep -E syntax).

* `if-not-match NAME /regex/`
    * True if `NAME` is not set or does not match the regex.

`VALUE` in `if-equal` and `if-not-equal` is parsed using the same rules as `$set` values.


5. Variables and Values
-----------------------
Variable names must match `[A-Za-z][A-Za-z0-9_]*`. Names starting with `_` are reserved for system use and cannot be set/unset in style files.

Value parsing rules:

- Unquoted values are trimmed (leading/trailing whitespace removed).

- Double-quoted values preserve whitespace and support escapes: `\n`, `\r`,
  `\t`, `\"`, `\\`. Other escapes keep the backslash.

- Trailing text after a quoted value is an error.


Only all-caps variable names (`[A-Z][A-Z0-9_]*`) are exported to the build environment as `__style_set_<NAME>`.

External variables:

- The build system defines `_TARGET`, `_TARGET_OS`, and `_TARGET_CPU` for use in
include conditions.

- Any environment variable named `__style_set_<NAME>` is treated as a pre-set style variable.


6. Examples
-----------
Example style file:

    # Base flags
    $include _defaults/_default.cfg

    # Enable deploy post-processing
    $set DEPLOY_PROCESSING

    # macOS-only flags
    $include(if-equal _TARGET_OS "macos") _defaults/macos.cfg

    # Optional local overrides
    $include? ../_inc/_default.cfg
