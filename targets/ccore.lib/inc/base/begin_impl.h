#pragma once

#include <assert.h>   // IWYU pragma: keep
#include <stdarg.h>   // IWYU pragma: keep
#include <string.h>   // IWYU pragma: keep

// ============================================================================

#include "common/begin_common.h"
#include "common/always/begin_ptr.h"

// ============================================================================

#include "implementation/assert.h"          // IWYU pragma: keep
#include "implementation/break_unless.h"    // IWYU pragma: keep
#include "implementation/builtin.h"         // IWYU pragma: keep
#include "implementation/continue_unless.h" // IWYU pragma: keep
#include "implementation/guard.h"           // IWYU pragma: keep
#include "implementation/return_unless.h"   // IWYU pragma: keep
#include "implementation/ptr.h"             // IWYU pragma: keep

// ============================================================================

#define begin_impl \
	_Pragma("clang assume_nonnull begin")

#define end_impl \
	_Pragma("clang assume_nonnull end")

// ============================================================================

#define init  __auto_type
#define def   const __auto_type

// ============================================================================

#define public __attribute__((visibility("default")))
