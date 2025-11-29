#ifdef STRICT_INCLUDE_CHECKS
	#ifndef _beginCppActive
		#error end_cpp.h included without including begin_cpp.h first
	#endif
#endif
#undef _beginCppActive

// ============================================================================

#undef _STR
#undef STR

// ============================================================================

#undef _CONCAT
#undef CONCAT

// ============================================================================

#undef COUNT_ARGS
#undef _COUNT_ARGS_
#undef _COUNT_ARGS_SELECT_
#undef _COUNT_ARGS_SEQ_
