#ifdef STRICT_INCLUDE_CHECKS
	#ifndef _beginPtrActive
		#error end_ptr.h included without including begin_ptr.h first
	#endif
#endif
#undef _beginPtrActive

// ============================================================================

#undef _opt
#undef _req
#undef Opt

#undef OutPtr
#undef OutPtrOpt
#undef OptOutPtr
#undef OptOutPtrOpt

#undef PtrArrayOf
#undef OptPtrArrayOf
#undef PtrArrayOfOpt
#undef OptPtrArrayOfOpt
